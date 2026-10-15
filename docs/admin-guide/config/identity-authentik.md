# Authentik (identity provider, SSO, LDAP)

[← Admin Guide](../README.md) · [Home](../../README.md)

Authentik is the single source of truth for users and groups. Version **2026.5.4** runs on `hpc01` in `/srv/authentik/` (Docker Compose), behind Traefik at <https://sso.isr.tecnico.ulisboa.pt>.

| Container | Role |
|---|---|
| `authentik_server` | Web UI, API, flows; also serves the Traefik forward-auth endpoint |
| `authentik-worker-1` | Background tasks |
| `authentik-postgresql-1` | PostgreSQL 16 (data in `./postgresql`) |
| `authentik-db-backup-pgsql-1` | Daily database dump to `./db-backups` |
| `ak-outpost-ldap-outpost` | LDAP outpost (LDAPS 636), deployed and managed by Authentik through the Docker integration |

- **Apps without their own login** (e.g. the Traefik dashboard) are protected by the `authentik@docker` forward-auth middleware.
- **Linux logins** on every node go through Authentik's **LDAP outpost** (LDAPS, port 636), read by [SSSD](ldap-sssd.md).

Tasks: [Users & groups](../procedures/users-and-groups.md) · [Authentik maintenance](../procedures/authentik-maintenance.md)

## Groups

