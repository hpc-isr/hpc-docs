---
title: "Notebook services"
parent: "Configuration"
grand_parent: "Admin Guide"
nav_order: 10
---

# Notebook services

Notebook and interactive application services are not part of the published user-facing cluster baseline unless explicitly announced. Their host placement, authentication path, user scope, container privileges, GPU access, data mounts, secrets, and proxy configuration require restricted review.

Do not reuse a historical configuration without reviewing its authentication and authorization boundary. In particular, host user databases, privileged container sockets, shared home directories, or direct GPU access can grant broad host or user-data access. Current availability and ownership are not verified here.
