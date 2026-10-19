---
title: "SLURM job examples"
parent: "User Guide"
nav_order: 5
---

# SLURM job examples

[← User Guide](README.md) · [Home](../README.md)

These are small starting examples, not a promise that a particular account, QoS, software package, or filesystem is available. Ask your group SysAdmin for your assigned account and currently permitted QoS. Keep the examples short and use paths confirmed for your account. Create the log directory before submitting:

    export SLURM_ACCOUNT="<account-assigned-by-your-admin>"
    mkdir -p "$HOME/slurm-logs"

Use --qos=low only after confirming that it is permitted for your association. Request a higher tier only after the administrator confirms the change is active; see [Group-aware access and priority](../slurm/access-priority.md).

## 1. Short CPU smoke job

    sbatch --account="$SLURM_ACCOUNT" --partition=normal --qos=low \
      --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=2G --time=00:05:00 \
      --output="$HOME/slurm-logs/cpu-%j.out" \
      --error="$HOME/slurm-logs/cpu-%j.err" \
      --wrap='id -un; hostname; date -Is; echo "CPU smoke test passed."'

Expected: Slurm returns a job ID. After the job completes, inspect the output and accounting record using the commands in [SLURM basics](04-slurm-basics.md). A pending job is not a failure; do not resubmit it repeatedly.

## 2. CPU program with a user-owned environment

The path and software setup below are examples. Confirm that the environment path is visible from compute nodes and that the required packages can be installed under site policy. Do not assume that another person's virtual environment exists.

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

    source "$HOME/envs/my-project/bin/activate"
    python "$HOME/code/my-project/run.py" \
      --input "/path/confirmed/by/your/admin/input" \
      --output "/path/confirmed/by/your/admin/results/$SLURM_JOB_ID"
    SBATCH

    sbatch --account="$SLURM_ACCOUNT" --partition=normal --qos=low \
      "$HOME/slurm-logs/cpu-program.sbatch"

Replace the environment, script, and data paths with locations that your administrator has confirmed. The example changes to the existing log directory before submission so the relative `#SBATCH` output paths resolve there. Ensure the output directory exists and the job can write to it.

## 3. One-GPU visibility smoke job

The dated 2026-10-19 staging record reports that a one-GPU smoke job completed and saw an NVIDIA L40S. It does not validate PyTorch, CUDA compatibility for a particular application, or multi-node communication.

    sbatch --account="$SLURM_ACCOUNT" --partition=normal --qos=low \
      --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=2G --gres=gpu:1 \
      --time=00:05:00 \
      --output="$HOME/slurm-logs/gpu-%j.out" \
      --error="$HOME/slurm-logs/gpu-%j.err" \
      --wrap='hostname; printf "CUDA_VISIBLE_DEVICES=%s\n" "$CUDA_VISIBLE_DEVICES"; nvidia-smi --query-gpu=index,name --format=csv,noheader'

A higher QoS or larger GPU allocation must be confirmed for your association before use. Do not use this smoke test to benchmark performance or load the GPU.

## 4. Small job array

This example creates two short tasks and asks Slurm to run at most one array element at a time. That array throttle does not prove that other per-user limits are enforced.

    sbatch --account="$SLURM_ACCOUNT" --partition=normal --qos=low \
      --array=0-1%1 --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=1G \
      --time=00:02:00 \
      --output="$HOME/slurm-logs/array-%A_%a.out" \
      --wrap='echo "array task $SLURM_ARRAY_TASK_ID on $(hostname)"'

Expected: two task records and distinct output files. Do not scale the array without confirming current site limits and capacity.

## 5. Job dependency

The second job becomes eligible after the first succeeds. This does not guarantee when either job starts.

    producer=$(sbatch --parsable --account="$SLURM_ACCOUNT" --partition=normal --qos=low \
      --time=00:02:00 --output="$HOME/slurm-logs/producer-%j.out" \
      --wrap='echo producer; sleep 2')
    printf 'producer job: %s\n' "$producer"

    consumer=$(sbatch --parsable --account="$SLURM_ACCOUNT" --partition=normal --qos=low \
      --dependency="afterok:$producer" --time=00:02:00 \
      --output="$HOME/slurm-logs/consumer-%j.out" --wrap='echo consumer')
    printf 'consumer job: %s\n' "$consumer"

Inspect both jobs with squeue and sacct. Cancel only an exact job ID that you have verified belongs to you.

## 6. Interactive shell procedure

A successful one-shot srun command was observed on staging; successful interactive PTY input and shell exit were not. Coordinate this procedure with your group SysAdmin before trying it. Use a short allocation and exit promptly:

    srun --partition=normal --account="$SLURM_ACCOUNT" --qos=low \
      --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=2G --time=00:05:00 \
      --pty bash -l

Inside the allocated shell, run hostname, then type exit. If the prompt does not accept input, stop and ask the administrator; do not leave the allocation running or repeatedly resubmit.

## Monitor and get help

    squeue -u "$USER" -o '%i|%a|%q|%T|%M|%R'
    sacct -X -j "<job-id>" --noheader \
      --format=JobIDRaw,User,Account,Partition,QOS,State,ExitCode,Elapsed,AllocTRES

For a problem report, include the job ID, the command or example used, approximate submit time, observed state or sanitized error, and what output you expected. Send this through the support route for your group from [Who's who](../overview/contacts.md). Do not include passwords, tokens, private keys, private research data, or unredacted logs in a public issue or message. See [FAQ and troubleshooting](07-faq.md).

## Not covered by these examples

The multi-node GPU/NCCL procedure and successful interactive PTY acceptance have not been demonstrated in the recorded staging evidence. Do not submit the multi-node case without specific SysAdmin coordination and confirmation of software, network, account, QoS, and test-window readiness.
