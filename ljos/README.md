# ljos seat pack for Snellius

[ljos](https://github.com/HaoZeke/ljos) is a seat that any coding agent runner shares: a memory pack, a work
tracker, a deed store and a vote. A runner that sits in the seat is handed the memories a prompt activates
before it acts, whichever model or harness it is. This directory loads the Snellius rules and the system
facts into such a seat, once, so that every runner on the person's machine carries the same context.

`snellius-pack.sh` writes:

- two personas, `snellius` and `hpcsite`, that vote on decisions from the batch system's side;
- the standing preferences from this guide: login node use, interactive allocations, no polling, job
  scripts that state their resources, secrets, bursts, filesystem walks;
- the facts that trip people up: the failed-login ban, scratch retention and quotas, `$TMPDIR`, the staging
  and cbuild partitions, Apptainer and bwrap, trial jobs;
- one line per partition with cores, memory, smallest allocation, SBU weight and walltime, generated from
  the handbook by [snelnext](https://github.com/HaoZeke/snelnext) (`tools/ljos_snellius_pack.py`).

Run it on the machine where the agents run, after `ljos onboard`:

```bash
bash ljos/snellius-pack.sh
ljos search "login node"
```

Nothing in the pack names a hostname, a path under a home, or a credential; it is the public handbook in
sentences a seat can hold. Regenerate it from snelnext when the partitions page changes.
