---
title: "Storage"
parent: "User Guide"
nav_order: 3
---

# Storage

[← User Guide](README.md) · [Home](../README.md)

| Path | What it is | Shared between nodes | Limit | Backed up |
|---|---|---|---|---|
| `/home/<username>` | Your home, on the cluster's MooseFS filesystem | Yes: the same on `hpc01`–`hpc03` and on group nodes that have joined the cluster | 200 GiB soft, 500 GiB hard | No |
| `/storage/shared` | Shared software and container images, on MooseFS | Yes | | No |
| `/scratch` | Fast local NVMe disk on each node, 3.5 TB (shared nodes, and group nodes that have joined the cluster) | No: each node has its own | 100 GiB soft, 200 GiB hard on each node; files untouched for 30 days are deleted | No |
| `/storage/<group>/anubis-nas` | Your group's storage on the ISR NAS (DSOR so far) | Yes: mounted on every node | The group's NAS volume | No |

## Your home

Your home is the same on every node, so a job sees the files you left from `hpc01`. MooseFS keeps three copies of every file in your home on different nodes, so it survives two disk or node failures at once. That isn't a backup: a deleted or overwritten file can't be restored after the 24 hours it stays in the MooseFS trash. Keep a copy of anything important somewhere else.

### Quota

Each home has a quota of **200 GiB soft and 500 GiB hard**:

- Above 200 GiB you can keep writing for 7 days. After that, the soft limit acts as a hard one until you go back under 200 GiB.
- A write that would go above 500 GiB fails with `Disk quota exceeded`.

Check your usage and limits:

    mfsgetquota -h "$HOME"
    cd ~ && du -sh .[!.]* * 2>/dev/null | sort -h | tail -20

Everything under your home counts, hidden files and directories included: those whose name starts with a dot, such as `~/.cache`. `ls` and `du -sh *` skip them, so use `ls -a` to see them, and `du -sh .[!.]* *` as above to count them with the rest.

