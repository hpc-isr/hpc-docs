#!/bin/bash
# Runs after every task of the sweep has succeeded (see submit.sh).
#SBATCH --job-name=kalman-collect
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=logs/%x-%j.out

set -euo pipefail
# The environment is on this node's /scratch; create it on each node you use with
#   sbatch --nodelist=<node> setup-env.sbatch   (see "Before you start" in the Slurm README)
ENV_DIR="${ENV_DIR:-/scratch/$USER/envs/slurm-examples}"
if [ ! -x "$ENV_DIR/bin/python" ]; then
    echo "No Python environment in $ENV_DIR on $(hostname)." >&2
    echo "Create it from the examples folder: sbatch --nodelist=$(hostname) setup-env.sbatch" >&2
    exit 1
fi
source "$ENV_DIR/bin/activate"
python "$SLURM_SUBMIT_DIR/collect.py" "${RESULTS_DIR:-$HOME/results/kalman-sweep}"
