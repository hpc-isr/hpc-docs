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
