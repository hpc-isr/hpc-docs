#!/bin/bash
set -Eeuo pipefail
trap 'printf "ERROR at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

user_uid=$(id -u)
port_offset=$((user_uid % 1000))
signal_port=$((49100 + port_offset))
stream_port=$((47998 + port_offset))
server_ip=$(ip -4 -o addr show ens3 | awk '{print $4}' | cut -d/ -f1)   # this node's private IP
printf '\nUser: %s (UID %s)\n' "$(id -un)" "$user_uid"
printf 'Server:      %s\n' "$server_ip"
printf 'Signal port: %s (TCP)\n' "$signal_port"
printf 'Stream port: %s (UDP)\n\n' "$stream_port"

image="/storage/software/containers/isaac-sim-6.1.0.sif"
scratch="/scratch/$(id -un)"
isaac_dir="$scratch/isaac-scratch"
sandbox="$isaac_dir/sandbox"

mountpoint -q /scratch || {
    echo "ERROR: /scratch is not mounted." >&2
    exit 1
}

umask 077
mkdir -p "$isaac_dir"

valid_sandbox() {
    [[ -d "$1/dev" &&
       -f "$1/etc/passwd" &&
       -f "$1/etc/group" &&
       -x "$1/isaac-sim/kit/kit" &&
       -f "$1/isaac-sim/runheadless.sh" ]]
}

# Build once; reuse on subsequent launches.
if ! valid_sandbox "$sandbox"; then
    [[ -r "$image" ]] || {
        echo "ERROR: Cannot read $image" >&2
        exit 1
    }

    stage=$(mktemp -d "$isaac_dir/build-XXXXXX")
    mkdir "$stage/tmp"

    printf '\nExtracting container into %s\n' "$stage/sandbox"
    APPTAINER_TMPDIR="$stage/tmp" \
        apptainer build --sandbox "$stage/sandbox" "$image"

    valid_sandbox "$stage/sandbox" || {
        echo "ERROR: Extracted container is incomplete." >&2
        exit 1
    }

    chmod -R u+rwX "$stage/sandbox/isaac-sim"

    if [[ -e "$sandbox" || -L "$sandbox" ]]; then
        mv "$sandbox" "$stage/previous-sandbox"
        printf 'Previous sandbox preserved in %s\n' "$stage/previous-sandbox"
    fi

    mv "$stage/sandbox" "$sandbox"
fi

printf '\nPreparing SSD-backed caches and configuration...\n'
binds=()

# Persistent, per-user Isaac state on the SSD.
state_dir="$isaac_dir/user-state"
mkdir -p "$state_dir"

# Overlay selected home directories only inside this container.
# The rest of the real home remains accessible.
for relative in \
    .cache \
    .nv \
    .nvidia-omniverse \
    .local/share/ov \
    .config/omniverse
do
    source_dir="$state_dir/$relative"
    target_dir="$HOME/$relative"

    mkdir -p "$source_dir"

    # Writable Apptainer containers require existing destinations.
    # This creates missing directories; existing contents are preserved.
    mkdir -p "$target_dir"

    binds+=(--bind "$source_dir:$target_dir")

    printf '  %s -> %s\n' "$target_dir" "$source_dir"
done

# Prepare destinations required by --nv with a writable sandbox.
for path in \
    /usr/bin/nvidia-smi \
    /usr/bin/nvidia-debugdump \
    /usr/bin/nvidia-persistenced \
    /usr/bin/nvidia-cuda-mps-control \
    /usr/bin/nvidia-cuda-mps-server \
    /usr/share/vulkan/icd.d/nvidia_icd.json \
    /usr/share/vulkan/implicit_layer.d/nvidia_layers.json \
    /usr/share/egl/egl_external_platform.d/10_nvidia_wayland.json \
    /usr/share/egl/egl_external_platform.d/15_nvidia_gbm.json \
    /usr/share/nvidia/nvoptix.bin
do
    if [[ -f "$path" && ! -e "$sandbox$path" && ! -L "$sandbox$path" ]]; then
        mkdir -p "$(dirname "$sandbox$path")"
        touch "$sandbox$path"
    fi
done

container_env=(
    --env ACCEPT_EULA=Y
    --env OMNICLIENT_HUB_MODE=disabled
)

if [[ ${CUDA_VISIBLE_DEVICES+x} ]]; then
    container_env+=(--env "CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES")
fi

printf '\nStarting Isaac Sim...\n'
exec apptainer exec \
    --nv --writable --cleanenv \
    --no-mount cwd \
    --home "$HOME:$HOME" \
    --pwd /isaac-sim \
    "${container_env[@]}" \
    "${binds[@]}" \
    "$sandbox" \
    bash -c '
        set -Eeuo pipefail

        signal_port="${1:?Missing signal port}"
        stream_port="${2:?Missing stream port}"
        server_ip="${3:?Missing server IP}"
        shift 3

        unset PRIVACY_CONSENT PYTHONDONTWRITEBYTECODE

        printf "Container ports: TCP %s, UDP %s\n" \
            "$signal_port" "$stream_port"

        exec ./runheadless.sh \
            "$@" \
            --/exts/omni.kit.livestream.app/primaryStream/publicIp="$server_ip" \
            --/exts/omni.kit.livestream.app/primaryStream/signalPort="$signal_port" \
            --/exts/omni.kit.livestream.app/primaryStream/streamPort="$stream_port"
    ' bash "$signal_port" "$stream_port" "$server_ip" "$@"
