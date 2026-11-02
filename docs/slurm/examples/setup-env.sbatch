#!/bin/bash
# Create the Python environment for examples 2–6 and 10 on one node's /scratch.
# /scratch is local to each node, so run it, from this folder, on every node
# your jobs will use:  sbatch --nodelist=hpc02 setup-env.sbatch
# Running it again on a node updates the environment there.
#SBATCH --job-name=setup-env
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=00:45:00
#SBATCH --output=%x-%N-%j.out

set -euo pipefail

# On the node's local NVMe: Python starts much faster reading its thousands of
# small files from here than from your home on MooseFS. Only this node sees it.
ENV_DIR="${ENV_DIR:-/scratch/$USER/envs/slurm-examples}"
mkdir -p "$(dirname "$ENV_DIR")"

if [ ! -x "$ENV_DIR/bin/python" ]; then
    python3 -m venv "$ENV_DIR"
fi
source "$ENV_DIR/bin/activate"

# Keep pip's download cache off your home quota.
export PIP_CACHE_DIR="/scratch/$USER/pip-cache"
echo "Node: $(hostname)   Environment: $ENV_DIR   pip cache: $PIP_CACHE_DIR"

python -m pip install --upgrade pip
python -m pip install -r "$SLURM_SUBMIT_DIR/requirements.txt"

python - <<'PY'
import torch, torchvision, ultralytics
print("torch", torch.__version__, "| torchvision", torchvision.__version__,
      "| ultralytics", ultralytics.__version__)
print("CUDA build:", torch.version.cuda)
PY
echo "Environment ready on $(hostname): $ENV_DIR"
