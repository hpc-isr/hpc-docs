# Group nodes

[← User Guide](README.md) · [Home](../README.md)

Each research group has one dedicated VM (56 cores, 440 GB RAM, 1 × L40S) for its members. Each group's admin sets it up and decides the rules, so details differ from node to node.

| Group | Node |
|---|---|
| DSOR | `hpc-dsor.isr.tecnico.ulisboa.pt` |
| IRSg | `hpc-irsg.isr.tecnico.ulisboa.pt` |
| LaSEEB | `hpc-laseeb.isr-hpc.tp.vps.tecnico.ulisboa.pt` (private only) |
| SIPg | `hpc-sipg.isr-hpc.tp.vps.tecnico.ulisboa.pt` (private only) |
| VisLab | `hpc-vislab.isr-hpc.tp.vps.tecnico.ulisboa.pt` (private only) |

Nodes marked *private only* have no public name. Connect to them from inside IST's network, or from outside through [IST's VPN](https://si.tecnico.ulisboa.pt/en/servicos/redes-e-conetividade/vpn/).

## How group nodes differ from the shared cluster

- **No SLURM.** You run programs directly, so coordinate with your group (see below).
- **Different `/home`.** Your home directory on a group node is **not** the same as on `hpc01`–`hpc03`. Files you create on one are not visible on the other; copy them with `rsync` if needed.
- Same username and password as everywhere else, but you can only log in to **your own group's** node (rules are set by each group).

## Log in

```bash
ssh <username>@hpc-<group>.isr.tecnico.ulisboa.pt
```

## Group-specific guides

Each group's node has its own storage layout and services. What is specific to one node is documented in that group's guide:

- DSOR: hpc-dsor guide (not yet published)

## Sharing one GPU politely

There is no scheduler on a group node, so check before you start something big:

```bash
nvidia-smi                    # is the GPU busy? who's using it?
htop                          # CPU and memory use (q to quit)
free -h                       # memory
who                           # who's logged in
```

Run long jobs inside `tmux` so they survive a disconnect (see [SSH login](02-ssh-login.md#keep-sessions-alive-with-tmux)), and limit CPU threads so others can work:

```bash
export OMP_NUM_THREADS=16
nice -n 10 python train.py
```

Agree on usage rules within your group, and ask your group admin if the machine seems stuck.
