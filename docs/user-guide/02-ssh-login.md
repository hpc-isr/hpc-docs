---
title: "SSH login"
parent: "User Guide"
nav_order: 2
---

# SSH login

[← User Guide](README.md) · [Home](../README.md)

## Which machine?

| You want to… | Connect to |
|---|---|
| Run jobs on the shared GPU cluster | `hpc01.isr.tecnico.ulisboa.pt` (login node) |
| Use your group's dedicated node | `hpc-<group>.isr.tecnico.ulisboa.pt` (see [Group nodes](06-group-nodes.md)) |

On the shared cluster, log in to the documented login node and submit work through SLURM. Do not use compute nodes as interactive login destinations.

Your institutional username and password are used for account authentication.

## First login and host identity

```bash
ssh <username>@hpc01.isr.tecnico.ulisboa.pt
```

Before accepting a first-time or changed host-key prompt, compare the presented fingerprint with the current value distributed through an approved administrator channel. If you cannot verify it, stop and contact the administrators; do not accept the prompt just to continue. A changed fingerprint can have legitimate causes, but must be confirmed before connecting.

Repeated failed attempts may trigger temporary protection. If login is blocked, wait or contact the administrators rather than repeatedly retrying.

## Set up an SSH key (recommended)

Keys reduce password entry. Create them on your own device and protect the private key with a passphrase. Share only the public key with the cluster administrators using the approved enrollment process. Never copy a private key to a cluster host or repository.

```bash
ssh-keygen -t ed25519 -C "<username>@isr-hpc"
```

## Short names with `~/.ssh/config`

On your device, you may define a short alias after confirming the official login hostname:

```sshconfig
Host isr-hpc
    HostName hpc01.isr.tecnico.ulisboa.pt
    User <username>
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
```

## Copy files

Use `scp` or `rsync` to transfer data to and from your home directory. For large transfers, `rsync` can resume interrupted transfers. Keep data within the applicable institutional data-handling rules.

## Limits outside Slurm

Compute work runs inside Slurm jobs. Outside a job:

- **On `hpc01`**, all of your SSH and VS Code sessions together get at most **4 CPU cores and 16 GiB of memory**, and no GPU. A session that goes above 16 GiB has its largest process killed. You can't use `crontab` or `at`. For recurring work, use Slurm (`sbatch --begin=...`, or a job that resubmits itself).
- **On `hpc02` and `hpc03`** you can only SSH in while you have a job running there. Your session then joins the job and sees only its CPUs, memory and GPUs.
- **On your group's node**, once it has joined the cluster, you log in as before, but the GPU only works inside a job. See [Group nodes](06-group-nodes.md).

Editing, compiling small programs, `git` and submitting jobs are fine on `hpc01`. For anything heavier, start a job with `salloc` or `srun` (see [SLURM basics](04-slurm-basics.md#interactive-work)). Use `tmux` to keep a session running after you disconnect.
