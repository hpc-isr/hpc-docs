# Base node configuration

[← Admin Guide](../README.md) · [Home](../../README.md)

What every node has, independent of its role. Diagram: [Inside a node](../../overview/node-anatomy.md).

## OS

- Ubuntu 24.04 LTS (Noble), cloud image (`Ubuntu-Noble-Latest` on the VPS platform).
- Standard admin account: `ubuntu` (key-based SSH, passwordless `sudo` from the cloud image).

## Name resolution: `/etc/hosts`

Short names for the shared nodes plus the MooseFS master alias. Add on every shared node:

```bash
sudo tee -a /etc/hosts >/dev/null <<'EOF'
100.68.8.86     hpc01   mfsmaster
100.68.8.70     hpc02
100.68.8.76     hpc03
EOF
getent hosts hpc01 hpc02 hpc03 mfsmaster
```

Full names resolve through DNS: `<name>.isr-hpc.tp.vps.tecnico.ulisboa.pt` (private), `<name>.isr.tecnico.ulisboa.pt` (public). See [Hosts](../reference/hosts.md).

## Time sync

SLURM and MUNGE need clocks in sync. Ubuntu uses `systemd-timesyncd` by default:

```bash
timedatectl status | grep -E 'synchronized|NTP'
```

## Disk layout

```text
vda      80G  → vda1 → /                       (ext4, OS only)
vdb     780G ┐
vdc     780G ┴→ scratch_vg/scratch 1.5T → /scratch   (ext4, CEPH-backed, node-local)
nvme0n1 3.5T  → /mnt/mfschunks/chunk1          (xfs, MooseFS chunks)
nvme1n1 3.5T  → /mnt/mfschunks/chunk2          (xfs, MooseFS chunks)
```

### Create the `/scratch` LVM volume

> Wipes `vdb` and `vdc`. Check with `lsblk` first.

```bash
lsblk
sudo apt-get install -y lvm2
sudo pvcreate /dev/vdb /dev/vdc
sudo vgcreate scratch_vg /dev/vdb /dev/vdc
sudo lvcreate -l 100%FREE -n scratch scratch_vg
sudo mkfs.ext4 -L scratch /dev/scratch_vg/scratch
sudo mkdir -p /scratch

UUID=$(sudo blkid -s UUID -o value /dev/scratch_vg/scratch)
echo "UUID=$UUID /scratch ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo mount /scratch
sudo chmod 1777 /scratch      # world-writable with sticky bit, like /tmp
df -h /scratch
```

On the shared nodes the result is `scratch_vg/scratch`, 1.52 TB, mode `drwxrwxrwt root:root`.

### NVMe disks for MooseFS

See [MooseFS → Prepare the SSDs](storage-moosefs.md#step-2--on-all-nodes-prepare-the-two-ssds).

### Bind mounts onto MooseFS

`/` is only 80 GB, so large/growing directories live on MooseFS. After MooseFS is mounted at `/mnt/mfs` (node name in the path for per-node dirs):

```bash
NODE=$(hostname -s)
sudo mkdir -p /mnt/mfs/home /mnt/mfs/opt /mnt/mfs/$NODE/srv /mnt/mfs/$NODE/var/lib/docker

sudo tee -a /etc/fstab >/dev/null <<EOF
/mnt/mfs/home     /home      none    bind    0  0
/mnt/mfs/opt     /opt      none    bind    0  0
/mnt/mfs/$NODE/srv     /srv      none    bind    0  0
/mnt/mfs/$NODE/var/lib/docker     /var/lib/docker      none    bind    0  0
EOF
```

> Move existing contents across **before** mounting over them (e.g. `/home/ubuntu`, anything in `/opt`): `sudo rsync -aHAX /home/ /mnt/mfs/home/`, then `sudo mount -a`.

**Boot ordering caveat:** the bind mounts depend on the FUSE mount. If MooseFS is unreachable at boot, `/home` will be the empty directory on `/`. Consider adding `x-systemd.requires-mounts-for=/mnt/mfs` to the bind lines:

```fstab
/mnt/mfs/home  /home  none  bind,x-systemd.requires-mounts-for=/mnt/mfs  0 0
```

## GPU driver

Installed today: driver **595.71.05** (CUDA 13.2) on `hpc01`/`hpc02`. Keep the shared nodes on the same version; group nodes choose their own.

On `hpc01` the driver is Ubuntu's own server package, `nvidia-driver-595-server` (595.71.05-0ubuntu0.24.04.1). To install or reproduce it on a new shared node:

```bash
sudo apt-get update
sudo apt-get install -y nvidia-driver-595-server
sudo reboot
nvidia-smi
```

Group nodes may use the open-kernel-module variant instead (`sudo apt-get install -y nvidia-driver-595-open`). Both packages support the L40S.

Docker containers that use the GPU also need the NVIDIA Container Toolkit on that host. Apptainer only needs the driver (`apptainer exec --nv`).

## Other base components

| Component | Page |
|---|---|
| LDAP logins (SSSD) | [Configure LDAP/SSSD on a node](../procedures/node-ldap-setup.md) |
| firewalld + fail2ban | [Security](security.md) |
| Docker (service nodes) | [Docker](docker.md) |
