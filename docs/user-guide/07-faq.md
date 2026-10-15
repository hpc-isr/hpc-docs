---
title: "FAQ & troubleshooting"
parent: "User Guide"
nav_order: 8
---

# FAQ & troubleshooting

[← User Guide](README.md) · [Home](../README.md)

### `Permission denied (publickey,password)` when logging in

- Check the username: it's your Authentik username, case-sensitive.
- Check the password at <https://sso.isr.tecnico.ulisboa.pt>. If the web login works but SSH doesn't, ask your group admin.
- On a group node: you can only log in to your own group's node.

### `Connection refused` or SSH hangs

Your IP may be temporarily banned after repeated failed logins. Wait (bans expire) or ask an admin to unban it, giving them your public IP (`curl ifconfig.me`).

### I changed my password and the old one still works / new one doesn't

Nodes cache credentials. Give it a few minutes. If it persists, ask an admin.

### My job is stuck in `PD` (pending)

See [Why is my job pending?](04-slurm-basics.md#why-is-my-job-pending). Usually all three GPUs are in use.

### My job died with `OUT_OF_MEMORY`

Increase `--mem`. To see how much it really needs, run a short test in an interactive job and watch `top` or `free -h`, or add `/usr/bin/time -v` before your command in the script (look for *Maximum resident set size*).

### My job died with `TIMEOUT`

Increase `--time`, or make your program save checkpoints and resume.

### `CUDA error: no CUDA-capable device` inside a job

You didn't request a GPU. Add `#SBATCH --gres=gpu:1`.

### `No space left on device`

```bash
df -h /home /scratch /tmp
du -sh ~/* | sort -h | tail
```

Clean up caches (`~/.cache/pip`, `~/.cache/huggingface`, old checkpoints). If `/` (root) is full, tell an admin; don't write there.

### I deleted a file by mistake

Ask an admin quickly. MooseFS keeps deleted files in a trash for a limited time (24 h by default).

### Can I use Docker?

Not directly: membership of the `docker` group is equivalent to root. Use **Apptainer** instead: it is installed for all users and runs containers as you, without root. Shared images are in `/opt/containers` ([Storage](03-storage.md#shared-software-in-opt)), and Docker images can be converted, e.g. `apptainer pull docker://ubuntu:24.04`. Example: [Isaac Sim](08-isaac-sim.md).

### Can I install software with `sudo apt`?

No. Install in your home (venv, conda, uv), or ask your group admin to install it in `/opt` for everyone.
