---
title: "SLURM"
parent: "Configuration"
grand_parent: "Admin Guide"
nav_order: 8
---

# SLURM (shared hpc-isr cluster)

[← Admin Guide](../README.md) · [Home](../../README.md)

This public page is a high-level overview, not an administrator runbook. It omits privileged deployment commands, internal network and certificate details, and protected configuration. The current as-built administrator record and deployable policy, code, playbooks, and procedures are maintained in separate access-controlled repositories.

## Overview

The shared cluster is named hpc-isr and runs Slurm 26.05 (SchedMD packages) since 2026-10-26.

| Role | Node |
|---|---|
| Controller and SlurmDBD; interactive GPU shards and preemptible batch work | hpc01 |
| Compute, `shared` partition | hpc02, hpc03 |
| Compute, owned by a research group | group nodes, as each group joins |

Each node has one NVIDIA L40S GPU. Slurm uses consumable CPU, memory and GPU resources with backfill scheduling, partition-priority preemption on group nodes, and Fair Tree fair-share between groups. Munge authenticates Slurm daemons. User identities come from the institutional directory through SSSD, and Slurm accounts, users and tiers are synced from it automatically. Users see the policy in [SLURM basics](../../user-guide/04-slurm-basics.md) and [Access and priority](../../slurm/access-priority.md).

## Administrator boundary

Do not use historical setup recipes or configuration snippets from this public page. They were removed because deployment has evolved and the former examples were not an approved current procedure. Administrators should use reviewed automation and the restricted as-built documentation. Before a change, verify the target environment, capture protected rollback state, use the approved change process, and read back the affected service.

This repository is public. Host-specific network addresses, database endpoints, certificate material, private-key custody, firewall rules, protected membership/grant manifests, and privileged recovery commands must remain in approved restricted systems.
