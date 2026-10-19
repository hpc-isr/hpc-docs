---
title: "Researcher Test Journey"
parent: "User Guide"
nav_order: 0
---

# Researcher Test Journey

Use this guide for a small, administrator-approved test of your own ISR HPC access and Slurm workflow. Reading this page does not grant account, cluster, QoS, storage, or repository access.

## Before the test

1. Read [Getting an account](01-getting-an-account.md) and [SSH login](02-ssh-login.md). Ask your group administrator to confirm your exact HPC login, authentication method, supported SSH hostname, and that your account is enabled for the target service. An identity-provider account alone does not prove cluster authorization.
2. Ask the administrator to confirm the Slurm account, partition, allowed QoS, resource bounds, and whether a GPU allocation is permitted. Use only those values. Do not infer that a documented QoS or configured limit is available to your association.
3. Read [Storage](03-storage.md). Before using research data, obtain an administrator-confirmed path and its persistence, quota, backup, retention, and cross-node visibility rules. Those details are not established universally in the public guidance. Use a small non-sensitive test input until they are confirmed.
4. Confirm that your GitHub account can read the private [Slurm testing examples](https://github.com/hpc-isr/slurm-testing-cases). Public documentation access does not grant access to that repository. If the link returns a permission error, ask your group administrator to confirm the approved access route; do not use a fork or copy from an unreviewed source.
5. Use the documented small examples first: no more than one CPU, 2 GiB of memory, one GPU, and five minutes. These are example bounds, not a statement of cluster-wide limits or a guarantee that a job will start.

## Run the starter cases

### 1. CPU batch smoke test

Follow the [CPU case instructions and script](https://github.com/hpc-isr/slurm-testing-cases/tree/main/use-cases/cpu-basic). The example requests one node, one CPU, 2 GiB, and five minutes. It prints the allocated host and request details, then runs `hostname` inside the allocation.

**Expected result:** the job reaches `COMPLETED` with exit code `0:0`, and its output contains the host and allocation details. These are acceptance expectations for the example, not a promise about queue wait time.

### 2. Optional single-GPU visibility test

Run the [basic GPU smoke case](https://github.com/hpc-isr/slurm-testing-cases/tree/main/use-cases/gpu-basic) only after the administrator confirms your GPU access and current availability. It requests one GPU, one CPU, 2 GiB, and five minutes, then runs `nvidia-smi`.

**Expected result:** the job completes successfully, reports one visible device, and accounting records one GPU allocation. A visible device or a successful `nvidia-smi` check does not prove that PyTorch, CUDA libraries, or your research software are installed. The separate [single-node PyTorch case](https://github.com/hpc-isr/slurm-testing-cases/tree/main/use-cases/gpu-single-node) requires an administrator-confirmed software environment and has no successful cluster run recorded in the current test documentation.

### 3. Optional interactive test

Use the [interactive PTY procedure](https://github.com/hpc-isr/slurm-testing-cases/tree/main/use-cases/interactive) only if the administrator approves it for the test window. A one-shot `srun command` is not an interactive terminal test. The documented PTY procedure requires typing commands in the allocated shell, then exiting and checking that the allocation ended. No successful PTY shell result is currently recorded in the test repository.

## Monitor and troubleshoot

Use the [SLURM basics guide](04-slurm-basics.md) to inspect your own queued or running jobs and the [FAQ and troubleshooting guide](07-faq.md) for pending jobs, failures, missing logs, and GPU visibility. A pending job is not necessarily rejected. Do not repeatedly resubmit, increase resource requests to probe a limit, or submit deliberately unauthorized requests.

Keep output and error files in a user-owned directory outside the Git checkout. After a job ends, compare its state and exit code with its output and accounting record. If the result is unexpected, stop and ask your group SysAdmin rather than guessing a different account, QoS, partition, or GPU request.

## Report feedback

The [structured researcher test feedback form](https://github.com/hpc-isr/slurm-testing-cases/issues/new?template=researcher-test-feedback.yml) becomes available after the feedback-form change is merged to the private test repository. It requires access to that repository and permission to open issues. Until the form is available to you, use your group's approved SysAdmin support route in the [contact directory](../overview/contacts.md). Do not post passwords, tokens, private keys, raw logs, personal account details, or research data in a public issue. Share job identifiers or raw output only through an administrator-approved private support channel.

## Completion checklist

A starter run is complete when you have recorded the case name, date, your own job result, exit code, and whether the expected output appeared; you have checked any error output; and you have reported blockers through the structured form or approved support route. Do not treat one passing smoke job as proof of priority ranking, hard limit enforcement, multi-node GPU readiness, or production readiness.
