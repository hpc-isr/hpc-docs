---
title: "10. Training across several nodes"
parent: "Slurm"
nav_order: 10
---

# 10. Training across several nodes (PyTorch DDP)

[← Slurm](../../README.md)

| Nodes | CPUs | Memory | GPU | Time |
|---|---|---|---|---|
| 2 | 16 per node | 64 GB per node | 1 × L40S per node | about 10 min |

**First run:** Creates this example's Python environment (PyTorch with CUDA, 7 GB, 2–5 min) in `/scratch` on each new node. Downloads CIFAR-10 (170 MB, seconds, under a minute to unpack) on each node; 0.4 GB of `/scratch` per node and 50 MB of results. See [Downloads and disk space](../../README.md#downloads-and-disk-space).

> **Ask an admin before running this.** Multi-node jobs haven't been tested on this cluster yet, and a two-node job takes both GPUs of the `shared` partition. Your group's admin can confirm that your tier allows it and pick a quiet time. See [Who's who](../../../overview/contacts.md).

Every node of the cluster has a single GPU, so using more than one GPU for one training run means using more than one node. This example trains ResNet-18 on [CIFAR-10](https://www.cs.toronto.edu/~kriz/cifar.html) with PyTorch's **DistributedDataParallel** (DDP): one process per GPU, each training on a different part of every batch, with the gradients averaged over the network after every step.

## Run it

Uses its own Python environment, from [`requirements.txt`](requirements.txt), created on each node the first time (see [Before you start](../../README.md#before-you-start)).

    cd ~/slurm-examples/10-ddp-multinode
    sbatch job.sbatch               # 2 nodes
    sbatch --nodes=1 job.sbatch     # 1 node, to compare

Files: [`job.sbatch`](job.sbatch), [`train_ddp.py`](train_ddp.py)

## What you should see

`ddp-cifar-<jobid>.out` (in the folder you submitted from) shows the three stages, with the node each line comes from, then one line per process, per-epoch throughput from rank 0, and a summary:

    01:02:03 1/3 Python environment on hpc[02-03]
    01:02:04 hpc02: environment ready
    01:06:40 hpc03: environment ready
    01:06:41 2/3 CIFAR-10 on every node
    01:06:42 hpc02: data ready, 410G free on /scratch
    01:06:55 hpc03: data ready, 395G free on /scratch
    01:06:56 3/3 Training on 2 node(s), rendezvous at hpc02:20144
    hpc02: rank 0 of 2 (pid 41873) joining hpc02:20144
    hpc03: rank 1 of 2 (pid 30215) joining hpc02:20144
    rank 0/2 on hpc02, GPU NVIDIA L40S
    rank 1/2 on hpc03, GPU NVIDIA L40S
    training: 10 epochs of 97 steps, global batch 512; results are written when training ends
    epoch 1/10: loss 1.412  25.3s  1,976 images/s
    ...
    {"gpus": 2, "nodes": 2, "global_batch": 512, "test_accuracy": 0.91, "seconds_per_epoch": 9.8, ...}

The summary and the model are copied to `~/results/ddp-cifar/<jobid>/`. Run it with `--nodes=1` and `--nodes=2` and put the two `result.json` files side by side:

| GPUs | Seconds per epoch | Images per second | Speed-up |
|---|---|---|---|
| 1 | from your run | | 1.0× |
| 2 | from your run | | |

Perfect scaling would be 2×. Over the nodes' Ethernet network, a small model like ResNet-18 gets noticeably less, because every step waits for the gradients to cross the network. Bigger models with more computation per step scale better.

## How it works

- **One task per node.** `--nodes=2 --ntasks-per-node=1 --gres=gpu:1` gives one GPU on each of two nodes, and `srun` starts one copy of the command on each.
- **torchrun** starts the training process on each node. The first node of the job is the meeting point (`MASTER_ADDR`), and each node passes its own `--node_rank` (Slurm's `SLURM_NODEID`), so rank 0, which writes the results, always runs on the first node, where the batch script runs.
- **NCCL** carries the gradients between GPUs. `NCCL_SOCKET_IFNAME=ens3` makes it use the nodes' private network.
- **Data on each node.** `/scratch` is local to each node, so the first `srun` step makes sure every node has its own copy of CIFAR-10, downloading it once per node. Training then reads only from the local disk.
- **Results.** Rank 0 writes to `/scratch` on the first node only when training ends, so `/scratch/$USER/<jobid>/out` stays empty while the job runs; follow progress in the log instead. When the job ends, the batch script copies the results to `RESULTS_DIR` and removes the working folder on every node.
- **Failing fast.** Each `srun` has `--kill-on-bad-exit=1`, so an error on one node ends the job instead of leaving the other node waiting. A data download still going after 10 minutes, or a process that can't reach the others for 10 minutes, fails with an error in the log rather than running until the time limit.
- **Learning rate.** The global batch grows with the number of GPUs, so the script scales the learning rate with it.

## Try next

- Use the same pattern for your own model: wrap it in `DDP`, use a `DistributedSampler`, and only save from rank 0.
- Isaac Lab trains across nodes the same way: [example 11](../11-isaaclab-4gpu/README.md) runs it on 4 GPUs.

## If the log stops moving

The last line of the log says which stage it is in. Check, from `hpc01`:

    tail -n 30 ddp-cifar-<jobid>.out
    squeue -s -j <jobid>                     # the running step: .0 environment, .1 data, .2 training
    sacct -j <jobid> -o JobID%-14,JobName%-10,State,Elapsed,NodeList

- **Stuck in 1/3 on one node:** that node is creating the environment (installing PyTorch, 2–5 min; longer with a cold pip cache). The line `Creating the 'ddp' environment on <node>` says so.
- **Stuck in 2/3:** a slow download, or `/scratch` on that node is full or over your quota. While the job runs you can SSH to its nodes; on the node, `quota -s` and `df -h /scratch` show your usage.
- **Stuck in 3/3 before the `training:` line:** the processes can't reach each other: `joining` lines but no `rank … GPU` lines means the first contact with the first node, and `rank` lines but no `training:` line means NCCL's own connection. After 10 minutes the job fails with a timeout. Run it again as `NCCL_DEBUG=INFO sbatch job.sbatch` and send the log to your admin.
- **Stuck after `training:`, with no epoch line:** the first epoch takes about 30 s. To see where a process is, SSH to its node and run `kill -USR1 <pid>`, with the pid from that node's `joining` line; the process prints its Python stack to the log and keeps going. `sstat -j <jobid>.2 -o JobID,AveCPU,MaxRSS` shows whether it is using CPU.
