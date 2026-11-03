#!/bin/bash
# Build an Apptainer image on this node's /scratch, in /scratch/$USER/containers.
#   sbatch --nodelist=hpc02 build-sif.sbatch <source> <name>
# <source> is anything `apptainer build` takes, for example:
#   docker://pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime   a registry image
#   mytool.def                                                a definition file
#   docker-archive://$HOME/mytool.tar                         a `docker save` file
# /scratch is local to each node: build on the node your jobs will run on, or once
# on each node you use. The cache and build files go to /scratch too, not your home,
# and are removed when the build ends.
#SBATCH --job-name=build-sif
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=%x-%N-%j.out

set -euo pipefail
SRC=${1:?usage: sbatch --nodelist=<node> build-sif.sbatch <source> <name>}
NAME=${2:?usage: sbatch --nodelist=<node> build-sif.sbatch <source> <name>}
SIF="/scratch/$USER/containers/$NAME.sif"

BUILD="/scratch/$USER/$SLURM_JOB_ID"
export APPTAINER_CACHEDIR="$BUILD/cache" APPTAINER_TMPDIR="$BUILD/tmp"
mkdir -p "$(dirname "$SIF")" "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"
trap 'rm -rf "$BUILD" "$SIF.part"' EXIT

echo "Building $SIF from $SRC on $(hostname)"
# "Creating SIF file..." can run for many minutes with no output on a large image.
apptainer build "$SIF.part" "$SRC"
mv "$SIF.part" "$SIF"
ls -lh "$SIF"
