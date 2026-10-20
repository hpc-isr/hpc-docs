---
nav_exclude: true
---

# Group-aware access and priority

## Current status

This page describes the five-level QoS configuration observed on the shared hpc-isr staging cluster on 2026-10-19. It does not establish that the policy has received all required approvals, that any tier is enabled for a particular account, or that the configuration is in production. It is user guidance, not a live readback or promise of a job start time. The [dated baseline](verified-baseline.md) records evidence and limits.

## Who can submit

The shared pool serves eligible researchers affiliated with VisLab, DSOR, LaSEEB, IRSg, and SIPg. Administrators provision access and Slurm account associations. A user with multiple verified affiliations has a separate association for each group and selects the corresponding account for each job. Usage is charged to that group association and is not combined into one cross-group balance.

New users start at low QoS. Role, seniority, group, or job title does not automatically grant a higher tier. Ask the relevant group SysAdmin to review a higher-priority request.

## Group Accounts and Individual Access

The staging accounting read-back on 2026-10-19 showed a `low` default for each listed group account:

| Group account | Staging default observed on 2026-10-19 |
|---|---|
| `vislab` | `low` |
| `dsor` | `low` |
| `laseeb` | `low` |
| `irsg` | `low` |
| `sipg` | `low` |

This is a dated staging observation, not a current authorization list. It does not mean that every user in a group can request every QoS. Slurm access is configured on each user's account association; higher QoS access can differ between users and affiliated accounts. Confirm your current eligible QoS with your group SysAdmin before submitting. If the site permits users to query their own association, this read-only command shows the account and QoS recorded for your login:

```bash
sacctmgr -nP show assoc where cluster=hpc-isr user="$USER" \
  format=User,Account,QOS,DefaultQOS
```

If the command is unavailable or returns no row, ask your SysAdmin to check your association. Do not infer access from the group table alone.

## QoS levels

| QoS | Relative priority | Configured maximum wall time | Configured GPUs per user within this QoS | Configured concurrent jobs per user within this QoS |
|---|---:|---:|---:|---:|
| very_low | 0 | 4 hours | 1 | 1 |
| low | 10 | 12 hours | 1 | 1 |
| medium | 20 | 24 hours | 1 | 2 |
| high | 30 | 48 hours | 2 | 1 |
| very_high | 40 | 48 hours | 2 | 1 |

All group accounts and user associations default to low. A request does not change access by itself.

These are configured staging QoS values, not verified enforcement limits. Staging reported `AccountingStorageEnforce=none`, and a same-user low-QoS overlap was observed despite the configured one-job value. Do not rely on these caps to reject excess jobs or GPU requests; administrators must resolve and validate enforcement before treating them as safeguards. See the [dated baseline](verified-baseline.md).

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

Every user may ask their affiliated group's SysAdmin to review a higher QoS. A request is not an approval and does not change your association. Include:

- your exact HPC login and the affiliated account you plan to charge;
- the tier requested and why your current tier is insufficient;
- the workload type and approximate CPU, memory, GPU, wall-time, and concurrency needs;
- the relevant deadline or project milestone;
- a preferred review or end date for the request.

Do not send passwords, tokens, private keys, or sensitive research data with the request. Administrators verify the account affiliation, resource need, current queue/fair-share conditions, and impact on other users. They may ask for more detail or retain the current tier. Medium requires recorded approval for the affected association. High and very_high are dated grants with a maximum duration of 90 days under the recorded staging policy. Do not interpret a higher QoS as a guaranteed start time or a larger wall-time/concurrency allowance beyond the table above.

Use the group contact listed in [Who's who](../overview/contacts.md). Do not submit until an administrator confirms the requested QoS is active for your account. Production settings may differ from this dated staging policy.
