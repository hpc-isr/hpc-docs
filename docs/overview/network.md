---
title: "Network"
parent: "Overview"
nav_order: 2
---

# Network

[← Overview](README.md) · [Home](../README.md)

The shared GPU service has a public login entry and internal compute services. Users submit work through the scheduler; compute nodes are not user login destinations. Research-group services may have separate access paths.

Identity is centrally managed and consumed by Linux login services. Scheduler authentication, database accounting, storage, monitoring, and external identity services are operational dependencies maintained by the administrators. Their endpoint addresses, internal DNS names, firewall rules, service-port inventory, and failure procedures are intentionally kept out of this public guide.

For access, use the [SSH login guide](../user-guide/02-ssh-login.md). For service status or connection problems, contact the cluster administrators through the established support channel.

This page describes the user-facing boundary only. It is not an as-built network diagram or an administrator runbook.
