# New node checklist

[← Admin Guide](../README.md) · [Home](../../README.md)

Order of work when a VM is (re)provisioned. Tick each box as you go.

## Every node

- [ ] DNS: `<name>.isr-hpc.tp.vps.tecnico.ulisboa.pt` and `<name>.isr.tecnico.ulisboa.pt` resolve (`getent hosts <name>.isr.tecnico.ulisboa.pt`).
- [ ] Log in as `ubuntu`, update: `sudo apt-get update && sudo apt-get -y full-upgrade && sudo reboot`
- [ ] Hostname: `sudo hostnamectl set-hostname <name>`
- [ ] `/etc/hosts` entries ([Base node](../config/base-node.md#name-resolution-etchosts))
- [ ] Time sync OK (`timedatectl`)
- [ ] firewalld + fail2ban ([Security](../config/security.md))
- [ ] `/scratch` LVM on the CEPH volumes ([Base node](../config/base-node.md#create-the-scratch-lvm-volume))
- [ ] NVIDIA driver, `nvidia-smi` shows the L40S ([Base node](../config/base-node.md#gpu-driver))
- [ ] SSSD / LDAP logins ([Configure LDAP/SSSD](node-ldap-setup.md))
- [ ] Test login as a normal user

## Shared cluster node (`hpc01`–`hpc03`) additionally

- [ ] NVMe disks formatted and mounted, MooseFS chunkserver + client ([MooseFS](../config/storage-moosefs.md))
- [ ] Bind mounts `/home`, `/opt`, `/srv`, `/var/lib/docker` ([Base node](../config/base-node.md#bind-mounts-onto-moosefs))
- [ ] MUNGE key copied, `slurmd` installed, config copied ([SLURM](../config/slurm.md))
- [ ] Node added to `slurm.conf` ([Add a node to SLURM](slurm-operations.md#add-a-node))
- [ ] `sinfo` shows it `idle`; `srun -w <name> --gres=gpu:1 nvidia-smi -L` works
- [ ] If it replaced a failed node: `mfscli -SCS` shows it, replication catches up (`mfscli -SIG`)

## Group node additionally

- [ ] Restrict logins to the group ([step 5](node-ldap-setup.md#5-restrict-logins-to-a-group-group-nodes))
- [ ] Sudo for the group admin ([Users & groups](users-and-groups.md#give-a-group-admin-sudo-on-their-group-node))
- [ ] Storage set up as the group chooses (e.g. CEPH volumes in LVM + bind mounts; see the [baseline](../config/group-nodes.md#what-all-group-nodes-should-have))
- [ ] Tell the group admin it's ready

## Afterwards

- [ ] Remove any temporary root SSH keys (`sudo rm /root/.ssh/authorized_keys` or edit it).
- [ ] Update [Hosts](../reference/hosts.md) with the IPs.
