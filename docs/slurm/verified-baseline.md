---
nav_exclude: true
---

# Shared ISR Slurm Baseline

## Record status

- **Status:** Dated operational observations, not a live health check or approved change plan.
- **Scope:** Shared ISR Slurm cluster `hpc-isr` on `hpc01`, `hpc02`, and `hpc03`.
- **Record owner:** HPC Documentation Maintainers.
- **Operational owner:** The named owner for the shared cluster configuration has not been confirmed in the available evidence. Use the [research group SysAdmin directory](../../README.md#research-group-sysadmins) to coordinate verification.
- **Recorded:** 2026-10-06.
- **Next review:** Recheck before relying on these values for configuration or user guidance. The stated target is to test all clusters by 2026-10-31; record refreshed results after those tests.

This baseline summarizes administrator-provided terminal observations from 2026-10-02 and 2026-10-06. They are point-in-time snapshots. The underlying raw terminal outputs are not stored here. No passwords, credentials, user account names, private addresses, or personal paths are included.

## Observed configuration and service state

| Area | Observation | Evidence date and source |
|---|---|---|
| Cluster identity and version | `ClusterName=hpc-isr`; Slurm `23.11.4` was reported. | `scontrol show config` and `scontrol --version`, 2026-10-02; cluster name also appeared in the 2026-10-06 configuration output. |
| Controller service | `slurmctld` and `slurmd` were active on `hpc01`. This confirms service state on that host, but the configured `SlurmctldHost` value was not captured. | `systemctl is-active` and `systemctl show slurmd slurmctld`, 2026-10-06. Earlier controller inspection was recorded on 2026-10-02. |
| Node services | `slurmd` and Munge were active on `hpc01`, `hpc02`, and `hpc03` in the 2026-10-02 inspection. | Administrator terminal checks using `systemctl is-active`. |
| Partition snapshot | `normal` was the default partition and included `hpc01`, `hpc02`, and `hpc03`. All three were idle in that snapshot, with 56 CPUs and approximately 443 GB configured memory per node. The inspection reported no partition time limit, no oversubscription, and unrestricted group/account fields. These observations do not establish user eligibility or role priority. | `scontrol` partition/node inspection, 2026-10-02. |
| Scheduling and resource selection | Backfill scheduling; `SelectType=select/cons_tres`; `SelectTypeParameters=CR_CORE_MEMORY`. | `scontrol show config`, 2026-10-02. The resource-selection values were also present in the 2026-10-06 output. |
| Authentication | `AuthType=auth/munge`; Munge was active on the three nodes in the 2026-10-02 service checks. | `scontrol show config` and `systemctl is-active`, 2026-10-02; authentication value repeated in the 2026-10-06 output. |
| Accounting | `AccountingStorageType=(null)` appeared in the 2026-10-06 configuration output. `slurmdbd` was inactive in the 2026-10-02 inspection. No successful accounting-backed account or QoS management was verified. | `scontrol show config`, 2026-10-06; `systemctl is-active slurmdbd`, 2026-10-02. |
| GPU resources | `GresTypes=gpu`. The 2026-10-02 inspection reported one NVIDIA L40S GPU per node, 46,068 MiB per GPU, and driver `595.71.05`. CUDA `13.2` was reported on `hpc02`; equivalent CUDA output for every node was not captured. | `scontrol show config` and `nvidia-smi`, 2026-10-02; GRES setting repeated in the 2026-10-06 output. |
| Cgroups | An earlier inspection described cgroup process/task handling, but the exact plugin settings and resource limits are not preserved in the available evidence. | Summary of administrator inspection, 2026-10-02; exact configuration values unknown. |

## Policy and job-launch status

The [group-aware access and priority model](access-priority.md) records stakeholder intent, not deployed enforcement. The 2026-10-02 `normal` partition snapshot does not verify the intended group or role priorities. Account associations, QoS values, fair-share weights, and priority mappings remain to be confirmed by the responsible administrators.

The general [batch-job guide](batch-jobs.md) describes the `sbatch` and `srun` workflow and explicitly requires site-specific settings to be confirmed. The [Slurm testing use-case catalog](https://github.com/hpc-isr/slurm-testing-cases/tree/main/use-cases) contains single-node and three-node GPU procedures. Their scripts and instructions are examples, not evidence of a successful test run. The account requirements, current node membership, resource requests, CUDA-enabled PyTorch environment, and GPU request syntax must be confirmed before execution. The repository does not include a generic PyTorch installer because the approved CUDA-compatible build has not been established.

## Open verification items

- Confirm the configured controller host, current compute-node membership, and node-to-partition mapping.
- Recheck the installed Slurm version and all service states before planning a configuration change.
- Confirm the accounting design and how accounts, QoS, and role/group priorities are implemented. Do not infer these from partition visibility.
- Capture the exact cgroup plugin and limits, GPU configuration on each node, and the supported single-node and distributed job-launch paths.
- Run and record an approved small pilot before treating the distributed-GPU example or user access as validated.
- Confirm the operational owner, maintenance window, security boundaries, recovery procedure, and change-approval process; these were not established by the evidence summarized here.

## Sources

- Administrator-provided terminal observations dated 2026-10-02 and 2026-10-06, as summarized in the HPC setup discussion. Command families included `scontrol`, `systemctl`, `sinfo`, and `nvidia-smi`. Exact capture times are unavailable for some outputs.
- [Submitting a batch job with Slurm](batch-jobs.md) and [Group-aware access and priority model](access-priority.md) in this repository.
- [Slurm testing cases](https://github.com/hpc-isr/slurm-testing-cases), for the example script and setup instructions only, not as proof of a successful run.
- SIPg-specific architecture and operational decisions remain in the separate [SIPg research-computing repository](https://github.com/sipg-isr/sipg-cluster-architecture). This shared-cluster record does not copy SIPg-specific configuration.
