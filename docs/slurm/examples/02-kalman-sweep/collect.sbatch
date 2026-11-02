#!/bin/bash
# Runs after every task of the sweep has succeeded (see submit.sh).
#SBATCH --job-name=kalman-collect
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:10:00
#SBATCH --output=logs/%x-%j.out

set -euo pipefail
source "$SLURM_SUBMIT_DIR/../env.sh"   # this example's environment on this node
ensure_env kalman-sweep "$SLURM_SUBMIT_DIR/requirements.txt"
python "$SLURM_SUBMIT_DIR/collect.py" "${RESULTS_DIR:-$HOME/results/kalman-sweep}"
