---
title: "Users & groups"
parent: "Procedures"
grand_parent: "Admin Guide"
nav_order: 1
---

# Users & groups

[← Admin Guide](../README.md) · [Home](../../README.md)

Users and groups are managed **only in Authentik** (<https://sso.isr.tecnico.ulisboa.pt>). Nodes pick them up through LDAP/SSSD; never create regular users with `adduser` on a node.

How it flows: Authentik user/group → LDAP outpost → SSSD on each node → `getent`/SSH/SLURM.

## Add a new user (invitation, recommended)

Each group's admin invites the people of their own group and manages that group's members. The user picks their own username and password; you decide their group. Invitation emails go out through DSOR's email account ([Authentik → Password recovery](../config/identity-authentik.md#password-recovery)).

1. Log in to <https://sso.isr.tecnico.ulisboa.pt> and open the **Admin interface**.
2. Go to **Directory → Invitations → Create**.
3. Choose the invitation-enrollment flow, set an expiry, tick **single use**.
4. In **Custom attributes**, set the group(s):

   ```yaml
   group: ["dsor"]
   ```

   Several groups: `group: ["dsor", "dsor-admins"]`. Valid research groups: `dsor`, `irsg`, `laseeb`, `sipg`, `vislab` (or any Authentik group).
5. Save, then **send the link by email** from the invitation's page (or copy the link and send it yourself).
6. Tell the user: the email they register must be valid; it's their only way to recover a password. Point them to [Getting an account](../../user-guide/01-getting-an-account.md).

### Same thing via the API (optional)

For scripting. Create an API token in **Directory → Tokens and App passwords** (intent: API).

```bash
AK=https://sso.isr.tecnico.ulisboa.pt
TOKEN=<api-token>

# Find the invitation flow's slug/UUID
curl -s -H "Authorization: Bearer $TOKEN" "$AK/api/v3/flows/instances/?designation=enrollment" | jq '.results[] | {slug, pk}'

# Create a single-use invitation for DSOR, valid 7 days
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$AK/api/v3/stages/invitation/invitations/" \
  -d "{\"name\": \"dsor-$(date +%s)\", \"single_use\": true,
       \"expires\": \"$(date -u -d '+7 days' +%Y-%m-%dT%H:%M:%SZ)\",
       \"flow\": \"<flow-uuid>\",
       \"fixed_data\": {\"group\": [\"dsor\"]}}" | jq '.pk'
# Link: $AK/if/flow/<flow-slug>/?itoken=<invitation-pk>
```

> Check endpoint names against your version's API browser at `$AK/api/v3/` if anything 404s.

## Add a user directly (no invitation)

1. **Directory → Users → Create**: username, name, email.
2. Open the user → **Set password** (or **Send recovery link** so they set it themselves).
3. **Groups** tab → **Add to existing group** → pick the research group.

## Create a new group

1. **Directory → Groups → Create**. Name in lowercase, no spaces (it becomes a Linux group name, e.g. `dsor`).
2. Optional parent group, and attributes.
3. Verify on a node (may take a few minutes for the LDAP outpost cache and SSSD cache):

   ```bash
   sudo sss_cache -G             # drop SSSD's group cache
   getent group <group>
   ```

Use the group on the nodes, e.g. to restrict a group node ([SSSD access](node-ldap-setup.md#5-restrict-logins-to-a-group-group-nodes)), a SLURM partition ([AllowGroups](slurm-operations.md#restrict-a-partition-to-groups)), or sudo (below).

## Assign a user to a group

1. **Directory → Groups → <group> → Users → Add existing user**, or
2. **Directory → Users → <user> → Groups → Add to existing group**.

API:

```bash
# Get IDs
USER_PK=$(curl -s -H "Authorization: Bearer $TOKEN" "$AK/api/v3/core/users/?username=<username>" | jq '.results[0].pk')
GROUP_ID=$(curl -s -H "Authorization: Bearer $TOKEN" "$AK/api/v3/core/groups/?name=<group>" | jq -r '.results[0].pk')

# Add
curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$AK/api/v3/core/groups/$GROUP_ID/add_user/" -d "{\"pk\": $USER_PK}"
```

Verify on a node:

```bash
sudo sss_cache -u <username>
id <username>
```

The user must log out and back in for a new group to apply to their session.

## Reset a password

- **User does it:** login page → enter username → **Forgot password?** → email link.
- **Admin does it:** **Directory → Users → <user> → Set password**, or **Send recovery link**.

## Disable or remove a user

1. **Directory → Users → <user> → Deactivate**. Prefer deactivate over delete so the UID isn't reused and file ownership stays readable.
2. On nodes, clear the cache so they can't use cached credentials:

   ```bash
   sudo sss_cache -u <username>
   ```

3. Kill running sessions and jobs:

   ```bash
   sudo pkill -u <username>
   scancel -u <username>          # on hpc01
   ```

4. Decide what to do with `/home/<username>` (archive, hand over to supervisor).

## Add an LDAP user to a local group (e.g. `docker`, `render`)

`usermod -aG` only works for users in `/etc/passwd`. For LDAP users use `gpasswd`:

```bash
sudo gpasswd -a <username> docker
getent group docker
```

This edits `/etc/group` on **that node only**. Repeat on each node. Remember `docker` membership is root-equivalent.

## Give a group admin sudo on their group node

Both ways are in use: a per-group admin group in Authentik (preferred, since each admin uses their own account and sudo logs show who did what) and the local `ubuntu` account as a fallback when LDAP is unavailable.

1. In Authentik, create the group `<group>-admins` (e.g. `dsor-admins`) and add the group's admins (**Directory → Groups → Create**).
2. On the group node, create a sudoers drop-in:

   ```bash
   echo '%dsor-admins ALL=(ALL:ALL) ALL' | sudo tee /etc/sudoers.d/90-dsor-admins
   sudo chmod 440 /etc/sudoers.d/90-dsor-admins
   sudo visudo -c
   ```

3. Check as the admin: `sudo -l`.

On the shared nodes, the admins are the members of `authentik Admins`. Group names with spaces must be escaped in sudoers:

```bash
echo '%authentik\ Admins ALL=(ALL:ALL) ALL' | sudo tee /etc/sudoers.d/90-authentik-admins
sudo chmod 440 /etc/sudoers.d/90-authentik-admins
sudo visudo -c
```

## Check a user from a node

```bash
getent passwd <username>          # exists? UID, home, shell
id <username>                     # groups
sudo sssctl user-checks <username> # full NSS + PAM check
sudo sss_cache -E                 # clear all SSSD caches if data looks stale
```
