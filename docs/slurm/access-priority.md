---
nav_exclude: true
---

# Access and priority

## Who can submit

The shared cluster serves researchers affiliated with VisLab, DSOR, LaSEEB, IRSg and SIPg. Each group is a Slurm account. Your Slurm user and account are created automatically from your institutional (Authentik) account within about 10 minutes of being added to your group. A user in more than one group has an association for each, and chooses one with `--account`.

## Tiers

Each user has one tier, set by an administrator. It is shown as your QOS:

    sacctmgr show assoc user=$USER format=account,qos%25,defaultqos

| Tier | Longest job (own node and `shared`) | On your group's own node | Fair-share weight within the group |
|---|---|---|---|
| high | 1 day | Scheduled first; preempts low-tier jobs and scavengers; never preempted | 4 |
| medium | 3 days | Preempts low-tier jobs and scavengers; never preempted | 2 |
| low | 7 days | Preempts scavengers; can be preempted by medium and high groupmates | 1 |

Members of a group who aren't in any tier get low. A user with a higher tier can also submit with a lower one (`--qos=low`), for example for a job longer than the higher tier allows.

The tier matters mostly on your group's own node. On the `shared` nodes every tier has the same priority and nobody is preempted. Between groups, Slurm's fair-share balances usage: a group that has used less recently goes first.

## What a tier does not do

A tier doesn't reserve a GPU or guarantee a start time. Jobs still wait when the requested resources are busy. CPUs, memory, GPUs and wall time are enforced: a request over a limit is rejected at submit, with a message saying which one.

## Request a change

Ask your group's SysAdmin. Include:

- your HPC login and the group account;
- the tier you need and why your current one isn't enough;
- the kind of work and its approximate CPU, memory, GPU and wall-time needs;
- the deadline, if there is one.

Don't send passwords, tokens or private data. A change takes effect within about 10 minutes of the administrator making it, and applies to new jobs only. Use the group contact in [Who's who](../overview/contacts.md).

See [SLURM basics](../user-guide/04-slurm-basics.md) for partitions, limits and preemption.
