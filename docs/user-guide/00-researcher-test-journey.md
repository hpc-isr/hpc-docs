---
title: "Researcher Test Journey"
parent: "User Guide"
nav_order: 0
---

# Researcher Test Journey

Use this guide for a small, administrator-approved test of your own ISR HPC access and Slurm workflow. Reading this page does not grant account, cluster, QoS, storage, or repository access.

## Before the test

1. Read [Getting an account](01-getting-an-account.md) and [SSH login](02-ssh-login.md). Ask your group administrator to confirm your exact HPC login, authentication method, supported SSH hostname, and that your account is enabled for the target service. An identity-provider account alone does not prove cluster authorization.
2. Ask the administrator to confirm the Slurm account, partition, allowed QoS, resource bounds, and whether a GPU allocation is permitted. Use only those values. Do not infer that a documented QoS or configured limit is available to your association.
3. Read [Storage](03-storage.md). Before using research data, obtain an administrator-confirmed path and its persistence, quota, backup, retention, and cross-node visibility rules. Those details are not established universally in the public guidance. Use a small non-sensitive test input until they are confirmed.
4. Read the [Slurm section](../slurm/README.md) and its [example jobs](../slurm/README.md#example-jobs). They are public documentation in this repository, so you need no extra repository access. Copy them into your home on `hpc01` as described in [Before you start](../slurm/README.md#before-you-start):

       git clone https://github.com/hpc-isr/hpc-docs.git ~/hpc-docs
       cp -r ~/hpc-docs/docs/slurm/examples ~/slurm-examples

   Use the copy and the scripts as published; do not run scripts from an unreviewed source. If the `git clone` fails, ask your group administrator.
5. Use the small examples first: [example 1](../slurm/examples/01-hello/README.md) needs one CPU, 1 GB of memory and five minutes, and [example 4](../slurm/examples/04-mnist-gpu/README.md) adds one GPU (8 CPUs, 32 GB, a few minutes). These are example bounds, not a statement of cluster-wide limits or a guarantee that a job will start. The example pages say they have not all been run on the cluster yet, so timings and outputs are estimates.

## Run the starter cases

Submit each example from its own folder (`cd ~/slurm-examples/<example>`, then `sbatch ...`): the scripts find their files through `$SLURM_SUBMIT_DIR` and write their logs there. Check a job with `squeue --me` and read its log when it ends.

The examples keep their working data on the node's local `/scratch`: Python environments in `/scratch/$USER/envs/<example>`, datasets and model caches under `/scratch/$USER/`, and each job's working files in `/scratch/$USER/<jobid>`. `/scratch` is not shared between nodes, is not backed up, and files untouched for 30 days are deleted. Results are copied to `RESULTS_DIR` (by default `~/results/<example>`) when the job ends, even if it fails or hits its time limit. The first job of an example on a node also downloads and builds what it needs there, so it takes longer. See [Data and results](../slurm/README.md#data-and-results) and [Downloads and disk space](../slurm/README.md#downloads-and-disk-space) before running the larger examples, and [Storage](03-storage.md#scratch) for the quotas.

### 1. CPU smoke test (required)

[Example 1, Hello cluster](../slurm/examples/01-hello/README.md) ([`job.sbatch`](../slurm/examples/01-hello/job.sbatch)) uses one CPU, 1 GB and five minutes, downloads nothing, and prints the host, account, partition, QoS and `SLURM_*` variables.

    cd ~/slurm-examples/01-hello
    sbatch job.sbatch
    squeue --me

**Expected result:** the job reaches `COMPLETED` with exit code `0:0`, and `hello-<jobid>.out` shows the allocated host and the account and partition Slurm chose. Compare them with the values your administrator gave you. This is an acceptance expectation for the example, not a promise about queue wait time.

### 2. Optional single-GPU test

Run [example 4, Train a network on a GPU](../slurm/examples/04-mnist-gpu/README.md) ([`job.sbatch`](../slurm/examples/04-mnist-gpu/job.sbatch)) only after the administrator confirms your GPU access and current availability. It uses 8 CPUs, 32 GB and one L40S for a few minutes. The first run on a node creates a 7 GB PyTorch environment in `/scratch` (2 to 5 minutes) and caches MNIST there.

    cd ~/slurm-examples/04-mnist-gpu
    sbatch job.sbatch

It runs `../03-mnist-cpu/mnist.py`, so keep both folders. **Expected result:** `mnist-gpu-<jobid>.out` reports `device=cuda` and an L40S, reaches about 98% or more test accuracy after the first epoch, and the model is saved under `~/results/mnist/<jobid>/`. Running [example 3](../slurm/examples/03-mnist-cpu/README.md) (`sbatch job.sbatch` in `~/slurm-examples/03-mnist-cpu`) first gives a CPU baseline to compare epoch times.

### 3. Optional workflow examples

Run these only if the administrator approves them for your test window.

| Example | What it tests | Command |
|---|---|---|
| [2, Parameter sweep](../slurm/examples/02-kalman-sweep/README.md) | A 20-task job array plus an `afterok` collector job, on CPUs | `cd ~/slurm-examples/02-kalman-sweep && ./submit.sh` |
| [5, Jupyter on a GPU slice](../slurm/examples/05-jupyter-shard/README.md) | An interactive session on a shard of `hpc01`'s GPU, reached with an SSH tunnel | `cd ~/slurm-examples/05-jupyter-shard && sbatch job.sbatch` |

### 4. Optional large GPU examples

These need large downloads and a lot of `/scratch` space (about 25 to 30 GB for Isaac Lab and about 41 GB for vLLM on each node, against a 100 GiB soft quota), so check your quota first and run them only with administrator approval.

- **Isaac Lab (single GPU).** [Example 7](../slurm/examples/07-isaaclab-rl/README.md) trains the Unitree H1 humanoid with one GPU (about one hour). The first job on a node installs Isaac Lab in `/scratch` (15 to 30 minutes); to do that ahead of time, pin the jobs to one node:

      cd ~/slurm-examples/07-isaaclab-rl
      sbatch --nodelist=hpc02 setup.sbatch
      sbatch --nodelist=hpc02 train.sbatch

  `play.sbatch` and `gui.sbatch` stream the trained policy or the Isaac Sim editor to your laptop. For using Isaac Sim itself, see the [Isaac Sim guide](08-isaac-sim.md).
- **vLLM image captioning.** [Example 9](../slurm/examples/09-vlm-captions/README.md) runs Qwen3.8-27B on one GPU. The first job on a node builds the vLLM image and downloads about 31 GB of weights into `/scratch`; `pull.sbatch` does the image ahead of time.

      cd ~/slurm-examples/09-vlm-captions
      sbatch --nodelist=hpc02 pull.sbatch
      sbatch --nodelist=hpc02 job.sbatch

- **Multi-node PyTorch DDP.** [Example 10](../slurm/examples/10-ddp-multinode/README.md) trains ResNet-18 on CIFAR-10 across two nodes (one GPU each, about 10 minutes). Multi-node jobs have not been tested on this cluster, and a two-node job takes both GPUs of the `shared` partition. Ask an administrator first.

      cd ~/slurm-examples/10-ddp-multinode
      sbatch job.sbatch               # 2 nodes
      sbatch --nodes=1 job.sbatch     # 1 node, to compare

- **Isaac Lab on 4 GPUs.** [Example 11](../slurm/examples/11-isaaclab-4gpu/README.md) uses four nodes in the `scavenge` partition, where the job is killed as soon as any of its nodes is wanted by its owners. Ask an administrator first, and for a run that must finish, ask for a reservation (`--reservation=<name>`).

      cd ~/slurm-examples/11-isaaclab-4gpu
      sbatch job.sbatch

Examples [6](../slurm/examples/06-yolo-voc/README.md) (YOLO, hours long) and [8](../slurm/examples/08-gaussian-splatting/README.md) (3D scene from a video) are for real workloads rather than a first test.

## Monitor and troubleshoot

Use the [SLURM basics guide](04-slurm-basics.md) to inspect your own queued or running jobs and the [FAQ and troubleshooting guide](07-faq.md) for pending jobs, failures, missing logs, and GPU visibility. A pending job is not necessarily rejected. Do not repeatedly resubmit, increase resource requests to probe a limit, or submit deliberately unauthorized requests.

Keep output and error files in your copy of the examples (`~/slurm-examples`), not in the `~/hpc-docs` Git checkout. After a job ends, compare its state and exit code with its output and accounting record. If the result is unexpected, stop and ask your group SysAdmin rather than guessing a different account, QoS, partition, or GPU request.

## Report feedback

The [structured researcher test feedback form](https://github.com/hpc-isr/slurm-testing-cases/issues/new?template=researcher-test-feedback.yml) is available in the private test repository to users with repository access and permission to open issues. If you cannot access the form, use your group's approved SysAdmin support route in the [contact directory](../overview/contacts.md). Do not post passwords, tokens, private keys, raw logs, personal account details, or research data in a public issue. Share job identifiers or raw output only through an administrator-approved private support channel.

## Completion checklist

A starter run is complete when you have recorded the case name, date, your own job result, exit code, and whether the expected output appeared; you have checked any error output; and you have reported blockers through the structured form or approved support route. Do not treat one passing smoke job as proof of priority ranking, hard limit enforcement, multi-node GPU readiness, or production readiness.
