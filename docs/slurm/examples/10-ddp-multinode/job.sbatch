#!/bin/bash
# Data-parallel training on several nodes, one GPU each. Ask an admin before running it.
#   sbatch job.sbatch               # 2 nodes (hpc02 + hpc03 on the shared partition)
#   sbatch --nodes=1 job.sbatch     # the same on 1 GPU, for the scaling comparison
#   NCCL_DEBUG=INFO sbatch job.sbatch   # if it hangs at start-up: NCCL logs its network set-up
#SBATCH --job-name=ddp-cifar
#SBATCH --partition=shared
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=01:00:00
#SBATCH --output=%x-%j.out

set -euo pipefail
export PYTHONUNBUFFERED=1   # print progress as it happens, not when a buffer fills

# Runs a bash snippet once on every node of the job. --kill-on-bad-exit: if it
# fails on one node, the step stops at once instead of waiting for the others,
# and the job ends with that node's error in the log.
on_every_node() {
    srun --ntasks-per-node=1 --kill-on-bad-exit=1 bash -c "set -euo pipefail; $1"
}
step() { echo "$(date +%T) $*"; }

# 1. This example's environment, on each node's /scratch: created on every node
#    of the job that doesn't have it yet (a few minutes), then activated here;
#    srun passes it to the tasks on every node.
step "1/3 Python environment on $SLURM_JOB_NODELIST"
on_every_node 'source "$SLURM_SUBMIT_DIR/../env.sh"
    ensure_env ddp "$SLURM_SUBMIT_DIR/requirements.txt"
    echo "$(date +%T) $(hostname -s): environment ready"'
source "$SLURM_SUBMIT_DIR/../env.sh"
ensure_env ddp "$SLURM_SUBMIT_DIR/requirements.txt"

# Where the result is kept: your home by default, or your group's NAS,
# e.g. RESULTS_DIR=/storage/<group>/anubis-nas/ddp-cifar
RESULTS_DIR="${RESULTS_DIR:-$HOME/results/ddp-cifar}"
DATA="/scratch/$USER/datasets/cifar10"   # a copy on each node's local disk
WORK="/scratch/$USER/$SLURM_JOB_ID"      # on each node; rank 0 (this node) writes the results
export DATA WORK EPOCHS="${EPOCHS:-10}"   # srun passes these to the tasks on every node

finish() {
    mkdir -p "$RESULTS_DIR/$SLURM_JOB_ID"
    cp -r "$WORK/out/." "$RESULTS_DIR/$SLURM_JOB_ID/" 2>/dev/null || true
    srun --ntasks-per-node=1 --overlap rm -rf "$WORK" || true   # clean up on every node
    echo "Results in $RESULTS_DIR/$SLURM_JOB_ID"
}
trap finish EXIT
trap 'exit 143' TERM

# 2. Stage the data on every node. CIFAR-10 comes from its Hugging Face copy
#    (143 MB in two Parquet files, seconds to download; the original server at
#    cs.toronto.edu often manages under 100 kB/s). It is downloaded once, on this
#    node, and kept in its /scratch; sbcast copies it over the cluster network to
#    the nodes that don't have the dataset yet, and each node converts its copy
#    to NumPy arrays (under a minute).
step "2/3 CIFAR-10 on every node"
HF_DATASET=https://huggingface.co/datasets/uoft-cs/cifar10/resolve/0b2714987fa478483af9968de7c934580d0bb9a2/plain_text
declare -A SHA256=(
    [train]=8428b53a88a11ac374111006708df51469e315a22ac6d66470afd9c78d2ae883
    [test]=841389e6f2d64f28bf17310e430aebac20ec3ba611a3c5e231dc93c645ce84de
)
missing=$(on_every_node 'mkdir -p "$WORK/out" "$DATA"; [ -f "$DATA/.ready" ] || hostname -s')
if [ -n "$missing" ]; then
    echo "Needs CIFAR-10:" $missing
    for split in train test; do
        file="$DATA/$split.parquet"
        if ! echo "${SHA256[$split]}  $file" | sha256sum -c --status 2>/dev/null; then
            step "$(hostname -s): downloading $split.parquet"
            # Retries and resumes after a dropped connection; gives up if the
            # transfer stays under 10 kB/s for 5 minutes.
            curl -fL --retry 5 --retry-all-errors -C - --speed-limit 10000 --speed-time 300 \
                -sS -o "$file.part" "$HF_DATASET/$split-00000-of-00001.parquet"
            mv "$file.part" "$file"
            echo "${SHA256[$split]}  $file" | sha256sum -c --quiet || {
                rm -f "$file"; echo "$split.parquet is corrupt; submit the job again." >&2; exit 1; }
        fi
        sbcast --force "$file" "$WORK/$split.parquet"   # to $WORK on every node of the job
    done
fi
on_every_node 'if [ ! -f "$DATA/.ready" ]; then
        for split in train test; do
            cmp -s "$WORK/$split.parquet" "$DATA/$split.parquet" || mv "$WORK/$split.parquet" "$DATA/$split.parquet"
        done
        python "$SLURM_SUBMIT_DIR/prepare_cifar10.py" "$DATA"
        rm -rf "$DATA/cifar-10-batches-py" "$DATA"/cifar-10-python.tar.gz*   # the old torchvision copy, if any
        touch "$DATA/.ready"
    fi
    echo "$(date +%T) $(hostname -s): data ready, $(df -h --output=avail /scratch | tail -1 | tr -d " ") free on /scratch"'

# 3. Train. The first node of the job hosts the rendezvous; every node starts
#    torchrun with its own node rank, so rank 0 runs here, on the first node.
MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n1)
MASTER_PORT=$(( 20000 + SLURM_JOB_ID % 20000 ))
export MASTER_ADDR MASTER_PORT
export NCCL_SOCKET_IFNAME=ens3   # the nodes' private network interface
export NCCL_DEBUG="${NCCL_DEBUG:-WARN}"   # NCCL_DEBUG=INFO sbatch job.sbatch for its full set-up log
export OMP_NUM_THREADS=4

step "3/3 Training on $SLURM_NNODES node(s), rendezvous at $MASTER_ADDR:$MASTER_PORT"
srun --kill-on-bad-exit=1 bash -c 'exec torchrun \
    --nnodes="$SLURM_NNODES" --nproc_per_node=1 --node_rank="$SLURM_NODEID" \
    --master_addr="$MASTER_ADDR" --master_port="$MASTER_PORT" \
    "$SLURM_SUBMIT_DIR/train_ddp.py" --epochs "$EPOCHS" --data "$DATA" --out "$WORK/out"'
