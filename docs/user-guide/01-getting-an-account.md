---
title: "Getting an account"
parent: "User Guide"
nav_order: 1
---

# Getting an account

[← User Guide](README.md) · [Home](../README.md)

Accounts are managed in **Authentik**, ISR's single sign-on at <https://sso.isr.tecnico.ulisboa.pt>. Creating an identity account does not by itself authorize access to every node, group system, partition, Slurm account, or web application. Your group's admin must confirm your exact HPC POSIX login and provision the services you are eligible to use.

## 1. Ask for an invitation

Ask your group's admin (see [Who's who](../overview/contacts.md)) for an invitation. Tell them which research group you belong to.

## 2. Accept the invitation

You will receive an email with a link. Opening it lets you choose:

- **Username**: this is what you will type for `ssh <username>@…`. Use the identifier accepted or assigned by Authentik and keep its exact spelling. Do not assume that the login contains only lowercase letters and digits; some existing POSIX logins include an email-style identifier. If the login shown by Authentik differs from the POSIX login given by your group administrator, ask them which exact name to use for SSH.
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
