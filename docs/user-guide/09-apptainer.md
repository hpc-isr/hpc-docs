---
title: "Containers with Apptainer"
parent: "User Guide"
nav_order: 9
---

# Containers with Apptainer

[← User Guide](README.md) · [Home](../README.md)

[Apptainer](https://apptainer.org/docs/user/latest/) is installed on every HPC node. It runs a container as your own user, with no daemon and no root, inside your Slurm job. Docker isn't available to users, but Apptainer runs Docker and OCI images.

## Get an image

Convert an image from a registry into a single `.sif` file in your home:

    mkdir -p "$HOME/containers"
    srun -c 4 --mem=16G -t 1:00:00 \
      apptainer pull "$HOME/containers/pytorch.sif" docker://pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime

Building or pulling a large image takes several CPUs and a lot of memory. Do it inside a job, as above, because a session on `hpc01` is limited to 4 CPUs and 16 GiB (see [SSH login](02-ssh-login.md#limits-outside-slurm)). Pin a version tag, so the image doesn't change under you.

The `.sif` file and the download cache (`~/.apptainer/cache`) count toward your [home quota](03-storage.md#quota). Clear the cache with `apptainer cache clean` once the image is built.

## Run it in a job

Add `--nv` to give the container the GPUs that Slurm allocated to your job. It uses the node's NVIDIA driver, so the image only needs the CUDA libraries.

    srun --gres=gpu:1 -c 8 --mem=64G -t 12:00:00 \
      apptainer exec --nv "$HOME/containers/pytorch.sif" \
      python "$HOME/code/train.py"

In a batch script:

    #!/bin/bash
    #SBATCH --job-name=train
    #SBATCH --gres=gpu:1
    #SBATCH --cpus-per-task=8
    #SBATCH --mem=64G
    #SBATCH --time=12:00:00
    #SBATCH --output=%x-%j.out

    srun apptainer exec --nv "$HOME/containers/pytorch.sif" \
      python "$HOME/code/train.py" --data /scratch/$USER/$SLURM_JOB_ID

Your home is mounted inside the container. `/scratch` and other paths are not mounted by default: add `--bind /scratch` to `apptainer exec` to reach them.

Check that the GPU is visible:

    srun --gres=gpu:1 -t 0:05:00 apptainer exec --nv "$HOME/containers/pytorch.sif" \
      python -c 'import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))'

## Tips

- Keep data and results outside the image, in your home or `/scratch`. A `.sif` file is read-only.
- `apptainer shell --nv image.sif` inside `salloc` gives you an interactive shell in the container.
- To add packages to an image, write a [definition file](https://apptainer.org/docs/user/latest/definition_files.html) and run `apptainer build` in a job, or `pip install --user` inside the container. Packages installed that way go to `~/.local` in your home and are picked up by every container you run, which can mix versions; prefer a definition file or a virtual environment per project.
