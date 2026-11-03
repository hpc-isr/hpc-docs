#!/bin/bash
# Build the vLLM Apptainer image on one node's /scratch. Optional: job.sbatch does
# the same on any node that doesn't have it yet. Running this first, on the node
# you'll caption on, saves that wait:  sbatch --nodelist=hpc02 pull.sbatch
#SBATCH --job-name=vllm-pull
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --output=%x-%N-%j.out

set -euo pipefail
source "$SLURM_SUBMIT_DIR/vllm-image.sh"
ensure_vllm_image
ls -lh "$SIF"
