---
title: "Account administration boundary"
parent: "Procedures"
grand_parent: "Admin Guide"
nav_order: 1
---

# Account administration boundary

Account lifecycle is managed through the institution's approved identity process. Linux identity, group-based system access, scheduler account/QoS associations, sudo privileges, and application access are separate authorization decisions. Changes may take time to propagate through directory and node caches.

Apart from the invitation steps below, this public page does not contain identity-provider API instructions, privileged group names, access-control commands, user records, or administrator rosters. Administrators must use the protected identity and HPC operations procedures. Never commit tokens, bind credentials, populated membership manifests, or user-specific access lists.

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
