# User Guide

[← Home](../README.md)

Everything a researcher needs to log in and run work on the ISR HPC nodes. Read in order the first time.

1. [Getting an account](01-getting-an-account.md): invitation, choosing a username, password recovery.
2. [SSH login](02-ssh-login.md): connecting, SSH keys, `~/.ssh/config`, copying files, VS Code.
3. [Storage](03-storage.md): `/home` vs `/scratch`, what is shared, what is backed up.
4. [SLURM basics](04-slurm-basics.md): see the cluster, start interactive and batch jobs, request a GPU.
5. [SLURM job script examples](05-slurm-job-examples.md): copy-paste scripts for CPU, GPU, arrays and pipelines.
6. [Group nodes](06-group-nodes.md): using your group's dedicated machine.
7. [FAQ & troubleshooting](07-faq.md)
8. [Isaac Sim](08-isaac-sim.md): run NVIDIA Isaac Sim with Apptainer and stream it to your laptop.

## Quick start

```bash
# 1. Log in to the shared cluster (use your Authentik username and password)
ssh <username>@hpc01.isr.tecnico.ulisboa.pt

# 2. See what's available
sinfo

# 3. Get an interactive shell with 1 GPU, 8 cores and 32 GB RAM for 1 hour
srun --gres=gpu:1 --cpus-per-task=8 --mem=32G --time=01:00:00 --pty bash

# 4. Or submit a batch script
sbatch myjob.sh
squeue -u $USER
```

Need help? See [Who's who](../overview/contacts.md).
