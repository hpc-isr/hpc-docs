# SLURM (scheduler for hpc01–hpc03)

[← Admin Guide](../README.md) · [Home](../../README.md)

Day-to-day tasks: [SLURM operations](../procedures/slurm-operations.md). User docs: [SLURM basics](../../user-guide/04-slurm-basics.md).

## Design

| Role | Node |
|---|---|
| Controller (`slurmctld`) and login | `hpc01` |
| Compute (`slurmd`) | `hpc01`, `hpc02`, `hpc03` |

- **MUNGE** authenticates SLURM daemons to each other (shared secret key).
- **Identities come from SSSD.** SLURM has no user database; every node must resolve the same users with the same UID/GID (`getent passwd <user>`).
- **`select/cons_tres` + `CR_Core_Memory`**: cores and memory are consumable; GPUs via GRES.
- **cgroups** confine each job to its cores, memory and devices.
- **`sched/backfill`**: small jobs can start while big ones wait.
- **No accounting DB at first** (simpler to validate). `slurmdbd` can be added later (below).
- Cluster name `hpc-isr`, partition `normal`.


## Deployed configuration (hpc01)

Slurm **23.11.4** (Ubuntu `slurm-wlm`), accounting **not** enabled (`slurmdbd` inactive). All three nodes `idle` with `gpu:1`.

`/etc/slurm/slurm.conf` (comments and blank lines removed):

```ini
ClusterName=hpc-isr
SlurmctldHost=hpc01
SlurmUser=slurm
AuthType=auth/munge
CryptoType=crypto/munge
StateSaveLocation=/var/lib/slurm/slurmctld
SlurmdSpoolDir=/var/spool/slurmd
SwitchType=switch/none
MpiDefault=none
ProctrackType=proctrack/cgroup
TaskPlugin=task/affinity,task/cgroup
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core_Memory
ReturnToService=2
SlurmctldPidFile=/run/slurmctld.pid
SlurmdPidFile=/run/slurmd.pid
SlurmctldPort=6817
SlurmdPort=6818
SlurmctldTimeout=120
SlurmdTimeout=300
InactiveLimit=0
KillWait=30
MinJobAge=300
JobAcctGatherType=jobacct_gather/linux
JobAcctGatherFrequency=30
AccountingStorageType=accounting_storage/none
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log
SlurmctldDebug=info
SlurmdDebug=info
GresTypes=gpu
NodeName=hpc01 NodeAddr=hpc01 CPUs=56 Boards=1 SocketsPerBoard=56 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=443195 State=UNKNOWN Gres=gpu:1
NodeName=hpc02 NodeAddr=hpc02 CPUs=56 Boards=1 SocketsPerBoard=56 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=443195 State=UNKNOWN Gres=gpu:1
NodeName=hpc03 NodeAddr=hpc03 CPUs=56 Boards=1 SocketsPerBoard=56 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=443195 State=UNKNOWN Gres=gpu:1
PartitionName=normal Nodes=hpc01,hpc02,hpc03 Default=YES MaxTime=INFINITE State=UP
SrunPortRange=60001-60100
```

`/etc/slurm/cgroup.conf`:

```ini
ConstrainCores=yes
ConstrainDevices=yes
ConstrainRAMSpace=yes
ConstrainSwapSpace=no
AllowedRAMSpace=100
```

`/etc/slurm/gres.conf` (no `NodeName=`, so it applies to every node that reads it):

```ini
#AutoDetect=nvml
Name=gpu File=/dev/nvidia0
```

