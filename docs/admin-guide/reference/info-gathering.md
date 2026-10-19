---
title: "Operational evidence collection"
parent: "Reference"
grand_parent: "Admin Guide"
nav_order: 3
---

# Operational evidence collection

Collect host, DNS, route, interface, firewall, SSH, identity, certificate, listener, and service evidence only through approved administrator access. Store raw output in the protected change record; it can expose internal addresses, user names, access rules, filesystem paths, and certificate metadata.

Before sharing a summary, remove credentials, keys, tokens, private endpoints, fingerprints, identity records, and service topology that is not needed by the audience. Read-back should state host, timestamp, command scope, and whether runtime and persistent state were both checked.
