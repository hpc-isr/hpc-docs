---
title: "Cluster at a glance"
parent: "Overview"
nav_order: 1
---

# Cluster at a glance

[← Overview](README.md) · [Home](../README.md)

The ISR HPC cluster is a set of GPU machines (called **nodes**) that you use remotely over SSH. There are two kinds of node, and the difference matters for how you work.

## The machines

| Node | What it is for | Who can use it |
|---|---|---|
| `hpc01` | **Login node** for the shared cluster, and where SLURM is controlled. Edit files, use `git`, submit and watch jobs. Light work only. | Everyone |
| `hpc02`, `hpc03` | **Shared compute nodes**. Jobs with GPUs run here (the `shared` partition). | Everyone, through SLURM jobs |
| `hpc-<group>` | **Your research group's own node**, for example `hpc-dsor`. | Members of that group |

Each node has its own GPU. Your jobs get a whole GPU or a slice of one, depending on what you ask for.

```mermaid
%%{init: {"theme": "base", "flowchart": {"curve": "basis", "nodeSpacing": 40, "rankSpacing": 50, "padding": 12}, "themeVariables": {"fontFamily": "Inter, Segoe UI, Helvetica Neue, Arial, sans-serif", "fontSize": "15px", "primaryColor": "#ffffff", "primaryBorderColor": "#94a3b8", "primaryTextColor": "#1e293b", "lineColor": "#64748b", "clusterBkg": "#f8fafc", "clusterBorder": "#cbd5e1", "edgeLabelBackground": "#ffffff"}}}%%
flowchart TB
    ME(["<b>You</b>"])
    subgraph SHARED["Shared SLURM cluster · everyone"]
        direction LR
        H1["<b>hpc01</b><br/>login node<br/>submit and watch jobs"]
        H2["<b>hpc02</b><br/>GPU compute"]
        H3["<b>hpc03</b><br/>GPU compute"]
        H1 -. "SLURM starts jobs" .-> H2
        H1 -. "SLURM starts jobs" .-> H3
        GS["<b>hpc-#lt;group#gt;</b><br/>idle group nodes:<br/><i>scavenge</i> jobs for everyone"]
        H1 -. "scavenge jobs,<br/>can be preempted" .-> GS
    end
    subgraph GROUPS["Group nodes · one per research group, for its members"]
        G["<b>hpc-dsor</b><br/><b>hpc-irsg</b><br/><b>hpc-laseeb</b><br/><b>hpc-sipg</b><br/><b>hpc-vislab</b>"]
    end
    FS[("<b>/home</b> and <b>/storage</b><br/>shared storage")]
    ME -- "ssh" --> H1
    ME -- "ssh, your own group only" --> G
    H1 --- FS
    H2 --- FS
    H3 --- FS
    G -. "once the group's node<br/>has joined the cluster" .-> FS
    classDef you fill:#f1f5f9,stroke:#64748b,stroke-width:1.5px,color:#1e293b
    classDef shared fill:#e0ecfb,stroke:#2f6fbf,stroke-width:1.5px,color:#0f2a4d
    classDef group fill:#e3f4e8,stroke:#2e8b57,stroke-width:1.5px,color:#123d25
    classDef store fill:#fff1d6,stroke:#c47f12,stroke-width:1.5px,color:#4a2f05
    classDef fast fill:#efe6fa,stroke:#7b4fb3,stroke-width:1.5px,color:#2e1650
    class ME you
    class H1,H2,H3 shared
    class G,GS group
    class FS store
    style SHARED fill:#f2f7fe,stroke:#9dbde6
    style GROUPS fill:#f2faf4,stroke:#9fd0b1
```

## Which one should I use?

| I want to… | Use |
|---|---|
| Log in, edit code, copy files, submit jobs | `hpc01` |
| Run something that needs a GPU, or a lot of CPU or memory | A **SLURM job** (`sbatch` or `salloc`). It runs on a compute node: you don't choose the node, SLURM does |
| Work on my group's machine | `hpc-<group>`. Group nodes are joining the SLURM cluster one at a time: once yours has, the GPU there is also used through SLURM jobs |

The GPU is **not available in a plain SSH session**, on any node: `nvidia-smi` will fail until you are inside a job. See [SLURM basics](../user-guide/04-slurm-basics.md).

## Things worth knowing

- **Your account.** One account works everywhere, but your group's admin must enable each service for you. A new account can take a while to show up on every node: ask your admin if something is missing. See [Getting an account](../user-guide/01-getting-an-account.md).
- **Shared and group nodes are separate.** Having access to one does not give you access to the other.
- **What is free right now.** `sinfo` on `hpc01`, or [Slurm-web](https://slurm.hpc.isr.tecnico.ulisboa.pt) in a browser, shows which nodes and GPUs are busy.
- **Software.** You can't install system packages on the nodes. Use Python environments on `/scratch`, or containers: see [Storage](../user-guide/03-storage.md#software-environments) and [Apptainer](../user-guide/09-apptainer.md).

Next: [Network](network.md)
