---
title: "SLURM"
parent: "Configuration"
grand_parent: "Admin Guide"
nav_order: 8
---

# SLURM (shared hpc-isr cluster)

[← Admin Guide](../README.md) · [Home](../../README.md)

This public page is a high-level overview, not an administrator runbook. It omits privileged deployment commands, internal network and certificate details, and protected configuration. The current as-built administrator record and deployable policy, code, playbooks, and procedures are maintained in separate access-controlled repositories.

## Staging overview

The shared staging cluster is named hpc-isr and reports Slurm 23.11.4.

| Role | Node |
|---|---|
| Controller and SlurmDBD; also compute | hpc01 |
| Compute | hpc02, hpc03 |

The normal partition contains all three nodes. Each was reported with one NVIDIA L40S GPU. These are dated staging observations, not an availability or performance guarantee.

Slurm uses consumable CPU, memory, and GPU resources with backfill scheduling. Munge authenticates Slurm daemons. User identities are resolved through institutional identity and SSSD/NSS. SlurmDBD-backed accounting is enabled on staging. The five-level QoS and request process are documented in [Group-aware access and priority](../../slurm/access-priority.md).

## Administrator boundary

Do not use historical setup recipes or configuration snippets from this public page. They were removed because deployment has evolved and the former examples were not an approved current procedure. Administrators should use reviewed automation and the restricted as-built documentation. Before a change, verify the target environment, capture protected rollback state, use the approved change process, and read back the affected service.

This repository is public. Host-specific network addresses, database endpoints, certificate material, private-key custody, firewall rules, protected membership/grant manifests, and privileged recovery commands must remain in approved restricted systems.
