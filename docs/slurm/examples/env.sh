# Sourced by the example jobs:  ensure_env <name> <requirements.txt>
#
# Each example has its own Python environment, /scratch/$USER/envs/<name>, on the
# node's local disk: fast to start, and only the packages that example needs.
# /scratch is local to each node, so the first job of an example on a node
# creates it there (seconds for numpy, a few minutes for PyTorch), and later
# jobs on that node reuse it. It is rebuilt when requirements.txt changes.
# A lock makes jobs that start together on one node wait for a single build.
ensure_env() {
    local name=$1 req=$2
    local envs="/scratch/$USER/envs"
    local env="$envs/$name"
    local sum
    sum=$(sha256sum "$req" | cut -d' ' -f1)
    mkdir -p "$envs"
    (
        flock 9
        if [ "$(cat "$env/.requirements.sha256" 2>/dev/null)" != "$sum" ]; then
            echo "Creating the '$name' environment on $(hostname) from $req"
            rm -rf "$env"
            python3 -m venv "$env"
            export PIP_CACHE_DIR="/scratch/$USER/pip-cache"   # off your home quota
            "$env/bin/python" -m pip install --progress-bar off -q --upgrade pip
            "$env/bin/python" -m pip install --progress-bar off -r "$req"
            echo "$sum" > "$env/.requirements.sha256"
        fi
    ) 9>"$envs/$name.lock"
    source "$env/bin/activate"
}

# Start TensorBoard on this node for the rest of the job and print the SSH
# tunnel to reach it from your laptop. It listens on the node's loopback only,
# so nobody else on the network can see your runs.
#   start_tensorboard <logdir> [command that runs tensorboard]   (default: tensorboard)
start_tensorboard() {
    local logdir=$1; shift
    local cmd=("$@")
    [ ${#cmd[@]} -gt 0 ] || cmd=(tensorboard)
    # A free port derived from your UID and the job ID, so two users rarely collide.
    local port=$(( 40000 + ($(id -u) + SLURM_JOB_ID) % 10000 ))
    while ss -ltn "( sport = :$port )" | grep -q LISTEN; do port=$((port + 1)); done
    mkdir -p "$logdir"
    "${cmd[@]}" --logdir "$logdir" --host 127.0.0.1 --port "$port" >/dev/null 2>&1 &
    local me node via
    me=$(id -un)
    node=$(hostname -s)
    via="$me@hpc01.isr.tecnico.ulisboa.pt"
    # Other nodes: jump through hpc01 into the node, which lets you in while you have a job there.
    [ "$node" = hpc01 ] || via="-J $via $me@$node"
    cat <<EOT

================  TensorBoard  ================
TensorBoard runs on $node, port $port, until the job ends.
On your laptop, open a tunnel (leave it open):

    ssh -N -L 6006:localhost:$port $via

then open http://127.0.0.1:6006. Curves appear once training has
written its first logs.
===============================================

EOT
}
