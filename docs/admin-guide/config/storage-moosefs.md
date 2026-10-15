---
title: "MooseFS"
parent: "Configuration"
grand_parent: "Admin Guide"
nav_order: 3
---

# MooseFS (shared filesystem)

[← Admin Guide](../README.md) · [Home](../../README.md)

MooseFS Community Edition **4.59.2** pools the six local NVMe disks of `hpc01`–`hpc03` (2 × 3.5 TiB each, ~21 TiB raw) into one POSIX filesystem mounted at `/mnt/mfs`. `/home`, `/opt`, and per-node `/srv` and `/var/lib/docker` are bind-mounted from it ([why](base-node.md#bind-mounts-onto-moosefs)).

Day-to-day tasks: [MooseFS operations](../procedures/moosefs-operations.md).

## Design

| Role | Node(s) | Why |
|---|---|---|
| Master | `hpc01` | CE supports a single active master |
| Metalogger | `hpc02`, `hpc03` | Continuous metadata backups; one can be promoted if `hpc01` dies |
| Chunkserver | `hpc01`, `hpc02`, `hpc03` | Each NVMe disk is a separate chunk store |
| Client (FUSE) | `hpc01`, `hpc02`, `hpc03` | Mounted at `/mnt/mfs` |

- **Replication goal 2**: every chunk has 2 copies on different nodes. Survives loss of one node; usable ≈ 21 TiB / 2 ≈ 10.5 TiB. Goal 3 would give ~7 TiB. Override per directory with `mfssetgoal`.
- **Raw XFS, no RAID**: MooseFS replicates across nodes, so local RAID would waste capacity. `noatime` reduces SSD writes; `nofail` lets a node boot with a dead disk; labels survive NVMe renumbering.
- **Official MooseFS APT repo** for current 4.x packages instead of Ubuntu universe.
- **Ports**: master 9419 (metaloggers), 9420 (chunkservers), 9421 (clients), chunkserver 9422, CGI web UI 9425.

> **Not a backup.** Replication protects against disk/node loss, not against `rm -rf` or a corrupt master.

## Step 1 — On all nodes: add the MooseFS repository

```bash
sudo apt-get update
sudo apt-get install -y curl gnupg lsb-release ca-certificates xfsprogs

curl -fsSL https://repository.moosefs.com/moosefs.key \
  | sudo gpg --dearmor -o /usr/share/keyrings/moosefs-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/moosefs-archive-keyring.gpg] \
http://repository.moosefs.com/moosefs-4/apt/ubuntu/noble noble main" \
  | sudo tee /etc/apt/sources.list.d/moosefs.list

sudo apt-get update
```

## Step 2 — On all nodes: prepare the two SSDs

> **Destroys all data on both NVMe disks.** Verify device names with `lsblk` first.

```bash
lsblk

sudo wipefs -a /dev/nvme0n1
sudo wipefs -a /dev/nvme1n1
sudo mkfs.xfs -f -L mfschunk1 /dev/nvme0n1
sudo mkfs.xfs -f -L mfschunk2 /dev/nvme1n1

sudo mkdir -p /mnt/mfschunks/chunk1 /mnt/mfschunks/chunk2
echo 'LABEL=mfschunk1  /mnt/mfschunks/chunk1  xfs  defaults,noatime,nofail  0 2' | sudo tee -a /etc/fstab
echo 'LABEL=mfschunk2  /mnt/mfschunks/chunk2  xfs  defaults,noatime,nofail  0 2' | sudo tee -a /etc/fstab

sudo mount -a
df -hT | grep mfschunks
```

## Step 3 — On hpc01: master

```bash
sudo apt-get install -y moosefs-master moosefs-cli moosefs-cgi moosefs-cgiserv
sudo -u mfs cp -n /var/lib/mfs/metadata.mfs.empty /var/lib/mfs/metadata.mfs || true

sudo sed -i 's|^# *WORKING_USER.*|WORKING_USER = mfs|'  /etc/mfs/mfsmaster.cfg
sudo sed -i 's|^# *WORKING_GROUP.*|WORKING_GROUP = mfs|' /etc/mfs/mfsmaster.cfg
sudo sed -i 's|^# *DATA_PATH.*|DATA_PATH = /var/lib/mfs|' /etc/mfs/mfsmaster.cfg
```

`/etc/mfs/mfsexports.cfg` controls who may mount:

```bash
sudo tee /etc/mfs/mfsexports.cfg >/dev/null <<'EOF'
# <client network>     <path>   <options>
*                       .           rw
100.68.8.86              /           rw,alldirs,maproot=0
100.68.8.70              /           rw,alldirs,maproot=0
100.68.8.76              /           rw,alldirs,maproot=0
EOF
```

This is the deployed file: only the three shared nodes may mount the filesystem, and root on them acts as root on it (`maproot=0`). The `* . rw` line only gives access to the meta filesystem (trash and reserved files).

```bash
sudo systemctl enable --now moosefs-master
sudo systemctl enable --now moosefs-cgiserv   # web UI on :9425
sudo systemctl status moosefs-master --no-pager
```

Optional DNS/hosts alias `mfsmaster → hpc01` (already in `/etc/hosts`, see [Base node](base-node.md#name-resolution-etchosts)) makes failover a name change instead of editing every node.

## Step 4 — On hpc02 and hpc03: metaloggers

```bash
sudo apt-get install -y moosefs-metalogger
sudo sed -i 's|^# *MASTER_HOST.*|MASTER_HOST = hpc01.isr-hpc.tp.vps.tecnico.ulisboa.pt|' /etc/mfs/mfsmetalogger.cfg
sudo systemctl enable --now moosefs-metalogger
sudo systemctl status moosefs-metalogger --no-pager
```

## Step 5 — On all nodes: chunkservers

```bash
sudo apt-get install -y moosefs-chunkserver
sudo sed -i 's|^# *MASTER_HOST.*|MASTER_HOST = hpc01.isr-hpc.tp.vps.tecnico.ulisboa.pt|' /etc/mfs/mfschunkserver.cfg

sudo tee /etc/mfs/mfshdd.cfg >/dev/null <<'EOF'
/mnt/mfschunks/chunk1
/mnt/mfschunks/chunk2
EOF

sudo chown -R mfs:mfs /mnt/mfschunks/chunk1 /mnt/mfschunks/chunk2
sudo systemctl enable --now moosefs-chunkserver
sudo systemctl status moosefs-chunkserver --no-pager
```

Each SSD is listed separately so MooseFS balances across disks and survives a single-disk failure without dropping the node. A `*` prefix on a line marks a disk for removal.

## Step 6 — On all nodes: client mount

```bash
sudo apt-get install -y moosefs-client
sudo mkdir -p /mnt/mfs
echo 'mfsmount  /mnt/mfs  fuse  mfsmaster=hpc01.isr-hpc.tp.vps.tecnico.ulisboa.pt,_netdev  0 0' | sudo tee -a /etc/fstab
sudo mount /mnt/mfs
df -hT | grep mfs
```

Then add the [bind mounts](base-node.md#bind-mounts-onto-moosefs).

## Step 7 — Replication goal

Once, from any client:

```bash
sudo mfssetgoal -r 2 /mnt/mfs
mfsgetgoal /mnt/mfs
# Example: triple-replicate something critical
sudo mfssetgoal -r 3 /mnt/mfs/critical-path
```

## Step 8 — Firewall

`hpc01`:

```bash
sudo firewall-cmd --permanent --add-port=9419-9422/tcp
sudo firewall-cmd --permanent --add-port=9425/tcp
sudo firewall-cmd --reload
```

`hpc02`, `hpc03`:

```bash
sudo firewall-cmd --permanent --add-port=9422/tcp
sudo firewall-cmd --reload
```

> Consider restricting these to the private subnet with a firewalld zone or rich rule rather than opening them on all interfaces. See [Security](security.md).

## Step 9 — Verify

```bash
mfscli -SIN   # master info
mfscli -SCS   # chunkservers: all 3 should be listed
mfscli -SHD   # disks: should list 6 (2 per node)
```

Web UI: `http://hpc01.isr-hpc.tp.vps.tecnico.ulisboa.pt:9425/`

Group nodes are **not** part of MooseFS (see [Group nodes](group-nodes.md)).

### Deprecated commands in 4.59

MooseFS 4.59 warns that `mfsgetgoal`/`mfssetgoal` and `mfsgettrashtime`/`mfssettrashtime` are deprecated in favour of storage classes and `mfsgettrashretention`/`mfssettrashretention`. The old commands still work. Current values: trash retention **86400 s (24 h)** on `/mnt/mfs`.

```bash
mfsgetsclass /mnt/mfs              # storage class (replaces goal)
mfsscadmin list                    # defined storage classes
mfsgettrashretention /mnt/mfs
```
