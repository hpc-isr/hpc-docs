---
title: "Open questions"
parent: "Reference"
grand_parent: "Admin Guide"
nav_order: 3
---

# Open questions and review notes

[← Admin Guide](../README.md) · [Home](../../README.md)

Two lists: **open questions** are facts the docs still need (each also appears as a TODO on its page); **review notes** are things in the current configuration that look worth a second look. Most remaining questions are decisions still to be made.

## Open questions

### Group nodes
- [ ] Storage, services and access rules of `hpc-irsg`, `hpc-laseeb`, `hpc-sipg`, `hpc-vislab` (each group's admin can run the [group-node block](info-gathering.md#3-on-a-group-node)). → [group nodes](../config/group-nodes.md)
- [ ] Apply the [suggested per-node SSSD access rules](../config/ldap-sssd.md#suggested-isrconf-changes-per-node) and per-group sudo groups (each group decides for its node).

### Storage
- [ ] Quota policy for `/home`. → [MooseFS ops](../procedures/moosefs-operations.md#quotas)
- [ ] `/scratch` cleanup policy. → [storage](../../user-guide/03-storage.md)
- [ ] Set up off-cluster backups to **Anubis** (NAS): MooseFS metadata, Authentik DB dumps, and possibly `/home`. → [MooseFS ops](../procedures/moosefs-operations.md#add-a-disk), [Authentik maintenance](../procedures/authentik-maintenance.md#database-backups)

### SLURM
- [ ] Accounting (`slurmdbd`): being set up by David's colleague, who will document it. → [SLURM ops](../procedures/slurm-operations.md)
- [ ] Default memory, time limits, `AllowGroups`. → [SLURM](../config/slurm.md#recommended-additions)
- [ ] Mail on job end (`MailProg`)?

### Software and services
- [ ] Open Isaac Sim streaming ports `47000–50000` (TCP+UDP) on `hpc01`–`hpc03`. → [security](../config/security.md#isaac-sim-streaming-ports)
- [ ] Isaac Sim: UIDs ending above 900 get a signal port above `50000`; UIDs sharing the last three digits get the same ports. → [Isaac Sim](../../user-guide/08-isaac-sim.md#ports)
- [ ] Stop JupyterHub on `hpc01` (David is doing it).
- [ ] Authentik: export the invitation group-assignment policy so it can be rebuilt; confirm the compose file name. → [Authentik](../config/identity-authentik.md#invitation-flow-that-assigns-groups)
- [ ] JupyterHub reference config: `Dockerfile.jupyterhub` (optional). → [JupyterHub](../config/apps-jupyterhub.md)

## Review notes

Observations from the info-gathering output and the original notes. Nothing was changed on the servers.

1. **Cluster-internal ports are open on the public zone.** On the shared nodes, MooseFS (9419–9422, 9425), SLURM (6817–6819) and `srun` (60001–60100) are open to any source, although rich rules already accept all traffic between the three nodes. Every VM has a global IPv6 address on `ens3`, so these may be reachable from the Internet unless the platform's security groups block them. The MooseFS CGI on 9425 shows the whole filesystem layout. Port `20038/tcp` is open on `hpc01`/`hpc02` with nothing listening on it. → [security](../config/security.md#firewalld)
2. **Every Authentik user can log in to every node** (`access_provider = permit`). Suggested per-node rules are in [SSSD](../config/ldap-sssd.md#suggested-isrconf-changes-per-node).
3. **Root SSH keys are still installed.** `PermitRootLogin without-password` on all nodes. On `hpc01` the two root keys are the same key (`id_dcabecinhas_rsa@dsor`) added twice. → [security](../config/security.md#ssh)
4. **No default memory or time limits in SLURM.** `DefMemPerNode=UNLIMITED` means a job without `--mem` reserves the whole node; `MaxTime=UNLIMITED` lets a job hold a GPU indefinitely. → [SLURM](../config/slurm.md#recommended-additions)
5. **`hpc01` is a single point of failure for almost everything:** SLURM controller, MooseFS master, Authentik/LDAP and Traefik. Authentik's data and its backups live in `/srv`, which is on MooseFS, whose master is on the same node. Database backups are kept only 7 days, and there is no off-cluster copy yet. → [MooseFS ops](../procedures/moosefs-operations.md#recovering-from-loss-of-hpc01-master)
6. **No ACME email in Traefik**, so nobody is warned if certificate renewal starts failing. → [Traefik](../config/traefik.md)
7. **MooseFS master referenced by full hostname.** fstab and cfg files use `hpc01.isr-hpc…` instead of the `mfsmaster` alias already in `/etc/hosts`; the alias would make failover a one-line change.
8. **Bind mounts and boot order.** If MooseFS isn't mounted at boot, `/home` silently becomes the empty directory on `/`. `x-systemd.requires-mounts-for=/mnt/mfs` on the bind lines prevents that. → [base node](../config/base-node.md#bind-mounts-onto-moosefs)
9. **SSSD runs with `debug_level=9`** in every section on `hpc01`, which logs every lookup. → [SSSD](../config/ldap-sssd.md)

### Resolved since the first version

- LDAPS certificate checking: the deployed SSSD config no longer sets `ldap_tls_reqcert = never`, so the certificate is verified.
- Base DN: deployed SSSD uses `dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt` consistently.
- GPUs are configured as SLURM GRES (`gpu:1` per node).
- `mfsexports.cfg` allows only the three shared nodes.
- Docker on MooseFS uses the `overlayfs` driver and works.
- Port 9000 is closed.
- Five research groups; the IRSg group is `irsg`; admins are contacted by email (ISR website).
- Full SSSD config, JupyterHub hostname and config, `/opt/containers`, driver package, all node IPs (round 2).
- Accepting private address ranges on group nodes is deliberate: campus and VPN users connect without restrictions.
- Group node rules are per group; each node should admit only its own group. Sudo: per-group admin groups (preferred) plus the local `ubuntu` account; shared-node admins are `authentik Admins`.
- Users log in only to `hpc01` and reach `hpc02`/`hpc03` through SLURM. Private-only nodes are reached from IST's network or VPN.
- `/home` has no backup (MooseFS is resilient to losses); Apptainer is installed for all users.
- JupyterHub is a reference configuration for admins, not a user service.
- Group admins handle their group's invitations; Authentik mails through DSOR's account (managed by David Cabecinhas).

Open points and review notes specific to one group node are in that group's guide (e.g. hpc-dsor (not yet published)).
