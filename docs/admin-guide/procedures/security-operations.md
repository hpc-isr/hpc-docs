---
title: "Security operations"
parent: "Procedures"
grand_parent: "Admin Guide"
nav_order: 3
---

# Security operations

Host firewall, SSH, intrusion-prevention, account access, logging, and recovery procedures are restricted operational information. Administrators should use the current automation and protected runbooks, verify both active and persistent state, and capture a protected rollback record before a change.

Do not apply historical firewall snippets blindly. Check IPv4 and IPv6 behavior, source scope, established service dependencies, and the management path before changing rules. Keep at least one verified administrative recovery path. Do not publish access lists, host keys, logs containing identifiers, private addresses, or privileged command sequences.
