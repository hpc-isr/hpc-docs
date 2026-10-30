---
title: "Containers with Apptainer"
parent: "User Guide"
nav_order: 9
---

# Containers with Apptainer

[← User Guide](README.md) · [Home](../README.md)

[Apptainer](https://apptainer.org/docs/user/latest/) is installed on every HPC node. It runs a container as your own user, with no daemon and no root, inside your Slurm job. Docker isn't available to users, but Apptainer runs Docker and OCI images: you convert the image once to a single `.sif` file, then run that file in your jobs.

## From Docker to Apptainer in short

    # 1. Convert the Docker image to a .sif file (once, inside a job)
    srun -c 4 --mem=16G -t 1:00:00 \
      apptainer pull "$HOME/containers/pytorch.sif" docker://pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

    # 2. Run it in a job, with the GPU and /scratch
    srun --gres=gpu:1 -c 8 --mem=64G -t 12:00:00 \
      apptainer exec --nv --bind /scratch "$HOME/containers/pytorch.sif" \
      python "$HOME/code/train.py"

The sections below explain each step, and what to do when the image isn't on a public registry.

## Get an image

Building or pulling a large image takes several CPUs and a lot of memory. Do it inside a job, as in the examples here, because a session on `hpc01` is limited to 4 CPUs and 16 GiB (see [SSH login](02-ssh-login.md#limits-outside-slurm)). Pin a version tag, so the image doesn't change under you.

The `.sif` file and the download cache (`~/.apptainer/cache`) count toward your [home quota](03-storage.md#quota). Clear the cache with `apptainer cache clean` once the image is built.

### From Docker Hub or another registry

Put `docker://` in front of the image name you would give `docker pull`. The name you need is the one in the page's `docker pull` command, not the page's web address:

| Where the image is | `docker pull` name | Apptainer source |
|---|---|---|
| Official image, `https://hub.docker.com/_/python` | `python:3.12-slim` | `docker://python:3.12-slim` |
| User or organisation image, `https://hub.docker.com/r/pytorch/pytorch/tags` | `pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime` | `docker://pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime` |
| NVIDIA NGC | `nvcr.io/nvidia/pytorch:24.10-py3` | `docker://nvcr.io/nvidia/pytorch:24.10-py3` |
| GitHub Container Registry | `ghcr.io/owner/image:1.0` | `docker://ghcr.io/owner/image:1.0` |

Without a tag, Docker and Apptainer both take `latest`, which changes over time.

Then pull it into your home:

    mkdir -p "$HOME/containers"
    srun -c 4 --mem=16G -t 1:00:00 \
      apptainer pull "$HOME/containers/python.sif" docker://python:3.12-slim

`apptainer build "$HOME/containers/python.sif" docker://python:3.12-slim` does the same thing.

For a private image, or a registry that needs a login, add `--docker-login` and Apptainer asks for your username and password or access token:

    srun -c 4 --mem=16G -t 1:00:00 --pty \
      apptainer pull --docker-login "$HOME/containers/mytool.sif" docker://ghcr.io/mygroup/mytool:1.0

### From an image you built with Docker on your own computer

If the image only exists on your laptop or workstation, save it as a tar file there, copy it to the cluster, and convert it:

    # On your computer
    docker save mytool:1.0 -o mytool.tar
    scp mytool.tar <username>@hpc01.isr.tecnico.ulisboa.pt:containers/

    # On hpc01
    srun -c 4 --mem=16G -t 1:00:00 \
      apptainer build "$HOME/containers/mytool.sif" docker-archive://"$HOME/containers/mytool.tar"
    rm "$HOME/containers/mytool.tar"

The cluster nodes are `x86_64` (`amd64`). On a Mac with Apple Silicon, or another ARM computer, build the image for that platform, or it won't start on the cluster (`exec format error`):

    docker build --platform linux/amd64 -t mytool:1.0 .

Pushing the image to a registry, such as GitHub Container Registry, and pulling it as above works too, and saves the copy.

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

`RUN` lines go in `%post`, `ENV` in `%environment`, and `ENTRYPOINT`/`CMD` in `%runscript`. Build it in a job:

    srun -c 8 --mem=32G -t 2:00:00 \
      apptainer build "$HOME/containers/mytool.sif" mytool.def

## Run it in a job

Add `--nv` to give the container the GPUs that Slurm allocated to your job. It uses the node's NVIDIA driver, so the image only needs the CUDA libraries.

    srun --gres=gpu:1 -c 8 --mem=64G -t 12:00:00 \
      apptainer exec --nv "$HOME/containers/pytorch.sif" \
      python "$HOME/code/train.py"

`apptainer exec image.sif <command>` runs a command of your choice. `apptainer run image.sif [args]` runs the image's own entry point, like `docker run image [args]`.

### Files: `/home` and `/scratch`

Your home is mounted inside the container at the same path, and so is the directory you start from. `/scratch` and other paths are not mounted by default: add `--bind` to reach them, at the same path or at a path the image expects:

    apptainer exec --bind /scratch image.sif ...                      # /scratch at /scratch
    apptainer exec --bind /scratch/$USER/data:/data image.sif ...     # like docker -v host:container
    apptainer exec --bind /scratch,/storage/anubis-nas image.sif ...  # several paths

The paths must exist on the node the job runs on. `/scratch` exists on `hpc01`–`hpc03` and on group nodes that have joined the cluster, and is local to each node (see [Storage](03-storage.md#scratch)).

### A batch script

This job copies its input to the node's `/scratch`, runs the container with one GPU, and copies the results back to your home:

    #!/bin/bash
    #SBATCH --job-name=train
    #SBATCH --gres=gpu:1
    #SBATCH --cpus-per-task=8
    #SBATCH --mem=64G
    #SBATCH --time=12:00:00
    #SBATCH --output=%x-%j.out

    set -euo pipefail

    IMAGE="$HOME/containers/pytorch.sif"
    WORK="/scratch/$USER/$SLURM_JOB_ID"
    mkdir -p "$WORK"
    trap 'rm -rf "$WORK"' EXIT

    cp -r "$HOME/datasets/mydata" "$WORK/"

    srun apptainer exec --nv --bind /scratch "$IMAGE" \
      python "$HOME/code/train.py" --data "$WORK/mydata" --out "$WORK/results"

    mkdir -p "$HOME/results/$SLURM_JOB_ID"
    cp -r "$WORK/results/." "$HOME/results/$SLURM_JOB_ID/"

Submit it with `sbatch train.sh`. For a CPU-only job, drop `--gres=gpu:1` and `--nv`.

Check that the GPU is visible:

    srun --gres=gpu:1 -t 0:05:00 apptainer exec --nv "$HOME/containers/pytorch.sif" \
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

- **You are not root.** The container runs as your user. An image that writes to `/root`, `/app` or another directory owned by root fails with `Permission denied` or `Read-only file system`. Point it at your home or `/scratch` instead, for example with `--env` or a command-line option of the tool.
- **The image is read-only.** Keep data and results outside it, in your home or `/scratch`. For a tool that insists on writing scratch files inside the image, `--writable-tmpfs` gives it a small, temporary writable layer that is discarded at the end.
- **Your environment is passed in.** Variables set in your session, like `PYTHONPATH` or a Conda `PATH`, reach the container and can break it. Add `--cleanenv` to start from the image's own environment.
- **Your `~/.local` is visible.** Python packages installed with `pip install --user` go to `~/.local` in your home and are picked up by every container you run, which can mix versions. Prefer a definition file, or a virtual environment per project.
- **The working directory is where you started**, not the image's `WORKDIR`. Use `--pwd` if the image expects a specific directory.

## Tips

- `apptainer shell --nv image.sif` inside `salloc` gives you an interactive shell in the container.
- `apptainer inspect --runscript image.sif` shows what `apptainer run` will execute.
- To add packages to an image, write a [definition file](#from-a-dockerfile) and run `apptainer build` in a job.
