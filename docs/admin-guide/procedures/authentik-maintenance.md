---
title: "Authentik maintenance"
parent: "Procedures"
grand_parent: "Admin Guide"
nav_order: 7
---

# Authentik maintenance

[← Admin Guide](../README.md) · [Home](../../README.md)

Configuration background: [Authentik](../config/identity-authentik.md). Runs on `hpc01` in `/srv/authentik/`.

## Status and logs

```bash
cd /srv/authentik
docker compose ps
docker compose logs -f --tail=100 server worker
```

## Upgrade

Upgrade **one minor version at a time** (e.g. 2026.2 → 2026.4 → …), reading the [release notes](https://docs.goauthentik.io/releases/) for each step, and take a DB backup first.

```bash
cd /srv/authentik

# 1. Backup first (see below), and check it exists
ls -lh db-backups/ | tail

# 2. Get the new compose file and bump the tag
cp compose.yml compose.yml.bak
wget -O compose.yml https://docs.goauthentik.io/compose.yml
sed -i 's/^AUTHENTIK_TAG=.*/AUTHENTIK_TAG=<new-version>/' .env

# 3. Pull and restart (migrations run automatically)
docker compose pull
docker compose up -d
docker compose logs -f server      # watch for migration errors
```

The local changes are in `docker-compose.override.yml`, so replacing `compose.yml` doesn't lose them.

After upgrading, test: web login at <https://sso.isr.tecnico.ulisboa.pt>, and an SSH login on a node (LDAP outpost).

> **TODO:** Confirm the upstream compose file name used in `/srv/authentik` (`compose.yml` vs `docker-compose.yml`).

## Database backups

The `db-backup-pgsql` service in `docker-compose.override.yml` dumps PostgreSQL periodically into `./db-backups`.

```bash
ls -lh /srv/authentik/db-backups/ | tail
```

Current policy: one dump per day (`DB_DUMP_FREQ=1440`), dumps older than 7 days deleted (`DB_CLEANUP_TIME=10080`), gzip + SHA1 checksum.

> **TODO:** There is no copy off the cluster yet. The planned destination is **Anubis**, a NAS. `/srv` is on MooseFS, so until then losing MooseFS would take the backups with it. Also planned (from the original notes): spaced retention, daily for a month, weekly for a year, monthly forever.

### Restore (outline)

```bash
cd /srv/authentik
docker compose stop server worker
gunzip -c db-backups/<file>.sql.gz | docker compose exec -T postgresql psql -U authentik -d authentik
docker compose start server worker
```

> Adjust to the dump format `tiredofit/db-backup` produces, and test a restore once on a scratch copy.

## Certificates

Certificates come from Traefik via `traefik-certificate-exporter`. If the LDAPS or web certificate expires or changes:

1. Check the exporter output files are fresh.
2. In Authentik: **System → Certificates** — confirm the certificate was (re)discovered/imported.
3. **Applications → Providers → LDAP** → certificate selection; **System → Brands** → web certificate.
4. Restart the LDAP outpost if it doesn't pick up the change.

```bash
echo | openssl s_client -connect sso.isr.tecnico.ulisboa.pt:636 2>/dev/null | openssl x509 -noout -subject -dates
```
