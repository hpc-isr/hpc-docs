---
nav_exclude: true
---

# Group-aware access and priority

## Current status

This page describes the five-level policy reported as SysAdmin-approved and applied on the shared hpc-isr staging cluster on 2026-10-19. It is user guidance, not a live readback, production configuration, or promise of a job start time. The [dated baseline](verified-baseline.md) records evidence and limits.

## Who can submit

The shared pool serves eligible researchers affiliated with VisLab, DSOR, LaSEEB, IRSg, and SIPg. Administrators provision access and Slurm account associations. A user with multiple verified affiliations has a separate association for each group and selects the corresponding account for each job. Usage is charged to that group association and is not combined into one cross-group balance.

New users start at low QoS. Role, seniority, group, or job title does not automatically grant a higher tier. Ask the relevant group SysAdmin to review a higher-priority request.

## QoS levels

| QoS | Relative priority | Maximum wall time | GPUs per user within this QoS | Concurrent jobs per user within this QoS |
|---|---:|---:|---:|---:|
| very_low | 0 | 4 hours | 1 | 1 |
| low | 10 | 12 hours | 1 | 1 |
| medium | 20 | 24 hours | 1 | 2 |
| high | 30 | 48 hours | 2 | 1 |
| very_high | 40 | 48 hours | 2 | 1 |

All group accounts and user associations default to low. A request does not change access by itself.

- very_low is a documented lower-than-baseline choice.
- low is the standard default for all users.
- medium requires a recorded request and SysAdmin approval for the affected association.
- high and very_high require approved, dated temporary grants limited to 90 days.
- very_high requires a documented reason why high is insufficient.

The GPU and concurrent-job limits apply within each QoS association. They do not establish a cumulative limit across multiple QoS levels or group affiliations. Ask administrators how limits apply before submitting work that uses multiple accounts or tiers.

## How priority affects jobs

The staging scheduler considers QoS along with job age and fair-share. A higher QoS can improve scheduling preference relative to other eligible jobs. It does not reserve a GPU, guarantee a start time, preempt a running job, or remove partition and resource constraints. Jobs can wait when requested resources are busy or unavailable.

The shared partition is named normal. Confirm your account, QoS, time limit, memory request, GPU syntax, and software environment with administrators before submitting. See the general [batch-job guide](batch-jobs.md).

## Request a change

Contact your affiliated group's SysAdmin through the approved support route. Include your HPC login, affiliated account, requested tier, workload resource needs, deadline, and why low is insufficient. Administrators verify affiliation and current scheduler conditions, record approval, and apply approved changes through the controlled process.

Do not assume a higher QoS is active until an administrator confirms it. Production settings may differ from this staging policy.
