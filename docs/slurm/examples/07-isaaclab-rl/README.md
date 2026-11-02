---
title: "7. Robot learning with Isaac Lab"
parent: "Slurm"
nav_order: 7
---

# 7. Robot learning with Isaac Lab (and streaming it)

[← Slurm](../../README.md)

| CPUs | Memory | GPU | Time |
|---|---|---|---|
| 16 | 64 GB | 1 × L40S | about 1 h for the H1 walking task |

**First run:** Each node needs its own Isaac Lab environment in `/scratch`: about 12 GB to download (about 1 min), 15–30 min to install and 25–30 GB of `/scratch` there. `setup.sbatch` creates it on one node, and the jobs create it on any other node the first time they run there. The first run on each node also compiles shaders and fetches robot assets, 5–15 min. Each run keeps 0.1–1 GB of checkpoints and logs. See [Downloads and disk space](../../README.md#downloads-and-disk-space).

Trains a reinforcement learning policy with [Isaac Lab](https://isaac-sim.github.io/IsaacLab/) 3.0, NVIDIA's robot learning framework on top of Isaac Sim. Thousands of copies of the robot are simulated in parallel on the GPU, and PPO (from [RSL-RL](https://github.com/leggedrobotics/rsl_rl)) learns from all of them at once. The default task teaches the Unitree **H1 humanoid** to walk and follow velocity commands.

Isaac Lab's code is cloned into your home, so you can change it and add your own tasks, and Isaac Sim and Isaac Lab are installed from pip into a uv environment on each node's `/scratch`. You can **watch** the robots in three ways, all streamed over WebRTC to your laptop:

| Script | What you see |
|---|---|
| `train.sbatch` with `STREAM=1` | The training itself, live |
| `play.sbatch` | The trained policy, after training |
| `gui.sbatch` | The full Isaac Sim editor, from the shared Apptainer image |

## Set up (once)

    cd ~/slurm-examples/07-isaaclab-rl
    sbatch --nodelist=hpc02 setup.sbatch      # pick the node you'll train on

This installs [uv](https://docs.astral.sh/uv/) in `~/.local/bin` if you don't have it and clones Isaac Lab `release/3.0.0` to `~/IsaacLab`. Then, on that node, it installs Isaac Lab, Isaac Sim 6.2 and CUDA PyTorch in `/scratch/$USER/envs/isaaclab`. It downloads about 12 GB, and the environment takes 25–30 GB of your `/scratch` quota on that node. The uv download cache (`/scratch/$USER/uv-cache`) is on the same disk and shares its files with the environment, so it takes no extra space.

`/scratch` is local to each node. `train.sbatch`, `play.sbatch` and example 11 run `uv sync` first: on a node that has the environment it takes seconds, and on any other node it builds the environment, which takes 15–30 min. To skip that wait, send the jobs to the node you set up, with the same `--nodelist`.

By running Isaac Sim you accept the [NVIDIA Isaac Sim license](https://docs.isaacsim.omniverse.nvidia.com/latest/common/NVIDIA_Omniverse_License_Agreement.html); the scripts set `OMNI_KIT_ACCEPT_EULA=YES` for that.

Files: [`setup.sbatch`](setup.sbatch), [`train.sbatch`](train.sbatch), [`play.sbatch`](play.sbatch), [`gui.sbatch`](gui.sbatch), [`stream-info.sh`](stream-info.sh)

## Train

    sbatch train.sbatch

`isaaclab-train-<jobid>.out` shows each PPO iteration with the mean reward and episode length, which rise as the robot learns. Training writes to `/scratch/$USER/<jobid>` on the node. Checkpoints (`model_<iteration>.pt`) and TensorBoard logs are copied every 30 minutes, and when the job ends, to `~/results/isaaclab/logs/rsl_rl/<experiment>/<date>/` (set `RESULTS_DIR` for another place, such as your group's NAS).

The first run on a node is slower: Isaac Sim compiles its shaders and downloads the robot assets.

Change the task, size or length with `--export`:

    sbatch --export=ALL,TASK=Isaac-Velocity-Flat-G1 train.sbatch          # Unitree G1
    sbatch --export=ALL,TASK=Isaac-Velocity-Rough-AnymalD train.sbatch    # ANYmal D on rough terrain
    sbatch --export=ALL,TASK=Isaac-Humanoid,MAX_ITERATIONS=500 train.sbatch
    sbatch --export=ALL,TASK=IsaacContrib-TrackPositionNoObstacles-ARL-Robot-1 train.sbatch   # a drone

List every task with `uv run --project ~/IsaacLab --extra isaacsim isaaclab list_envs` inside a job. Isaac Lab 3.0 removed the old `Isaac-Quadcopter-Direct` task; the drone tasks are now the `IsaacContrib-*-ARL-Robot-1` ones.

**TensorBoard:** the job starts TensorBoard on its node and prints the SSH tunnel to reach it near the top of `isaaclab-train-<jobid>.out`. Open the tunnel on your laptop, then go to `http://127.0.0.1:6006`. The job reads the logs live from the node's `/scratch`. The copy in `~/results/isaaclab/logs` is updated only every 30 minutes and when the job ends, so a TensorBoard pointed there runs up to half an hour behind.

To run TensorBoard yourself on the live logs, run it on the job's node, since `/scratch` is local to each node: `srun --jobid=<jobid> --overlap /scratch/$USER/envs/isaaclab/bin/tensorboard --logdir /scratch/$USER/<jobid>/logs --port <port>`, then tunnel to that node and port as the job log shows.

## Watch it

All three need you to be on IST's network or VPN. Install the **Isaac Sim WebRTC Streaming Client** on your laptop ([download](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/download.html#isaac-sim-latest-release)). When the job runs, its log prints the server address and ports to type into the client.

**Live training.** Add `STREAM=1`:

    sbatch --export=ALL,STREAM=1 train.sbatch

Rendering the scene costs GPU time, so this uses 256 environments instead of 4096 (`STREAM_NUM_ENVS` to change it) and learns more slowly. Use it to check a new task looks right, then train without streaming.

**The trained policy.** After training:

    sbatch play.sbatch

It loads the latest checkpoint for the task (`--checkpoint latest`) and runs 16 robots. Both use Isaac Lab's private-network stream (`--livestream 2`) on ports 49100/TCP and 47998/UDP. Each node has one GPU, so only one such job runs on a node and the ports don't collide.

**The full Isaac Sim editor.** To build scenes, import a robot or try things in the GUI, use the [Isaac Sim launch script](../../../user-guide/08-isaac-sim.md) with the shared image in `/storage/shared/containers`:

    cp ~/hpc-docs/docs/user-guide/examples/launch_isaac_sim.sh ~/ && chmod +x ~/launch_isaac_sim.sh
    sbatch gui.sbatch

It prints your own ports, computed from your user ID.

> The streaming ports (47000–50000) must be open on the node the job runs on. If the client can't connect, ask your group's admin whether they are open on the shared nodes and on your group's node.

## How it works

- **One GPU, many robots.** The physics of every environment runs on the GPU, so a single L40S simulates thousands of robots. CPUs mostly prepare the run; 16 is plenty.
- **Headless by default.** With no visualizer requested, Isaac Lab doesn't render anything, which is fastest. `--livestream 2` adds a viewport and streams it.
- **`--project ~/IsaacLab`** runs Isaac Lab from any folder, with its environment from `UV_PROJECT_ENVIRONMENT` on the node's `/scratch`. The job runs in its `/scratch` folder, so logs are written to the local disk, not to your home or the Isaac Lab checkout.
- **`play.sbatch`** copies your runs from `RESULTS_DIR` to `/scratch` and plays from there.

## Try next

- Several seeds at once: a job array with `--export=ALL,...` and `--seed $SLURM_ARRAY_TASK_ID` added to the `isaaclab train` line, as in [example 2](../02-kalman-sweep/README.md).
- Many GPUs: [example 11](../11-isaaclab-4gpu/README.md) trains on 4 GPUs across 4 nodes.