Effective partition settings worth knowing: `DefMemPerNode=UNLIMITED`, `DefaultTime=NONE`, `MaxTime=UNLIMITED`, `AllowGroups=ALL`. See [Recommended additions](#recommended-additions).

The sections below are the recipe used to build it, kept for rebuilding a node or the cluster.

## Prerequisites (all three nodes)

- `/etc/hosts` with `hpc01`–`hpc03` ([Base node](base-node.md#name-resolution-etchosts)).
- Time synchronised.
- SSSD working: `getent passwd <user>` and `id <user>` give identical output on every node.
- Shared `/home` mounted (MooseFS), so job scripts and output are visible everywhere.

The rollout below runs loops from `hpc01` over `ssh root@hpcXX`. That needs root SSH **temporarily**: add a key to `/root/.ssh/authorized_keys` on each node and **remove it afterwards**. Alternatively run each block on each node by hand with `sudo`.

```bash
sudo -i
cat >/root/slurm-cluster-vars.sh <<'EOF'
export SLURM_CONTROLLER="hpc01"
export SLURM_ALL_NODES="hpc01 hpc02 hpc03"
export SLURM_COMPUTE_NODES="hpc01 hpc02 hpc03"
export SLURM_CLUSTER_NAME="hpc-isr"
export SLURM_PARTITION_NAME="normal"
EOF
source /root/slurm-cluster-vars.sh
```

## 1. Install packages (all nodes)

```bash
for node in $SLURM_ALL_NODES; do
  echo "===== $node ====="
  ssh root@"$node" 'bash -s' <<'EOF'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y munge libmunge2 slurm-wlm slurmctld slurmd slurm-client rsync

getent group slurm  >/dev/null || groupadd --system slurm
getent passwd slurm >/dev/null || useradd --system --gid slurm --home-dir /var/lib/slurm --shell /usr/sbin/nologin slurm

mkdir -p /etc/slurm /var/lib/slurm/slurmctld /var/spool/slurmd /var/log/slurm
chown -R slurm:slurm /var/lib/slurm /var/spool/slurmd /var/log/slurm
chmod 0755 /var/lib/slurm /var/spool/slurmd /var/log/slurm
EOF
done
```

## 2. MUNGE key (same key everywhere)

```bash
# Ubuntu's munge package normally creates a key on install; create one if missing
[ -f /etc/munge/munge.key ] || mungekey --create
chown munge:munge /etc/munge/munge.key
chmod 0400 /etc/munge/munge.key

for node in $SLURM_ALL_NODES; do
  rsync -av /etc/munge/munge.key root@"$node":/etc/munge/munge.key
  ssh root@"$node" 'chown munge:munge /etc/munge/munge.key && chmod 0400 /etc/munge/munge.key && systemctl enable --now munge && systemctl restart munge'
done

# Test locally and across nodes
for node in $SLURM_ALL_NODES; do ssh root@"$node" 'munge -n | unmunge | grep STATUS'; done
munge -n | ssh root@hpc02 unmunge | grep STATUS
```

Expect `STATUS: Success (0)`. Protect `munge.key` like a password.

## 3. Firewall (all nodes)

| Service | Port |
|---|---|
| `slurmctld` | 6817/tcp |
| `slurmd` | 6818/tcp |
| `slurmdbd` | 6819/tcp |
| `srun` I/O (`SrunPortRange`) | 60001–60100/tcp |

```bash
for node in $SLURM_ALL_NODES; do
  ssh root@"$node" 'firewall-cmd --permanent --add-port=6817-6819/tcp && firewall-cmd --permanent --add-port=60001-60100/tcp && firewall-cmd --reload'
done
```

Without `SrunPortRange` and the matching open range, `sbatch` works but interactive `srun` hangs, because job-step I/O uses dynamic ports back to the submitting host.

## 4. `slurm.conf`

Generated on `hpc01` from each node's real hardware (`slurmd -C`):

```bash
cat >/etc/slurm/slurm.conf <<EOF
ClusterName=${SLURM_CLUSTER_NAME}
SlurmctldHost=${SLURM_CONTROLLER}

SlurmUser=slurm
AuthType=auth/munge
CryptoType=crypto/munge

StateSaveLocation=/var/lib/slurm/slurmctld
SlurmdSpoolDir=/var/spool/slurmd
SwitchType=switch/none
MpiDefault=none

ProctrackType=proctrack/cgroup
TaskPlugin=task/affinity,task/cgroup

SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core_Memory

ReturnToService=2
SlurmctldPidFile=/run/slurmctld.pid
SlurmdPidFile=/run/slurmd.pid
SlurmctldPort=6817
SlurmdPort=6818
SrunPortRange=60001-60100

SlurmctldTimeout=120
SlurmdTimeout=300
InactiveLimit=0
KillWait=30
MinJobAge=300

JobAcctGatherType=jobacct_gather/linux
JobAcctGatherFrequency=30
AccountingStorageType=accounting_storage/none

SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log
SlurmctldDebug=info
SlurmdDebug=info

# Node definitions generated from slurmd -C
EOF

for node in $SLURM_COMPUTE_NODES; do
  line="$(ssh root@"$node" "slurmd -C | sed -n '1p'")"
  line="$(echo "$line" | sed -E "s/^NodeName=[^ ]+/NodeName=${node} NodeAddr=${node}/")"
  echo "${line} State=UNKNOWN" >>/etc/slurm/slurm.conf
done

echo "PartitionName=${SLURM_PARTITION_NAME} Nodes=$(echo $SLURM_COMPUTE_NODES | tr ' ' ',') Default=YES MaxTime=INFINITE State=UP" >>/etc/slurm/slurm.conf

chown slurm:slurm /etc/slurm/slurm.conf
chmod 0644 /etc/slurm/slurm.conf
cat /etc/slurm/slurm.conf
```

On Slurm 23.11+ (Ubuntu 24.04 ships 23.11), `CryptoType` was renamed `CredType`; the old name is still accepted.

## 5. `cgroup.conf`

```bash
cat >/etc/slurm/cgroup.conf <<'EOF'
ConstrainCores=yes
ConstrainDevices=yes
ConstrainRAMSpace=yes
ConstrainSwapSpace=no
AllowedRAMSpace=100
EOF
chown slurm:slurm /etc/slurm/cgroup.conf
chmod 0644 /etc/slurm/cgroup.conf
```

`ConstrainDevices=yes` is what stops a job without `--gres=gpu:1` from using the GPU.

## 6. GPUs (GRES)

As deployed: one untyped GPU per node.

```bash
# slurm.conf: declare the GRES type, and add Gres=gpu:1 to each node line
sed -i '1i GresTypes=gpu' /etc/slurm/slurm.conf
sed -i -E '/^NodeName=hpc0[1-3] /s/$/ Gres=gpu:1/' /etc/slurm/slurm.conf

# gres.conf: same on every node
cat >/etc/slurm/gres.conf <<'EOF'
Name=gpu File=/dev/nvidia0
EOF
chmod 0644 /etc/slurm/gres.conf
```

Then distribute and restart all daemons (next step). Users request it with `--gres=gpu:1`.

If you later want users to be able to ask for the model explicitly (`--gres=gpu:l40s:1`), add `Type=l40s` in `gres.conf` and use `Gres=gpu:l40s:1` on the node lines.

## 7. Distribute config and start services

```bash
CONF_FILES="/etc/slurm/slurm.conf /etc/slurm/cgroup.conf"
[ -f /etc/slurm/gres.conf ] && CONF_FILES="$CONF_FILES /etc/slurm/gres.conf"

for node in $SLURM_ALL_NODES; do
  rsync -av $CONF_FILES root@"$node":/etc/slurm/
done

systemctl enable --now slurmctld
for node in $SLURM_COMPUTE_NODES; do ssh root@"$node" 'systemctl enable --now slurmd && systemctl restart slurmd'; done
```

Logs: `journalctl -u slurmctld -n 100 --no-pager`, `journalctl -u slurmd -n 100 --no-pager`, `/var/log/slurm/`.

## 8. Validate

```bash
scontrol ping                # Slurmctld(primary) at hpc01 is UP
sinfo -Nel
sinfo -R                     # reasons for down/drained nodes
srun -N1 -n1 hostname
srun --gres=gpu:1 nvidia-smi -L
```

Test as an LDAP user:

```bash
getent passwd <username> && id <username>
sudo -iu <username> srun -N1 -n1 id
```

## Recommended additions

> **TODO:** Decide on these; none are in the deployed config.

| Setting | Why |
|---|---|
| `DefMemPerCPU=7800` (≈ 433 GiB / 56) in `slurm.conf` | Today `DefMemPerNode=UNLIMITED`: a job that omits `--mem` reserves the whole node's memory and blocks everyone else on it |
| `MaxTime=3-00:00:00`, `DefaultTime=01:00:00` on the partition | `MaxTime=INFINITE` lets one job hold a GPU forever |
| `AllowGroups=dsor,irsg,laseeb,sipg,vislab` on the partition | Only research-group members can submit |
| Accounting + fairshare (below) | Fair GPU sharing between groups, `sacct` history |

## Optional: accounting with MariaDB + `slurmdbd`

Gives `sacct`, history, per-group accounts, fairshare and QoS.

```bash
export SLURM_DB_PASS='<strong-password>'
apt-get install -y mariadb-server slurmdbd
systemctl enable --now mariadb

mysql <<EOF
CREATE DATABASE IF NOT EXISTS slurm_acct_db;
CREATE USER IF NOT EXISTS 'slurm'@'localhost' IDENTIFIED BY '${SLURM_DB_PASS}';
GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost';
FLUSH PRIVILEGES;
EOF

cat >/etc/slurm/slurmdbd.conf <<EOF
AuthType=auth/munge
DbdHost=${SLURM_CONTROLLER}
DbdPort=6819
SlurmUser=slurm
DebugLevel=info
LogFile=/var/log/slurm/slurmdbd.log
PidFile=/run/slurmdbd.pid
StorageType=accounting_storage/mysql
StorageHost=localhost
StoragePort=3306
StorageUser=slurm
StoragePass=${SLURM_DB_PASS}
StorageLoc=slurm_acct_db
EOF
chown slurm:slurm /etc/slurm/slurmdbd.conf
chmod 0600 /etc/slurm/slurmdbd.conf
systemctl enable --now slurmdbd

sed -i 's/^AccountingStorageType=.*/AccountingStorageType=accounting_storage\/slurmdbd/' /etc/slurm/slurm.conf
grep -q '^AccountingStorageHost=' /etc/slurm/slurm.conf || cat >>/etc/slurm/slurm.conf <<EOF
AccountingStorageHost=${SLURM_CONTROLLER}
AccountingStoragePort=6819
EOF

for node in $SLURM_ALL_NODES; do rsync -av /etc/slurm/slurm.conf root@"$node":/etc/slurm/; done
systemctl restart slurmctld

sacctmgr -i add cluster "$SLURM_CLUSTER_NAME"
```

Per-group accounts are then created as in [SLURM operations → accounts](../procedures/slurm-operations.md#accounting-accounts-and-users-if-slurmdbd-is-enabled).

Accounting is **not enabled** today (`AccountingStorageType=accounting_storage/none`, `slurmdbd` inactive). It will be enabled; a colleague of David's is doing the setup and will document it.

References: [quick start admin guide](https://slurm.schedmd.com/quickstart_admin.html) · [slurm.conf](https://slurm.schedmd.com/slurm.conf.html) · [cgroup.conf](https://slurm.schedmd.com/cgroup.conf.html) · [gres.conf](https://slurm.schedmd.com/gres.conf.html) · [accounting](https://slurm.schedmd.com/accounting.html)
