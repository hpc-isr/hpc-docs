#!/bin/bash
# Install Isaac Lab 3.0 with Isaac Sim 6.2 from pip. The checkout goes in your home
# (~/IsaacLab, the same on every node, so you can edit it); the uv environment goes
# on this node's /scratch (/scratch/$USER/envs/isaaclab), since Python loads it much
# faster from the local disk. Run once, choosing a node:
#   sbatch --nodelist=hpc02 setup.sbatch   (downloads about 12 GB; takes 15–30 min)
# The training jobs create the environment themselves on any other node, the
# first time they run there; running this on a node first saves that wait.
#SBATCH --job-name=isaaclab-setup
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:30:00
#SBATCH --output=%x-%j.out

set -euo pipefail

ISAACLAB_DIR="${ISAACLAB_DIR:-$HOME/IsaacLab}"
ISAACLAB_BRANCH="${ISAACLAB_BRANCH:-release/3.0.0}"

# uv: a fast pip replacement that also installs the Python version Isaac Lab needs (3.12).
if ! command -v uv >/dev/null && [ ! -x "$HOME/.local/bin/uv" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"

# Environment and download cache on this node's /scratch, not in your home quota.
# They are on the same disk, so uv hard-links the files: the cache costs no extra space.
export UV_PROJECT_ENVIRONMENT="/scratch/$USER/envs/isaaclab"
export UV_CACHE_DIR="/scratch/$USER/uv-cache"

if [ ! -d "$ISAACLAB_DIR/.git" ]; then
    git clone --depth 1 --branch "$ISAACLAB_BRANCH" https://github.com/isaac-sim/IsaacLab.git "$ISAACLAB_DIR"
fi
cd "$ISAACLAB_DIR"
echo "Isaac Lab checkout: $ISAACLAB_DIR, branch $(git branch --show-current 2>/dev/null || echo '?')"

# An older or unrelated ~/IsaacLab (for example a 2.x install) has no uv project
# for this setup; stop with a clear message instead of a uv error.
if [ ! -f pyproject.toml ] || [ ! -f uv.lock ]; then
    echo "$ISAACLAB_DIR is not an Isaac Lab $ISAACLAB_BRANCH checkout (no pyproject.toml or uv.lock)." >&2
    echo "Move it aside (mv $ISAACLAB_DIR $ISAACLAB_DIR.old) and submit setup.sbatch again," >&2
    echo "or use another folder: sbatch --export=ALL,ISAACLAB_DIR=\$HOME/IsaacLab-3 setup.sbatch" >&2
    exit 1
fi

# Creates $UV_PROJECT_ENVIRONMENT with Isaac Lab, Isaac Sim (pip wheels) and CUDA PyTorch.
uv sync --extra isaacsim

uv run --extra isaacsim python -c "import isaaclab, isaacsim, torch; print('isaaclab OK, torch', torch.__version__)"
echo "Isaac Lab ready on $(hostname): code in $ISAACLAB_DIR, environment in $UV_PROJECT_ENVIRONMENT"
