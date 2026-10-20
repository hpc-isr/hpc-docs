---
title: "Account administration boundary"
parent: "Procedures"
grand_parent: "Admin Guide"
nav_order: 1
---

# Account administration boundary

Account lifecycle is managed through the institution's approved identity process. Linux identity, group-based system access, scheduler account/QoS associations, sudo privileges, and application access are separate authorization decisions. Changes may take time to propagate through directory and node caches.

Every ISR group admin is responsible for managing their own group's users. Only they should add users to their own `hpc-<group>` group. Users and groups are managed in Authentik. Remember to also add the user to the appropriate Slurm group.

> **TODO:** Describe the Slurm groups better and add the steps to add a user to them.

For a user account request, see [Getting an account](../../user-guide/01-getting-an-account.md).

## Add a user

New users register themselves through an invitation link that an admin creates in Authentik. The link lets them choose their own username, password, name and email in the SSO.

1. Log in to the [ISR SSO](https://sso.isr.tecnico.ulisboa.pt).
2. Open the **Admin interface**.
3. Go to **Directory > Invitations** and choose **New Invitation**.
4. Assign the new user to their group(s) by adding this custom attribute to the invitation:

   ```yaml
   {group: ["dsor"]}
   ```

   The value is a comma-separated list, for example `{group: ["dsor", "vislab"]}`. Use one or more of:

   - `dsor`
   - `irsg`
   - `laseeb`
   - `sipg`
   - `vislab`
   - any other existing Authentik group

5. Send the invitation to the user's email. You can email it directly from the Authentik UI.

When the user opens the invitation link, they choose their username, password, name and email. **The email must be valid, because it is used for password recovery.**

The user-side steps are in [Getting an account](../../user-guide/01-getting-an-account.md).
