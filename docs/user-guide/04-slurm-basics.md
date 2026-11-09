---
title: "SLURM basics"
parent: "User Guide"
nav_order: 4
---

# SLURM basics

[← User Guide](README.md) · [Home](../README.md)

This page explains how jobs are placed, what limits apply and how to submit. The tiers and how to get a higher one are in [Access and priority](../slurm/access-priority.md).

## Example scripts

To try the cluster quickly, start with the [Slurm example jobs](../slurm/README.md). They begin with a short "Hello cluster" job and go up to training on a GPU, each with its scripts and an explanation of what to expect.

For more options, [SLURM job examples](05-slurm-job-examples.md) has short copy-paste scripts for CPU and GPU jobs. Copy one, change the resources and the command to match your work, and submit it with `sbatch`.

## Where jobs run

You submit from `hpc01` (or from your group's node, once it has joined the cluster). Slurm picks the partition for you: you don't need `--partition` for normal work.

| Partition | Nodes | Who | Notes |
|---|---|---|---|
| `<group>-high`, `<group>-med`, `<group>-low` | your group's own node | members of that group, by tier | Tried first. High and medium jobs can preempt low-tier jobs and scavengers there |
| `<group>-shard` | your group's own node | members of that group, any tier | GPU shards (a sixth of the GPU each), up to 8 h. Never preempted, and it doesn't preempt your groupmates |
| `shared` | `hpc02`, `hpc03` | everyone | Whole GPUs, never preempted. Jobs here preempt scavengers on these nodes |
| `interactive` | `hpc01` | everyone | GPU shards (a sixth of the GPU each), up to 8 h |
| `scavenge` | every node: idle group nodes, `hpc01`, `hpc02` and `hpc03` | everyone | Lowest priority: jobs here can be preempted. Fills idle group nodes first, then `hpc02`/`hpc03`, then `hpc01`. The only partition where one job can span more than two nodes |

A job that names no partition goes to `<your group>-<your tier>,shared,scavenge`, and Slurm starts it wherever it fits first. A job asking for `--gres=shard:1` goes to `<your group>-shard,interactive` (just `interactive` if your group has no node yet).

## Your tier and limits

Your tier (low, medium or high) is set by an administrator and shown as your QOS. Check it with:

    sacctmgr show assoc user=$USER format=account,qos%25,defaultqos

| Tier | Longest job | On your group's node |
|---|---|---|
| high | 7 days | Scheduled first, never preempted |
| medium | 7 days | Never preempted |
| low | 7 days | Can be preempted by medium and high groupmates |

All tiers have the same 7-day limit, on your group's node and on `shared`. The tier decides who is scheduled first and who can be preempted, not how long a job may run. A job asking for more than 7 days is rejected at submit, with a message giving the cap. `--qos=low` on your own node never preempts groupmates, but your job can be preempted.

Other limits:

- **Default wall time is 4 hours.** A job without `-t` is stopped after 4 h.
- **Default memory is 7800 MB per CPU core** when you don't give `--mem`.
- **CPU-only jobs** can use at most 48 cores per node (36 on `hpc01`): 8 cores per node are kept for GPU jobs. Larger requests are rejected at submit.
- **Shards:** on `hpc01`, one per user at a time, with at most 6 cores and 64 GB. On your group's node you can hold up to 3 shards in total (one job with 3, or three jobs with 1), with at most 22 cores and 220 GB in all.
- CPUs, memory and GPUs are enforced. Ask for what you use: over-asking makes others wait or get preempted.

## Submit

    sbatch --gres=gpu:1 -t 12:00:00 job.sh               # one GPU, 12 h
    sbatch -c 16 --mem=64G -t 12:00:00 job.sh            # CPU-only
    sbatch --qos=low --gres=gpu:1 -t 5-00:00:00 job.sh   # 5 days, preemptible on your group's node

If you belong to more than one group, add `--account=<group>` to choose which one the job is charged to.

## Interactive work

- **A whole GPU:** `salloc --gres=gpu:1 -t 2:00:00`, on your group's node or on `shared`.
- **A small GPU slice:** `salloc --gres=shard:1 -c 4 --mem=32G` gets a sixth of a GPU for up to 8 h (2 h by default): on your group's node if it has a free shard, otherwise on `hpc01`. It is time-shared with up to five other users and has no memory isolation, so keep GPU memory under about 8 GB. While shards are in use on a node, a whole-GPU job can't start there, and the other way round: keep shard sessions short and exit when you are done.
- Interactive sessions can't be requeued. If one is preempted it is killed, so don't run them in `scavenge`.
- A shard session opens on `hpc01`, where you are already logged in, so the new shell looks exactly like your login shell. `echo $SLURM_JOB_ID` shows the job number inside a job and nothing outside one.
- Exit when you're done, so the allocation is released.

## No GPU outside a job

In an SSH session on a cluster node, the GPU isn't visible (`nvidia-smi` fails with "Failed to initialize NVML"). Use `salloc` or `srun` to get one. GPU work started in `tmux` or with `nohup` outside a job doesn't work.

## Preemption

Jobs in `scavenge`, and low-tier jobs on a group node, can be preempted when the node's owners, a `shared` job (on `hpc02`/`hpc03`) or a shard user (on `hpc01`) need it. A job is not preempted during its first 15 minutes. A preempted job gets SIGTERM, then 180 seconds, then it is requeued and starts again later. Allow a few minutes between a higher-priority job arriving and the preemption.

To survive it:

- trap SIGTERM and write a checkpoint;
- start the program with `srun` or `exec`, so it gets the signal;
- use `#SBATCH --requeue` and `#SBATCH --open-mode=append`;
- make the job idempotent: a job that ends during the grace time is requeued even if it finished, so check for a "done" marker before redoing work.

`--qos=low` on your own node is the considerate choice for long, restartable work: it never preempts groupmates.

## Check, monitor and cancel

    sinfo                                     # partitions and node states
    squeue -u "$USER" -o '%i|%P|%q|%T|%M|%l|%R'
    scontrol show job <job-id>
    sacct -X -j <job-id> --format=JobIDRaw,Account,Partition,QOS,State,ExitCode,Elapsed,AllocTRES
    scancel <job-id>

The same information is in a browser at [Slurm-web](https://slurm.hpc.isr.tecnico.ulisboa.pt): log in with your Authentik account to see the jobs, nodes, partitions, QOS and accounts, with history charts.

A pending job isn't a failure: read its reason (the last column of `squeue`) before resubmitting. Common reasons are `Resources` (waiting for a free GPU or cores) and `QOSMaxGRESPerUser` (you already have a shard). Cancel only job IDs that you have checked are yours.

## Getting help

Include the job ID, the command you used, the time and the error or pending reason. Send it through your group's support route in [Who's who](../overview/contacts.md). Don't include passwords, tokens or private data.
