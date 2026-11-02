---
title: "2. Parameter sweep on CPUs"
parent: "Slurm"
nav_order: 2
---

# 2. Parameter sweep on CPUs (job array + dependency)

[← Slurm](../../README.md)

| CPUs | Memory | GPU | Time |
|---|---|---|---|
| 1 per task, 20 tasks, 10 at a time | 1 GB per task | none | under a minute per task |

**First run:** Downloads nothing beyond the [examples environment](../../README.md#before-you-start). Results take under 1 MB. See [Downloads and disk space](../../README.md#downloads-and-disk-space).

Many small, independent runs are the most common HPC job, and a **job array** is the way to submit them: one script, one job ID, and `SLURM_ARRAY_TASK_ID` telling each task which case to run.

Here each task runs 500 Monte Carlo trials of a Kalman filter tracking a target in 2D, for one sensor noise level between 0.25 m and 5 m. When all 20 tasks have succeeded, a second job, started with `--dependency=afterok`, collects the results into a table, a CSV file and a plot.

## Run it

Needs the [examples environment](../../README.md#before-you-start) (numpy and matplotlib).

    cd ~/slurm-examples/02-kalman-sweep
    ./submit.sh
    squeue --me          # the array shows as <jobid>_[0-19%10]

Files: [`submit.sh`](submit.sh), [`sweep.sbatch`](sweep.sbatch), [`collect.sbatch`](collect.sbatch), [`kalman.py`](kalman.py), [`collect.py`](collect.py)

## What you should see

One log per task in `logs/`, one JSON file per noise level in `~/results/kalman-sweep/`, and then, in `logs/kalman-collect-<jobid>.out`, a table like this (your numbers will differ a little):

     sigma  RMSE meas   RMSE KF   gain
      0.25      0.353     0.150   2.4x
      ...
      5.00      7.070     1.490   4.7x

The filter's advantage grows with the noise. The plot is `~/results/kalman-sweep/summary.png`.

## How it works

- **Work on `/scratch`, keep results elsewhere.** Each task computes in `/scratch/$USER/<jobid>` on its node, copies its result to `RESULTS_DIR` (default `~/results/kalman-sweep`; it can be your group's NAS) and removes its working folder. See [Data and results](../../README.md#data-and-results).
- `#SBATCH --array=0-19%10` creates tasks 0 to 19 and runs at most 10 at once, so the sweep doesn't fill the cluster. Cancel one task with `scancel <jobid>_7`, or all of them with `scancel <jobid>`.
- `%A_%a` in the log name is the array's job ID and the task number.
- `OMP_NUM_THREADS=1` stops numpy from starting a thread per core of the node when the task has one CPU.
- `afterok` waits for every task of the array. If one fails, the collector can never start, so `submit.sh` also passes `--kill-on-invalid-dep=yes` and Slurm cancels it instead of leaving it pending with reason `DependencyNeverSatisfied`.
- Tasks can run on any node you have access to, and the [examples environment](../../README.md#before-you-start) is local to each node. A task that lands on a node without it fails at once with `No Python environment ... on <node>` in its log: create the environment there, or on every node, before you submit.

## If a task fails

Find which tasks failed and why. Replace `<jobid>` with the sweep's job ID, the number before `_` in the log names:

    sacct -j <jobid> -X -o JobID,State,ExitCode,NodeList
    cat logs/kalman-sweep-<jobid>_7.out

Fix the problem, then rerun only the failed tasks. The collector is submitted again and gathers every result in `RESULTS_DIR`, old and new:

    ./submit.sh 7,12

A collector submitted by an older `submit.sh` stays pending with reason `DependencyNeverSatisfied`. Cancel it with `scancel <collector-jobid>`; it will never start on its own, and a new sweep doesn't release it.

## Try next

Sweep two parameters by mapping the task ID to a grid, for example `i=$((SLURM_ARRAY_TASK_ID / 5)); j=$((SLURM_ARRAY_TASK_ID % 5))`, or read the parameters from line `$SLURM_ARRAY_TASK_ID` of a text file with `sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" params.txt`.
