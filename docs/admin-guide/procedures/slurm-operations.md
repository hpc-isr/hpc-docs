---
title: "Scheduler operations"
parent: "Procedures"
grand_parent: "Admin Guide"
nav_order: 4
---

# Scheduler operations

Scheduler configuration, account/QoS reconciliation, node maintenance, job intervention, accounting, and recovery are privileged operations. Use the source-controlled hpc-automation playbooks and the protected host inventory; review the current cluster state and approved change record first.

Never apply historical commands from this public repository. Validate a candidate against the installed Slurm version, preserve a protected rollback copy, ensure the maintenance preconditions are met, and read back both controller and accounting state after the change. Workload acceptance cases are maintained separately in access-controlled materials.
