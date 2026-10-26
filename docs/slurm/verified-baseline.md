---
nav_exclude: true
---

# Shared ISR Slurm Baseline

> **Superseded.** This page records the Slurm 23.11 staging setup as observed on 2026-10-19. The cluster was reinstalled with Slurm 26.05 on 2026-10-26, with different partitions, tiers and limits. For current use, see [SLURM basics](../user-guide/04-slurm-basics.md) and [Access and priority](access-priority.md).

## Record status

- **Status:** Dated staging observations, not a live health check or production deployment record.
- **Scope:** Shared cluster hpc-isr on hpc01, hpc02, and hpc03.
- **Recorded:** 2026-10-19.
- **Operational owner:** The named owner for shared cluster configuration is not confirmed.
- **Evidence:** Operator-provided terminal readbacks in the HPC planning discussion dated 2026-10-18 and 2026-10-19. The hosts were not queried while preparing this page.

The cluster was designated as staging by its operator. These are point-in-time results, not a change approval or production configuration.

## Observed staging configuration

| Area | Observation | Evidence and limits |
|---|---|---|
| Slurm build | Slurm 23.11.4; cluster name hpc-isr. | Operator readbacks, 2026-10-18/19. |
| Controller and services | hpc01 runs slurmctld and slurmdbd and also participates as a compute node. Later readbacks reported controller, SlurmDBD, and Munge active. | No controller failover test is recorded. |
| Compute and partition | The normal partition includes all three nodes. A 2026-10-19 snapshot showed them idle, each with 56 CPUs, approximately 443 GB configured memory, and one NVIDIA L40S GPU. | Point-in-time capacity, not a guarantee. |
| Scheduling and selection | Backfill scheduling, consumable CPU/memory/GRES selection, and task affinity/cgroup controls. Multifactor priority uses fair-share, age, and QoS. | Exact live values remain in restricted operational records. |
| Authentication | Munge authenticates Slurm daemons. User identity resolution depends on institutional identity and SSSD/NSS integration. | All compute nodes must resolve the same user IDs and groups. |
| Accounting | SlurmDBD-backed accounting is enabled on staging. A completed test job appeared in accounting. | This does not establish every authorization or resource limit. |
| Storage | Shared user storage and node-local scratch are described in the [storage guide](../user-guide/03-storage.md). | This review did not obtain fresh filesystem inventories for all nodes. Confirm current mounts and free space with administrators. |
| GPU test | A one-GPU staging smoke job exposed an NVIDIA L40S to the job. | Not acceptance of a PyTorch application or distributed GPU workload. |

## Staging QoS policy

The controller reported five QoS levels. Each user and group association defaults to low. The complete user-facing policy and limits are in [Group-aware access and priority](access-priority.md). QoS affects scheduling preference; it does not reserve resources or promise a start time.

A low-QoS CPU job and a one-GPU smoke job completed and were visible in accounting. Two same-user low-QoS concurrency observations differed: an earlier pair serialized, while a later pair overlapped despite the reported one-job limit. Do not rely on that configured job-count value as an enforced safety cap. These checks do not establish fair-share outcomes, cross-account limits, temporary-grant expiry, or rejection of every unauthorized request. Staging readbacks and workload observations do not establish strict association, QoS, or concurrency-limit enforcement. Do not describe those controls as fully validated until positive and negative staging tests pass.

## Database and backup status

Staging accounting uses a database service separate from the controller. A mutual-TLS connection was verified from the SlurmDBD host. A later manual encrypted backup was restored into an isolated validation schema; the 12 table definitions and source/restored row counts matched.

The sender timer was intentionally disabled in the latest recorded state, and a manual backup succeeded. The receiver retention timer was reported active. This is a tested manual backup and restore path, not a daily backup guarantee, alerting service, or disaster-recovery objective. Host-specific endpoints, network details, certificate identities, filesystem paths, and privileged recovery instructions belong in restricted administrator documentation.

## Sources and review

- Operator-provided Slurm configuration, service, node, QoS, association, accounting, TLS, and backup/restore readbacks, 2026-10-18 and 2026-10-19.
- [Batch job guide](batch-jobs.md) for the general submission workflow.
- [Group-aware access and priority](access-priority.md) for user-facing QoS policy.
- Executable workload cases and their acceptance evidence are maintained separately in an access-controlled repository; their availability depends on repository access.
- Detailed host, storage, network, certificate, deployment, and recovery material belongs in access-controlled administrator documentation.
