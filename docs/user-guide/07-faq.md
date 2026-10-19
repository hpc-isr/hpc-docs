---
title: "FAQ & troubleshooting"
parent: "User Guide"
nav_order: 8
---

# FAQ & troubleshooting

[← User Guide](README.md) · [Home](../README.md)

## I cannot log in

Use the exact HPC POSIX login supplied by your group administrator; do not assume it is identical to your display name or email. If a first-time or changed SSH host-key prompt appears, verify the fingerprint through the approved administrator channel before accepting it. If you cannot verify it, stop and contact your group administrator. See [Getting an account](01-getting-an-account.md) and [SSH login](02-ssh-login.md).

## My job is pending

Inspect your own job's state and pending reason:

    squeue --jobs="<job-id>" -o '%i|%u|%a|%q|%T|%M|%R'

A pending job is not necessarily rejected, and a reason such as (None) may be inconclusive. Do not repeatedly resubmit or increase resources to probe a limit. Ask your group SysAdmin if the reason or expected wait is unclear.

## My job failed or disappeared

Inspect the job record and your output/error files:

    sacct -X -j "<job-id>" --noheader \
      --format=JobIDRaw,User,Account,Partition,QOS,State,ExitCode,Elapsed,AllocTRES

Accounting availability and retention can change. If the record is missing, provide the job ID and approximate submission time to your administrator; do not conclude that no job ran based only on a missing row.

For OUT_OF_MEMORY, TIMEOUT, or an application error, review the requested resources and sanitized job output. Request a change through your group SysAdmin rather than assuming a larger limit is available.

## A GPU application cannot find a device

Check that the job was submitted with a GPU request allowed for your association and inspect the job's allocated resources. A GPU visible to nvidia-smi does not prove that your Python environment contains a compatible CUDA framework. Ask your administrator which software environment is supported; do not install system packages or change node configuration.

## I do not know where to put data or software

See [Storage](03-storage.md). Ask your group SysAdmin to confirm the persistent path, cross-node visibility, backup policy, and supported environment setup for your workload. Do not assume that a path, package, container, quota, or backup service is available.

## How do I report a problem?

Use the support contact for your group in [Who's who](../overview/contacts.md). Include the job ID, case or command, approximate submission time, observed state or sanitized error, and expected result. Keep raw logs and personal or research data in approved storage. Never include passwords, tokens, private keys, or sensitive research data in a public issue or message.