The biggest hidden ones are usually the download caches that tools fill by default: `~/.cache` (pip, Hugging Face, PyTorch) and `~/.apptainer/cache`. Keep those caches, Python environments, container images and a job's working files on `/scratch` instead, mainly for speed: `/scratch` is the node's local NVMe disk, much faster than your home on MooseFS for the thousands of small files that environments and caches are made of, and a job that works there doesn't slow down everyone else's access to their home. It also keeps them off your home quota. See [Download caches](#download-caches) and [Containers with Apptainer](09-apptainer.md#where-things-go). If you need more space, ask your group's admin.

## `/scratch`

`/scratch` is a local NVMe disk (3.5 TB) on each node: `hpc01`–`hpc03`, and each group node once it has joined the cluster. It is the fastest storage on the cluster, especially for many small files, but it is not shared: a file written there by a job on `hpc02` isn't visible on `hpc03` or `hpc01`. Use it for temporary files during a job:

    WORK="/scratch/$USER/$SLURM_JOB_ID"
    mkdir -p "$WORK"
    cp -r "$HOME/data/input" "$WORK/"
    srun python "$HOME/code/train.py" --data "$WORK/input" --out "$WORK/out"
    cp -r "$WORK/out" "$HOME/results/$SLURM_JOB_ID"
    rm -rf "$WORK"

Copy results back to your home before the job ends, and delete what you leave there. Other users share the same disk.

### Staging a dataset

Reading a dataset straight from your home or the NAS in every epoch is slower than reading it from `/scratch`, and it slows everyone else down too. Measured with several nodes reading at once:

| From | Nodes reading | All together | Per node |
|---|---|---|---|
| Your home (MooseFS) | 4 (2026-11-01) | about 3.3 GiB/s | about 860 MiB/s |
| `/storage/shared` (MooseFS) | 4 (2026-11-01) | about 2.4 GiB/s | about 620 MiB/s |
| Group NAS (`/storage/<group>/anubis-nas`) | 5 (2026-11-02) | about 570 MiB/s | about 115 MiB/s |

The NAS link is shared by every node, so it gets slower the more jobs read from it at once. What helps:

- **Copy it to `/scratch` once per node and reuse it.** Keep the copy in a fixed place, such as `/scratch/$USER/datasets/<name>`, and skip the copy when it is already there, so your next jobs on that node start at once. It stays for 30 days after its last use (see below), within your `/scratch` quota.
- **Pin jobs to nodes that have it** with `#SBATCH --nodelist=<node>` if you rerun often (it waits for that node).
- **A dataset many people use** can live on MooseFS in `/storage/shared` instead, read from every node at the speed above. Ask the admins.

For example, at the start of a job script:

    DATA="/scratch/$USER/datasets/my-dataset"
    if [ ! -f "$DATA/.complete" ]; then
        mkdir -p "$DATA"
        rsync -a /storage/dsor/anubis-nas/datasets/my-dataset/ "$DATA/"
        touch "$DATA/.complete"
    fi

### Quota

On each node you have a quota of **100 GiB soft and 200 GiB hard** on `/scratch`, counted separately on each node:

- Above 100 GiB you can keep writing for 7 days. After that, the soft limit acts as a hard one until you go back under 100 GiB.
- A write that would go above 200 GiB fails with `Disk quota exceeded`.

Check your usage and limits on the node you are on (in a job, or on `hpc01`):

    quota -s
    du -sh /scratch/$USER

If a job needs more, ask the admins.

### Old files are deleted

`/scratch` is for files a job is using, not for keeping data. Every week, and whenever a node's `/scratch` is more than 90% full, files that nobody has read, written or changed for **30 days** are deleted. Then empty directories are deleted too, except your top-level `/scratch/<name>` directory. While you have a job running anywhere on the cluster, or a session on that node, none of your files are deleted. Deleted files can't be restored: keep results in your home or your group's NAS storage.

## Group NAS storage

Some research groups have their own volume on the ISR NAS, mounted on every node at `/storage/<group>/anubis-nas`. So far that is DSOR (`/storage/dsor/anubis-nas`); other groups follow as their NAS is set up.

- Only members of the group can open the directory. New files are group-writable, so everyone in the group can read and change them.
- It is meant for datasets and results you share within the group. The link to the NAS is slower than the cluster's own storage, so copy what a job reads heavily to `/scratch` first ([Staging a dataset](#staging-a-dataset)).
- It is mounted on first access, so the first `ls` can take a few seconds.
- It is **not backed up**. The NAS survives one failed disk, but not a deleted file. Keep your own copy of anything you can't regenerate.

Check it and the free space:

    ls /storage/dsor/anubis-nas
    df -h /storage/dsor/anubis-nas

## Software environments

Create Python environments on `/scratch`, in a job on the node that will use them. Python reads thousands of small files at start-up, and the local NVMe serves them much faster than your home on MooseFS. `/scratch` isn't shared, so build the environment on every node your jobs run on, or pin the jobs to one node with `--nodelist`:

    #!/bin/bash
    #SBATCH --nodelist=hpc02
    #SBATCH --cpus-per-task=4
    #SBATCH --mem=16G
    #SBATCH --time=00:45:00
    ENV="/scratch/$USER/envs/my-project"
    mkdir -p "$(dirname "$ENV")"
    python3 -m venv "$ENV"
    source "$ENV/bin/activate"
    export PIP_CACHE_DIR="/scratch/$USER/pip-cache"
    python -m pip install -r "$HOME/code/my-project/requirements.txt"

Keep your `requirements.txt` in your home, so you can recreate the environment on any node. An environment nobody uses for 30 days is deleted with other old `/scratch` files. The [Slurm examples](../slurm/README.md#before-you-start) do this automatically: each job creates its environment on its node when it isn't there yet ([`env.sh`](../slurm/examples/env.sh)).

### Download caches

Many tools download into `~/.cache` in your home unless told otherwise, and never clean it up. In a job, point their caches at the node's `/scratch`, where they are fast and reused by your later jobs on that node:

    export PIP_CACHE_DIR="/scratch/$USER/pip-cache"
    export HF_HOME="/scratch/$USER/hf-cache"            # Hugging Face models and datasets
    export TORCH_HOME="/scratch/$USER/torch-cache"      # torchvision and torch.hub weights
    export UV_CACHE_DIR="/scratch/$USER/uv-cache"
    export APPTAINER_CACHEDIR="/scratch/$USER/$SLURM_JOB_ID/apptainer-cache"   # removed with the job folder

Check what is already in your home with `du -sh ~/.cache/* ~/.apptainer/cache 2>/dev/null | sort -h`, and delete it: everything there is downloaded again when needed.

For a full software stack, CUDA libraries included, use a container: see [Containers with Apptainer](09-apptainer.md). You can't install system packages on the nodes.

Don't put passwords, tokens or private keys in job scripts or repositories.
