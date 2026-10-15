# MooseFS operations

[← Admin Guide](../README.md) · [Home](../../README.md)

Configuration background: [MooseFS](../config/storage-moosefs.md).

## Health check

```bash
mfscli -SIN    # master info, total/free space
mfscli -SCS    # chunkservers: expect hpc01, hpc02, hpc03
mfscli -SHD    # disks: expect 6
mfscli -SIG    # chunks by goal / under-replicated counts
mfscli -SMO    # master operation counters
df -h /mnt/mfs
```

Web UI: `http://hpc01.isr-hpc.tp.vps.tecnico.ulisboa.pt:9425/` (look for "undergoal" or "missing" chunks; both should be 0).

Services:

```bash
systemctl status moosefs-master moosefs-cgiserv --no-pager     # hpc01
systemctl status moosefs-metalogger --no-pager                  # hpc02, hpc03
systemctl status moosefs-chunkserver --no-pager                 # all
```

## Replication goals

MooseFS 4.59 prints a deprecation warning for the `goal` and `trashtime` commands below; they still work. The newer equivalents are storage classes (`mfsgetsclass`, `mfssetsclass`, `mfsscadmin`) and `mfsgettrashretention`/`mfssettrashretention`.

```bash
mfsgetgoal /mnt/mfs/home
sudo mfssetgoal -r 3 /mnt/mfs/<important-dir>   # 3 copies
```

## Trash (recover deleted files)

Deleted files are kept 24 h by default.

```bash
mfsgettrashtime /mnt/mfs
sudo mfssettrashtime -r 604800 /mnt/mfs/home      # 7 days for /home
```

To restore, mount the meta filesystem and move the file out of `trash`:

```bash
sudo mkdir -p /mnt/mfsmeta
sudo mfsmount -m /mnt/mfsmeta -H hpc01.isr-hpc.tp.vps.tecnico.ulisboa.pt
sudo find /mnt/mfsmeta/trash -name '*<filename>*'
# Each trash entry is named <inode>|<original/path>; moving it into the 'undel' dir restores it:
sudo mv "/mnt/mfsmeta/trash/<entry>" /mnt/mfsmeta/trash/undel/
sudo umount /mnt/mfsmeta
```

> Check `man mfsmount` for the meta-mount layout of your MooseFS version; newer versions split `trash` into subdirectories.

## Quotas

```bash
sudo mfssetquota -L 500GiB /mnt/mfs/home/<username>     # hard size limit
mfsgetquota /mnt/mfs/home/<username>
mfsdirinfo -h /mnt/mfs/home/<username>                    # usage
```

> **TODO:** Quotas are not set today; the policy is still to be defined (per user, per group, or none).

## Add a disk

```bash
sudo mkfs.xfs -f -L mfschunk3 /dev/<new-disk>
sudo mkdir -p /mnt/mfschunks/chunk3
echo 'LABEL=mfschunk3  /mnt/mfschunks/chunk3  xfs  defaults,noatime,nofail  0 2' | sudo tee -a /etc/fstab
sudo mount /mnt/mfschunks/chunk3
sudo chown mfs:mfs /mnt/mfschunks/chunk3
echo '/mnt/mfschunks/chunk3' | sudo tee -a /etc/mfs/mfshdd.cfg
sudo systemctl reload moosefs-chunkserver
mfscli -SHD
```

## Remove a disk safely

Prefix it with `*` so MooseFS copies its chunks elsewhere first:

```bash
sudo sed -i 's|^/mnt/mfschunks/chunk2$|*/mnt/mfschunks/chunk2|' /etc/mfs/mfshdd.cfg
sudo systemctl reload moosefs-chunkserver
watch mfscli -SHD          # wait until the disk shows no chunks / "ready to remove"
```

Then remove the line, reload, unmount.

## Take a node out for maintenance

With goal 2 and three chunkservers, one node can be offline without losing data, but files will be under-goal until it returns. Drain it in SLURM first ([SLURM operations](slurm-operations.md#maintenance-on-a-node)), then reboot. Afterwards check `mfscli -SIG` until no chunks are under-goal.

## Back up the master metadata

Metaloggers protect against losing `hpc01`'s disk, not against human error. Also copy metadata off the cluster regularly:

```bash
# On hpc01, e.g. from a daily cron job
sudo tar czf /scratch/mfs-meta-$(date +%F).tgz -C /var/lib/mfs metadata.mfs.back changelog.*.mfs
# then copy off-cluster
```

> **TODO:** There is no off-cluster backup yet. The planned destination is **Anubis**, a NAS. Until then `/home` has no backup; it relies on MooseFS's two copies and 24 h trash.

## Recovering from loss of hpc01 (master)

If `hpc01` is gone for good, promote a metalogger (e.g. `hpc02`):

```bash
# On hpc02
sudo apt-get install -y moosefs-master moosefs-cli moosefs-cgi moosefs-cgiserv
sudo systemctl stop moosefs-metalogger
cd /var/lib/mfs
sudo cp metadata_ml.mfs.back metadata.mfs.back
for f in changelog_ml.*.mfs; do sudo cp "$f" "${f/_ml/}"; done
sudo chown mfs:mfs /var/lib/mfs/*
sudo mfsmaster -a          # rebuild metadata from backup + changelogs
sudo systemctl enable --now moosefs-master
# copy mfsexports.cfg from documentation / backup
```

Then point everything at the new master: change `mfsmaster` in `/etc/hosts` (and DNS CNAME, if used), `MASTER_HOST` in `mfschunkserver.cfg`/`mfsmetalogger.cfg`, and the `mfsmaster=` option in each node's `/etc/fstab`; restart chunkservers and remount clients.

> `hpc01` also runs the SLURM controller and Authentik (whose data is in `/srv` on MooseFS). After the filesystem is back, those need to be brought up on the new node too. **TODO:** write a full "hpc01 lost" runbook.

> **Tip:** Using the name `mfsmaster` everywhere (fstab, cfg files) instead of `hpc01.isr-hpc…` turns failover into a one-line `/etc/hosts` (or DNS) change. The current fstab uses the full `hpc01` name.
