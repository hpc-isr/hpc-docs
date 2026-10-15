# SSH login

[← User Guide](README.md) · [Home](../README.md)

## Which machine?

| You want to… | Connect to |
|---|---|
| Run jobs on the shared GPU cluster | `hpc01.isr.tecnico.ulisboa.pt` (the login node) |
| Use your group's dedicated node | `hpc-<group>.isr.tecnico.ulisboa.pt` (see [Group nodes](06-group-nodes.md)) |

On the shared cluster you log in **only to `hpc01`** and reach `hpc02`/`hpc03` through SLURM ([SLURM basics](04-slurm-basics.md)). Don't SSH to `hpc02` or `hpc03`.

Your username and password are your Authentik (SSO) credentials.

## First login

```bash
ssh <username>@hpc01.isr.tecnico.ulisboa.pt
```

The first time, SSH asks you to confirm the host fingerprint. Type `yes`.

Too many failed password attempts will get your IP **temporarily banned** (fail2ban). If that happens, wait and try again, or ask an admin to unban you.

## Set up an SSH key (recommended)

Keys are safer than passwords and save typing. Do this **on your own laptop**, not on the cluster.

```bash
# Create a key (press Enter to accept the default path; choose a passphrase)
ssh-keygen -t ed25519 -C "<username>@isr-hpc"

# Copy the public key to the cluster (asks for your password one last time)
ssh-copy-id <username>@hpc01.isr.tecnico.ulisboa.pt

# Test: should log in without asking for your account password
ssh <username>@hpc01.isr.tecnico.ulisboa.pt
```

Because `/home` is shared across `hpc01`–`hpc03`, the key is also there inside your SLURM jobs.

Windows: run the same commands in PowerShell (OpenSSH is built in). If `ssh-copy-id` is missing, use:

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh <username>@hpc01.isr.tecnico.ulisboa.pt "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

## Short names with `~/.ssh/config`

On your laptop, add this to `~/.ssh/config`:

```sshconfig
Host isr-hpc
    HostName hpc01.isr.tecnico.ulisboa.pt
    User <username>
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60

Host isr-group
    HostName hpc-<group>.isr.tecnico.ulisboa.pt
    User <username>
    IdentityFile ~/.ssh/id_ed25519
```

Now `ssh isr-hpc` is enough.

## Copy files

```bash
# Laptop → cluster
scp data.tar.gz isr-hpc:~/
rsync -avP ./dataset/ isr-hpc:~/dataset/

# Cluster → laptop
scp isr-hpc:~/results/out.csv .
rsync -avP isr-hpc:~/results/ ./results/
```

`rsync -avP` resumes interrupted transfers and shows progress. Prefer it for anything large.

## Keep sessions alive with `tmux`

If your laptop disconnects, anything running in your shell dies. Run long interactive work inside `tmux`:

```bash
tmux new -s work      # start a session
# ... work ...
# detach: press Ctrl-b then d
tmux attach -t work   # reattach later, even from another computer
tmux ls               # list sessions
```

On the shared cluster, long work should go through SLURM instead (see [SLURM basics](04-slurm-basics.md)).

## VS Code Remote-SSH

1. Install the **Remote - SSH** extension.
2. `Ctrl+Shift+P` → **Remote-SSH: Connect to Host…** → pick `isr-hpc` from your `~/.ssh/config`.

> Please don't run heavy computations in a VS Code terminal on `hpc01` outside SLURM; it competes with other users' jobs.

## Port forwarding (e.g. Jupyter, TensorBoard)

```bash
# Your job runs on hpc02 and serves on port 8888: forward through hpc01
ssh -L 8888:hpc02:8888 isr-hpc
# then open http://localhost:8888 on your laptop
```

This only forwards a port through `hpc01`; you don't log in to `hpc02`. It works because the shared nodes accept all traffic from each other. For a group node, forward to `localhost` on that node directly (`ssh -L 8888:localhost:8888 <username>@hpc-<group>.isr.tecnico.ulisboa.pt`).
