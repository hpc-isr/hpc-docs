# Storage

[← User Guide](README.md) · [Home](../README.md)

## Where to put things

| Path | Size | Shared between nodes? | Speed | Use for |
|---|---|---|---|---|
| `/home/<username>` | ~10.5 TiB total, shared by everyone | **Yes**, same on `hpc01`–`hpc03` (not on group nodes) | Network (MooseFS over NVMe) | Code, environments, results, job scripts |
| `/scratch` | ~1.5 TB per node | **No**, each node has its own | Local block storage | Temporary large data during a job |
| `/` (root) | 80 GB | No | — | Don't write here |

**`/home` is replicated** (two copies on different nodes), so one node failing doesn't lose your files. **Replication is not a backup**: a file you delete or overwrite is gone everywhere.

**`/home` is not backed up.** MooseFS survives the loss of a disk or a node, but nothing protects you from deleting or overwriting a file. Keep your own copy of anything important.

There are no quotas on `/home` yet; a quota policy is still to be defined. Please clean up what you no longer need.

`/scratch` is world-writable like `/tmp`: make your own `/scratch/$USER` folder. Its cleanup policy is still to be defined, so treat it as temporary and don't rely on files staying there.

Deleted files in `/home` stay in MooseFS's trash for **24 hours**. If you delete something by mistake, ask an admin quickly.

## Check your usage

```bash
du -sh ~                 # how much your home uses
df -h /home /scratch     # free space on each filesystem
```

## Use `/scratch` inside a job

`/scratch` on the node where your job runs is fast and doesn't load the shared filesystem. Copy data in, work, copy results out, clean up:

```bash
#!/bin/bash
#SBATCH --job-name=scratch-demo
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00

WORK=/scratch/$USER/$SLURM_JOB_ID
mkdir -p "$WORK"
rsync -a ~/datasets/mydata/ "$WORK/data/"

cd "$WORK"
python ~/code/train.py --data "$WORK/data" --out "$WORK/out"

rsync -a "$WORK/out/" ~/results/$SLURM_JOB_ID/
rm -rf "$WORK"
```

## Shared software in `/opt`

`/opt` is also on MooseFS and identical on every shared node. Admins install shared tools there.

There is no module system. Today `/opt` holds one shared container image:

| File | What |
|---|---|
| `/opt/containers/isaac-sim-6.1.0.sif` | NVIDIA Isaac Sim 6.1.0 as an Apptainer/Singularity image (10.6 GB) |

Apptainer is installed for all users. Run a `.sif` image with it, passing the GPU through with `--nv`, e.g. inside a GPU job:

```bash
srun --gres=gpu:1 --cpus-per-task=16 --mem=64G --time=02:00:00 --pty \
  apptainer shell --nv /opt/containers/isaac-sim-6.1.0.sif
```

To run Isaac Sim and stream it to your laptop, use the launch script in [Isaac Sim](08-isaac-sim.md).

## Python environments

Create environments in your home so they're visible on every node:

```bash
# venv
python3 -m venv ~/envs/myproj
source ~/envs/myproj/bin/activate
pip install torch numpy

# or uv (fast)
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv ~/envs/myproj && source ~/envs/myproj/bin/activate
uv pip install torch numpy
```
