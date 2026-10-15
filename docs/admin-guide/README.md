# Admin Guide

[← Home](../README.md)

For the ISR HPC admin team. Pages are split into **configuration** (how things are set up and why) and **procedures** (step-by-step tasks with copy-paste commands).

## Common tasks

| Task | Page |
|---|---|
| Add a user, create a group, put a user in a group | [Users & groups](procedures/users-and-groups.md) |
| Configure LDAP logins on a node | [Configure LDAP/SSSD on a node](procedures/node-ldap-setup.md) |
| Bring up a new node | [New node checklist](procedures/new-node-checklist.md) |
| Drain a node, cancel jobs, change SLURM config | [SLURM operations](procedures/slurm-operations.md) |
| Check storage health, recover from a failed node | [MooseFS operations](procedures/moosefs-operations.md) |
| Unban an IP, open a port | [Security operations](procedures/security-operations.md) |
| Update Authentik, check backups | [Authentik maintenance](procedures/authentik-maintenance.md) |

## How the system fits together → [Overview](../overview/README.md)

- [Cluster at a glance](../overview/cluster.md): hardware, nodes, resource split
- [Network diagram](../overview/network.md)
- [Inside a node](../overview/node-anatomy.md): disks, mounts, services on shared and group nodes
- [Who's who](../overview/contacts.md): group admins

## Procedures: day-to-day tasks

| Page | Covers |
|---|---|
| [Users & groups](procedures/users-and-groups.md) | Invite/add a user, create a group, assign users to groups, reset password, disable a user, local groups (docker), sudo for group admins |
| [Configure LDAP/SSSD on a node](procedures/node-ldap-setup.md) | Make a node accept Authentik logins; restrict a node to one group |
| [New node checklist](procedures/new-node-checklist.md) | Everything to do on a freshly provisioned VM, in order |
| [SLURM operations](procedures/slurm-operations.md) | Drain/resume nodes, manage jobs, change config, add a node, limits |
| [MooseFS operations](procedures/moosefs-operations.md) | Health checks, trash, quotas, add/remove disks, master recovery |
| [Security operations](procedures/security-operations.md) | fail2ban status/unban, firewall ports |
| [Authentik maintenance](procedures/authentik-maintenance.md) | Upgrades, database backups, certificates |

## Configuration: how it's built

| Page | Component |
|---|---|
| [Base node](config/base-node.md) | Ubuntu, `ubuntu` user, `/etc/hosts`, disks, LVM scratch, bind mounts |
| [Group nodes](config/group-nodes.md) | Per-group VMs: what all of them share and how they differ from the shared nodes |
| [MooseFS](config/storage-moosefs.md) | Shared filesystem: master, metaloggers, chunkservers, clients |
| [Docker](config/docker.md) | Docker CE install and conventions for services in `/srv` |
| [Traefik](config/traefik.md) | Reverse proxy and TLS certificates |
| [Authentik](config/identity-authentik.md) | IdP, groups, flows, invitations, LDAP provider |
| [SSSD](config/ldap-sssd.md) | Reference SSSD configuration for nodes |
| [SLURM](config/slurm.md) | Scheduler install, `slurm.conf`, cgroups, GPUs, accounting |
| [Security](config/security.md) | firewalld and fail2ban |
| [JupyterHub](config/apps-jupyterhub.md) | Reference configuration for admins to run on their own machines (not for use on hpc01) |

## Group-specific guides

Each group node's own setup is documented separately: hpc-dsor guide (not yet published).

## Reference

- [Hosts and IPs](reference/hosts.md)
- [Ports](reference/ports.md)
- [Open questions and review notes](reference/open-questions.md): every TODO in one list, plus configuration issues worth a second look.
- [Info-gathering commands](reference/info-gathering.md): read-only commands that collect the missing facts.

## Admin conventions

- Log in as `ubuntu` and use `sudo`. Avoid enabling root SSH; if you must (e.g. SLURM rollout), remove the key afterwards.
- Docker services live in `/srv/<app>/` with a `docker-compose.yml`, secrets only in `.env` (mode 600).
- Changes to files that must be identical on all shared nodes (`slurm.conf`, `munge.key`) are made on `hpc01` and copied out.
- Record every change you make in these docs.
- `ubuntu` is the standard local admin account on every node.
- **`TODO`** boxes mark facts not yet confirmed. Every TODO is also listed in [Open questions](reference/open-questions.md) so they can be filled in from one place.
- Hostnames: `<name>.isr-hpc.tp.vps.tecnico.ulisboa.pt` is the **private** network, `<name>.isr.tecnico.ulisboa.pt` is the **public** one. See [Hosts](reference/hosts.md).
