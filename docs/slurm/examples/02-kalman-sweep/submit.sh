#!/bin/bash
# Submit the sweep, then the collector, which waits for the whole array to succeed.
#
#   ./submit.sh            all 20 tasks
#   ./submit.sh 7,12       only tasks 7 and 12 (to rerun the ones that failed),
#                          then the collector again over every result so far
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p logs

array=()
[ $# -gt 0 ] && array=(--array="$1")

sweep=$(sbatch --parsable --export=ALL "${array[@]}" sweep.sbatch)
# If any task fails, Slurm cancels the collector instead of leaving it
# pending forever with reason DependencyNeverSatisfied.
collect=$(sbatch --parsable --export=ALL --dependency="afterok:$sweep" \
    --kill-on-invalid-dep=yes collect.sbatch)

echo "Sweep array: $sweep   Collector: $collect (starts when the sweep succeeds)"
echo "Follow with: squeue --me"
