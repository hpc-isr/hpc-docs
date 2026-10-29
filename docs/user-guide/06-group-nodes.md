---
title: "Group nodes"
parent: "User Guide"
nav_order: 6
---

# Group nodes

[← User Guide](README.md) · [Home](../README.md)

Some research groups provide separately administered compute systems for their members. Hardware, software, storage, access controls, and usage rules differ between groups and may change. Ask your group administrator for the current hostname, eligibility, and connection instructions.

## Group nodes in the shared cluster

Group nodes are joining the Slurm cluster one at a time, after each group agrees. Once your group's node has joined:

- you can still SSH in, but the GPU is only usable inside a Slurm job (`salloc --gres=gpu:1 -t 2:00:00` for an interactive shell);
- your jobs go to your group's node first, at your tier, before the shared nodes;
- when the node is idle, other groups can use it through the `scavenge` partition, and their jobs are preempted as soon as your group needs it;
- `/home` and `/storage` are the same as on the shared cluster. Files from the node's old local home stay where they were; your administrator can tell you the path, so you can copy what you need.

Until your group's node has joined, it keeps its own rules: follow the instructions of its administrator. See [SLURM basics](04-slurm-basics.md) for partitions, tiers and preemption.

## Safe use

Check current resource use before starting a long or resource-intensive task. Use the execution method approved by your group administrator, and stop workloads when finished. Contact that administrator if the host is unavailable or its access instructions no longer work.

Hostnames, internal routes, storage paths, and node-level service details are provided only to authorized users through the approved administrator channel.
