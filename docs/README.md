---
title: "Home"
nav_order: 1
---

# ISR HPC Knowledge Base

User-facing documentation for the HPC services of the **Institute for Systems and Robotics (ISR)**. Service availability and resource capacity are reported by the live scheduler and may change; this site is not a host inventory or deployment record.

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
- Host-specific internal names and address mappings are maintained in restricted operator inventory and are not published here.

The [Admin Guide](admin-guide/README.md) explains the public/private documentation boundary. Host-level configuration, inventories, and administrator procedures are kept in access-controlled operator sources.
