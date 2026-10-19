---
title: "User Guide"
nav_order: 2
has_children: true
has_toc: false
---

# User Guide

[← Home](../README.md)

Everything a researcher needs to log in and run work on the ISR HPC nodes. Read in order the first time.

1. [Getting an account](01-getting-an-account.md): invitation, assigned login, password recovery.
2. [SSH login](02-ssh-login.md): connecting, SSH keys, `~/.ssh/config`, copying files, VS Code.
3. [Storage](03-storage.md): confirm approved persistent and temporary storage paths.
4. [SLURM basics](04-slurm-basics.md): see the cluster, start interactive and batch jobs, request a GPU.
5. [SLURM job script examples](05-slurm-job-examples.md): copy-paste scripts for CPU, GPU, arrays and pipelines.
6. [Group nodes](06-group-nodes.md): using your group's dedicated machine.
7. [FAQ & troubleshooting](07-faq.md)
8. [Isaac Sim](08-isaac-sim.md): check the approved access and connection instructions.

## Quick start

1. Confirm your exact HPC login and the authentication method with your group administrator, then follow [SSH login](02-ssh-login.md).
2. Ask the administrator to confirm your account, partition, allowed QoS, resource limits, storage paths, and software setup.
3. Start with the short [CPU smoke job](05-slurm-job-examples.md#1-short-cpu-smoke-job). The GPU and interactive procedures have separate prerequisites and validation limits.
4. Monitor and report the job using [SLURM basics](04-slurm-basics.md) and [FAQ & troubleshooting](07-faq.md).

Need help? See [Who's who](../overview/contacts.md).
