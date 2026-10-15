# SLURM job script examples

[← User Guide](README.md) · [Home](../README.md)

Copy a script into a file, adjust the `#SBATCH` lines and the command, then `sbatch file.sh`. Basics are in [SLURM basics](04-slurm-basics.md).

Create a log folder once: `mkdir -p ~/logs`

## 1. Single-core job

```bash
#!/bin/bash
#SBATCH --job-name=hello
#SBATCH --output=%x-%j.out
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:05:00

hostname
date
id
```

## 2. Multi-threaded job (OpenMP, NumPy, PyTorch on CPU)

```bash
#!/bin/bash
#SBATCH --job-name=threads
#SBATCH --output=logs/%x-%j.out
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=02:00:00

# Make libraries use exactly the cores SLURM gave you
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK

source ~/envs/myproj/bin/activate
python ~/code/compute.py
```

## 3. GPU training job

```bash
#!/bin/bash
#SBATCH --job-name=train
#SBATCH --output=logs/%x-%j.out
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=16
#SBATCH --mem=96G
#SBATCH --time=24:00:00

echo "Node: $(hostname)  GPU(s): $CUDA_VISIBLE_DEVICES"
nvidia-smi

source ~/envs/myproj/bin/activate
python ~/code/train.py --epochs 50 --workers $SLURM_CPUS_PER_TASK
```

Check from Python that the GPU is visible:

```bash
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

## 4. Job array: same script, many inputs

Runs 10 tasks, `SLURM_ARRAY_TASK_ID` = 0…9. `%4` limits it to 4 at a time.

```bash
#!/bin/bash
#SBATCH --job-name=sweep
#SBATCH --output=logs/%x-%A_%a.out   # %A = array id, %a = task id
#SBATCH --array=0-9%4
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=01:00:00

SEEDS=(1 2 3 4 5 6 7 8 9 10)
SEED=${SEEDS[$SLURM_ARRAY_TASK_ID]}

source ~/envs/myproj/bin/activate
python ~/code/experiment.py --seed "$SEED"
```

Cancel one task: `scancel <arrayid>_3`. Cancel all: `scancel <arrayid>`.

## 5. Pipeline: run B after A succeeds

```bash
jid=$(sbatch --parsable preprocess.sh)
sbatch --dependency=afterok:$jid train.sh
```

## 6. Interactive GPU session with Jupyter

```bash
# On hpc01: get a GPU node
srun --gres=gpu:1 --cpus-per-task=8 --mem=64G --time=04:00:00 --pty bash

# On the compute node it lands on (note the hostname!)
hostname
source ~/envs/myproj/bin/activate
jupyter lab --no-browser --ip=0.0.0.0 --port=8888
```

Then on your laptop forward the port (replace `hpc02` with the hostname printed above) as described in [SSH login → Port forwarding](02-ssh-login.md#port-forwarding-eg-jupyter-tensorboard).

## 7. Email when the job ends

```bash
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<you>@tecnico.ulisboa.pt
```

> **TODO:** Only works if a mail relay is configured on `hpc01` (`MailProg` in `slurm.conf`). Confirm.
