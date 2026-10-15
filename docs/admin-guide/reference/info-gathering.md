---
title: "Info-gathering commands"
parent: "Reference"
grand_parent: "Admin Guide"
nav_order: 4
---

<!-- {% raw %} -->
# Info-gathering commands

[← Admin Guide](../README.md) · [Home](../../README.md)

Read-only commands that collect what the [open questions](open-questions.md) need. Each block writes one text file in your home directory. Secrets (passwords, tokens, keys) are replaced with `<REDACTED>`, but **look through the file before sharing it**.

Run them as `ubuntu`. They only read files and query status; they change nothing.

## 1. On `hpc01`

```bash
{
echo "== HOST"; hostname -f; lsb_release -ds; uname -r
echo "== NAMES"; getent hosts hpc01 hpc02 hpc03 hpc-dsor hpc-irsg hpc-isrg hpc-laseeb hpc-sipg hpc-vislab mfsmaster sso.isr.tecnico.ulisboa.pt
echo "== IP"; ip -br addr
echo "== GPU"; nvidia-smi --query-gpu=name,driver_version --format=csv; nvidia-smi | grep -i 'cuda version'
echo "== SLURM VERSION"; sinfo --version
echo "== slurm.conf"; grep -vE '^\s*(#|$)' /etc/slurm/slurm.conf
echo "== cgroup.conf"; grep -vE '^\s*(#|$)' /etc/slurm/cgroup.conf
echo "== gres.conf"; cat /etc/slurm/gres.conf 2>&1
echo "== PARTITIONS"; scontrol show partition
echo "== NODES"; sinfo -N -o "%N %c %m %G %T"
echo "== SLURMDBD"; systemctl is-active slurmdbd 2>&1
echo "== MFS EXPORTS"; grep -vE '^\s*(#|$)' /etc/mfs/mfsexports.cfg
echo "== MFS GOAL/TRASH"; mfsgetgoal /mnt/mfs; mfsgettrashtime /mnt/mfs
echo "== MFS CHUNKSERVERS"; mfscli -SCS
echo "== FIREWALL"; for z in $(sudo firewall-cmd --get-active-zones | grep -v '^ '); do sudo firewall-cmd --zone=$z --list-all; done
echo "== FAIL2BAN"; sudo cat /etc/fail2ban/jail.local /etc/fail2ban/jail.d/*.conf 2>&1
echo "== SSHD"; sudo sshd -T | grep -E '^(passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitrootlogin) '
echo "== ROOT KEYS (count only)"; sudo sh -c 'wc -l < /root/.ssh/authorized_keys' 2>&1
echo "== SSSD (selected lines)"; sudo grep -hE '^\s*(access_provider|simple_allow|ldap_access|ldap_tls_reqcert|ldap_uri|ldap_search_base|enumerate)' /etc/sssd/conf.d/*.conf
echo "== DOCKER"; docker info 2>/dev/null | grep -iE 'storage driver|docker root dir'; docker ps --format '{{.Names}}\t{{.Image}}'
echo "== /srv"; ls /srv
echo "== SCRATCH"; stat -c '%A %U:%G %n' /scratch; sudo lvs
echo "== /opt"; ls /opt
echo "== MOUNTS"; findmnt -t fuse,fuse.mfs,ext4,xfs -o TARGET,SOURCE,FSTYPE,OPTIONS
for f in /srv/traefik/docker-compose.yml /srv/traefik/*.yml /srv/traefik/*.toml /srv/authentik/docker-compose.override.yml /srv/authentik/post-script.sh; do
  [ -f "$f" ] || continue
  echo "== FILE $f"
  sed -E 's/((pass|secret|token|key|password|authtok|apikey)[A-Za-z_]*["]?\s*[=:]\s*).*/\1<REDACTED>/I' "$f"
done
} > ~/isr-info-hpc01.txt 2>&1; echo "Wrote ~/isr-info-hpc01.txt"
```

## 2. On `hpc02` (one shared compute node is enough)

```bash
{
echo "== HOST"; hostname -f; uname -r
echo "== GPU"; nvidia-smi --query-gpu=name,driver_version --format=csv
echo "== SERVICES"; systemctl is-active slurmd munge moosefs-chunkserver moosefs-metalogger sssd fail2ban firewalld
echo "== MOUNTS"; findmnt -t fuse,fuse.mfs,ext4,xfs -o TARGET,SOURCE,FSTYPE,OPTIONS
echo "== FIREWALL"; for z in $(sudo firewall-cmd --get-active-zones | grep -v '^ '); do sudo firewall-cmd --zone=$z --list-all; done
echo "== SSHD"; sudo sshd -T | grep -E '^(passwordauthentication|permitrootlogin) '
echo "== ROOT KEYS (count only)"; sudo sh -c 'wc -l < /root/.ssh/authorized_keys' 2>&1
} > ~/isr-info-hpc02.txt 2>&1; echo "Wrote ~/isr-info-hpc02.txt"
```

