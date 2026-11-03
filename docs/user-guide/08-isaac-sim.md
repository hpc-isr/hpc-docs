---
title: "Isaac Sim"
parent: "User Guide"
nav_order: 8
---

# Isaac Sim

Use Isaac Sim only through a scheduled job on a node and partition that currently support it. Start from the approved job template and use the service endpoint and connection instructions supplied by the job or current user documentation. Do not hard-code internal node addresses or fixed service ports into scripts or public documentation.

Keep the service bound to the intended job/node scope, and expose it to your workstation only through the documented secure access method. Stop the job when finished. For a failed connection, verify the job state and current job-provided endpoint before changing firewall or certificate settings; contact an administrator if no approved endpoint is provided.

## Slurm examples

Two worked examples run Isaac Sim with [Isaac Lab](https://isaac-sim.github.io/IsaacLab/), NVIDIA's robot learning framework, as ordinary batch jobs:

- [Example 7: Robot learning with Isaac Lab](../slurm/examples/07-isaaclab-rl/README.md) trains the Unitree H1 humanoid to walk with reinforcement learning on one L40S GPU, in about an hour. The job installs Isaac Lab on the node's `/scratch` the first time, and you can watch the training, the trained policy or the full Isaac Sim editor streamed to your laptop over WebRTC. Start here.
- [Example 11: Robot learning on 4 GPUs](../slurm/examples/11-isaaclab-4gpu/README.md) scales example 7 to four nodes with one GPU each, on a harder rough-terrain task, with the GPUs averaging gradients over the network. It runs in the preemptible `scavenge` partition, so ask an admin before running it.
