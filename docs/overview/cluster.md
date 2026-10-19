---
title: "Cluster at a glance"
parent: "Overview"
nav_order: 1
---

# Cluster at a glance

[← Overview](README.md) · [Home](../README.md)

The shared service provides GPU compute through SLURM. A login/controller service accepts user submissions, and scheduler-managed compute nodes run allocated workloads. Research groups may also operate separate dedicated systems with their own administration and access rules.

Hardware availability, node roles, storage layouts, software versions, and service dependencies change over time. Current user-visible capacity is reported by SLURM; host inventories and internal service placement belong in the restricted operator documentation.

Identity is managed centrally. Linux access, scheduler associations, and group-specific system access are separate controls and may update on different schedules. Contact the cluster administrators when an account or group change is not reflected.

Next: [Network](network.md)
