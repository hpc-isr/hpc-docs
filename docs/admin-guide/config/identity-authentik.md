---
title: "Central identity service"
parent: "Configuration"
grand_parent: "Admin Guide"
nav_order: 3
---

# Central identity service

The platform uses a centrally managed identity service for institutional accounts and groups. Linux name and group resolution and authentication depend on the directory service and node-side identity clients. A directory update may not appear immediately because of service and client caches.

Provider configuration, bind identities, secrets, endpoint names, certificates, deployment files, access policies, recovery, and administrator membership are restricted. Use the approved identity-service console and protected operational documentation. Never place bind credentials or signing keys in Git.

User account instructions: [Getting an account](../../user-guide/01-getting-an-account.md).
