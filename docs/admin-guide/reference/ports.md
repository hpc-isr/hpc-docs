---
title: "Service access"
parent: "Reference"
grand_parent: "Admin Guide"
nav_order: 2
---

# Service access

[← Admin Guide](../README.md) · [Home](../../README.md)

The live service-port and firewall inventory is restricted operational information. Administrators should verify it on the target host and in the authoritative automation/infrastructure configuration before a change. A historical port list is not evidence of current exposure.

For a host-local review, inspect the active firewall configuration and listening sockets using approved administrative access. Compare runtime and persistent firewall state, IPv4 and IPv6 policy, and the intended source scope. Record the read-back in the protected change record.

Public user access instructions are in the [SSH login guide](../../user-guide/02-ssh-login.md). Do not add internal address ranges, firewall rules, management endpoints, or per-host port mappings here.
