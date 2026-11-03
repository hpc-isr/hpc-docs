# shellcheck shell=bash
# Sourced by the Isaac Lab jobs (examples 7 and 11):  ensure_isaaclab
#
# Isaac Lab lives on this node's /scratch: the checkout in /scratch/$USER/IsaacLab
# and its uv environment in /scratch/$USER/envs/isaaclab. Both load much faster
# from the local NVMe than from your home on MooseFS. /scratch is local to each
# node, so the first Isaac Lab job on a node clones and installs it there
# (about 12 GB to download, 15–30 min); later jobs on that node reuse it.
# A lock makes jobs that start together on one node wait for a single install.
ISAACLAB_DIR="${ISAACLAB_DIR:-/scratch/$USER/IsaacLab}"
ISAACLAB_BRANCH="${ISAACLAB_BRANCH:-release/3.0.0}"
export PATH="$HOME/.local/bin:$PATH"
export UV_PROJECT_ENVIRONMENT="${UV_PROJECT_ENVIRONMENT:-/scratch/$USER/envs/isaaclab}"
# Same disk as the environment, so uv hard-links the files: the cache costs no extra space.
export UV_CACHE_DIR="/scratch/$USER/uv-cache"
export OMNI_KIT_ACCEPT_EULA=YES   # accept the Isaac Sim license wherever it starts
export ISAACLAB_DIR ISAACLAB_BRANCH

ensure_isaaclab() {
    mkdir -p "/scratch/$USER"
    (
        flock 9
        # uv: a fast pip replacement that also installs the Python Isaac Lab needs (3.12).
        if ! command -v uv >/dev/null; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
        if [ ! -d "$ISAACLAB_DIR/.git" ]; then
            echo "Cloning Isaac Lab $ISAACLAB_BRANCH to $ISAACLAB_DIR on $(hostname)"
            git clone --depth 1 --branch "$ISAACLAB_BRANCH" \
                https://github.com/isaac-sim/IsaacLab.git "$ISAACLAB_DIR"
        fi
        if [ ! -f "$ISAACLAB_DIR/pyproject.toml" ] || [ ! -f "$ISAACLAB_DIR/uv.lock" ]; then
            echo "$ISAACLAB_DIR on $(hostname) is not an Isaac Lab $ISAACLAB_BRANCH checkout (no pyproject.toml or uv.lock)." >&2
            echo "Move it aside, or set ISAACLAB_DIR to another folder." >&2
            exit 1
        fi
        # Seconds when the environment is up to date; 15–30 min the first time on a node.
        uv sync --project "$ISAACLAB_DIR" --extra isaacsim
    ) 9>"/scratch/$USER/isaaclab.lock"
}
