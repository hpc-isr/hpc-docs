---
title: "SLURM basics"
parent: "User Guide"
nav_order: 4
---

# SLURM basics

[← User Guide](README.md) · [Home](../README.md)

The shared nodes `hpc01`, `hpc02`, `hpc03` are managed by **SLURM**: you describe what you need (cores, memory, GPU, time) and SLURM runs your work when those resources are free. This keeps the three shared GPUs fair for everyone.

**Rule of thumb:** on `hpc01`–`hpc03`, anything heavier than editing files or compiling goes through `srun` or `sbatch`.

## What's available

| Partition | Nodes | Per node | Default | Time limit |
|---|---|---|---|---|
| `normal` | `hpc01`, `hpc02`, `hpc03` | 56 cores, ~433 GiB RAM (443195 MB), 1 × L40S | Yes | None |

There is one partition and no time limit. GPUs are configured as untyped GRES, so request them with `--gres=gpu:1` (not `gpu:l40s:1`).

```bash
sinfo                       # partitions and node states
sinfo -N -o "%N %c %m %G %T" # per node: cores, memory (MB), GPUs, state
squeue                      # everyone's jobs
squeue -u $USER             # your jobs
```

Node states: `idle` (free), `mix` (partly used), `alloc` (full), `drain`/`down` (unavailable).

## Interactive job: a shell on a compute node

```bash
# 4 cores, 16 GB RAM, 1 hour, no GPU
srun --cpus-per-task=4 --mem=16G --time=01:00:00 --pty bash

# With the GPU
srun --gres=gpu:1 --cpus-per-task=8 --mem=64G --time=02:00:00 --pty bash
nvidia-smi   # check you see the L40S
exit         # release the resources when done
```

The resources are held until you `exit`, even if you are idle. Please exit when you're done.

## Batch job: submit and walk away

Create `myjob.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=myjob
#SBATCH --output=%x-%j.out        # %x = job name, %j = job id
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:00:00

echo "Running on $(hostname)"
python3 ~/code/analysis.py
```

Submit and follow it:

```bash
sbatch myjob.sh                 # prints: Submitted batch job 1234
squeue -u $USER                 # PD = pending, R = running
tail -f myjob-1234.out          # watch output
scancel 1234                    # cancel if needed
```

More scripts (GPU, arrays, pipelines): [Job script examples](05-slurm-job-examples.md).

## Requesting resources

| Option | Meaning | Example |
|---|---|---|
| `--cpus-per-task=N` | CPU cores for your program | `--cpus-per-task=8` |
| `--mem=SIZE` | RAM per node | `--mem=64G` |
| `--gres=gpu:1` | One GPU (each node has one L40S) | `--gres=gpu:1` |
| `--time=HH:MM:SS` | Maximum run time; job is killed after | `--time=12:00:00` |
| `--nodelist=NODE` | Force a specific node | `--nodelist=hpc02` |
| `--job-name=NAME` | Name shown in `squeue` | `--job-name=train` |
| `--output=FILE` | Where stdout goes | `--output=logs/%x-%j.out` |

**Always set `--mem` and `--time`.** There is no default memory limit: a job that omits `--mem` reserves the **whole node's memory**, blocking everyone else on that node. Jobs are confined to what they asked for: exceeding `--mem` kills the job (`OUT_OF_MEMORY`), and exceeding `--time` kills it too. Asking for much more than needed makes your job (and everyone else's) wait longer.

Each node has only **one GPU**, so at most three GPU jobs run at once on the shared cluster. A multi-GPU job must span nodes; ask an admin first.

## Inspecting jobs

```bash
scontrol show job <jobid>       # full details of a pending/running job
squeue -u $USER --start         # estimated start times
```

SLURM accounting is **not enabled yet** (it is being set up), so `sacct` shows nothing for now. A finished job stays visible in `scontrol show job <jobid>` for about 5 minutes; after that, your job's output file is the record.

## Why is my job pending?

`squeue -u $USER` shows a reason in the last column:

| Reason | Meaning |
|---|---|
| `Resources` | Waiting for enough free cores/memory/GPU |
| `Priority` | Other jobs are ahead of yours |
| `ReqNodeNotAvail` | Requested node is down or reserved |
| `QOSMaxGRESPerUser` or similar | You hit a per-user limit |

## Etiquette

- Don't hold an interactive GPU session while idle.
- Test with a short `--time` before submitting long runs.
- Put large temporary data in `/scratch` (see [Storage](03-storage.md)).

## Related pages

- [Shared ISR Slurm baseline](../slurm/verified-baseline.md): recorded configuration of the shared cluster.
- [Submitting a batch job with Slurm](../slurm/batch-jobs.md): a general step-by-step batch workflow.
- [Group-aware access and priority model](../slurm/access-priority.md): who can use the shared pool and how priority works.
