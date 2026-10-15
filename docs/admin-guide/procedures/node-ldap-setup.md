---
title: "LDAP/SSSD on a node"
parent: "Procedures"
grand_parent: "Admin Guide"
nav_order: 2
---

# Configure LDAP/SSSD on a node

[← Admin Guide](../README.md) · [Home](../../README.md)

Makes a node accept logins from Authentik users. Reference config and explanation: [SSSD](../config/ldap-sssd.md).

Run as `ubuntu` with `sudo`.

## 1. Install packages

```bash
sudo apt-get update
sudo apt-get install -y sssd-ldap sssd-tools libnss-sss libpam-sss ldap-utils
```

## 2. Check you can reach Authentik's LDAP

```bash
nc -vz sso.isr.tecnico.ulisboa.pt 636
ldapsearch -x -H ldaps://sso.isr.tecnico.ulisboa.pt \
  -D "cn=ldapservice,ou=users,dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt" -W \
  -b "dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt" "(cn=<a-known-username>)" cn uidNumber memberOf
```

The certificate should verify (it's the Let's Encrypt one exported from Traefik). If `ldapsearch` complains, check the outpost certificate in Authentik before working around it.

## 3. Write the config

Copy the reference config from an existing node (it contains the bind password) rather than retyping it:

```bash
# From a node that already works (e.g. hpc01):
sudo cat /etc/sssd/conf.d/isr.conf | ssh ubuntu@<new-node> 'sudo mkdir -p /etc/sssd/conf.d && sudo tee /etc/sssd/conf.d/isr.conf >/dev/null'
```

Or create it by hand from [the reference](../config/ldap-sssd.md#deployed-configuration-etcsssdconfdisrconf-hpc01), replacing `<REDACTED>` with the `ldapservice` password:

```bash
sudo mkdir -p /etc/sssd/conf.d
sudo nano /etc/sssd/conf.d/isr.conf
```

SSSD refuses to start unless the file is owned by root with mode 600:

```bash
sudo chown root:root /etc/sssd/conf.d/isr.conf
sudo chmod 600 /etc/sssd/conf.d/isr.conf
```

## 4. Enable home directory creation and start SSSD

```bash
# Create /home/<user> on first login (harmless if /home is shared and it already exists)
sudo pam-auth-update --enable mkhomedir

sudo systemctl enable sssd
sudo systemctl restart sssd
sudo systemctl status sssd --no-pager
```

## 5. Restrict logins to a group (group nodes)

With `access_provider = permit` every Authentik user can log in. Restrict each node to the groups that should use it; the [suggested `isr.conf` per node](../config/ldap-sssd.md#suggested-isrconf-changes-per-node) lists them. On a group node, allow only that group:

```bash
sudo cp /etc/sssd/conf.d/isr.conf /etc/sssd/conf.d/isr.conf.bak
sudo sed -i 's/^access_provider = permit/access_provider = simple/' /etc/sssd/conf.d/isr.conf
sudo sed -i '/^access_provider = simple/a simple_allow_groups = <group>' /etc/sssd/conf.d/isr.conf
grep -E '^(access_provider|simple_allow)' /etc/sssd/conf.d/isr.conf

sudo sss_cache -E
sudo systemctl restart sssd
```

Replace `<group>` with e.g. `dsor`. On `hpc02`/`hpc03` use `simple_allow_groups = authentik Admins`; on `hpc01`, `dsor, irsg, laseeb, sipg, vislab, authentik Admins`. Local accounts (`ubuntu`) are not affected.

Test before closing your current session:

```bash
sudo sssctl user-checks <member-username>      # should end with "pam_acct_mgmt: Success"
sudo sssctl user-checks <non-member-username>  # should say "Permission denied"
```

## 6. Allow SSH password logins (if users log in with passwords)

Ubuntu cloud images set `PasswordAuthentication no`. On the shared nodes that's still the case, but `KbdInteractiveAuthentication yes` lets users type their password through PAM anyway; group nodes decide for themselves. See [Security → SSH](../config/security.md#ssh). Check:

```bash
sudo sshd -T | grep -E 'passwordauthentication|kbdinteractiveauthentication|usepam'
```

If `passwordauthentication no` and users need passwords (at least for their first `ssh-copy-id`):

```bash
grep -l PasswordAuthentication /etc/ssh/sshd_config.d/*.conf   # find the cloud-init override
echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/10-isr-ldap.conf
sudo sshd -t && sudo systemctl reload ssh
```

Files in `sshd_config.d` are read in alphabetical order and the **first** value wins, so the `10-` prefix beats `60-cloudimg-settings.conf`. fail2ban protects against brute force.


## 7. Verify

```bash
getent passwd <username>
id <username>
sudo sssctl user-checks <username>
sudo sssctl domain-status sso.isr.tecnico.ulisboa.pt
# From your laptop:
ssh <username>@<node>.isr.tecnico.ulisboa.pt
```

## Troubleshooting

```bash
# Turn on debug logging temporarily: uncomment debug_level=6 in [domain/...] then
sudo systemctl restart sssd
sudo tail -f /var/log/sssd/sssd_sso.isr.tecnico.ulisboa.pt.log

# Stale data
sudo sss_cache -E && sudo systemctl restart sssd

# Login denied but user resolves → access control
sudo journalctl -u ssh -n 50 --no-pager
```

| Symptom | Likely cause |
|---|---|
| `sssd` won't start | Config file not `600 root:root`, or syntax error (`sudo sssctl config-check`) |
| `getent passwd <user>` empty | Bind DN/password wrong, search base wrong, LDAPS blocked |
| User resolves, password rejected | Wrong password, or SSH password auth disabled |
| User resolves, "access denied" | `simple_allow_groups` doesn't include their group |
| Groups missing in `id` | Group search base or `rfc2307bis` membership issue; clear cache |
