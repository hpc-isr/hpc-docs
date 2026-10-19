---
title: "SLURM basics"
parent: "User Guide"
nav_order: 4
---

# SLURM basics

[← User Guide](README.md) · [Home](../README.md)

## Before you submit

The shared cluster configuration and resource availability can change. The facts in this guide are dated observations from operator readbacks on 2026-10-18 and 2026-10-19, not a live check or a production guarantee. Ask your group SysAdmin to confirm your POSIX login, affiliated account, partition, allowed QoS, software environment, storage paths, and current resource limits before a larger run.

The staging readbacks described a Slurm cluster named hpc-isr, with a normal partition containing hpc01, hpc02, and hpc03. Each node was reported with 56 CPUs, approximately 443 GB configured memory, and one NVIDIA L40S GPU. These values are point-in-time configuration evidence; the scheduler is authoritative for current node state.

The five QoS names and their dated limits are listed in [Group-aware access and priority](../slurm/access-priority.md). New associations default to low in the recorded staging policy. A higher QoS is not available until an administrator confirms it is allowed for your association. QoS affects scheduling preference; it does not reserve resources or guarantee a start time.

## Check the current queue and nodes

    sinfo -N -h -o '%N|%T|%c|%m|%G'
    squeue -u "$USER" -o '%i|%a|%q|%T|%M|%R'

A pending job is not necessarily rejected. Read the pending reason, wait for the agreed observation period, and ask your group SysAdmin if the reason is unclear. Do not repeatedly resubmit the same job.

## Submit a short CPU job

For a first test, use the short, one-CPU example in [SLURM job examples](05-slurm-job-examples.md). Replace the account placeholder with the group account assigned to you. Keep the resource request within the QoS and account limits confirmed for your association.

    export SLURM_ACCOUNT="<account-assigned-by-your-admin>"
    mkdir -p "$HOME/slurm-logs"
    sbatch --parsable --partition=normal --account="$SLURM_ACCOUNT" --qos=low \
      --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=2G --time=00:05:00 \
      --output="$HOME/slurm-logs/cpu-%j.out" \
      --wrap='id -un; hostname; date -Is'

Use --qos=low only if your administrator has confirmed that it is allowed. If the site or your association uses a different approved default, follow that instruction rather than guessing.

## Requesting a GPU or an interactive session

A one-GPU smoke-test procedure and its prerequisites are in [SLURM job examples](05-slurm-job-examples.md). The dated staging readback showed that a one-GPU batch smoke job could see the allocated GPU. This did not validate a research framework, a training workload, or a multi-node GPU job.

A successful one-shot srun command was recorded, but a successful interactive PTY shell was not. Coordinate a short interactive-shell test with your group SysAdmin; exit promptly and verify that the allocation is released. Do not leave an allocation running while idle.

Use the account and QoS explicitly when instructed by the administrator. Do not request another user's account, a higher QoS, or more resources as a diagnostic probe.

## Monitor and cancel your own job

Use the job ID returned by sbatch:

    squeue --jobs="<job-id>" -o '%i|%u|%a|%q|%T|%M|%l|%R'
    scontrol show job "<job-id>"
    sacct -X -j "<job-id>" --noheader \
      --format=JobIDRaw,User,Account,Partition,QOS,State,ExitCode,Elapsed,AllocTRES

SlurmDBD accounting and a completed test job were observed on staging on 2026-10-19. This does not guarantee current service availability or retention. Compare the readback with your submission and output files. A completed state alone does not confirm that your application produced the expected result.

Before cancellation, verify that the job ID belongs to you:

    squeue --jobs="<job-id>" -o '%i|%u|%T|%R'
    scancel "<job-id>"

Cancel only the specific job you verified. Do not use broad cancellation commands.

## Limits and enforcement

The staging readback reported AccountingStorageEnforce=none. It also included a same-user low-QoS overlap despite a configured one-job-per-user limit. Therefore, the recorded configured limits must not be treated as proven enforcement or as a safety barrier. Do not increase a request because you expect a limit to reject it. The enforcement behavior and the staging concurrency anomaly remain operational issues for SysAdmins.

For precise request guidance and the dated QoS values, see [Group-aware access and priority](../slurm/access-priority.md). For examples and case-specific validation status, use the public examples on this site and follow any case-specific instructions from your SysAdmin.
