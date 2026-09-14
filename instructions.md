## Working on Snellius

When working on Snellius, before running workloads, read
`~/.config/snellius-agent/snellius.md` and follow its guidance.

Login nodes `int3`–`int6` are shared: only lightweight interactive work.
Run resource-intensive work or workloads exceeding 10 minutes through
Slurm. `int3` GPU access is for brief development tests only.
Run bulk transfers and transfers involving many small files via `staging`.

If the guide cannot be read, retain these restrictions and report it.
