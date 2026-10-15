# Cluster at a glance

[← Overview](README.md) · [Home](../README.md)

## Hardware

ISR runs **8 virtual machines** on the IST VPS platform (`tp.vps.tecnico.ulisboa.pt`). They are identical:

| Per node | Value |
|---|---|
| CPU | 56 cores, Intel Xeon 6730P |
| RAM | 440 GB |
| GPU | 1 × NVIDIA L40S (48 GB) |
| Root disk | 80 GB (`/`) |
| CEPH-backed block storage | 2 × 780 GB, joined with LVM into ~1.5 TB `/scratch` |
| Local NVMe (ephemeral) | 2 × 3.5 TB, used as MooseFS chunk storage |
| OS | Ubuntu 24.04 LTS (Noble), cloud image |

## How the resources are split

| Resource | Total | Per group node | Shared SLURM cluster |
|---|---:|---:|---:|
| GPU (L40S) | 8 | 1 | 3 |
| CPU cores (Xeon 6730P) | 448 | 56 | 168 |
| RAM (GB) | 3520 | 440 | 1320 |
| CEPH storage (TB) | 12.5 | 1.5625 | 4.6875 |
| Ephemeral local NVMe SSD (TB) | 55.84 | 6.98 | 20.94 |

## The nodes

| Node | Purpose | Who can use it |
|---|---|---|
| `hpc01` | SLURM controller + compute, MooseFS master, Traefik + Authentik (SSO/LDAP) | Everyone, through SLURM |
| `hpc02` | SLURM compute, MooseFS chunkserver + metalogger | Everyone, through SLURM |
| `hpc03` | SLURM compute, MooseFS chunkserver + metalogger | Everyone, through SLURM |
| `hpc-dsor` | Group node | DSOR members |
| `hpc-irsg` | Group node | IRSg members |
| `hpc-laseeb` | Group node | LaSEEB members |
| `hpc-sipg` | Group node | SIPg members |
| `hpc-vislab` | Group node | VisLab members |

IPs and public names: [Hosts](../admin-guide/reference/hosts.md). Only `hpc-dsor` and `hpc-irsg` have public names; the other group nodes are reachable only from the private network.

## Research groups

| Group (Authentik / LDAP name) | Group node |
|---|---|
| `dsor` | `hpc-dsor` |
| `irsg` | `hpc-irsg` |
| `laseeb` | `hpc-laseeb` |
| `sipg` | `hpc-sipg` |
| `vislab` | `hpc-vislab` |

Group names are lowercase and must be spelled exactly like this in SSSD, SLURM and sudo rules (note `irsg`, not `isrg`).

## Software stack

| Layer | Software |
|---|---|
| OS | Ubuntu 24.04 LTS |
| Identity | Authentik 2026.5.4 (IdP, SSO, LDAP outpost) → SSSD on every node |
| Reverse proxy / TLS | Traefik v3.7, Let's Encrypt |
| Scheduler | SLURM 23.11.4 + MUNGE (shared nodes) |
| Shared filesystem | MooseFS CE 4.59.2 (`/home`, `/opt` on shared nodes; `/srv`, `/var/lib/docker` on hpc01) |
| GPU | NVIDIA driver 595.x, CUDA 13.2 |
| Containers | Docker CE + compose plugin (service hosting) |
| Security | firewalld, fail2ban |
| Containers for users | Apptainer (e.g. NVIDIA Isaac Sim) |
| Knowledge base | These pages, published on GitHub |

Next: [Network](network.md)
