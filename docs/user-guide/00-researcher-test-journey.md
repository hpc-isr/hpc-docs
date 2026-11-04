---
title: "Researcher Test Journey"
parent: "User Guide"
nav_order: 0
---

# Researcher Test Journey

Use this short path to check your own ISR HPC access. Public instructions and workload examples are in this repository; your group administrator confirms your account, allowed resources, and support route.

## Before you submit

1. Follow [Getting an account](01-getting-an-account.md) and [SSH login](02-ssh-login.md).
2. Ask your group administrator to confirm your Slurm account, allowed QoS, and whether GPU jobs are enabled for you. Use only those values.
3. Read the [storage guide](03-storage.md) before choosing where to put inputs or results. Use `/scratch` only for temporary work; keep results you need in an approved shared location.
4. Follow [Before you start](../slurm/README.md#before-you-start) to prepare the public examples and supported software environment.

## Run a small test

- **CPU:** Follow the [short CPU smoke job](05-slurm-job-examples.md#1-short-cpu-smoke-job). Slurm chooses the node and partition; the output should identify the allocated host and show successful completion.
- **GPU, if approved:** Follow the [one-GPU visibility check](05-slurm-job-examples.md#3-one-gpu-visibility-smoke-job). It checks the allocated device; it does not verify that your model's software environment works.
- **Interactive, if needed:** Follow the [interactive shell procedure](05-slurm-job-examples.md#6-interactive-shell-procedure). Type `exit` to leave the compute shell and release the allocation.
- **Research workloads:** Choose an example from the public [Slurm examples](../slurm/README.md) and follow its prerequisites and resource requests.

## Check and report the result

Use [Slurm basics](04-slurm-basics.md) to check your job and [FAQ and troubleshooting](07-faq.md) for common problems. A pending job is not necessarily rejected; do not repeatedly resubmit or increase resources to probe a limit.

If the result is unexpected, contact your group administrator through [Who's who](../overview/contacts.md). Share the example name, approximate run time, observed outcome, and a short sanitized error. Send job identifiers or raw logs only through a support route your administrator has approved. Do not include credentials, private keys, or research data in a public issue.

A successful smoke job confirms only that specific check. It does not establish priority ranking, resource-limit enforcement, or the success of a different workload.
