# Snellius (SURF)

This guide helps users and coding agents make effective use of Snellius and its shared compute and storage resources. For more information refer to the [docs](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/74227835/Generic+usage+guides).

## Shared-cluster rules

- Check `hostname` before running work. `int3`–`int6` are shared interactive/login nodes for editing, lightweight development (including running agents), inspection and job submission. Substantial RAM/CPU use, resource-intensive GPU work, or workloads over 10 minutes must use the Slurm queue; short runtime does not exempt heavy work.
- Long-running login-node processes that are not whitelisted are automatically force-killed (user-supplied policy; exact threshold/whitelist unknown). Do not assume tmux or an agent process is exempt.
- Never use `watch -n` with an interval below 2 seconds. Run quota/accounting commands only when needed; reuse recent results and do not put them in repeated polling or `watch` loops.
- Use scratch/project space for large or parallel job I/O, not `$HOME`. Use `$TMPDIR` for temporary job data, not `/tmp` or `/var/tmp`: filling system directories can disrupt other users and the OS.

## Software

- OS: RHEL; check `/etc/os-release` for the version. Lightweight environment checks can run on login nodes: `module list`, `nvcc --version` if installed, and `nvidia-smi` on GPU-equipped `int3`. Check the actual job/container environment too; the CUDA version shown by `nvidia-smi` is driver compatibility, not the installed toolkit version.
- Modules are supported: select a stack with `module load 2024` or `module load 2026`, then load a compatible package, e.g. `module load NCCL/2.26.6-GCCcore-14.2.0-CUDA-12.8.0` (availability depends on the stack).
- Apptainer is recommended. Existing vLLM containers: `/projects/2/managed_datasets/containers/vllm/`. You may build or pull your own containers; do so in a Slurm job on `rome` or `staging`. Cache/temp setup is in Environment setup below; `/dev/shm` is RAM-backed, so allow sufficient job memory.
- Prefer `uv` for Python environment management over manually managed virtual environments. Conda is discouraged; use modules or `pixi` instead.

## Filesystems

| path | purpose / visibility | default quota | backup / deletion |
|---|---|---|---|
| `$HOME` | work environment; shared across nodes | 200 GiB; 1 million files | nightly backup; home expires 15 weeks after project expiration |
| `/projects/<name>` | persistent logs, final project artefacts and shared project I/O | project-dependent, per group | no backup; inaccessible at agreed end date, deletion after 4-week grace period |
| `/scratch-shared/$USER` | temporary/preprocessed files and downloaded Hugging Face model checkpoints; shared GPFS | combined scratch quota below | no backup; purged after 2 weeks (14 days) without content modification |
| `/scratch-local/$USER` | node-specific view on shared GPFS, **not physical local disk** | combined scratch quota below | no backup; contents unchanged for 6 days are deleted |
| `/scratch-node/<user-specific>` | actual node-local NVMe; use `$TMPDIR` | allocation-dependent disk share | no backup; deleted at job end |
| `/archive/$USER` | long-term tape storage; login/staging access | by request | nightly backup; project duration |

- Shared/local scratch together: 8 TiB and 3 million files soft limit; 7-day grace period after exceeding the file soft limit. Hard limit or expired grace blocks file creation.
- Save required logs and training checkpoints periodically to project space (home for modest logs); keep final project artefacts there.
- Scratch deletion has no advance notification; retention is not guaranteed. Keep caches rebuildable and copy valuable results to backed-up storage in time.
- Request `#SBATCH --constraint=scratch-node` for NVMe (all fat nodes, some thin/GPU nodes). Only then does `$TMPDIR` point there; otherwise it points to `/scratch-local`. Each node has separate data; copy results out before the job ends.
- **Project space has no automatic backup. Keep a separate backup of valuable logs, checkpoints and final artefacts in the archive or off-site; project space alone is not a backup.**
- Project space must be requested and has no file-age purge. Preserve the project's quota-group ownership; `rsync -a` / `cp -p` may fail when trying to preserve a different group.
- Home backup requires closed files present during the backup; deleted backed-up files are retained for three weeks. Archive many small files as a tar bundle, not individually.

## Shared datasets and models

- Check `/scratch-nvme/ml-datasets/` and `/projects/2/managed_datasets/` for hosted training/benchmark datasets before downloading duplicates; additional datasets may be available on request from SURF. See [available datasets and models](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/62227640/Available+datasets+and+models+on+Snellius).
- Treat shared datasets as read-only and check each dataset's license; the supplied page states CC BY-NC-SA 3.0 (attribution, noncommercial, share-alike).

## Data transfer

- Run bulk data transfers and transfers involving many tiny files in a `staging` job; resources/rates are listed below. External connectivity and transfer limits are unverified; check only when needed.

## Batch system and hardware

Partitions, walltimes and SBU weights: SURF "Snellius partitions" docs, as of 2026-09-10.

| partition | node | nodes | smallest allocation | SBU per hour |
|---|---|---|---|---|
| `gpu_h100` | 4× H100 (94 GiB HBM2e each), 64 cores, 720 GiB RAM | 88 | 1 GPU + 16 cores + 180 GiB | 192 per GPU (768 per node) |
| `gpu_a100` | 4× A100 (40 GiB HBM2 each), 72 cores, 480 GiB RAM | 63 | 1 GPU + 18 cores + 120 GiB | 128 per GPU (512 per node) |
| `genoa` | thin, 192 cores, 336 GiB | 737 | 24 cores + 42 GiB | 1.0 per core (192 per node) |
| `rome` | thin, 128 cores, 224 GiB | 521 | 16 cores + 28 GiB | 1.0 per core (128 per node) |
| `fat_genoa` | 192 cores, 1440 GiB | 48 | 24 cores + 180 GiB | 1.5 per core |
| `fat_rome` | 128 cores, 960 GiB | 72 | 16 cores + 120 GiB | 1.5 per core |
| `staging` | service, SMT 32 threads, 224 GiB | 10 | 1 thread + 7 GiB | 2.0 per thread |

