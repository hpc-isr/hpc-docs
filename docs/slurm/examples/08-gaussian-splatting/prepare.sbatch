#!/bin/bash
# Step 1 (CPU): camera poses with COLMAP, from your video, your own scene or a free sample.
#SBATCH --job-name=splat-prepare
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=logs/%x-%j.out

set -euo pipefail
source "$SLURM_SUBMIT_DIR/common.sh"
trap 'rm -rf "$WORK"' EXIT
trap 'exit 143' TERM

ensure_sif   # the nerfstudio image on this node's /scratch

if [ -f "$SCENE_RESULTS/data/transforms.json" ]; then
    echo "Already prepared: $SCENE_RESULTS/data"
    exit 0
fi

# Images with COLMAP poses already computed (images/ and sparse/0/): convert them
# to nerfstudio's format without running COLMAP again.
from_colmap_model() {   # <folder with images/ and sparse/0/>
    mkdir -p "$WORK/data/colmap/sparse"
    cp -r "$1/sparse/0" "$WORK/data/colmap/sparse/0"
    ns ns-process-data images --data "$1/images" --output-dir "$WORK/data" --skip-colmap
}

if [ -n "${VIDEO:-}" ]; then
    # Frame extraction and COLMAP write thousands of small files: do it on /scratch.
    echo "Processing $VIDEO with COLMAP on $SLURM_CPUS_PER_TASK CPUs"
    cp "$VIDEO" "$WORK/input.${VIDEO##*.}"
    ns ns-process-data video --data "$WORK/input.${VIDEO##*.}" --output-dir "$WORK/data" \
        --num-frames-target 300 --matching-method sequential --no-gpu
elif [ -n "${DATA:-}" ]; then
    # A scene you already have: nerfstudio format, COLMAP output, or just photos.
    rsync -a "$DATA/" "$WORK/input/"
    if [ -f "$WORK/input/transforms.json" ]; then
        echo "Using $DATA as it is (nerfstudio format)"
        mv "$WORK/input" "$WORK/data"
    elif [ -d "$WORK/input/images" ] && [ -f "$WORK/input/sparse/0/cameras.bin" ]; then
        echo "Converting $DATA (images/ + COLMAP sparse/0/) to nerfstudio format"
        from_colmap_model "$WORK/input"
    elif [ -d "$WORK/input/images" ]; then
        echo "Running COLMAP on the photos in $DATA/images on $SLURM_CPUS_PER_TASK CPUs"
        ns ns-process-data images --data "$WORK/input/images" --output-dir "$WORK/data" --no-gpu
    else
        echo "$DATA has no transforms.json and no images/ folder: see the README." >&2
        exit 1
    fi
else
    # A free sample scene with its camera poses: the Truck from Tanks and Temples,
    # 251 photos, as hosted by the 3D Gaussian Splatting authors at Inria (683 MB
    # for four scenes; kept on this node's /scratch for later runs).
    SAMPLE_ZIP="/scratch/$USER/datasets/tandt_db.zip"
    SAMPLE_URL="https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/datasets/input/tandt_db.zip"
    if [ ! -f "$SAMPLE_ZIP" ]; then
        echo "No VIDEO or DATA given: downloading the sample scenes (683 MB)"
        mkdir -p "$(dirname "$SAMPLE_ZIP")"
        curl -fL --retry 3 -o "$SAMPLE_ZIP.part" "$SAMPLE_URL"
        mv "$SAMPLE_ZIP.part" "$SAMPLE_ZIP"
    fi
    python3 -c 'import sys, zipfile
z = zipfile.ZipFile(sys.argv[1])
z.extractall(sys.argv[2], [n for n in z.namelist() if n.startswith("tandt/truck/")])' "$SAMPLE_ZIP" "$WORK/download"
    from_colmap_model "$WORK/download/tandt/truck"
fi

# Keep the frames and poses (not COLMAP's scratch database) for the training step.
rsync -a --exclude 'colmap/database.db' "$WORK/data/" "$SCENE_RESULTS/data/"
echo "Prepared $(ls "$SCENE_RESULTS/data/images" | wc -l) images in $SCENE_RESULTS/data"
