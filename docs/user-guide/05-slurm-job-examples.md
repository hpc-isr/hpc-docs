---
title: "SLURM job examples"
parent: "User Guide"
nav_order: 5
---

# SLURM job examples

[← User Guide](README.md) · [Home](../README.md)

## Turnkey SLURM examples

For complete workloads (training on CPUs and GPUs, Isaac Lab, YOLO, vision-language models, multi-node), see the [Slurm example jobs](../slurm/README.md). Each one comes with its scripts and an explanation, and is a good first experiment on the cluster.

## Small starting examples

The short examples below are copy-paste starting points. Your Slurm account is your research group (`dsor`, `irsg`, `laseeb`, `sipg` or `vislab`). Check the account, allowed QoS values, and default with:

    sacctmgr -nP show assoc where cluster=hpc-isr user="$USER" format=Account,QOS,DefaultQOS

Use the account and QoS from the same association row. In the shell where you submit these examples, enter those values (choose the row's `DefaultQOS` if you want the default):

    read -r -p 'Slurm account from your association: ' SLURM_ACCOUNT
    read -r -p 'Enter one QoS from that row (or its DefaultQOS): ' SLURM_QOS
    export SLURM_ACCOUNT SLURM_QOS
    : "${SLURM_ACCOUNT:?Set the account from your association}"
    : "${SLURM_QOS:?Set an allowed QoS from the same row}"

Create the log directory before submitting:

    mkdir -p "$HOME/slurm-logs"

The examples use the selected `SLURM_QOS`; replace it only with another QoS shown for that account. You normally do not need `--partition`: Slurm places the job according to your group, tier and available resources (see [SLURM basics](04-slurm-basics.md#where-jobs-run)).

## 1. Short CPU smoke job

    sbatch --account="$SLURM_ACCOUNT" --qos="$SLURM_QOS" \
      --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=2G --time=00:05:00 \
      --output="$HOME/slurm-logs/cpu-%j.out" \
      --error="$HOME/slurm-logs/cpu-%j.err" \
      --wrap='id -un; hostname; date -Is; echo "CPU smoke test passed."'

Expected: Slurm returns a job ID. After the job completes, inspect the output and accounting record using the commands in [SLURM basics](04-slurm-basics.md). A pending job is not a failure; do not resubmit it repeatedly.

## 2. CPU program with a user-owned environment

This script assumes `/scratch/$USER/envs/my-project` already exists on the node Slurm selects; it does not create the environment or install packages. Because `/scratch` is node-local and placement can vary, prepare it on each node your jobs may use, or follow the per-node setup and reuse pattern in the [complete Slurm examples](../slurm/README.md#before-you-start).

    cd "$HOME/slurm-logs"
    cat > "$HOME/slurm-logs/cpu-program.sbatch" <<'SBATCH'
    #!/bin/bash
    #SBATCH --job-name=cpu-program
    #SBATCH --nodes=1
    #SBATCH --ntasks=1
    #SBATCH --cpus-per-task=1
    #SBATCH --mem=2G
    #SBATCH --time=00:05:00
    #SBATCH --output=cpu-program-%j.out
    #SBATCH --error=cpu-program-%j.err
    source "/scratch/$USER/envs/my-project/bin/activate"
    python "$HOME/code/my-project/run.py" \
      --input "$HOME/data/input" \
      --output "$HOME/results/$SLURM_JOB_ID"
    SBATCH

    sbatch --account="$SLURM_ACCOUNT" --qos="$SLURM_QOS" \
      "$HOME/slurm-logs/cpu-program.sbatch"

The example changes to the existing log directory before submission so the relative `#SBATCH` output paths resolve there. Ensure the output directory exists and the job can write to it.

## 3. One-GPU visibility smoke job

This checks the GPU that Slurm allocated to the job. It doesn't validate PyTorch, CUDA compatibility for a particular application, or multi-node communication.

    sbatch --account="$SLURM_ACCOUNT" --qos="$SLURM_QOS" \
      --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=2G --gres=gpu:1 \
      --time=00:05:00 \
      --output="$HOME/slurm-logs/gpu-%j.out" \
      --error="$HOME/slurm-logs/gpu-%j.err" \
      --wrap='hostname; printf "CUDA_VISIBLE_DEVICES=%s\n" "$CUDA_VISIBLE_DEVICES"; nvidia-smi --query-gpu=index,name --format=csv,noheader'

Do not use this smoke test to benchmark or load the GPU. Slurm assigns the device; do not select a physical GPU by index. Inside the job, use the devices exposed through `CUDA_VISIBLE_DEVICES`. The index shown inside the job may not be the node's physical index.

For multi-GPU work, the program must support the required parallel method. See [two-node PyTorch DDP](../slurm/examples/10-ddp-multinode/README.md) and [four-GPU Isaac Lab](../slurm/examples/11-isaaclab-4gpu/README.md). Follow each example's prerequisites and request only resources allowed by your association. For a small GPU slice, see [interactive GPU work](04-slurm-basics.md#interactive-work).

## 4. Small job array

This example creates two short tasks and asks Slurm to run at most one array element at a time. That array throttle does not prove that other per-user limits are enforced.

    sbatch --account="$SLURM_ACCOUNT" --qos="$SLURM_QOS" \
      --array=0-1%1 --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=1G \
      --time=00:02:00 \
      --output="$HOME/slurm-logs/array-%A_%a.out" \
      --wrap='echo "array task $SLURM_ARRAY_TASK_ID on $(hostname)"'

Expected: two task records and distinct output files. Do not scale the array without confirming current site limits and capacity.

## 5. Job dependency

The second job becomes eligible after the first succeeds. This does not guarantee when either job starts.

    producer=$(sbatch --parsable --account="$SLURM_ACCOUNT" --qos="$SLURM_QOS" \
      --time=00:02:00 --output="$HOME/slurm-logs/producer-%j.out" \
      --wrap='echo producer; sleep 2')
    printf 'producer job: %s\n' "$producer"

    consumer=$(sbatch --parsable --account="$SLURM_ACCOUNT" --qos="$SLURM_QOS" \
      --dependency="afterok:$producer" --time=00:02:00 \
      --output="$HOME/slurm-logs/consumer-%j.out" --wrap='echo consumer')
    printf 'consumer job: %s\n' "$consumer"

Inspect both jobs with squeue and sacct. Cancel only an exact job ID that you have verified belongs to you.

## 6. Interactive shell procedure

Use a short allocation and exit promptly. Interactive sessions can't be requeued, so if one is preempted it is killed:

    srun --account="$SLURM_ACCOUNT" --qos="$SLURM_QOS" \
      --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=2G --time=00:05:00 \
      --pty bash -l

Inside the allocated shell, run `hostname`, then type `exit` to return to your login shell and release the allocation. If you started `srun --pty bash -l` inside an `salloc` shell, the second prompt is the compute shell: type `exit` once to return to the allocation shell, then again to release it. If the prompt does not accept input, stop and ask the administrator; do not leave the allocation running or repeatedly resubmit.


If your SSH connection drops, this guide does not provide a session-recovery command. Use a batch job for work that must continue without an interactive terminal. Contact your group SysAdmin if an allocation may still be active.

## 7. Preemptible job that checkpoints

Jobs in `scavenge`, and low-tier jobs on a group node, can be preempted (not during their first 15 minutes): they get SIGTERM, 180 seconds, and are then requeued. This script saves its state on SIGTERM and skips finished work when it starts again. Replace the program with your own; it must be able to resume from its checkpoint.

    cat > "$HOME/slurm-logs/resumable.sbatch" <<'SBATCH'
    #!/bin/bash
    #SBATCH --job-name=resumable
    #SBATCH --gres=gpu:1
    #SBATCH --cpus-per-task=4
    #SBATCH --mem=32G
    #SBATCH --time=1-00:00:00
    #SBATCH --requeue
    #SBATCH --open-mode=append
    #SBATCH --output=resumable-%j.out

    # Checkpoints in your home, not /scratch: a requeued job can restart on another
    # node, which wouldn't see this node's /scratch.
    work="$HOME/runs/my-run"
    mkdir -p "$work"
    [ -e "$work/done" ] && { echo "already finished"; exit 0; }

    # srun forwards SIGTERM to the program, which should save a checkpoint
    # in $work and exit; Slurm then requeues the job.
    srun python "$HOME/code/my-project/train.py" --checkpoint-dir "$work" --resume
    touch "$work/done"
    SBATCH

    cd "$HOME/slurm-logs" && sbatch --account="$SLURM_ACCOUNT" --qos="$SLURM_QOS" resumable.sbatch

Check with `sacct -j <job-id>`: a preempted job shows `PREEMPTED` or `REQUEUED`, then runs again under the same job ID.

## Scratch, shared files and containers

Use `/scratch/$USER/$SLURM_JOB_ID` for temporary work on the allocated node. `/scratch` is node-local and is not backed up; copy results you need to keep to your home or approved group storage before the job ends. See [Storage](03-storage.md) for shared paths, quotas and cleanup rules. Do not use Docker on the cluster. Follow the documented [Apptainer guidance](09-apptainer.md) or ask your group SysAdmin which software environment is supported for your workload.

## Monitor and get help

    squeue -u "$USER" -o '%i|%a|%q|%T|%M|%R'
    sacct -X -j "<job-id>" --noheader \
      --format=JobIDRaw,User,Account,Partition,QOS,State,ExitCode,Elapsed,AllocTRES

For a problem report, include the job ID, the command or example used, approximate submit time, observed state or sanitized error, and what output you expected. Send this through the support route for your group from [Who's who](../overview/contacts.md). Do not include passwords, tokens, private keys, private research data, or raw logs in a public issue or message. Share only a short sanitized error excerpt. See [FAQ and troubleshooting](07-faq.md).

## Review recorded usage

Slurm can show recorded job usage, but the accounting output is not a remaining-credit balance. To inspect your recent jobs:

    sacct -X -u "$USER" -S "$(date -d '30 days ago' +%F)" \
      --format=JobIDRaw,Account,QOS,State,Elapsed,AllocCPUS,AllocTRES

If your group uses a separate credit budget, ask your group SysAdmin for its approved balance report and conversion rule.

## Further examples

The [complete Slurm example catalog](../slurm/README.md) includes multi-node workloads. Follow each example's prerequisites and use only resources allowed by your association.
