---
title: "Security operations"
parent: "Procedures"
grand_parent: "Admin Guide"
nav_order: 6
---

# Security operations

[← Admin Guide](../README.md) · [Home](../../README.md)

Configuration background: [Security](../config/security.md).

## fail2ban

```bash
sudo fail2ban-client status                  # list jails
sudo fail2ban-client status sshd             # banned IPs for SSH

# Unban an IP (e.g. a user who mistyped their password)
sudo fail2ban-client set sshd unbanip <ip>

# Ban manually
sudo fail2ban-client set sshd banip <ip>

# Logs
sudo tail -n 50 /var/log/fail2ban.log
```

A user can find their public IP with `curl ifconfig.me`.

Bans are per node; if a user is locked out everywhere, unban on each node:

```bash
for n in hpc01 hpc02 hpc03; do ssh ubuntu@$n "sudo fail2ban-client set sshd unbanip <ip>"; done
```

## firewalld

```bash
sudo firewall-cmd --state
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all

# Open a port permanently
sudo firewall-cmd --permanent --add-port=<port>/tcp
sudo firewall-cmd --reload

# Close it
sudo firewall-cmd --permanent --remove-port=<port>/tcp
sudo firewall-cmd --reload

# Allow a port only from the private network
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<private-subnet-cidr>" port port="<port>" protocol="tcp" accept'
sudo firewall-cmd --reload
```

Expected open ports per node: [Ports](../reference/ports.md).

## Failed login review

```bash
sudo journalctl -u ssh --since "24 hours ago" | grep -E 'Failed|Invalid' | tail -n 50
sudo lastb | head -n 20       # failed logins
last | head -n 20             # successful logins
```

## Remove temporary root SSH access

After any rollout that needed root SSH:

```bash
sudo cat /root/.ssh/authorized_keys      # review
sudo truncate -s 0 /root/.ssh/authorized_keys
sudo sshd -T | grep permitrootlogin      # should be "no" or "prohibit-password"
```
