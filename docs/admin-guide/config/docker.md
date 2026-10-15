# Docker

[← Admin Guide](../README.md) · [Home](../../README.md)

Docker hosts the infrastructure services (Traefik, Authentik) on `hpc01`.

## Rules of thumb

- Each app lives in `/srv/<app>/` with a `docker-compose.yml`.
- **No named Docker volumes.** Use bind-mounted folders inside the app folder (`./data`, `./db`, …) so everything about an app is in one directory.
- **Secrets only in `.env`** (mode `600`), never in `docker-compose.yml`.
- When upstream ships a standard compose file (e.g. Authentik), don't edit it; put changes in `docker-compose.override.yml` so upgrades are a file swap.
- Every database gets a `db-backup` sidecar (`tiredofit/db-backup`) dumping to `./db-backups`:

  ```yaml
  db-backup:
    image: tiredofit/db-backup
    # (...)
  ```

- Apps reachable from outside join the external `proxy` network so Traefik can reach them.

## Install Docker CE

From the [official instructions](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository):

```bash
# Docker's GPG key
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Repository
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Post-install

```bash
# Let ubuntu run docker without sudo (log out and in again)
sudo usermod -aG docker ubuntu

# Shared network for Traefik
docker network create proxy
```

## Common commands

```bash
cd /srv/<app>
docker compose up -d          # start / apply changes
docker compose ps             # status
docker compose logs -f --tail=100
docker compose pull && docker compose up -d   # update images
docker compose down           # stop
```

## Docker data on MooseFS

`/var/lib/docker` is a bind mount of `/mnt/mfs/hpc01/var/lib/docker` (FUSE). `docker info` on `hpc01` reports storage driver `overlayfs` (the containerd image store), and the services run fine on it.

Keep an eye on it after Docker upgrades: if the driver ever falls back to `vfs`, images take far more space and start slowly. In that case, move `/var/lib/docker` (and `/var/lib/containerd`) to `/scratch` and keep only app data (`/srv`) on MooseFS.

> **Docker group = root.** Anyone in the `docker` group can get root on the host. Don't add regular users to it.
