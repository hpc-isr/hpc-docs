#!/bin/bash
# Submit both steps; training starts only if preparation succeeds.
#   ./submit.sh                      # sample scene (Tanks and Temples Truck)
#   VIDEO=~/videos/lab.mp4 SCENE_NAME=lab ./submit.sh
#   DATA=~/scenes/bench SCENE_NAME=bench ./submit.sh   # a scene you already have
#   ./submit.sh --nodelist=hpc02     # extra sbatch options go to both steps
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p logs

prep=$(sbatch --parsable --export=ALL "$@" prepare.sbatch)
train=$(sbatch --parsable --export=ALL "$@" --dependency="afterok:$prep" train.sbatch)

echo "Prepare: $prep   Train + render: $train (waits for $prep)"
echo "Follow with: squeue --me"
