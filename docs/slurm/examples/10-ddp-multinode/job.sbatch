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
# e.g. RESULTS_DIR=/storage/anubis-nas/<group>/ddp-cifar
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

# 2. Stage the data on every node. The CIFAR-10 server is often slow (minutes
#    for its 170 MB), so the archive is downloaded only once, on this node, and
#    kept in its /scratch. sbcast then copies it over the cluster network to the
#    nodes that don't have the dataset yet, and each node unpacks its copy.
step "2/3 CIFAR-10 on every node"
TARBALL=cifar-10-python.tar.gz
CIFAR_URL="https://www.cs.toronto.edu/~kriz/$TARBALL"
CIFAR_MD5=c58f30108f718f92721af3b95e74349a
export TARBALL CIFAR_MD5
missing=$(on_every_node 'mkdir -p "$WORK/out" "$DATA"; [ -f "$DATA/.complete" ] || hostname -s')
if [ -n "$missing" ]; then
    echo "Needs CIFAR-10:" $missing
    if ! echo "$CIFAR_MD5  $DATA/$TARBALL" | md5sum -c --status 2>/dev/null; then
        step "$(hostname -s): downloading $CIFAR_URL"
        # Resumes after a dropped connection; gives up only if the transfer stays
        # under 10 kB/s for 5 minutes, however long a slow download takes overall.
        curl -fL --retry 5 --retry-all-errors -C - --speed-limit 10000 --speed-time 300 \
            -sS -o "$DATA/$TARBALL.part" "$CIFAR_URL"
        mv "$DATA/$TARBALL.part" "$DATA/$TARBALL"
        echo "$CIFAR_MD5  $DATA/$TARBALL" | md5sum -c --quiet || {
            rm -f "$DATA/$TARBALL"; echo "The download is corrupt; submit the job again." >&2; exit 1; }
    fi
    sbcast --force "$DATA/$TARBALL" "$WORK/$TARBALL"   # to $WORK on every node of the job
fi
on_every_node 'if [ ! -f "$DATA/.complete" ]; then
        cmp -s "$WORK/$TARBALL" "$DATA/$TARBALL" || mv "$WORK/$TARBALL" "$DATA/$TARBALL"
        # torchvision checks the archive (MD5) and unpacks it; it downloads nothing.
        python -c "import os, torchvision; torchvision.datasets.CIFAR10(os.environ[\"DATA\"], download=True)"
        touch "$DATA/.complete"
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
