---
title: "8. 3D scene from a video"
parent: "Slurm"
nav_order: 8
---

# 8. 3D scene from a video (COLMAP + Gaussian Splatting pipeline)

[← Slurm](../../README.md)

| Step | CPUs | Memory | GPU | Time |
|---|---|---|---|---|
| 1. Prepare: camera poses with COLMAP | 16 | 32 GB | none | 10–60 min for a video |
| 2. Train and render | 8 | 64 GB | 1 × L40S | about 30 min |

**First run:** On each new node, the first step that runs there downloads the nerfstudio image (5.4 GB, under a minute) and takes 10–20 min to build `/scratch/$USER/containers/nerfstudio-1.1.3.sif` (5.5 GB of `/scratch`, and about 20 GB more while it builds). Preparation and training can land on different nodes, so the first run may build it twice. The sample scenes are a 683 MB download, kept in `/scratch/$USER/datasets` on that node. Each scene keeps 0.2–1 GB in `RESULTS_DIR`; jobs use 1–2 GB of `/scratch`. See [Downloads and disk space](../../README.md#downloads-and-disk-space).

Turns a short phone video of a room, an object or a robot's workspace into a **3D Gaussian Splatting** model you can fly through, using [nerfstudio](https://docs.nerf.studio/) from its official container. It is a two-step **pipeline**: a CPU job finds the camera positions, and a GPU job, which Slurm starts only if the first succeeds, trains the model and renders a video. Splitting it this way means the GPU isn't held while COLMAP runs on CPUs.

## Run it

    cd ~/slurm-examples/08-gaussian-splatting

    # A free sample scene: the Truck from Tanks and Temples, 251 photos with camera poses
    ./submit.sh

    # Your own video: walk slowly around the scene for 30–60 s, then
    VIDEO=$HOME/videos/lab.mp4 SCENE_NAME=lab ./submit.sh

    # A scene you already have on disk (see below)
    DATA=$HOME/scenes/bench SCENE_NAME=bench ./submit.sh

`DATA` is a folder in one of three forms. `prepare.sbatch` picks the right step for each:

| `DATA` contains | What preparation does |
|---|---|
| `transforms.json` and the images it lists (nerfstudio's format) | Uses it as it is |
| `images/` and `sparse/0/` (COLMAP's output, as in most Gaussian Splatting datasets) | Converts it to nerfstudio's format, without running COLMAP again |
| `images/` only | Runs COLMAP on the photos to find the camera poses |

The sample comes from the [3D Gaussian Splatting](https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/) authors' server at Inria. If that download fails, fetch `tandt_db.zip` from their page on your laptop, copy it to the cluster, unzip it, and pass a scene with `DATA=~/tandt_db/tandt/truck SCENE_NAME=truck ./submit.sh`. Any other scene from nerfstudio's `ns-download-data` or the Mip-NeRF 360 dataset works the same way. Nerfstudio's own samples, such as the poster scene, are on Google Drive, which often refuses downloads from scripts, so this example doesn't use them.

Files: [`submit.sh`](submit.sh), [`prepare.sbatch`](prepare.sbatch), [`train.sbatch`](train.sbatch), [`common.sh`](common.sh)

Each step makes sure the nerfstudio image is in `/scratch/$USER/containers/nerfstudio-1.1.3.sif` on its node, and builds it there if not. To build it only once, send both steps to one node: `./submit.sh --nodelist=hpc02` (any options after `submit.sh` go to both `sbatch` calls). Each scene is kept in `~/results/splats/<scene>/` (set `RESULTS_DIR` for another place, such as your group's NAS). Preparation is skipped when the scene is already there, so you can rerun `submit.sh` safely.

## What you should see

In `logs/`, one log per step. When both are done:

| File | What |
|---|---|
| `~/results/splats/<scene>/data/` | Extracted frames and camera poses (`transforms.json`) |
| `~/results/splats/<scene>/runs/render-<jobid>.mp4` | A fly-through video of the scene |
| `~/results/splats/<scene>/runs/export/splat.ply` | The model; drag it into a web viewer such as [SuperSplat](https://superspl.at/editor) on your laptop |
| `~/results/splats/<scene>/runs/data/splatfacto/<date>/` | Checkpoints, config and TensorBoard logs |

**TensorBoard:** the job starts TensorBoard on its node and prints the SSH tunnel to reach it near the top of `logs/splat-train-<jobid>.out`. Open the tunnel on your laptop, then go to `http://127.0.0.1:6006`. It shows the training loss and the rendered views as they improve. The copy in `~/results/splats/<scene>/runs` is written only when the job ends.

To run TensorBoard yourself on the live logs, run it on the job's node, since `/scratch` is local to each node: `srun --jobid=<jobid> --overlap apptainer exec --bind /scratch /scratch/$USER/containers/nerfstudio-1.1.3.sif tensorboard --logdir /scratch/$USER/<jobid>/runs --port <port>`, then tunnel to that node and port as the job log shows.

## How it works

- **`--dependency=afterok`.** `submit.sh` submits both jobs at once. The second waits, with reason `Dependency`, until the first ends successfully. If preparation fails, training never starts: cancel it, fix the problem, and run `submit.sh` again.
- **COLMAP on CPUs.** `ns-process-data` extracts about 300 frames and runs COLMAP's feature matching and bundle adjustment with `--no-gpu`, using the job's 16 cores. Sequential matching suits video, where neighbouring frames overlap.
- **One container, both steps.** `common.sh` wraps every `ns-*` command in `apptainer exec`, adding `--nv` only in the GPU job.
- **Work on `/scratch`, keep results elsewhere.** Frame extraction and COLMAP write thousands of small files, and training reads every image thousands of times: both run in `/scratch/$USER/<jobid>` on the node. Each step copies what the next one needs to `RESULTS_DIR`, so the GPU step can run on any node and stage the scene from there.

## Tips for your own videos

Move slowly and steadily, keep the scene lit evenly, avoid moving people and reflective surfaces, and go around the object rather than turning on the spot. If COLMAP finds poses for only a few frames, the log says so; try again with a slower video, or `--matching-method exhaustive` in `prepare.sbatch` for short ones.
