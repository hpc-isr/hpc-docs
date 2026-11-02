---
title: "5. Jupyter on a GPU slice"
parent: "Slurm"
nav_order: 5
---

# 5. Jupyter on a GPU slice (shard)

[← Slurm](../../README.md)

| CPUs | Memory | GPU | Time |
|---|---|---|---|
| 4 | 32 GB | 1 shard (a sixth of `hpc01`'s L40S) | up to 8 h, 2 h here |

**First run:** Creates this example's Python environment (JupyterLab and PyTorch, 7 GB, 2–5 min) in `/scratch` on `hpc01`. See [Downloads and disk space](../../README.md#downloads-and-disk-space).

For trying things out, debugging a model, or a notebook, a whole GPU is usually more than you need. The `interactive` partition on `hpc01` splits its GPU into six **shards**: up to six users share it at once, so a shard often starts sooner than a whole GPU.

This job starts JupyterLab on a shard and prints the SSH tunnel to reach it from your laptop.

## Run it

Uses its own Python environment, created on the node the first time (see [Before you start](../../README.md#before-you-start)). Add the packages your notebooks need to [`requirements.txt`](requirements.txt); the next job rebuilds the environment.

    cd ~/slurm-examples/05-jupyter-shard
    sbatch job.sbatch
    cat jupyter-<jobid>.out      # once the job is running

File: [`job.sbatch`](job.sbatch)

## Connect

The log tells you what to do. In short, on your laptop:

    ssh -N -L 8888:localhost:<port> <username>@hpc01.isr.tecnico.ulisboa.pt

then open `http://127.0.0.1:8888/lab?token=<token>` with the token from the log. You need to be on IST's network or VPN to reach `hpc01`, as for any SSH login.

## Limits of a shard

- **One shard per user** at a time, with at most 6 CPUs and 64 GB of memory. A second one stays pending with `QOSMaxGRESPerUser`.
- **No GPU memory isolation.** All six users share the 48 GB, so keep your use under about 8 GB. In PyTorch you can enforce that in the first cell:

      import torch
      torch.cuda.set_per_process_memory_fraction(8 / 48)

- **Time-shared compute.** Your code gets the GPU in turns with the others, so don't time benchmarks on a shard.
- Up to 8 hours. For a long training run, submit a batch job with a whole GPU ([example 4](../04-mnist-gpu/README.md) or [6](../06-yolo-voc/README.md)).

## Data in a notebook

Notebooks and code live in your home. For data you read heavily, copy it to `/scratch/$USER/...` on `hpc01` from the notebook first and read it from there, as the batch examples do (see [Data and results](../../README.md#data-and-results)). Save anything you want to keep back to your home or your group's NAS: `/scratch` is cleaned after 30 days.

## TensorBoard

Your notebook environment has TensorBoard. To watch training curves from another example while it runs:

1. In JupyterLab, open **File → New → Terminal** and run `tensorboard --logdir <results folder>`, for example `~/results/yolo-voc`. It prints the port it listens on, usually 6006 (or the next free one if another user has it).
2. On your laptop, open a second tunnel with that port and leave it open:

       ssh -N -L 6006:localhost:<port> <username>@hpc01.isr.tecnico.ulisboa.pt

3. Open `http://127.0.0.1:6006`.

TensorBoard is not installed in your login shell or in the other examples' environments, so `tensorboard` there gives "command not found".

## Without a notebook

For a plain shell on a shard:

    srun --gres=shard:1 -c 4 --mem=32G -t 2:00:00 --pty bash

The shell opens on `hpc01`, the machine you are already logged in to, so it looks exactly like your login shell: same hostname, same prompt, no message. To check that you are inside the job, run `echo $SLURM_JOB_ID` (empty outside a job) or `nvidia-smi -L` (fails outside a job). `exit` ends the job and brings you back to your login shell.

The resources stay reserved until you `exit`, even while you are idle. Please exit or `scancel` when you're done.
