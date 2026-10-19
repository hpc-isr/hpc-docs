---
title: "Identity-service maintenance"
parent: "Procedures"
grand_parent: "Admin Guide"
nav_order: 4
---

# Identity-service maintenance

Identity-service upgrade, backup, certificate, database, LDAP, and recovery procedures are restricted because errors can affect authentication across multiple systems. Follow the provider's current upstream instructions and the approved protected deployment record.

Before a change, verify the active release, supported upgrade path, protected backup and restore, certificate chain and expiry, directory-client health, administrator recovery access, and a rollback route. Afterward, test user sign-in and a directory-backed Linux login without exposing credentials or identity records.

Do not publish compose files, secret environment variables, bind identities, internal endpoints, certificate paths, firewall rules, or privileged recovery commands here.
