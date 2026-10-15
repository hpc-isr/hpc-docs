# Hosts and IPs

[← Admin Guide](../README.md) · [Home](../../README.md)

Private subnet: **`100.68.8.64/27`** on `ens3` (IST VPS platform). Each VM also has a global IPv6 address in `2001:690:2139:203a::/64`. Public IPv4 addresses are floating IPs NAT'd by the platform.

| Node | Private name | Private IP | Public name | Public IPv4 | Role |
|---|---|---|---|---|---|
| `hpc01` | `hpc01.isr-hpc.tp.vps.tecnico.ulisboa.pt` | `100.68.8.86` | `hpc01.isr.tecnico.ulisboa.pt` | `192.92.147.70` | SLURM ctl + compute, MooseFS master, Docker services |
| `hpc02` | `hpc02.isr-hpc.tp.vps.tecnico.ulisboa.pt` | `100.68.8.70` | `hpc02.isr.tecnico.ulisboa.pt` | `192.92.147.104` | SLURM compute, MooseFS metalogger |
| `hpc03` | `hpc03.isr-hpc.tp.vps.tecnico.ulisboa.pt` | `100.68.8.76` | `hpc03.isr.tecnico.ulisboa.pt` | `192.92.147.48` | SLURM compute, MooseFS metalogger |
| `hpc-dsor` | `hpc-dsor.isr-hpc.tp.vps.tecnico.ulisboa.pt` | `100.68.8.71` | `hpc-dsor.isr.tecnico.ulisboa.pt` | `192.92.147.42` | DSOR group node |
| `hpc-irsg` | `hpc-irsg.isr-hpc.tp.vps.tecnico.ulisboa.pt` | `100.68.8.73` | `hpc-irsg.isr.tecnico.ulisboa.pt` | `192.92.147.99` | IRSg group node |
| `hpc-laseeb` | `hpc-laseeb.isr-hpc.tp.vps.tecnico.ulisboa.pt` | `100.68.8.75` | none | none | LaSEEB group node |
| `hpc-sipg` | `hpc-sipg.isr-hpc.tp.vps.tecnico.ulisboa.pt` | `100.68.8.91` | none | none | SIPg group node |
| `hpc-vislab` | `hpc-vislab.isr-hpc.tp.vps.tecnico.ulisboa.pt` | `100.68.8.84` | none | none | VisLab group node |

`/etc/hosts` on the shared nodes:

```text
100.68.8.86     hpc01   mfsmaster
100.68.8.70     hpc02
100.68.8.76     hpc03
```

## Service names

| Name | Points to | Service |
|---|---|---|
| `sso.isr.tecnico.ulisboa.pt` | `192.92.147.70` (hpc01, Traefik) | Authentik web (443), LDAPS (636) |
| `traefik.hpc.isr.tecnico.ulisboa.pt` | hpc01, Traefik | Traefik dashboard (Authentik login required) |
| `mfsmaster` (`/etc/hosts` alias) | `100.68.8.86` | MooseFS master |
| `jupyterhub.hpc.isr.tecnico.ulisboa.pt` | hpc01, Traefik | JupyterHub (admin reference only, not for users) |

"none" means the public name doesn't resolve: `hpc-laseeb`, `hpc-sipg` and `hpc-vislab` have no public DNS name, so users reach them from inside IST's network or through [IST's VPN](https://si.tecnico.ulisboa.pt/en/servicos/redes-e-conetividade/vpn/).

Networks that only one group node uses (VPNs, a group's own storage servers) are listed in that group's guide, e.g. hpc-dsor (not yet published).
