#!/bin/bash
# Install Isaac Lab 3.0 with Isaac Sim 6.2 from pip on one node's /scratch: the
# checkout in /scratch/$USER/IsaacLab and the uv environment in
# /scratch/$USER/envs/isaaclab. Optional: the training jobs do the same on any node
# that doesn't have it yet, the first time they run there. Running this first, on
# the node you'll train on, saves that wait:
#   sbatch --nodelist=hpc02 setup.sbatch   (downloads about 12 GB; takes 15–30 min)
#SBATCH --job-name=isaaclab-setup
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:30:00
#SBATCH --output=%x-%N-%j.out

set -euo pipefail
source "$SLURM_SUBMIT_DIR/isaaclab.sh"
ensure_isaaclab

uv run --project "$ISAACLAB_DIR" --extra isaacsim \
    python -c "import isaaclab, isaacsim, torch; print('isaaclab OK, torch', torch.__version__)"
echo "Isaac Lab ready on $(hostname): code in $ISAACLAB_DIR, environment in $UV_PROJECT_ENVIRONMENT"
