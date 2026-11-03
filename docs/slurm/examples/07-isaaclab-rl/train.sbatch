#!/bin/bash
# Train a policy with Isaac Lab + RSL-RL (PPO), headless.
#   sbatch train.sbatch                                   # H1 humanoid learns to walk
#   sbatch --export=ALL,TASK=Isaac-Humanoid train.sbatch  # another task
#   sbatch --export=ALL,STREAM=1 train.sbatch             # watch it train (WebRTC)
#   sbatch --export=ALL,NUM_ENVS=8192,NUM_MINI_BATCHES=4 train.sbatch    # bigger PPO batch
#SBATCH --job-name=isaaclab-train
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --output=%x-%j.out

set -euo pipefail

ISAACLAB_DIR="${ISAACLAB_DIR:-$HOME/IsaacLab}"
TASK="${TASK:-Isaac-Velocity-Flat-H1}"
NUM_ENVS="${NUM_ENVS:-4096}"
MAX_ITERATIONS="${MAX_ITERATIONS:-1500}"
# PPO batch: each iteration collects NUM_STEPS_PER_ENV steps from every environment
# and splits them into NUM_MINI_BATCHES. Empty: the task's own settings.
NUM_STEPS_PER_ENV="${NUM_STEPS_PER_ENV:-}"
NUM_MINI_BATCHES="${NUM_MINI_BATCHES:-}"
STREAM="${STREAM:-0}"
# Where checkpoints and logs are kept: your home by default, or your group's NAS,
# e.g. RESULTS_DIR=/storage/anubis-nas/<group>/isaaclab
RESULTS_DIR="${RESULTS_DIR:-$HOME/results/isaaclab}"

export PATH="$HOME/.local/bin:$PATH"
export UV_CACHE_DIR="/scratch/$USER/uv-cache"
export UV_PROJECT_ENVIRONMENT="/scratch/$USER/envs/isaaclab"   # on this node's local disk
[ -d "$ISAACLAB_DIR/.git" ] || { echo "No Isaac Lab checkout in $ISAACLAB_DIR: run setup.sbatch first." >&2; exit 1; }
# Create or update the environment on this node: 15–30 min the first time here.
uv sync --project "$ISAACLAB_DIR" --extra isaacsim
export OMNI_KIT_ACCEPT_EULA=YES

# Isaac Lab writes logs/rsl_rl/<experiment>/<date>/ under the current folder:
# make that the node's local disk, and copy it out when the job ends.
WORK="/scratch/$USER/$SLURM_JOB_ID"
mkdir -p "$WORK" "$RESULTS_DIR"
cd "$WORK"
sync_out() { [ -d "$WORK/logs" ] && rsync -a "$WORK/logs/" "$RESULTS_DIR/logs/" || true; }
( while sleep 1800; do sync_out; done ) &   # checkpoints out every 30 min as well
SYNC_PID=$!
finish() {
    kill "$SYNC_PID" 2>/dev/null || true
    sync_out
    cd / && rm -rf "$WORK"
    echo "Logs and checkpoints in $RESULTS_DIR/logs"
}
trap finish EXIT
trap 'exit 143' TERM

source "$SLURM_SUBMIT_DIR/../env.sh"   # for start_tensorboard
start_tensorboard "$WORK/logs" "$UV_PROJECT_ENVIRONMENT/bin/tensorboard"

extra=()
overrides=(physics=isaacsim_physx)   # Hydra overrides, after the options
[ -n "$NUM_STEPS_PER_ENV" ] && overrides+=(agent.num_steps_per_env="$NUM_STEPS_PER_ENV")
[ -n "$NUM_MINI_BATCHES" ] && overrides+=(agent.algorithm.num_mini_batches="$NUM_MINI_BATCHES")
if [ "$STREAM" = 1 ]; then
    source "$SLURM_SUBMIT_DIR/stream-info.sh"
    extra=(--livestream 2)
    # Rendering the viewport costs GPU time: fewer environments keep training usable.
    NUM_ENVS="${STREAM_NUM_ENVS:-256}"
fi

echo "Task $TASK, $NUM_ENVS envs, $MAX_ITERATIONS iterations, on $(hostname)"
echo "Overrides: ${overrides[*]}"
srun uv run --project "$ISAACLAB_DIR" --extra isaacsim \
    isaaclab train --rl_library rsl_rl --task "$TASK" \
    --num_envs "$NUM_ENVS" --max_iterations "$MAX_ITERATIONS" \
    "${extra[@]}" "${overrides[@]}"
