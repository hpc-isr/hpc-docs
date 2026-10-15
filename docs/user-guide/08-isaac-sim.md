# Isaac Sim

[← User Guide](README.md) · [Home](../README.md)

NVIDIA Isaac Sim runs headless on the server inside an **Apptainer** container and streams its window to a client on your laptop. Apptainer is installed for all users, and the image is `/opt/containers/isaac-sim-6.1.0.sif`.

On the shared cluster you run it inside a SLURM GPU job, on whichever node SLURM gives you. The launch script below finds that node's private IP by itself. You must be on IST's network or on [IST's VPN](https://si.tecnico.ulisboa.pt/en/servicos/redes-e-conetividade/vpn/) to reach it.

> The streaming ports (`47000–50000`) are being opened on `hpc01`–`hpc03`; until then the stream won't reach your laptop. On a group node, the group's admin decides whether the ports are open; see your group's guide (e.g. hpc-dsor (not yet published)).

## Run it

1. Copy [`launch_isaac_sim.sh`](examples/launch_isaac_sim.sh) to your home on `hpc01` and make it executable:

   ```bash
   chmod +x ~/launch_isaac_sim.sh
   ```

2. Start a GPU job inside `tmux`, so it keeps running if your SSH connection drops, and run the script in it:

   ```bash
   tmux new -s isaac
   srun --gres=gpu:1 --cpus-per-task=16 --mem=64G --time=04:00:00 --pty ~/launch_isaac_sim.sh
   ```

   It prints your ports first:

   ```text
   User: <username> (UID 12345)
   Server:      100.68.8.70
   Signal port: 49445 (TCP)
   Stream port: 48343 (UDP)
   ```

3. On your laptop, open the Isaac Sim WebRTC Streaming Client and connect to the server address and ports the script printed. Use your own ports, not the client's defaults; every user gets a different pair in `47000–50000`.

Extra arguments are passed on to Isaac Sim's `runheadless.sh`, e.g. `~/launch_isaac_sim.sh --help`. Stop it with `Ctrl-C`; when the job ends, Isaac Sim stops too.

## What the script does

- **First run only:** extracts the `.sif` image into a writable sandbox at `/scratch/$USER/isaac-scratch/sandbox`. This copies about 10 GB and takes a while. Later runs reuse it. If the extraction fails, the previous sandbox is kept.
- Keeps Isaac Sim's caches and settings (`~/.cache`, `~/.nv`, `~/.nvidia-omniverse`, `~/.local/share/ov`, `~/.config/omniverse`) on `/scratch/$USER/isaac-scratch/user-state`, mounted over those folders **only inside the container**. Your real home is otherwise untouched.
- Uses the private IP of the node it runs on (interface `ens3`) as the streaming address.
- Runs Isaac Sim with the GPU (`--nv`), accepting the EULA, and passes on `CUDA_VISIBLE_DEVICES` if it is set.
- Exits with an error if `/scratch` isn't mounted or the image can't be read.

Everything it creates is under `/scratch/$USER`, readable only by you (`umask 077`). Delete `/scratch/$USER/isaac-scratch` to start from scratch.

## Ports

Each user gets their own ports, computed from their numeric user ID (`id -u`), so several people can stream at once:

| Port | Protocol | Formula |
|---|---|---|
| Signal | TCP | `49100 + UID % 1000` |
| Stream | UDP | `47998 + UID % 1000` |

The firewall range is `47000–50000` (TCP and UDP). Two limits follow from the formula:

- If the last three digits of your UID are above `900`, your signal port is above `50000` and is blocked.
- Two users whose UIDs end in the same three digits get the same ports and can't stream at the same time.

If either happens, ask an admin.

See also: [Storage → `/opt`](03-storage.md#shared-software-in-opt) · [Group nodes](06-group-nodes.md)