## 3. On a group node

```bash
{
echo "== HOST"; hostname -f; lsb_release -ds; uname -r
echo "== IP"; ip -br addr
echo "== GPU"; nvidia-smi --query-gpu=name,driver_version --format=csv
echo "== DISKS"; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
echo "== FSTAB"; grep -vE '^\s*(#|$)' /etc/fstab
echo "== SERVICES"; systemctl is-active slurmd moosefs-chunkserver moosefs-master moosefs-metalogger sssd fail2ban firewalld docker 2>&1
echo "== SSSD (selected lines)"; sudo grep -hE '^\s*(access_provider|simple_allow|ldap_access)' /etc/sssd/conf.d/*.conf
echo "== SUDOERS DROP-INS"; sudo ls /etc/sudoers.d; sudo grep -hv '^#' /etc/sudoers.d/* 2>/dev/null
echo "== FIREWALL"; for z in $(sudo firewall-cmd --get-active-zones | grep -v '^ '); do sudo firewall-cmd --zone=$z --list-all; done
echo "== SSHD"; sudo sshd -T | grep -E '^(passwordauthentication|permitrootlogin) '
} > ~/isr-info-$(hostname -s).txt 2>&1; echo "Wrote ~/isr-info-$(hostname -s).txt"
```

## Sending the results

Print a file with `cat ~/isr-info-hpc01.txt`, check it for anything sensitive, and paste it in the thread (or copy it to your laptop with `scp hpc01:~/isr-info-hpc01.txt .` and attach it).

Not covered by commands (answer in words): five or six groups, and the contact channel for each group admin.

## Round 2

Follow-up after the first round. Same rules: read-only, secrets redacted, check before sharing.

### On `hpc01`

```bash
{
echo "== WHO LISTENS ON 20038"; sudo ss -tulpn | grep -E ':20038\b' || echo "nothing listening"
echo "== SSSD FULL (password redacted)"; sudo sed -E 's/^(\s*ldap_default_authtok\s*=).*/\1 <REDACTED>/' /etc/sssd/conf.d/*.conf
echo "== ROOT KEYS (comments only)"; sudo awk '{print $NF}' /root/.ssh/authorized_keys
echo "== WEB HOSTNAMES"; for c in jupyterhub; do echo "-- $c"; docker inspect "$c" --format '{{range $k,$v := .Config.Labels}}{{$k}}={{$v}}{{"\n"}}{{end}}' 2>&1 | grep -i 'rule='; done
echo "== JUPYTERHUB FILES"; ls -la /srv/jupyterhub
for f in /srv/jupyterhub/docker-compose.yml /srv/jupyterhub/jupyterhub_config.py /srv/jupyterhub/Dockerfile; do
  [ -f "$f" ] || continue
  echo "== FILE $f"
  sed -E 's/((pass|secret|token|key|password|client_secret|apikey)[A-Za-z_]*["]?\s*[=:]\s*).*/\1<REDACTED>/I' "$f"
done
echo "== /opt/containers"; ls -la /opt/containers
echo "== TRAEFIK DYNAMIC"; ls -la /srv/traefik/dynamic; for f in /srv/traefik/dynamic/*; do [ -f "$f" ] && { echo "-- $f"; sed -E 's/((pass|secret|token|key)[A-Za-z_]*\s*[=:]\s*).*/\1<REDACTED>/I' "$f"; }; done
echo "== DRIVER INSTALL"; dpkg -l | grep -E '^ii\s+(nvidia-driver|cuda-drivers|nvidia-open)' | awk '{print $2, $3}'
echo "== GROUP NODE NAMES"; for g in irsg isrg sipg vislab laseeb dsor; do getent ahostsv4 hpc-$g.isr-hpc.tp.vps.tecnico.ulisboa.pt | head -1 | sed "s/^/hpc-$g private: /"; getent ahostsv4 hpc-$g.isr.tecnico.ulisboa.pt | head -1 | sed "s/^/hpc-$g public:  /"; done
echo "== SHARED NODE PUBLIC IPS"; for n in hpc02 hpc03; do getent ahostsv4 $n.isr.tecnico.ulisboa.pt | head -1; done
} > ~/isr-info2-hpc01.txt 2>&1; echo "Wrote ~/isr-info2-hpc01.txt"
```

Node-specific follow-ups are in each group's guide (e.g. hpc-dsor (not yet published)).

To document another group node, run the [group-node block](#3-on-a-group-node) on it.

<!-- {% endraw %} -->
