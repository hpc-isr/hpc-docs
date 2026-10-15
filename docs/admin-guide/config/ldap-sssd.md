---
title: "SSSD"
parent: "Configuration"
grand_parent: "Admin Guide"
nav_order: 7
---

# SSSD (Linux logins for Authentik/LDAP users)

[← Admin Guide](../README.md) · [Home](../../README.md)

Every node runs SSSD so Authentik users can log in over SSH with the same username, UID and groups everywhere. SLURM relies on this: it has no user database of its own and trusts NSS (`getent passwd`).

Step-by-step setup on a node: [Configure LDAP/SSSD on a node](../procedures/node-ldap-setup.md).

## Deployed configuration: `/etc/sssd/conf.d/isr.conf` (hpc01)

Bind password redacted. Copy this file from a working node when setting up a new one.

```ini
[nss]
debug_level=9
filter_groups = root
filter_users = root
reconnection_retries = 3
#override_homedir = /mnt/mfs/home/%u
override_shell = /bin/bash

[sssd]
debug_level=9
config_file_version = 2
reconnection_retries = 3
sbus_timeout = 30
domains = sso.isr.tecnico.ulisboa.pt
services = nss, pam, ssh

[pam]
reconnection_retries = 3

[domain/sso.isr.tecnico.ulisboa.pt]
enumerate = true
debug_level=9
cache_credentials = True
id_provider = ldap
chpass_provider = ldap
auth_provider = ldap
#access_provider = ldap
access_provider = permit
ldap_uri = ldaps://sso.isr.tecnico.ulisboa.pt
#ldap_id_use_start_tls = False
#ldap_tls_reqcert = never

ldap_default_bind_dn = cn=ldapservice,ou=users,dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt
ldap_default_authtok = <REDACTED>

#ldap_id_use_start_tls = true
#ldap_tls_reqcert = allow

ldap_schema = rfc2307bis
ldap_search_base = dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt
ldap_user_search_base = ou=users,dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt
#ldap_group_search_base = ou=groups,dc=isr,dc=tecnico,dc=ulisboa,dc=pt
#ldap_group_search_base = ou=virtual-groups,dc=isr,dc=tecnico,dc=ulisboa,dc=pt
ldap_group_search_base = ou=groups,dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt???ou=virtual-groups,dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt??

ldap_user_object_class = user
ldap_user_name = cn
ldap_group_object_class = group
ldap_group_name = cn

# Optionally, filter logins to only a specific group
#ldap_access_order = filter
#ldap_access_filter = memberOf=cn=authentik Admins,ou=groups,dc=dsor,dc=isr,dc=tecnico,dc=ulisboa,dc=pt
#ldap_access_order = filter
#ldap_access_filter = (&(ObjectClass=user))
```

Compared with the version in the original notes: every base DN now starts with `dc=ldap,…` (matching Authentik's LDAP provider), `ldap_tls_reqcert = never` is commented out (so SSSD verifies the certificate), the access filter is commented out, and `override_shell = /bin/bash` gives every LDAP user bash.

**`debug_level=9` is on in all three sections.** That's the most verbose level: it logs every lookup and can fill `/var/log/sssd/` quickly on a busy node. Comment those lines out (or set `debug_level=2`) once troubleshooting is done:

```bash
sudo sed -i 's/^debug_level=9/#debug_level=9/' /etc/sssd/conf.d/isr.conf
sudo systemctl restart sssd
sudo du -sh /var/log/sssd
```

## What the important settings do

| Setting | Effect |
|---|---|
| `ldap_uri = ldaps://…` | Talk to the Authentik LDAP outpost over TLS (636) |
| `ldap_schema = rfc2307bis` | Group membership by DN (`member` attribute), which Authentik uses |
| `ldap_user_object_class = user`, `ldap_user_name = cn` | Authentik exposes users as `objectClass=user` with the username in `cn` |
| `ldap_group_search_base = A???B??` | Search two bases: `ou=groups` (real groups) and `ou=virtual-groups` (Authentik's per-user primary groups) |
| `override_shell = /bin/bash` | Every LDAP user gets bash, whatever the directory says |
| `cache_credentials = True` | Users can still log in if `hpc01`/Authentik is briefly down |
| `enumerate = true` | `getent passwd` lists all users. Handy, but costly with many users |
| `access_provider = permit` | **Every** Authentik user may log in to the node. (The `ldap_access_filter` lines are commented out and would be ignored with `permit` anyway.) |
| `services = nss, pam, ssh` | Includes the `ssh` responder (only used if `sshd` is configured with `AuthorizedKeysCommand`) |
| `filter_users/groups = root` | Never take `root` from LDAP |

## Restricting a node to one group (recommended for group nodes)

Today every node has `access_provider = permit`: any Authentik user can log in anywhere. The goal is that every node keeps using the ISR IdP but admits only the people who should be there. Rules are per group: each group's admin decides them for their own node.

SSSD's `simple` access provider does this. It matches group names as `getent group` shows them. Only logins are affected; user and group lookups (`getent`, file ownership, SLURM jobs) keep working for everyone.

### Suggested `isr.conf` changes per node

In the `[domain/sso.isr.tecnico.ulisboa.pt]` section of `/etc/sssd/conf.d/isr.conf`, replace `access_provider = permit` with:

| Node | Suggested lines | Why |
|---|---|---|
| `hpc01` | `access_provider = simple`<br>`simple_allow_groups = dsor, irsg, laseeb, sipg, vislab, authentik Admins` | Login node: every research group submits SLURM jobs here |
| `hpc02`, `hpc03` | `access_provider = simple`<br>`simple_allow_groups = authentik Admins` | Users reach them only through SLURM from `hpc01`, never by SSH |
| `hpc-dsor` | `access_provider = simple`<br>`simple_allow_groups = dsor` | Only DSOR |
| `hpc-irsg` | `access_provider = simple`<br>`simple_allow_groups = irsg` | Only IRSg |
| `hpc-laseeb` | `access_provider = simple`<br>`simple_allow_groups = laseeb` | Only LaSEEB |
| `hpc-sipg` | `access_provider = simple`<br>`simple_allow_groups = sipg` | Only SIPg |
| `hpc-vislab` | `access_provider = simple`<br>`simple_allow_groups = vislab` | Only VisLab |

On a group node, add `, <group>-admins` if the group uses a separate admin group whose members aren't all in `<group>`, and `, authentik Admins` if the group wants the cluster admins to be able to log in. Local accounts (`ubuntu`, root) are never affected, so you can't lock yourself out with them.

SLURM jobs on `hpc02`/`hpc03` still run with these rules: `slurmd` starts jobs without a PAM login check, and SSSD still resolves every user. (Inferred from how SSSD and `slurmd` work; test with `srun -w hpc02 id` as a normal user after the change.)

The `ldap_access_filter` lines in the deployed config are commented out; with `access_provider = simple` they stay unused and can be deleted.

Example for a group node (here DSOR's):

```ini
[domain/sso.isr.tecnico.ulisboa.pt]
# ... everything else unchanged ...
access_provider = simple
simple_allow_groups = dsor
```

Apply and test as in [node-ldap-setup → Restrict logins](../procedures/node-ldap-setup.md#5-restrict-logins-to-a-group-group-nodes).
