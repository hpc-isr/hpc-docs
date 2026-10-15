---
title: "Ports"
parent: "Reference"
grand_parent: "Admin Guide"
nav_order: 2
---

# Ports

[← Admin Guide](../README.md) · [Home](../../README.md)

What is open in firewalld today (from the info-gathering output). The shared nodes also accept **all** traffic from each other via rich rules, so the cluster-internal ports below don't need to be open to anyone else. See [Security](../config/security.md#firewalld).

## Shared nodes

| Port | Proto | Service | Open on |
|---|---|---|---|
| 22 | tcp | SSH | all |
| 80, 443 | tcp | Traefik (HTTP → HTTPS redirect, HTTPS) | `hpc01` |
| 636 | tcp | LDAPS (Authentik LDAP outpost) | `hpc01` |
| 9419–9421 | tcp | MooseFS master (metaloggers, chunkservers, clients) | `hpc01`, `hpc02` (and presumably `hpc03`) |
| 9422 | tcp | MooseFS chunkserver | `hpc01`–`hpc03` |
| 9425 | tcp | MooseFS CGI web UI | `hpc01`, `hpc02` |
| 6817 / 6818 / 6819 | tcp | `slurmctld` / `slurmd` / `slurmdbd` (not running) | `hpc01`–`hpc03` |
| 60001–60100 | tcp | `srun` I/O (`SrunPortRange`) | `hpc01`–`hpc03` |
| 20038 | tcp | Nothing listening; can be closed | `hpc01`, `hpc02` |
| 47000–50000 | tcp + udp | NVIDIA Isaac Sim streaming, one pair per user ([Isaac Sim](../../user-guide/08-isaac-sim.md#ports)). **To be opened** ([how](../config/security.md#isaac-sim-streaming-ports)) | `hpc01`–`hpc03` |

Port 9000 (Authentik's direct HTTP, used during initial setup) is **not** open.

## Group nodes

Each group opens what its own services need, on top of SSH. See each group's guide, e.g. hpc-dsor ports (not yet published).

## Check what's open and listening

```bash
sudo firewall-cmd --list-all
sudo ss -tulpn
```