| Group | Purpose |
|---|---|
| `authentik Admins` | Authentik administrators. Its members are also the admins of `hpc01`–`hpc03`. |
| `dsor`, `irsg`, `laseeb`, `sipg`, `vislab` | One per research group. Every user must be in at least one. |
| `<group>-admins` (suggested, e.g. `dsor-admins`) | Admins of one group node, for sudo there. See [Users & groups](../procedures/users-and-groups.md#give-a-group-admin-sudo-on-their-group-node). |

Each group's admin manages their own group's members and sends its invitations ([Users & groups](../procedures/users-and-groups.md)).

## Install

Following the [official Docker Compose instructions](https://docs.goauthentik.io/install-config/install/docker-compose/):

```bash
sudo mkdir -p /srv/authentik
sudo chown ubuntu:ubuntu /srv/authentik
cd /srv/authentik
wget https://docs.goauthentik.io/compose.yml

# Secrets
echo "AUTHENTIK_TAG=2026.5.4" >> .env
echo "PG_PASS=$(openssl rand -base64 36 | tr -d '\n')" >> .env
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" >> .env
echo "AUTHENTIK_ERROR_REPORTING__ENABLED=true" >> .env
chmod 600 .env
```

Overrides (Traefik labels, `proxy` network, DB backup sidecar, etc.):

```bash
# copy docker-compose.override.yml and post-script.sh into /srv/authentik
chmod +x ./post-script.sh
docker compose up -d
```

Initial setup: <http://sso.isr.tecnico.ulisboa.pt:9000/if/flow/initial-setup/>

Port 9000 is not open in the firewall, so after initial setup Authentik is reachable only through Traefik.

### `/srv/authentik/docker-compose.override.yml`

```yaml
services:
  server:
    container_name: authentik_server
    volumes:
      - ../traefik/certs:/certs           # certificates exported from Traefik
    labels:
      - traefik.enable=true
      - traefik.http.routers.authentik.rule=Host(`sso.isr.tecnico.ulisboa.pt`)
      - traefik.http.routers.authentik.tls.certresolver=letsencrypt
      # Forward-auth middleware other routers can use as "authentik@docker"
      - traefik.http.middlewares.authentik.forwardauth.address=http://authentik_server:9000/outpost.goauthentik.io/auth/traefik
      - traefik.http.middlewares.authentik.forwardauth.trustForwardHeader=true
      - traefik.http.middlewares.authentik.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version,Authorization
    networks:
      - proxy
      - default

  worker:
    volumes:
      - ../traefik/certs:/certs
    env_file:
      - .env

  postgresql:
    volumes:
      - ./postgresql:/var/lib/postgresql/data

  db-backup-pgsql:
    image: tiredofit/db-backup
    restart: always
    volumes:
      - ./db-backups:/backup
      - ./post-script.sh:/assets/custom-scripts/post-script.sh
    environment:
      - DB_TYPE=pgsql
      - DB_HOST=postgresql
      - DB_NAME=${PG_DB:-authentik}
      - DB_USER=${PG_USER:-authentik}
      - DB_PASS=<REDACTED>
      - DB_DUMP_FREQ=1440            # once a day
      - DB_CLEANUP_TIME=10080        # delete dumps older than 7 days
      - CHECKSUM=SHA1
      - COMPRESSION=GZ
      - SPLIT_DB=FALSE
      - CONTAINER_ENABLE_MONITORING=FALSE

networks:
  proxy:
    external: true
```

`post-script.sh` only prints a one-line summary of each backup (exit code, file name, size, checksum) to the container log. Its first line is `##!/bin/bash` (double `#`), so it has no real shebang; that's harmless as long as `db-backup` runs it with a shell.

## Flows

Imported from the [example flows](https://docs.goauthentik.io/add-secure-apps/flows-stages/flow/examples/flows/):

| Blueprint | Purpose |
|---|---|
| `example/flows-enrollment-2-stage.yaml` | Enrollment with email prompt |
| `example/flows-recovery-email-verification.yaml` | Password recovery via email |
| `example/flows-invitation-enrollment.yaml` | Enrollment from an invitation |

### Invitation flow that assigns groups

The invitation flow is customised so an invitation's custom attributes (`fixed_data`) can carry `{"group": ["dsor"]}`, and the new user is added to those groups on enrollment. References:

- <https://docs.goauthentik.io/users-sources/user/invitations/#use-pre-built-blueprints-to-configure-invitations>
- <https://unhexium.net/authentik/authentik-group-assignment-on-invitation-usage/>

> **TODO:** Export the expression policy / stage used for group assignment (Customization → Policies) and paste it here so it can be rebuilt.

## Password recovery

The recovery flow must be set as the brand's recovery flow (System → Brands → your brand → Recovery flow) and an email transport must be configured.

Authentik sends email (invitations, password recovery) through **DSOR's email account**, managed by David Cabecinhas. The settings are the `AUTHENTIK_EMAIL__*` variables in `/srv/authentik/.env`.

## LDAP provider and outpost

Follow [Authentik LDAP provider docs](https://docs.goauthentik.io/add-secure-apps/providers/ldap/). In summary:

1. Create a **service account** user (here `ldapservice`) and give it permission to search the directory.
2. Applications → Providers → Create → **LDAP Provider**: set Base DN, bind flow, search mode (cached), TLS certificate (from the Traefik exporter), and the service account as bind user.
3. Create an **Application** bound to the provider.
4. Outposts → create an **LDAP outpost** for the application (embedded or Docker).
5. Open LDAPS on `hpc01`:

   ```bash
   sudo firewall-cmd --permanent --add-port=636/tcp
   sudo firewall-cmd --reload
   ```

Test from any node:

```bash
sudo apt-get install -y ldap-utils
ldapsearch -x -H ldaps://sso.isr.tecnico.ulisboa.pt \
  -D "cn=ldapservice,ou=users,dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt" -W \
  -b "dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt" "(cn=<username>)" cn uidNumber gidNumber memberOf
```

The deployed SSSD config uses `ldap_search_base = dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt`, matching the bind DN, so the provider's Base DN is `dc=ldap,dc=isr,dc=tecnico,dc=ulisboa,dc=pt`.

## Branding and certificate

- [Brands](https://docs.goauthentik.io/brands/), [Settings](https://docs.goauthentik.io/sys-mgmt/settings/)
- System → Brands → Other global settings → choose the certificate matching the DNS name.

## Integrations

Authentik has many [application integration guides](https://integrations.goauthentik.io) for adding OIDC/SAML apps.
