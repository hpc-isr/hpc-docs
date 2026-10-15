# JupyterHub

[← Admin Guide](../README.md) · [Home](../../README.md)

> **Reference configuration only.** JupyterHub was deployed on `hpc01` and is **being stopped there** (`docker compose down` in `/srv/jupyterhub`); the files stay. It is kept as a working example for group admins who want to run their own JupyterHub on their own machines. It is not offered to users, and the user guide does not mention it.

The example lives on `hpc01` in `/srv/jupyterhub/`, behind Traefik at <https://jupyterhub.hpc.isr.tecnico.ulisboa.pt>.

## How it works

| Aspect | Setting |
|---|---|
| Hub container | `jupyterhub`, built locally from `Dockerfile.jupyterhub` (`JUPYTERHUB_VERSION: latest`), runs as root |
| Login | **PAM through SSSD** (`PAMAuthenticator`, PAM service `jupyterhub` created in the Dockerfile). Users type their Authentik username and password; Authentik's OIDC is not used. |
| Who may log in | Any user SSSD accepts (`allow_all = True`) |
| Admins | `dcabecinhas` |
| Spawner | `dockerspawner.SystemUserSpawner`: each user gets a container running as their real UID/GID, with `/home/<username>` mounted from the host |
| Notebook image | `quay.io/jupyter/pytorch-notebook:x86_64-cuda13-python-3.13` |
| GPU | Every notebook gets **all** GPUs on `hpc01` (`DeviceRequest(count=-1)`) |
| Network | Hub and notebooks on the `proxy` Docker network; notebooks reach the hub at `jupyterhub:8080` |
| State | `./data/jupyterhub.sqlite`, cookie secret in `./data` |
| Timeouts | 300 s start and HTTP timeouts (large images take a while to pull) |

To make host users visible inside the hub, the compose file mounts the host's `/etc/nsswitch.conf`, `/etc/passwd`, `/etc/group`, the SSSD sockets (`/var/lib/sss/pipes`, `/run/sssd`) and `/home`. It also mounts the Docker socket so the hub can start notebook containers. That makes the hub container root-equivalent on `hpc01`.

## `/srv/jupyterhub/jupyterhub_config.py`

```python
import os

c = get_config()  # noqa: F821

c.JupyterHub.bind_url = "http://:8000"
c.JupyterHub.forwarded_host_header = "X-Forwarded-Host"

# Authenticate using PAM (service /etc/pam.d/jupyterhub, created in the Dockerfile)
c.JupyterHub.authenticator_class = "jupyterhub.auth.PAMAuthenticator"
c.PAMAuthenticator.service = "jupyterhub"
c.Authenticator.allow_all = True
c.Authenticator.admin_users = {'dcabecinhas'}

# Spawn each user as a real system user inside Docker
c.JupyterHub.spawner_class = "dockerspawner.SystemUserSpawner"
c.DockerSpawner.image = os.environ.get("DOCKER_NOTEBOOK_IMAGE", "jupyter/minimal-notebook:latest")
c.SystemUserSpawner.host_homedir_format_string = "/home/{username}"
c.SystemUserSpawner.image_homedir_format_string = "/home/{username}"
c.SystemUserSpawner.notebook_dir = "/home/{raw_username}"
c.SystemUserSpawner.run_as_root = True
c.SystemUserSpawner.environment = {"CHOWN_HOME": "yes"}

network_name = os.environ["DOCKER_NETWORK_NAME"]
c.SystemUserSpawner.use_internal_ip = True
c.SystemUserSpawner.network_name = network_name

c.Spawner.start_timeout = 300
c.Spawner.http_timeout = 300

# GPU support
from docker.types import DeviceRequest
c.SystemUserSpawner.extra_host_config = {
    "device_requests": [DeviceRequest(count=-1, capabilities=[["gpu"]])]
}

c.JupyterHub.hub_ip = "jupyterhub"
c.JupyterHub.hub_port = 8080

c.JupyterHub.cookie_secret_file = <REDACTED>
c.JupyterHub.db_url = "sqlite:////data/jupyterhub.sqlite"
```

The compose file (`/srv/jupyterhub/docker-compose.yml`) builds the hub image, sets `DOCKER_NETWORK_NAME=proxy` and `DOCKER_NOTEBOOK_IMAGE`, mounts the paths listed above, and has the Traefik labels for `jupyterhub.hpc.isr.tecnico.ulisboa.pt` with the `letsencrypt` resolver.

## Operations

```bash
cd /srv/jupyterhub
docker compose ps
docker compose logs -f --tail=100 hub
docker ps --filter "name=jupyter-"          # running user notebook containers
docker compose build --pull && docker compose up -d   # update the hub (JUPYTERHUB_VERSION is "latest")
docker pull quay.io/jupyter/pytorch-notebook:x86_64-cuda13-python-3.13   # update the notebook image
```

Stop a user's server from the admin panel (**Admin** in the hub's top menu) or with `docker stop jupyter-<username>`.

## Things to adapt when you reuse it

- **GPU sharing.** Notebooks get the host's GPU directly. On a machine that also runs SLURM (like `hpc01`), SLURM doesn't know about them, so a GPU job and any number of notebooks can end up on the same card. That is one reason it shouldn't be used on `hpc01`. On a SLURM host, spawn notebooks through SLURM with `batchspawner` instead.
- **Who may log in.** `allow_all = True` admits every Authentik user. On a group node, set `c.Authenticator.allowed_groups = {"<group>"}` (PAM groups) instead.
- **Unpinned versions.** `JUPYTERHUB_VERSION: latest` means a rebuild can silently jump versions.

> **TODO:** Paste `Dockerfile.jupyterhub` (redacted) to document how the PAM service and `dockerspawner` are installed.
