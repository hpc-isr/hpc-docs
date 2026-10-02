# Submitting a batch job with Slurm

This guide explains a general workflow for preparing, submitting, and checking
a workload with Slurm. It is not a site policy. Confirm the cluster's
partitions, account and QoS rules, resource limits, GPU syntax, storage layout,
software environment, and accounting support with its administrators. Slurm
configuration differs between sites.

For Slurm's command behavior, see the official [`sbatch`](https://slurm.schedmd.com/sbatch.html),
[`srun`](https://slurm.schedmd.com/srun.html), and
[`GRES` (including GPUs)](https://slurm.schedmd.com/gres.html) documentation.

## 1. Gather the workload details

Before writing a job script, ask the workload owner for:

- the exact command and arguments that currently run the workload;
- the project working directory, configuration files, and input and output paths;
- how its software environment is activated (for example, a site module,
  virtual environment, or container approved by the site);
- whether it uses one process, multiple processes on one node, or a supported
  multi-node launch method;
- whether it needs a GPU and any known CPU, memory, and runtime requirements;
- where logs, results, and checkpoints should be written;
- a small, representative run that can validate the setup safely.

Do not guess the command or resource request. If requirements are not known,
ask the owner and use a small pilot approved by the site to measure them.

## 2. Confirm site-specific requirements

Check the site's user guide or ask its administrators which partition, account,
QoS, time limit, memory units, CPU allocation, and GPU request syntax apply.
Names such as `gpu`, `normal`, and `debug` are examples only. Do not assume a
partition or a GPU request form exists because it appears in a generic example.

Confirm that input files and output locations are accessible from compute
nodes. A path visible on a login node may not be mounted on compute nodes.
Create the log directory before submission and verify that the submitting
account can write to it. Follow site policy for restricted data and approved
storage; do not put credentials, private host details, or restricted data in
scripts committed to a repository.

## 3. Prepare a batch script

The following template is intentionally **not runnable as written**. Replace
every `<...>` placeholder, remove directives that do not apply, and confirm
all values and options with the site before submitting. Slurm reads `#SBATCH`
directives only before the first non-comment, non-whitespace command in the
script.

```bash
#!/usr/bin/env bash
# Replace every placeholder and confirm requests with the cluster administrators.
#SBATCH --job-name=<short-job-name>
#SBATCH --partition=<site-approved-partition>
#SBATCH --nodes=<number-of-nodes>
#SBATCH --ntasks=<number-of-tasks>
#SBATCH --cpus-per-task=<cpus-per-task>
#SBATCH --mem=<memory-with-site-supported-unit>
#SBATCH --time=<HH:MM:SS>
#SBATCH --chdir=<absolute-project-working-directory>
#SBATCH --output=<existing-writable-log-directory>/%x-%j.out
#SBATCH --error=<existing-writable-log-directory>/%x-%j.err
# Add a GPU directive only when needed and after confirming the site's syntax:
##SBATCH --gres=gpu:<number-of-gpus>

set -euo pipefail

# Activate or load the workload's approved software environment here.
# For example, use the site's documented module or environment procedure.

srun <confirmed-workload-command> <arguments>
```

The GPU line above begins with two comment markers so it is not an active
directive. If GPUs are required, change it to the site's confirmed directive
with one `#` marker before submitting. Remove it otherwise. Do not copy an
activation command from another user's account; use the workload owner's
confirmed environment steps and the site's approved software practices.

The requested task count and CPUs per task should match how the application
uses processes and threads. Do not request multiple nodes unless the
application and its launch procedure support distributed execution. `srun`
launches the workload step within the resources allocated to the batch job.

## 4. Submit and monitor

From the directory containing the prepared script, submit it using the site's
documented procedure:

```bash
sbatch job.sbatch
```

Record the returned job ID. Check whether the job is queued or running with:

```bash
squeue --jobs=<job-id>
```

If the job is pending, inspect its reason and requested resources using the
site-approved tools or ask an administrator. Do not repeatedly resubmit an
unchanged job to work around a scheduling or policy decision.

For a running job, inspect the output and error logs in the configured log
directory. If the site permits it, `scontrol show job <job-id>` can show job
details. To stop a job, first verify the ID and ownership, then use the site's
documented cancellation procedure; `scancel <job-id>` cancels that job.

After completion, check the job's exit status, logs, expected outputs, and any
checkpoint or result files. `sacct` can report completed-job history only when
the site's accounting configuration and retention make that information
available; a missing record is not by itself proof that a job never ran.

## 5. Validate with a small run

Before a long or expensive run, submit a small representative pilot and verify:

1. the job starts in the intended partition and receives the requested
   resources;
2. the environment activates and the confirmed command runs;
3. the allocated compute node can read the inputs and write logs and outputs;
4. any requested GPU is visible to the job and used as expected;
5. the exit status is successful and the outputs are usable.

Use the pilot's observed resource use and runtime to refine later requests
with the workload owner. Keep a record of the command, configuration, resource
request, and relevant job ID in the approved project record, subject to site
data and privacy rules.

## Further reading

- [Slurm `sbatch`](https://slurm.schedmd.com/sbatch.html)
- [Slurm `srun`](https://slurm.schedmd.com/srun.html)
- [Slurm generic resources and GPUs](https://slurm.schedmd.com/gres.html)
- [Slurm job states](https://slurm.schedmd.com/job_state_codes.html)
