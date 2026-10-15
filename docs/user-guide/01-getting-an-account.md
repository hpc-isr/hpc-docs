# Getting an account

[← User Guide](README.md) · [Home](../README.md)

One account gives you access to every ISR HPC service: SSH on the nodes, SLURM, and web apps such as the wiki. Accounts live in **Authentik**, ISR's single sign-on at <https://sso.isr.tecnico.ulisboa.pt>.

## 1. Ask for an invitation

Ask your group's admin (see [Who's who](../overview/contacts.md)) for an invitation. Tell them which research group you belong to.

## 2. Accept the invitation

You will receive an email with a link. Opening it lets you choose:

- **Username**: this is what you will type for `ssh <username>@…`. Use lowercase letters and digits only; it cannot easily be changed later.
- **Password**
- **Name**
- **Email**: must be a **real, working address**. It is the only way to recover a forgotten password.

## 3. Log in

```bash
ssh <username>@hpc01.isr.tecnico.ulisboa.pt
```

Continue with [SSH login](02-ssh-login.md).

## Forgot your password?

1. Go to <https://sso.isr.tecnico.ulisboa.pt>.
2. Enter your **username** and continue.
3. On the password prompt click **Forgot password?**.
4. Follow the link sent to your registration email.

If you no longer have access to that email, ask your group admin to set a new password for you.

## Change your password

Change it in the web portal at <https://sso.isr.tecnico.ulisboa.pt> (user settings). The `passwd` command on the nodes will **not** work, because passwords are stored in Authentik, not on the machines.

> A new password can take a few minutes to be accepted on every node, because nodes cache credentials.
