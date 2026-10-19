---
title: "Storage"
parent: "User Guide"
nav_order: 3
---

# Storage

[← User Guide](README.md) · [Home](../README.md)

## Confirm your storage paths

Storage capacity, quotas, sharing between nodes, backup coverage, and cleanup rules can change. The public evidence available for this guide does not establish current values for those items. Before placing research data, ask your group SysAdmin which persistent path is approved for your account and workload, whether it is visible on every node your job may use, and what backup and retention policy applies.

Do not treat scratch space, a home directory, replication, or a Git repository as a backup unless the responsible administrator confirms that coverage. Keep a recoverable copy of important data in the location approved for your research.

You can inspect the filesystem that contains a path you already know:

    df -h "$HOME"
    du -sh "$HOME"

Use df only for paths that your administrator has confirmed. Do not infer that a mount is shared because it has the same path on two nodes.

## Temporary working files

Use node-local temporary storage only when an administrator confirms its path and cleanup policy. Such files may not be shared with another allocated node and may disappear after a job. Copy required inputs into the approved working location and copy results back to approved persistent storage before the job exits.

Use explicit paths in job scripts. Do not assume that a job starts in your project directory or that your home directory is mounted on every compute node:

    INPUT_DIR="/path/confirmed/by/your/admin/input"
    OUTPUT_DIR="/path/confirmed/by/your/admin/results/$SLURM_JOB_ID"
    mkdir -p "$OUTPUT_DIR"
    python3 "$HOME/code/analyze.py" --input "$INPUT_DIR" --output "$OUTPUT_DIR"

Replace the example paths with locations confirmed for your account. Do not place credentials, private keys, tokens, or sensitive research data in a job script or repository.

## Software environments

Create a user-owned environment only in a path confirmed to be available to your jobs. For example, if Python virtual environments are supported on that filesystem:

    python3 -m venv "$HOME/envs/my-project"
    source "$HOME/envs/my-project/bin/activate"
    python -m pip install -r "$HOME/code/my-project/requirements.txt"

Package installation may require network access and may be subject to site policy. Do not assume that a particular Python package, CUDA build, module, container runtime, shared image, or another user's environment is available. Ask your group SysAdmin for the supported setup method. See [SLURM job examples](05-slurm-job-examples.md) for how to activate your own environment inside a job.
