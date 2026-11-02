#!/bin/bash
# JupyterLab on a sixth of hpc01's GPU. The tunnel command is printed in the log.
#SBATCH --job-name=jupyter
#SBATCH --gres=shard:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=%x-%j.out

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

# A free port derived from your UID and the job ID, so two users rarely collide.
PORT=$(( 20000 + ($(id -u) + SLURM_JOB_ID) % 20000 ))
while ss -ltn "( sport = :$PORT )" | grep -q LISTEN; do PORT=$((PORT + 1)); done

cat <<EOF
JupyterLab is starting on $(hostname), port $PORT.

1. On your laptop, open a tunnel (leave it open):

     ssh -N -L 8888:localhost:$PORT $(id -un)@hpc01.isr.tecnico.ulisboa.pt

2. Open the http://127.0.0.1:$PORT/lab?token=... address printed below,
   with $PORT replaced by 8888.

3. When you are done: File → Shut Down, or  scancel $SLURM_JOB_ID

The GPU slice has no memory isolation: keep GPU memory under about 8 GB.
EOF

# Listen only on hpc01's loopback; the SSH tunnel reaches it from there.
exec jupyter lab --no-browser --ip=127.0.0.1 --port="$PORT" --notebook-dir="$HOME"
