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
| `/storage/shared` | Shared software and container images, on MooseFS | Yes | | No |
| `/scratch` | Fast local NVMe disk on each node, 3.5 TB (shared nodes, and group nodes that have joined the cluster) | No: each node has its own | 100 GiB soft, 200 GiB hard on each node; files untouched for 30 days are deleted | No |
| `/storage/anubis-nas/<group>` | Your group's storage on the ISR NAS (DSOR so far) | Yes: mounted on every node | The group's NAS volume | No |

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

`/scratch` is a local NVMe disk (3.5 TB) on each node: `hpc01`–`hpc03`, and each group node once it has joined the cluster. Some nodes still have the older 1.5 TB `/scratch` until they are moved, one at a time with a short drain, in early November 2026; your files there are carried over. It is the fastest storage on the cluster, especially for many small files, but it is not shared: a file written there by a job on `hpc02` isn't visible on `hpc03` or `hpc01`. Use it for temporary files during a job:

    WORK="/scratch/$USER/$SLURM_JOB_ID"
    mkdir -p "$WORK"
    cp -r "$HOME/data/input" "$WORK/"
    srun python "$HOME/code/train.py" --data "$WORK/input" --out "$WORK/out"
    cp -r "$WORK/out" "$HOME/results/$SLURM_JOB_ID"
    rm -rf "$WORK"

Copy results back to your home before the job ends, and delete what you leave there. Other users share the same disk.

### Staging a dataset

Reading a dataset straight from your home or the NAS in every epoch is slower than reading it from `/scratch`, and it slows everyone else down too. Measured with three nodes reading at once (2026-10-31):

| From | All three nodes together | Per node |
|---|---|---|
| Your home and `/storage/shared` (MooseFS) | about 1.8 GiB/s | about 600 MiB/s |
| Group NAS (`/storage/anubis-nas/<group>`) | about 470 MiB/s | about 160 MiB/s |

The NAS link is shared by every node, so it gets slower the more jobs read from it at once. What helps:

- **Copy it to `/scratch` once per node and reuse it.** Keep the copy in a fixed place, such as `/scratch/$USER/datasets/<name>`, and skip the copy when it is already there, so your next jobs on that node start at once. It stays for 30 days after its last use (see below), within your `/scratch` quota.
- **Pin jobs to nodes that have it** with `#SBATCH --nodelist=<node>` if you rerun often (it waits for that node).
- **A dataset many people use** can live on MooseFS in `/storage/shared` instead, read from every node at the speed above. Ask the admins.

For example, at the start of a job script:

    DATA="/scratch/$USER/datasets/my-dataset"
    if [ ! -f "$DATA/.complete" ]; then
        mkdir -p "$DATA"
        rsync -a /storage/anubis-nas/dsor/datasets/my-dataset/ "$DATA/"
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

Some research groups have their own volume on the ISR NAS, mounted on every node at `/storage/anubis-nas/<group>`. So far that is DSOR (`/storage/anubis-nas/dsor`); other groups follow as their NAS is set up.

- Only members of the group can open the directory. New files are group-writable, so everyone in the group can read and change them.
- It is meant for datasets and results you share within the group. The link to the NAS is slower than the cluster's own storage, so copy what a job reads heavily to `/scratch` first ([Staging a dataset](#staging-a-dataset)).
- It is mounted on first access, so the first `ls` can take a few seconds.
- It is **not backed up**. The NAS survives one failed disk, but not a deleted file. Keep your own copy of anything you can't regenerate.

Check it and the free space:

    ls /storage/anubis-nas/dsor
    df -h /storage/anubis-nas/dsor

## Software environments

Create Python environments in your home, so every node sees them:

    python3 -m venv "$HOME/envs/my-project"
    source "$HOME/envs/my-project/bin/activate"
    python -m pip install -r "$HOME/code/my-project/requirements.txt"

For a full software stack, CUDA libraries included, use a container: see [Containers with Apptainer](09-apptainer.md). You can't install system packages on the nodes.

Don't put passwords, tokens or private keys in job scripts or repositories.
