---
title: "Storage"
parent: "User Guide"
nav_order: 3
---

# Storage

[← User Guide](README.md) · [Home](../README.md)

| Path | What it is | Shared between nodes | Limit | Backed up |
|---|---|---|---|---|
| `/home/<username>` | Your home, on the cluster's MooseFS filesystem | Yes: the same on `hpc01`–`hpc03` and on group nodes that have joined the cluster | 500 GiB soft, 1000 GiB hard | No |
| `/opt` | Shared software, on MooseFS | Yes | | No |
| `/scratch` | Fast local disk on each shared node | No: each node has its own | Free space on that disk | No |

## Your home

Your home is the same on every node, so a job sees the files you left from `hpc01`. MooseFS keeps two copies of every file on different nodes, so it survives a disk or node failure. That isn't a backup: a deleted or overwritten file can't be restored after the 24 hours it stays in the MooseFS trash. Keep a copy of anything important somewhere else.

### Quota

Each home has a quota of **500 GiB soft and 1000 GiB hard**:

- Above 500 GiB you can keep writing for 7 days. After that, the soft limit acts as a hard one until you go back under 500 GiB.
- A write that would go above 1000 GiB fails with `Disk quota exceeded`.

Check your usage and limits:

    mfsgetquota -h "$HOME"
    du -sh "$HOME"/* | sort -h | tail

Everything under your home counts, including virtual environments, Apptainer images and the Apptainer cache (`~/.apptainer/cache`). If you need more space, ask your group's admin.

## `/scratch`

`/scratch` is a local disk on each shared node. It is faster than your home for many small files, but it is not shared: a file written there by a job on `hpc02` isn't visible on `hpc03` or `hpc01`. Use it for temporary files during a job:

    WORK="/scratch/$USER/$SLURM_JOB_ID"
    mkdir -p "$WORK"
    cp -r "$HOME/data/input" "$WORK/"
    srun python "$HOME/code/train.py" --data "$WORK/input" --out "$WORK/out"
    cp -r "$WORK/out" "$HOME/results/$SLURM_JOB_ID"
    rm -rf "$WORK"

Copy results back to your home before the job ends, and delete what you leave there. Other users share the same disk.

## Software environments

Create Python environments in your home, so every node sees them:

    python3 -m venv "$HOME/envs/my-project"
    source "$HOME/envs/my-project/bin/activate"
    python -m pip install -r "$HOME/code/my-project/requirements.txt"

For a full software stack, CUDA libraries included, use a container: see [Containers with Apptainer](09-apptainer.md). You can't install system packages on the nodes.

Don't put passwords, tokens or private keys in job scripts or repositories.
