# SLURM operations

[← Admin Guide](../README.md) · [Home](../../README.md)

Run on `hpc01` with `sudo` (or as root). Configuration background: [SLURM](../config/slurm.md).

## Cluster state

```bash
scontrol ping                 # is the controller up?
sinfo                         # partitions
sinfo -Nel                    # per node, long format
sinfo -R                      # why nodes are down/drained
scontrol show node hpc02      # full node detail (CPU/mem/GRES allocated)
squeue                        # all jobs
squeue -o "%.10i %.9P %.20j %.10u %.2t %.10M %.6D %R %b"   # with GRES column
```

## Maintenance on a node

```bash
# Stop new jobs landing; running jobs finish
sudo scontrol update NodeName=hpc02 State=DRAIN Reason="kernel update"

# Wait until no jobs remain on it
squeue -w hpc02

# ... do the work, reboot ...

sudo scontrol update NodeName=hpc02 State=RESUME
```

A node that rebooted unexpectedly usually returns by itself (`ReturnToService=2`). If it's stuck `down`:

```bash
sinfo -R
sudo scontrol update NodeName=hpc02 State=RESUME
```

## Manage jobs

```bash
scontrol show job <jobid>
sudo scancel <jobid>                 # cancel one
sudo scancel -u <username>           # cancel all of a user's jobs
sudo scontrol hold <jobid>           # keep pending
sudo scontrol release <jobid>
sudo scontrol requeue <jobid>        # put a running job back in the queue
sudo scontrol update JobId=<jobid> TimeLimit=2-00:00:00   # extend time
```

## Change configuration

Edit on `hpc01`, copy to all nodes, then reload:

```bash
sudo nano /etc/slurm/slurm.conf
for n in hpc02 hpc03; do sudo rsync -av /etc/slurm/slurm.conf /etc/slurm/cgroup.conf root@$n:/etc/slurm/; done
sudo scontrol reconfigure
```

`scontrol reconfigure` is enough for most changes (partitions, limits). Adding/removing nodes or changing ports/plugins needs a restart:

```bash
sudo systemctl restart slurmctld
for n in hpc01 hpc02 hpc03; do ssh root@$n systemctl restart slurmd; done
```

Copying as `root@` needs temporary root SSH. Without it, copy to `ubuntu@$n:/tmp/` and `sudo mv` on each node.

## Restrict a partition to groups

```bash
getent group dsor irsg laseeb sipg vislab     # all must resolve
sudo sed -i 's/^PartitionName=normal .*/& AllowGroups=dsor,irsg,laseeb,sipg,vislab/' /etc/slurm/slurm.conf
# distribute as above, then
sudo scontrol reconfigure
scontrol show partition normal | grep AllowGroups
```

## Set limits (time, memory)

```bash
# Default and max wall time on the partition
sudo sed -i -E 's/^(PartitionName=normal .*)MaxTime=INFINITE/\1MaxTime=3-00:00:00 DefaultTime=01:00:00/' /etc/slurm/slurm.conf
# Default memory per allocated core (MB), ~440 GB / 56 cores
grep -q '^DefMemPerCPU' /etc/slurm/slurm.conf || echo 'DefMemPerCPU=7800' | sudo tee -a /etc/slurm/slurm.conf
# distribute, then
sudo scontrol reconfigure
```

## Add a node

1. Prepare it ([New node checklist](new-node-checklist.md)): `/etc/hosts`, SSSD, MUNGE key, `slurmd` package.
2. Get its hardware line: `ssh root@<new> slurmd -C | head -1`
3. Add a `NodeName=…` line to `slurm.conf` (with `Gres=gpu:l40s:1` if GRES is configured) and the node to the partition's `Nodes=` list; add it to `gres.conf`.
4. Copy `slurm.conf`, `cgroup.conf`, `gres.conf` to **all** nodes, restart `slurmctld` and every `slurmd`.
5. `sinfo -Nel` → new node `idle`.

## Accounting: accounts and users (if `slurmdbd` is enabled)

One account per research group lets you see and balance usage by group.

```bash
for g in dsor irsg laseeb sipg vislab; do
  sudo sacctmgr -i add account $g Description="ISR $g" Organization=isr
done

sudo sacctmgr -i add user <username> Account=dsor
sudo sacctmgr show assoc format=Account,User,Share,GrpTRES

# Usage report for the last month
sudo sreport cluster AccountUtilizationByUser start=$(date -d '-1 month' +%F) -t hours
sacct -a -S $(date -d '-1 day' +%F) --format=JobID,User,Account,State,Elapsed,AllocTRES%40
```

> Accounting is being enabled by a colleague of David's, who will document the setup here. When it is:
>
> **TODO:** add `AccountingStorageEnforce=associations,limits` so users without an account can't submit, and document how new users get an association (manual `sacctmgr` step in [Users & groups](users-and-groups.md), or a script).

## Logs

```bash
sudo journalctl -u slurmctld -n 200 --no-pager
sudo tail -f /var/log/slurm/slurmctld.log
ssh root@hpc02 'tail -n 100 /var/log/slurm/slurmd.log'
```
