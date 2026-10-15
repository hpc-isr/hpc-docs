# Security: firewalld, fail2ban, SSH

[← Admin Guide](../README.md) · [Home](../../README.md)

Every node runs **firewalld** and **fail2ban**. Tasks: [Security operations](../procedures/security-operations.md).

## firewalld

`ens3` is not assigned to a zone explicitly, so it falls into the default zone **`public`**. Docker's bridges are in the `docker` zone (target `ACCEPT`), managed by Docker.

### Shared nodes (deployed)

`hpc01`, `public` zone:

```text
services: dhcpv6-client ssh
ports: 80/tcp 443/tcp 9419/tcp 9420/tcp 9421/tcp 9422/tcp 9425/tcp 636/tcp 6817-6819/tcp 60001-60100/tcp 20038/tcp
rich rules:
  rule family="ipv4" source address="100.68.8.76/32" accept
  rule family="ipv4" source address="100.68.8.86/32" accept
  rule family="ipv4" source address="100.68.8.70/32" accept
```

`hpc02` (and presumably `hpc03`): the same, without `80`, `443` and `636`.

The rich rules already accept **all** traffic between the three shared nodes. The explicit MooseFS, SLURM and `srun` ports are therefore only needed by hosts *other* than those three, and as listed they are open to anyone who can reach `ens3`. Each VM has a global IPv6 address directly on `ens3`, so unless the VPS platform's security groups block it, those ports are reachable from the IPv6 Internet. Closing them keeps the cluster working:

```bash
# On hpc01 (repeat on hpc02/hpc03 without 9419-9421, 9425)
sudo firewall-cmd --permanent --remove-port={9419,9420,9421,9422,9425}/tcp
sudo firewall-cmd --permanent --remove-port=6817-6819/tcp --remove-port=60001-60100/tcp
sudo firewall-cmd --reload
```

Keep `636/tcp` open on `hpc01` while group nodes reach LDAPS through it, or replace it with a rich rule for `100.68.8.64/27`.

Port `20038/tcp` is open on `hpc01` and `hpc02`, but nothing listens on it (checked on `hpc01`). It can be closed:

```bash
sudo firewall-cmd --permanent --remove-port=20038/tcp && sudo firewall-cmd --reload
```

### Isaac Sim streaming ports

Users stream NVIDIA Isaac Sim from SLURM jobs, so `47000–50000` (TCP and UDP) should be open on `hpc01`–`hpc03`. Not yet done:

```bash
# On each of hpc01, hpc02, hpc03
sudo firewall-cmd --permanent --add-port=47000-50000/tcp --add-port=47000-50000/udp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
```

Each user's ports are derived from their UID by the [launch script](../../user-guide/08-isaac-sim.md#ports).

### Private address ranges are trusted

The nodes live inside IST's university network. Accepting connections from its private ranges is a deliberate choice: people on campus or on IST's VPN connect without restrictions, while the public Internet stays limited to the open services (SSH, HTTPS, LDAPS). Group nodes may do this with firewalld rich rules, e.g. accepting everything from `100.64.0.0/10` (VPS network) and `10.0.0.0/8` (campus and VPN).

### Group nodes

Each group sets its own firewall on top of the [baseline](group-nodes.md#what-all-group-nodes-should-have); node-specific rules are in each group's guide.

### Setting up on a new node

```bash
sudo apt-get install -y firewalld
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-service=ssh
# trust the other shared nodes
for ip in 100.68.8.86 100.68.8.70 100.68.8.76; do
  sudo firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"$ip/32\" accept"
done
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

> Ubuntu ships `ufw` by default. Make sure only one firewall is active: `sudo ufw status` should say `inactive`.

## fail2ban

Bans IPs after repeated failed SSH logins. Deployed config lives in `/etc/fail2ban/jail.d/` (there is no `jail.local`):

```ini
[DEFAULT]
banaction = nftables
banaction_allports = nftables[type=allports]
backend = systemd

[sshd]
enabled = true
```

Bans are nftables rules; ban time, find time and retry count are the fail2ban defaults (10 min ban after 5 failures in 10 min). To change them, add to the `[DEFAULT]` section, e.g. `bantime = 1h`, and `ignoreip = 127.0.0.1/8 ::1 100.68.8.64/27` so cluster nodes are never banned.

```bash
sudo apt-get install -y fail2ban
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

## SSH

Shared nodes:

| Setting | Value |
|---|---|
| `PasswordAuthentication` | `no` |
| `KbdInteractiveAuthentication` | `yes` (hpc01) |
| `PermitRootLogin` | `without-password` (keys only) |
| Keys in `/root/.ssh/authorized_keys` | 2 on `hpc01` and `hpc02`; on `hpc01` both are `id_dcabecinhas_rsa@dsor` |

Group nodes set their own SSH policy; keep `PermitRootLogin` at `without-password` or `no`.

On the shared nodes, `PasswordAuthentication no` together with `KbdInteractiveAuthentication yes` means users can still type their password: sshd asks for it through PAM's keyboard-interactive method, and SSSD checks it against Authentik. (Inferred from the settings, not tested.)

Root can still log in with a key on every node. On `hpc01` the two root keys are both David's (`id_dcabecinhas_rsa@dsor`), most likely the same key added twice during the SLURM rollout. If root SSH is no longer needed, remove them; otherwise remove the duplicate line. See [Security operations](../procedures/security-operations.md#remove-temporary-root-ssh-access).
