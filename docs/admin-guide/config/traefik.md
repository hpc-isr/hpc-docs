---
title: "Traefik"
parent: "Configuration"
grand_parent: "Admin Guide"
nav_order: 5
---

# Traefik (reverse proxy)

[← Admin Guide](../README.md) · [Home](../../README.md)

Traefik v3.7 runs on `hpc01` in `/srv/traefik/` and is the only entry point for web traffic (80/443). It gets TLS certificates from Let's Encrypt (HTTP challenge) and routes requests by hostname to containers on the `proxy` Docker network.

| Item | Value |
|---|---|
| Entrypoints | `web` (:80, permanent redirect to HTTPS), `websecure` (:443, TLS) |
| Certificate resolver | `letsencrypt`, HTTP-01 challenge on `web`, stored in `./acme.json` |
| Provider | Docker labels, `exposedbydefault=false`, network `proxy` |
| Dashboard | <https://traefik.hpc.isr.tecnico.ulisboa.pt>, protected by the `authentik@docker` forward-auth middleware |
| Logs / metrics | Access log on, `./logs`; Prometheus metrics enabled |
| Dynamic config | `./dynamic` (mounted read-only) |
| Certificate export | `traefik-certs-dumper` writes `./certs/<domain>/fullchain.pem` and `privkey.pem` |

## `/srv/traefik/docker-compose.yml`

```yaml
services:
  traefik:
    image: traefik:v3.7
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./acme.json:/acme.json
      - ./logs:/logs
      - ./dynamic:/dynamic:ro
    command:
      # EntryPoints
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.websecure.http.tls=true"
      # Providers
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=proxy"
      # API & Dashboard
      - "--api.dashboard=true"
      - "--api.insecure=false"
      # Observability
      - "--log.level=INFO"
      - "--accesslog=true"
      - "--metrics.prometheus=true"
      # Let's Encrypt
      - "--certificatesresolvers.letsencrypt.acme.storage=acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik.hpc.isr.tecnico.ulisboa.pt`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.middlewares=authentik@docker"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.tls=true"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"

  traefik-certs-dumper:
    image: ldez/traefik-certs-dumper:v2.9.3
    entrypoint: sh -c '
      while ! [ -e /acme.json ]
      || ! [ `jq ".[] | .Certificates | length" /acme.json | jq -s "add" ` != 0 ]; do
      sleep 1
      ; done
      && traefik-certs-dumper --domain-subdir file --version v3 --watch
      --source /acme.json --dest /certs --crt-name=fullchain --key-name=privkey --crt-ext=.pem --key-ext=.pem'
    volumes:
      - ./acme.json:/acme.json:ro
      - ./certs:/certs
    network_mode: "none"

networks:
  proxy:
    external: true
```

No ACME email is set (`--certificatesresolvers.letsencrypt.acme.email`), so Let's Encrypt can't warn anyone about expiring certificates if renewal breaks.

## Install from scratch

```bash
docker network create proxy                 # once per host
sudo mkdir -p /srv/traefik/{logs,dynamic,certs}
cd /srv/traefik
touch acme.json && chmod 600 acme.json      # Traefik refuses an acme.json readable by others
# put docker-compose.yml here
docker compose up -d
docker compose logs -f traefik
```

Firewall on `hpc01` (already open): `80/tcp`, `443/tcp`.

## Certificates for other apps

`traefik-certs-dumper` watches `acme.json` and writes one folder per domain under `/srv/traefik/certs/`. Authentik mounts that folder (`../traefik/certs:/certs`) and discovers the certificates for its web brand and LDAPS outpost.

```bash
ls /srv/traefik/certs/
openssl x509 -in /srv/traefik/certs/sso.isr.tecnico.ulisboa.pt/fullchain.pem -noout -subject -dates
```

## Expose a new app

Labels on the app's service in its own `docker-compose.yml`:

```yaml
services:
  myapp:
    image: example/myapp
    networks: [proxy]
    labels:
      - traefik.enable=true
      - traefik.http.routers.myapp.rule=Host(`myapp.isr.tecnico.ulisboa.pt`)
      - traefik.http.routers.myapp.entrypoints=websecure
      - traefik.http.routers.myapp.tls.certresolver=letsencrypt
      - traefik.http.services.myapp.loadbalancer.server.port=8080
      # Optional: require an Authentik login in front of the app
      # - traefik.http.routers.myapp.middlewares=authentik@docker

networks:
  proxy:
    external: true
```

The DNS name must point to `hpc01`'s public IP (`192.92.147.70`) before Let's Encrypt can issue the certificate.