- CPUs: H100 nodes use dual AMD EPYC 9334; A100 nodes dual Intel Xeon Platinum 8360Y. Rome thin/fat/high-memory nodes use dual AMD EPYC 7H12; Genoa thin/fat nodes dual AMD EPYC 9654.
- InfiniBand fabric: H100 nodes 4× NDR200 ConnectX-7; A100 nodes 2× HDR200 ConnectX-6; Rome/high-memory/service nodes HDR100; Genoa nodes NDR ConnectX-7 (200 Gbps within a rack, 100 Gbps outside). Existing configs use `NCCL_SOCKET_IFNAME=eno2np0`; verify before reusing.
- `himem_4tb` / `himem_8tb`: minimum 16 cores + 480 / 960 GiB; 2.0 / 3.0 SBU per core-hour; 2 nodes each.
- `gpu_mig`: minimum 1 A100 MIG slice + 9 cores + 60 GiB; 64 SBU per slice-hour.
- `gpu_vis`: same minimum allocation/rate as `gpu_a100`; `cbuild`: same as `staging`.
- Max walltime: 120 h on all partitions (`gpu_vis`: 24 h).
- Jobs of ≤ 1 h on thin, fat and GPU partitions run on dedicated short-job nodes: shorter wait, good for
  smoke tests. There are few of them, so not for jobs with many nodes.
- Available RAM in the table is what a job can request (less than the node's total).
- Node counts vary with maintenance and partition membership; use `sinfo` for current availability and node names. Check `sinfo --version` if needed.
- Inspect your jobs with `squeue --me`; cancel only explicit job IDs verified to belong to you.
- Interactive work: obtain a Slurm allocation with `salloc` / `srun --pty`; partition/resource flags depend on the workload.

### int3 interactive development

- Connect with `ssh <user>@int3-pub.snellius.surf.nl` for interactive agent development and lightweight GPU development. The shared login-node rules above still apply.
- `int3` provides shared, nonexclusive A100 MIG slices for GPU compilation and sanity tests of a few minutes. GPU use requires GPU access and ≥1 GPU SBU; load the required CUDA runtime modules. The supplied GPU-development policy specifies a 15-minute host-job limit.
- Use Slurm for longer tests, resource-intensive work or a full GPU.

## Accounting

- Compute is charged in **SBU**: weight × cores or GPUs × hours (table above). You can't allocate less
  than the smallest allocation, e.g. 1 H100 always comes with 16 cores + 180 GiB.
- Before submission, report estimated maximum SBU cost using requested walltime and allocated units, including minimum allocations and all array tasks. Example: 1 H100 × 1 h = 192 SBU; `gpu_a100` costs 2/3 as much per GPU-hour.
- `myquota`: disk-space and inode (file/directory count) usage/quotas for home and scratch; `myquota <prjsXXXX>` for project space (replace the placeholder with the project identifier).
- `accinfo`: compute quota information.
- `budget-overview`: budget command; exact scope/output still to be confirmed.

## Environment setup

Put these exports in `~/.bashrc` for interactive use, or in a small environment file sourced by both `~/.bashrc` and jobs. Set them before starting Python or containers. `CACHE_DIR` is only a helper; tool-specific variables control the actual locations.

```bash
CACHE_DIR="/scratch-shared/$USER/cache"
export HF_HOME="/scratch-shared/$USER/hf"
export HF_TOKEN_PATH="$HOME/.cache/huggingface/token"
export PIP_CACHE_DIR="$CACHE_DIR/pip"
export UV_CACHE_DIR="$CACHE_DIR/uv"
export TRITON_CACHE_DIR="$CACHE_DIR/triton"
export TORCH_EXTENSIONS_DIR="$CACHE_DIR/torch_extensions"
export APPTAINER_CACHEDIR="/scratch-shared/$USER/"
export APPTAINER_TMPDIR="/dev/shm/$USER/"
```

- HF downloads/caches stay on scratch; the token stays in home. These scratch caches may be purged and must be rebuildable.
- Batch shells may not read `~/.bashrc`; inherit the exported variables or explicitly source the environment file. Keep module selection and allocation-dependent thread settings in jobs.
- Before using Apptainer, run `mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"` on the node running it; `/dev/shm` is node-local. Keep this setup step out of routine shell startup.

## Single-GPU example

Run from a persistent working directory; replace image/model placeholders. Apply Environment setup above and make Apptainer available before running the workload. This requests one H100 allocation; the application must fit its GPU memory. No `--exclusive` needed.

```bash
#!/bin/bash
#SBATCH --job-name=vllm_serve
#SBATCH --partition=gpu_h100
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gpus-per-node=1
#SBATCH --mem=180G
#SBATCH --time=01:00:00
#SBATCH --output=slurm-%j.out

set -euo pipefail
CONTAINER='<path/to/image.sif>'
export OMP_NUM_THREADS="$SLURM_CPUS_PER_TASK"
srun apptainer exec --nv -B /projects -B /scratch-shared \
    "$CONTAINER" vllm serve '<model>'
```

- Bind actual paths used by the job; do not assume `/scratch` covers `/scratch-shared`. Add a bind for `$TMPDIR` if used inside the container, and verify symlink targets resolve there. `--nv` belongs after `exec`/`run`.
- A server intentionally runs until stopped or its walltime expires; assess startup/readiness from logs rather than expecting it to exit successfully on its own.
