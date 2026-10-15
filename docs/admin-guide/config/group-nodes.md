---
title: "Group nodes"
parent: "Configuration"
grand_parent: "Admin Guide"
nav_order: 2
---

# Group nodes

[← Admin Guide](../README.md) · [Home](../../README.md)

Each research group has one dedicated VM, managed by that group's admin ([Who's who](../../overview/contacts.md)). Group nodes share the identity setup (Authentik + SSSD) with the rest of the infrastructure but are otherwise independent: **no MooseFS, no SLURM**, own storage layout, own services.

Diagram: [Inside a node → Group node](../../overview/node-anatomy.md#group-node).

| Group | Node | Private IP | Documented |
|---|---|---|---|
| DSOR | `hpc-dsor` | `100.68.8.71` (public `192.92.147.42`) | ✓ hpc-dsor guide (not yet published) |
| IRSg | `hpc-irsg` | `100.68.8.73` (public `192.92.147.99`) | — |
| LaSEEB | `hpc-laseeb` | `100.68.8.75` (no public name) | — |
| SIPg | `hpc-sipg` | `100.68.8.91` (no public name) | — |
| VisLab | `hpc-vislab` | `100.68.8.84` (no public name) | — |

To document another group node, run the group-node block from [Info-gathering commands](../reference/info-gathering.md#3-on-a-group-node) on it.

## What all group nodes should have

Each group sets its own rules for its node. The common baseline is:

- Ubuntu 24.04, `ubuntu` local admin account, NVIDIA driver.
- SSSD pointing at the ISR IdP (Authentik) ([Configure LDAP/SSSD](../procedures/node-ldap-setup.md)), **admitting only the group's own users** ([suggested `isr.conf` per node](ldap-sssd.md#suggested-isrconf-changes-per-node)).
- sudo for the group's admins through a per-group Authentik group such as `dsor-admins` (preferred), with the local `ubuntu` account kept as a fallback ([Users & groups](../procedures/users-and-groups.md#give-a-group-admin-sudo-on-their-group-node)).
- firewalld + fail2ban ([Security](security.md)).
- Same VM flavour as every node: 80 GB root disk, 2 × ~780 GB CEPH volumes, 2 × 3.5 TB local NVMe (ephemeral). How the CEPH and NVMe disks are used is up to each group.
- Not part of MooseFS or SLURM: own `/home`, own services.
- Accepting the university's private ranges in the firewall is allowed and deliberate ([Security](security.md#private-address-ranges-are-trusted)).

Anything specific to one node (storage layout, VPNs, extra services, open ports) goes in that group's own guide, e.g. the hpc-dsor guide (not yet published).
