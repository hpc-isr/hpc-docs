---
title: "Home"
nav_order: 1
---

# ISR HPC Knowledge Base

Documentation for the HPC infrastructure of the **Institute for Systems and Robotics (ISR)**: eight Ubuntu 24.04 VMs, each with a 56-core Xeon 6730P, 440 GB RAM and one NVIDIA L40S GPU.

- **5 group nodes**, one per research group, for that group's exclusive use.
- **3 shared nodes** (`hpc01`–`hpc03`) that form a SLURM cluster open to everyone.

## Using the cluster → [User Guide](user-guide/README.md)

| Task | Page |
|---|---|
| Get an account, reset my password | [Getting an account](user-guide/01-getting-an-account.md) |
| Log in with SSH, set up keys, copy files | [SSH login](user-guide/02-ssh-login.md) |
| Know where to keep my data | [Storage](user-guide/03-storage.md) |
| Run jobs on the shared cluster | [SLURM basics](user-guide/04-slurm-basics.md) · [Job script examples](user-guide/05-slurm-job-examples.md) |
| Use my group's dedicated node | [Group nodes](user-guide/06-group-nodes.md) |
| Run NVIDIA Isaac Sim and stream it to my laptop | [Isaac Sim](user-guide/08-isaac-sim.md) |
| Something isn't working | [FAQ & troubleshooting](user-guide/07-faq.md) |

## Conventions used in these pages

- Commands are run as your normal user unless they start with `sudo`, which needs admin rights.
- Placeholders look like `<username>` or `<group>`. Replace them, including the angle brackets.
- Hostnames: `<name>.isr.tecnico.ulisboa.pt` is the **public** name, `<name>.isr-hpc.tp.vps.tecnico.ulisboa.pt` the **private** one, reachable from IST's network or VPN.

Administrators will find configuration details and step-by-step procedures in the [Admin Guide](admin-guide/README.md). Node-specific documentation for group nodes is kept separately, e.g. the hpc-dsor guide (not yet published).
