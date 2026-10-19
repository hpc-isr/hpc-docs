---
title: "User Guide"
nav_order: 2
has_children: true
has_toc: false
---

# User Guide

[← Home](../README.md)

Everything a researcher needs to log in and run work on the ISR HPC nodes. Read in order the first time.

1. [Researcher test journey](00-researcher-test-journey.md): prerequisites, bounded CPU/GPU checks, monitoring, and feedback.
2. [Getting an account](01-getting-an-account.md): invitation, assigned login, password recovery.
3. [SSH login](02-ssh-login.md): connecting, SSH keys, `~/.ssh/config`, copying files, VS Code.
4. [Storage](03-storage.md): confirm approved persistent and temporary storage paths.
5. [SLURM basics](04-slurm-basics.md): see the cluster, start interactive and batch jobs, request a GPU.
6. [SLURM job script examples](05-slurm-job-examples.md): copy-paste scripts for CPU, GPU, arrays and pipelines.
7. [Group nodes](06-group-nodes.md): using your group's dedicated machine.
8. [FAQ & troubleshooting](07-faq.md)
9. [Isaac Sim](08-isaac-sim.md): check the approved access and connection instructions.

## Quick start

For the controlled researcher test path, begin with the [Researcher Test Journey](00-researcher-test-journey.md).

1. Confirm your exact HPC login and the authentication method with your group administrator, then follow [SSH login](02-ssh-login.md).
2. Ask the administrator to confirm your account, partition, allowed QoS, resource limits, storage paths, and software setup.
3. Start with the short [CPU smoke job](05-slurm-job-examples.md#1-short-cpu-smoke-job). The GPU and interactive procedures have separate prerequisites and validation limits.
4. Monitor and report the job using [SLURM basics](04-slurm-basics.md) and [FAQ & troubleshooting](07-faq.md).

Need help? See [Who's who](../overview/contacts.md).
