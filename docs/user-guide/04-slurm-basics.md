---
title: "SLURM basics"
parent: "User Guide"
nav_order: 4
---

# SLURM basics

[← User Guide](README.md) · [Home](../README.md)

The shared cluster runs Slurm 26.05 since 2026-10-26. This page explains how jobs are placed, what limits apply and how to submit. The tiers and how to get a higher one are in [Access and priority](../slurm/access-priority.md). Copy-paste scripts are in [SLURM job examples](05-slurm-job-examples.md).

## Where jobs run

You submit from `hpc01` (or from your group's node, once it has joined the cluster). Slurm picks the partition for you: you don't need `--partition` for normal work.

| Partition | Nodes | Who | Notes |
|---|---|---|---|
| `<group>-high`, `<group>-med`, `<group>-low` | your group's own node | members of that group, by tier | Tried first. High and medium jobs can preempt low-tier jobs and scavengers there |
| `shared` | `hpc02`, `hpc03` | everyone | Whole GPUs, never preempted |
| `interactive` | `hpc01` | everyone | GPU shards (a sixth of the GPU each), up to 8 h |
| `scavenge` | idle group nodes and `hpc01` | everyone | Lowest priority: jobs here can be preempted |

A job that names no partition goes to `<your group>-<your tier>,shared,scavenge`, and Slurm starts it wherever it fits first. A job asking for `--gres=shard:1` goes to `interactive`.

## Your tier and limits

Your tier (low, medium or high) is set by an administrator and shown as your QOS. Check it with:

    sacctmgr show assoc user=$USER format=account,qos%25,defaultqos

| Tier | Longest job | On your group's node |
|---|---|---|
| high | 1 day | Scheduled first, never preempted |
| medium | 3 days | Never preempted |
| low | 7 days | Can be preempted by medium and high groupmates |

The same time limits apply on `shared`. A job asking for more than its tier allows is rejected at submit, with a message giving the cap. A high or medium user can submit a longer job with `--qos=low` (7 days, preemptible on the group node).

Other limits:

- **Default wall time is 4 hours.** A job without `-t` is stopped after 4 h.
- **Default memory is 7800 MB per CPU core** when you don't give `--mem`.
- **CPU-only jobs** can use at most 48 cores per node (36 on `hpc01`): 8 cores per node are kept for GPU jobs. Larger requests are rejected at submit.
- **Shards:** one per user at a time, with at most 6 cores and 64 GB.
- CPUs, memory and GPUs are enforced. Ask for what you use: over-asking makes others wait or get preempted.

## Submit

    sbatch --gres=gpu:1 -t 12:00:00 job.sh               # one GPU, 12 h
    sbatch -c 16 --mem=64G -t 12:00:00 job.sh            # CPU-only
    sbatch --qos=low --gres=gpu:1 -t 5-00:00:00 job.sh   # 5 days: low tier only

If you belong to more than one group, add `--account=<group>` to choose which one the job is charged to.

## Interactive work

- **A whole GPU:** `salloc --gres=gpu:1 -t 2:00:00`, on your group's node or on `shared`.
- **A small GPU slice:** `salloc --gres=shard:1 -c 4 --mem=32G` gets a sixth of `hpc01`'s GPU for up to 8 h (2 h by default). It is time-shared with up to five other users and has no memory isolation, so keep GPU memory under about 8 GB.
- Interactive sessions can't be requeued. If one is preempted it is killed, so don't run them in `scavenge`.
- Exit when you're done, so the allocation is released.

## No GPU outside a job

In an SSH session on a cluster node, the GPU isn't visible (`nvidia-smi` fails with "Failed to initialize NVML"). Use `salloc` or `srun` to get one. GPU work started in `tmux` or with `nohup` outside a job doesn't work.

## Preemption

Jobs in `scavenge`, and low-tier jobs on a group node, can be preempted when the node's owners or a shard user need it. A preempted job gets SIGTERM, then 180 seconds, then it is requeued and starts again later. Allow a few minutes between a higher-priority job arriving and the preemption.

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
