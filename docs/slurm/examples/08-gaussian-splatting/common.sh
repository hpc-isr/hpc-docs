# shellcheck shell=bash
# Shared settings for prepare.sbatch and train.sbatch.
NS_IMAGE="${NS_IMAGE:-docker://ghcr.io/nerfstudio-project/nerfstudio:1.1.3}"
# The image on this node's /scratch, where Apptainer reads it much faster than from
# your home. /scratch is local to each node, so each step builds it on its node the
# first time (10–20 min); later jobs there reuse it.
SIF="${SIF:-/scratch/$USER/containers/nerfstudio-1.1.3.sif}"
SCENE_NAME="${SCENE_NAME:-truck}"
# Where each scene is kept: your home by default, or your group's NAS,
# e.g. RESULTS_DIR=/storage/anubis-nas/<group>/splats
RESULTS_DIR="${RESULTS_DIR:-$HOME/results/splats}"
SCENE_RESULTS="$RESULTS_DIR/$SCENE_NAME"     # data/ (frames + poses) and runs/ (models, renders)

# Each job works on the node's local disk and removes it at the end.
WORK="/scratch/$USER/$SLURM_JOB_ID"
mkdir -p "$WORK" "$SCENE_RESULTS"

# Build the image on this node if it isn't there, under a lock so jobs that start
# together on one node wait for a single build. The .lock file stays; it is harmless.
ensure_sif() {
    mkdir -p "$(dirname "$SIF")"
    (
        flock 9
        if [ ! -f "$SIF" ]; then
            echo "Converting $NS_IMAGE to $SIF on $(hostname) (once per node, 10–20 min)"
            # Cache and build files on /scratch (about 20 GB at the peak), removed afterwards.
            # "Creating SIF file..." runs for minutes with no output; the heartbeat shows progress.
            local build="$WORK/apptainer"
            export APPTAINER_CACHEDIR="$build/cache" APPTAINER_TMPDIR="$build/tmp"
            mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"
            # Heartbeat: "Creating SIF file..." prints nothing for 10–20 min, so say how far it got.
            ( while sleep 60; do
                # mksquashfs writes into the build folder first; the .sif appears at the end.
                echo "  ... build folder $(du -sh "$build" 2>/dev/null | cut -f1), .sif $(du -h "$SIF.part" 2>/dev/null | cut -f1)"
            done ) &
            local beat=$!
            apptainer pull "$SIF.part" "$NS_IMAGE" && mv "$SIF.part" "$SIF"
            local status=$?
            kill "$beat" 2>/dev/null || true
            rm -rf "$build" "$SIF.part"
            [ "$status" = 0 ] || exit "$status"
        fi
    ) 9>"$SIF.lock"
}

# Run a nerfstudio command (ns-*) in the container, with the GPU when the job has one.
ns() {
    local nv=()
    [ -n "${CUDA_VISIBLE_DEVICES:-}" ] && nv=(--nv)
    apptainer exec "${nv[@]}" --bind /scratch "$SIF" "$@"
}
