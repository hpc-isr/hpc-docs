---
title: "Network"
parent: "Overview"
nav_order: 2
---

# Network

[← Overview](README.md) · [Home](../README.md)

This page shows how to reach the machines and how a request travels from your laptop to a job. It is the user's view: internal addresses and services are kept in the restricted administrator documentation.

## How to connect

| You want to… | Connect to | From where |
|---|---|---|
| Use the shared cluster | `ssh <username>@hpc01.isr.tecnico.ulisboa.pt` | Anywhere on the internet |
| Use your group's node | `ssh <username>@hpc-<group>.isr.tecnico.ulisboa.pt` | Ask your group's admin for the exact name |

`<username>` is the one you chose when you accepted your invitation. Details, SSH keys and a shortcut for `~/.ssh/config` are in [SSH login](../user-guide/02-ssh-login.md).

You only ever log in to `hpc01` or your group's node. You do **not** log in to `hpc02` and `hpc03` yourself: SLURM starts your job there (you can only open an SSH session on them while you have a job running on that node).

## How a job reaches a GPU

```mermaid
%%{init: {"theme": "base", "flowchart": {"curve": "basis", "nodeSpacing": 40, "rankSpacing": 50, "padding": 12}, "themeVariables": {"fontFamily": "Inter, Segoe UI, Helvetica Neue, Arial, sans-serif", "fontSize": "15px", "primaryColor": "#ffffff", "primaryBorderColor": "#94a3b8", "primaryTextColor": "#1e293b", "lineColor": "#64748b", "clusterBkg": "#f8fafc", "clusterBorder": "#cbd5e1", "edgeLabelBackground": "#ffffff"}}}%%
flowchart LR
    ME(["<b>You</b><br/>any computer"])
    NET{"campus network<br/>or IST VPN"}
    subgraph CLUSTER["ISR HPC cluster"]
        direction LR
        H1["<b>hpc01</b><br/>login + SLURM"]
        subgraph COMPUTE["Compute nodes with GPUs"]
            direction TB
            H2["<b>hpc02</b>"]
            H3["<b>hpc03</b>"]
            GN["<b>hpc-&lt;group&gt;</b><br/>your group's node"]
        end
        STORE[("<b>/home</b> · <b>/storage</b><br/>seen identically by<br/>all these nodes")]
        SSO["<b>Single sign-on</b><br/>checks your username<br/>and password"]
    end
    ME --> NET
    NET -- "ssh" --> H1
    NET -- "ssh" --> GN
    H1 -- "sbatch / salloc" --> H2
    H1 -- "sbatch / salloc" --> H3
    H1 -- "sbatch / salloc" --> GN
    H1 --- STORE
    COMPUTE --- STORE
    SSO -. "every login" .- H1
    SSO -. "every login" .- GN
    classDef you fill:#f1f5f9,stroke:#64748b,stroke-width:1.5px,color:#1e293b
    classDef shared fill:#e0ecfb,stroke:#2f6fbf,stroke-width:1.5px,color:#0f2a4d
    classDef group fill:#e3f4e8,stroke:#2e8b57,stroke-width:1.5px,color:#123d25
    classDef store fill:#fff1d6,stroke:#c47f12,stroke-width:1.5px,color:#4a2f05
    classDef fast fill:#efe6fa,stroke:#7b4fb3,stroke-width:1.5px,color:#2e1650
    class ME,NET you
    class H1,H2,H3 shared
    class GN group
    class STORE store
    class SSO fast
    style CLUSTER fill:#fbfcfe,stroke:#94a3b8,stroke-dasharray:6 4
    style COMPUTE fill:#f2f7fe,stroke:#9dbde6
```

Reading the diagram:

- **Logins.** Your username and password are checked by the central single sign-on (the same account you created with your invitation). It is also what you use for web tools such as [Slurm-web](https://slurm.hpc.isr.tecnico.ulisboa.pt).
- **Jobs.** From `hpc01` you hand a job to SLURM, and SLURM starts it on a compute node with free resources. Your files in `/home` are already there, because the storage is shared between the nodes.
- **Group nodes.** They have their own login, administered by your group. Once a group node has joined the cluster, it uses the same `/home` and SLURM as the shared nodes. See [Group nodes](../user-guide/06-group-nodes.md).

## When something does not connect

1. Check the hostname and your username (see [Getting an account](../user-guide/01-getting-an-account.md)).
2. After several failed attempts you may be blocked for a while. Wait, then try again, instead of retrying repeatedly.
3. Still stuck? Ask your group's admin: see [Who's who](contacts.md).

Next: [Inside a node](node-anatomy.md)
