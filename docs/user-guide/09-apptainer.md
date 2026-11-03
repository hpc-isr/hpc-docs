---
title: "Containers with Apptainer"
parent: "User Guide"
nav_order: 9
---

# Containers with Apptainer

[← User Guide](README.md) · [Home](../README.md)

[Apptainer](https://apptainer.org/docs/user/latest/) is installed on every HPC node. It runs a container as your own user, with no daemon and no root, inside your Slurm job. Docker isn't available to users, but Apptainer runs Docker and OCI images: you convert the image once to a single `.sif` file, then run that file in your jobs.

## From Docker to Apptainer in short

    # 1. Convert the Docker image to a .sif file on hpc02's /scratch (once per node)
    sbatch --nodelist=hpc02 build-sif.sbatch docker://pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime pytorch

    # 2. Run it in a job on the same node, with the GPU and /scratch
    srun --nodelist=hpc02 --gres=gpu:1 -c 8 --mem=64G -t 12:00:00 \
      apptainer exec --nv --bind /scratch "/scratch/$USER/containers/pytorch.sif" \
      python "$HOME/code/train.py"

[`build-sif.sbatch`](examples/build-sif.sbatch) is a short job script you copy once (see [Get an image](#get-an-image)). The sections below explain each step, and what to do when the image isn't on a public registry.

## Where things go

Keep container images, their caches and the data a container reads on `/scratch`, the node's local NVMe disk, like the [Slurm examples](../slurm/README.md#data-and-results) do. Apptainer reads a `.sif` much faster from there than from your home on MooseFS, and a build needs tens of GB of temporary space that would otherwise fill your [home quota](03-storage.md#quota).

| What | Where | Why |
|---|---|---|
| Definition files, job scripts, code | your home | Small, the same on every node, so you can rebuild anywhere |
| `.sif` images | `/scratch/$USER/containers/`, on each node | Fast to start. `/scratch` is local to each node, so each node needs its own copy |
| Apptainer cache and build files | `/scratch/$USER/<jobid>/`, set with `APPTAINER_CACHEDIR` and `APPTAINER_TMPDIR` | A build needs about 4 times the image's size while it runs. Removed when it ends |
| Download caches used inside the container (Hugging Face, pip, ...) | `/scratch/$USER/hf-cache`, `/scratch/$USER/pip-cache`, ... | Downloaded once per node, reused by later jobs there |
| The job's working data | `/scratch/$USER/<jobid>/` | Fast, and doesn't load the shared filesystem |
| Results to keep | your home or your group's NAS | Copied out when the job ends |

Without `APPTAINER_CACHEDIR`, Apptainer keeps every downloaded layer in `~/.apptainer/cache`, in your home, and never removes it. `build-sif.sbatch` sets both variables for you. If you run `apptainer pull` or `apptainer build` yourself, set them first, in the job:

    export APPTAINER_CACHEDIR="/scratch/$USER/$SLURM_JOB_ID/cache" APPTAINER_TMPDIR="/scratch/$USER/$SLURM_JOB_ID/tmp"
    mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"

If you already have a cache in your home, `du -sh ~/.apptainer/cache` shows its size and `apptainer cache clean` removes it.

Files on `/scratch` that nobody uses for 30 days are deleted (see [Storage](03-storage.md#old-files-are-deleted)), so an image you haven't used for a month disappears from that node. Keep the recipe (the image name or the definition file) in your home, and build it again when you need it.

## Get an image

Building or pulling a large image takes several CPUs, a lot of memory and up to tens of minutes. Do it in a job on the node that will run the container, because a session on `hpc01` is limited to 4 CPUs and 16 GiB (see [SSH login](02-ssh-login.md#limits-outside-slurm)), and its `/scratch` isn't visible from the other nodes. Pin a version tag, so the image doesn't change under you.

Copy [`build-sif.sbatch`](examples/build-sif.sbatch) to your home once. It builds any source `apptainer build` accepts into `/scratch/$USER/containers/<name>.sif` on the node it runs on, with its cache and build files on `/scratch`:

    git clone https://github.com/hpc-isr/hpc-docs.git ~/hpc-docs   # if you don't have it yet
    cp ~/hpc-docs/docs/user-guide/examples/build-sif.sbatch ~/
    cd ~

Choose the node with `--nodelist`, and run the container in jobs on that node. To use the image on several nodes, build it once on each, or let the job do it, as in [A batch script](#a-batch-script). The log is `build-sif-<node>-<jobid>.out`.

### From Docker Hub or another registry

Put `docker://` in front of the image name you would give `docker pull`. The name you need is the one in the page's `docker pull` command, not the page's web address:

| Where the image is | `docker pull` name | Apptainer source |
|---|---|---|
| Official image, `https://hub.docker.com/_/python` | `python:3.12-slim` | `docker://python:3.12-slim` |
| User or organisation image, `https://hub.docker.com/r/pytorch/pytorch/tags` | `pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime` | `docker://pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime` |
| NVIDIA NGC | `nvcr.io/nvidia/pytorch:24.10-py3` | `docker://nvcr.io/nvidia/pytorch:24.10-py3` |
| GitHub Container Registry | `ghcr.io/owner/image:1.0` | `docker://ghcr.io/owner/image:1.0` |

Without a tag, Docker and Apptainer both take `latest`, which changes over time.

Then build it on the node you'll use:

    sbatch --nodelist=hpc02 build-sif.sbatch docker://python:3.12-slim python-3.12

The image is `/scratch/$USER/containers/python-3.12.sif` on `hpc02`.

For a private image, or a registry that needs a login, log in once on `hpc01`. Apptainer asks for your username and password or access token, and keeps them in `~/.apptainer/docker-config.json` in your home, where every build job finds them:

    apptainer registry login --username <you> docker://ghcr.io
    sbatch --nodelist=hpc02 build-sif.sbatch docker://ghcr.io/mygroup/mytool:1.0 mytool

`apptainer registry logout docker://ghcr.io` removes them.

### From an image you built with Docker on your own computer

If the image only exists on your laptop or workstation, save it as a tar file there, copy it to your home on the cluster (the only place every node sees), and convert it on the node you'll use:

    # On your computer
    docker save mytool:1.0 -o mytool.tar
    scp mytool.tar <username>@hpc01.isr.tecnico.ulisboa.pt:

    # On hpc01
    sbatch --nodelist=hpc02 build-sif.sbatch "docker-archive://$HOME/mytool.tar" mytool

Delete `~/mytool.tar` once you have built the image on every node you need, or keep it (or a copy on your group's NAS) to rebuild after `/scratch` cleans it up. Pushing the image to a registry, such as GitHub Container Registry, and pulling it as above saves you that copy.

The cluster nodes are `x86_64` (`amd64`). On a Mac with Apple Silicon, or another ARM computer, build the image for that platform, or it won't start on the cluster (`exec format error`):

    docker build --platform linux/amd64 -t mytool:1.0 .

### From a Dockerfile

You can't run `docker build` on the cluster. Either build the image on your own computer as above, or rewrite the Dockerfile as an Apptainer [definition file](https://apptainer.org/docs/user/latest/definition_files.html) that starts from a Docker image:

    Bootstrap: docker
    From: pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

    %post
        pip install --no-cache-dir transformers==4.46.0 datasets==3.1.0

    %environment
        export HF_HOME=/scratch/$USER/hf-cache

    %runscript
        exec python "$@"

`RUN` lines go in `%post`, `ENV` in `%environment`, and `ENTRYPOINT`/`CMD` in `%runscript`. Keep `mytool.def` in your home and build it from there:

    cd ~ && sbatch --nodelist=hpc02 build-sif.sbatch mytool.def mytool

## Run it in a job

Add `--nv` to give the container the GPUs that Slurm allocated to your job. It uses the node's NVIDIA driver, so the image only needs the CUDA libraries. Run on the node that has the image:

    srun --nodelist=hpc02 --gres=gpu:1 -c 8 --mem=64G -t 12:00:00 \
      apptainer exec --nv --bind /scratch "/scratch/$USER/containers/pytorch.sif" \
      python "$HOME/code/train.py"

`apptainer exec image.sif <command>` runs a command of your choice. `apptainer run image.sif [args]` runs the image's own entry point, like `docker run image [args]`.

### Files: `/home` and `/scratch`

Your home is mounted inside the container at the same path, and so is the directory you start from. `/scratch` and other paths are not mounted by default: add `--bind` to reach them, at the same path or at a path the image expects. The `.sif` file itself doesn't need a `--bind`:

    apptainer exec --bind /scratch image.sif ...                      # /scratch at /scratch
    apptainer exec --bind /scratch/$USER/data:/data image.sif ...     # like docker -v host:container
    apptainer exec --bind /scratch,/storage/anubis-nas image.sif ...  # several paths

The paths must exist on the node the job runs on. `/scratch` exists on `hpc01`–`hpc03` and on group nodes that have joined the cluster, and is a local NVMe disk on each node (see [Storage](03-storage.md#scratch)).

Tools in the container that download models or packages write to `~/.cache` in your home by default. Point them at `/scratch` with `--env`, for example `--env HF_HOME=/scratch/$USER/hf-cache --env PIP_CACHE_DIR=/scratch/$USER/pip-cache --env TORCH_HOME=/scratch/$USER/torch-cache`, and add `--bind /scratch`.

### A batch script

This job builds the image on its node if that node doesn't have it yet, stages the dataset on the node's `/scratch` once, runs the container with one GPU in a working folder on `/scratch`, and copies the results to your home, however the job ends. It runs on any node, so you don't need `--nodelist`; the first job on a node waits for the build.

    #!/bin/bash
    #SBATCH --job-name=train
    #SBATCH --gres=gpu:1
    #SBATCH --cpus-per-task=8
    #SBATCH --mem=64G
    #SBATCH --time=12:00:00
    #SBATCH --output=%x-%j.out

    set -euo pipefail

    SRC="docker://pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime"   # or a .def file in your home
    SIF="/scratch/$USER/containers/pytorch-2.5.1.sif"
    DATA="/scratch/$USER/datasets/mydata"                          # kept for later jobs on this node
    WORK="/scratch/$USER/$SLURM_JOB_ID"                             # removed at the end
    RESULTS_DIR="${RESULTS_DIR:-$HOME/results/train}"              # or /storage/anubis-nas/<group>/...
    export HF_HOME="/scratch/$USER/hf-cache"
    mkdir -p "$(dirname "$SIF")" "$WORK/out" "$HF_HOME"

    finish() {                      # runs however the job ends
        mkdir -p "$RESULTS_DIR/$SLURM_JOB_ID"
        cp -r "$WORK/out/." "$RESULTS_DIR/$SLURM_JOB_ID/"
        rm -rf "$WORK"
    }
    trap finish EXIT
    trap 'exit 143' TERM            # time limit or preemption: still run finish

    # The image, once per node. The lock makes jobs that start together on one node
    # wait for a single build; the empty .lock file it leaves is harmless.
    (
        flock 9
        if [ ! -f "$SIF" ]; then
            export APPTAINER_CACHEDIR="$WORK/apptainer/cache" APPTAINER_TMPDIR="$WORK/apptainer/tmp"
            mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"
            apptainer build "$SIF.part" "$SRC" && mv "$SIF.part" "$SIF"
            rm -rf "$WORK/apptainer" "$SIF.part"
            [ -f "$SIF" ]
        fi
    ) 9>"$SIF.lock"

    # The dataset, once per node (see Storage, "Staging a dataset").
    if [ ! -f "$DATA/.complete" ]; then
        mkdir -p "$DATA"
        rsync -a "$HOME/datasets/mydata/" "$DATA/"
        touch "$DATA/.complete"
    fi

    srun apptainer exec --nv --bind /scratch --env HF_HOME="$HF_HOME" "$SIF" \
      python "$HOME/code/train.py" --data "$DATA" --out "$WORK/out"

Submit it with `sbatch train.sh`. For a CPU-only job, drop `--gres=gpu:1` and `--nv`. The [nerfstudio](../slurm/examples/08-gaussian-splatting/README.md) and [vLLM](../slurm/examples/09-vlm-captions/README.md) examples follow the same pattern with real workloads.

Check that the GPU is visible:

    srun --nodelist=hpc02 --gres=gpu:1 -t 0:05:00 apptainer exec --nv "/scratch/$USER/containers/pytorch.sif" \
      python -c 'import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))'

### `docker run` options in Apptainer

| Docker | Apptainer |
|---|---|
| `docker run image cmd` | `apptainer exec image.sif cmd` |
| `docker run image` (entry point) | `apptainer run image.sif` |
| `docker run -it image bash` | `apptainer shell image.sif` |
| `--gpus all` | `--nv` (only the GPUs Slurm gave your job) |
| `-v /host/path:/container/path` | `--bind /host/path:/container/path` |
| `-e NAME=value` | `--env NAME=value` |
| `-w /workdir` | `--pwd /workdir` |
| `--rm` | Not needed: nothing is left behind |
| `-p 8888:8888` | Not needed: the container uses the node's network, so a server listens on the node directly |

## Differences from Docker to watch for

- **You are not root.** The container runs as your user. An image that writes to `/root`, `/app` or another directory owned by root fails with `Permission denied` or `Read-only file system`. Point it at `/scratch` instead, for example with `--env` or a command-line option of the tool.
- **The image is read-only.** Keep data outside it, on `/scratch`, and copy results to your home or your group's NAS. For a tool that insists on writing scratch files inside the image, `--writable-tmpfs` gives it a small, temporary writable layer that is discarded at the end.
- **Your environment is passed in.** Variables set in your session, like `PYTHONPATH` or a Conda `PATH`, reach the container and can break it. Add `--cleanenv` to start from the image's own environment.
- **Your `~/.local` is visible.** Python packages installed with `pip install --user` go to `~/.local` in your home and are picked up by every container you run, which can mix versions. Prefer a definition file, or a virtual environment per project.
- **The working directory is where you started**, not the image's `WORKDIR`. Use `--pwd` if the image expects a specific directory.

## Tips

- `apptainer shell --nv --bind /scratch /scratch/$USER/containers/<name>.sif` inside `salloc` on the node that has the image gives you an interactive shell in the container.
- `apptainer inspect --runscript image.sif` shows what `apptainer run` will execute.
- To add packages to an image, write a [definition file](#from-a-dockerfile) and build it with `build-sif.sbatch`.
- `ls -lh /scratch/$USER/containers` in a job on a node shows which images that node has. Delete the ones you no longer use: they count toward your `/scratch` quota on that node.
