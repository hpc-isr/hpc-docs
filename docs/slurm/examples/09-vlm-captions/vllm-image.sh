# shellcheck shell=bash
# Sourced by pull.sbatch and job.sbatch:  ensure_vllm_image
#
# The vLLM image lives on this node's /scratch, /scratch/$USER/containers: Apptainer
# reads it much faster from the local NVMe than from your home on MooseFS. /scratch
# is local to each node, so the first job on a node builds the image there (9 GB,
# 15–30 min); later jobs on that node reuse it. A lock makes jobs that start
# together on one node wait for a single build. The .lock file next to the image
# stays there afterwards; it is empty and harmless (a lock is held only while a job
# has it open).
#
# The default CUDA 13.0 build runs on the nodes' NVIDIA driver (CUDA 13.2). Not the
# cu129 build: its torchcodec needs CUDA 13's libnvrtc.so.13, which that image lacks,
# so importing vLLM fails there.
VLLM_IMAGE="${VLLM_IMAGE:-docker://vllm/vllm-openai:v0.32.0}"
SIF="${SIF:-/scratch/$USER/containers/vllm-0.32.0-cu130.sif}"

ensure_vllm_image() {
    mkdir -p "$(dirname "$SIF")"
    (
        flock 9
        if [ ! -f "$SIF" ]; then
            echo "Building $SIF from $VLLM_IMAGE on $(hostname) (once per node, 15–30 min)"
            # Layer cache and build files (about 35 GB at the peak), removed afterwards.
            local build="/scratch/$USER/vllm-build-$SLURM_JOB_ID"
            export APPTAINER_CACHEDIR="$build/cache" APPTAINER_TMPDIR="$build/tmp"
            mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"
            # "Creating SIF file..." compresses about 20 GB with mksquashfs: 10–20 min
            # with no output; the heartbeat below shows the build folder growing.
            local start=$SECONDS
            # Heartbeat: "Creating SIF file..." prints nothing for 10–20 min, so say how far it got.
            ( while sleep 60; do
                # mksquashfs writes into the build folder first; the .sif appears at the end.
                echo "  ... build folder $(du -sh "$build" 2>/dev/null | cut -f1), .sif $(du -h "$SIF.part" 2>/dev/null | cut -f1)"
            done ) &
            local beat=$!
            apptainer pull "$SIF.part" "$VLLM_IMAGE" && mv "$SIF.part" "$SIF"
            local status=$?
            kill "$beat" 2>/dev/null || true
            rm -rf "$build" "$SIF.part"
            [ "$status" = 0 ] || exit "$status"
            echo "Built $SIF in $(( (SECONDS - start) / 60 )) min"
        fi
    ) 9>"$SIF.lock"
}
