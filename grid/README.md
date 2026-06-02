# grid -- FermiGrid submission & log extraction

Real, working grid workflow for running NuGraph inference (via EAF) on the grid with
LArBatch / `project.py`. The same pattern applies to other ML inference stages -- only the fcl and the
model-specific bits change.

Files here:
- `testsubmit.xml` -- the real submission XML, with user-specific folders replaced by
  the `&user;` entity (set it before running, see below).
- `extractLogs.sh` -- pull + unpack `log.tar` from a list of jobs for failure analysis.

> 🔒 **Placeholders so nothing of anyone's gets overwritten.** `testsubmit.xml` won't
> run until you set `<!ENTITY user "...">` to your username and confirm the
> `outdir` / `workdir` / tarball paths are yours. `extractLogs.sh` refuses to run
> while its `BASE` still contains `CHANGEME`.

---

## Submitting jobs (the full workflow)

Author of this recipe: S. Dey. General reference:
<https://sbnsoftware.github.io/sbndcode_wiki/Using_projectpy_for_grid_jobs.html>
Dashboard: <https://fifemon.fnal.gov/monitor/d/000000116/user-batch-details?orgId=1&var-cluster=fifebatch&var-user=YOUR_USER&from=now-15m&to=now>

```bash
# 1) standard icaruscode setup
sh /exp/$(id -ng)/data/users/vito/podman/start_SL7dev_jsl.sh
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p01 -q e26:prof
cd /exp/icarus/app/users/<USER>/<DEV_AREA>
source localProducts_larsoft_v10_06_00_e26_prof/setup
mrbslp

# 2) bearer token + the LArBatch version whose project.py understands tokens
#    (skip the version bump and project.py errors out)
htgettoken -a htvaultprod.fnal.gov -i icarus
unsetup larbatch
setup larbatch v01_61_00

# 3) submit
cd /exp/icarus/app/users/<USER>/<DEV_AREA>/GridWork
project.py --xml testsubmit.xml --stage ng2test --submit
```

`project.py` also supports `--check` (how many files processed), `--makeup` (retry
failed jobs), and `--clean` -- same `--xml/--stage` syntax.

### Checking results

```bash
cat larStage0.out          # in the defined output dir: time + memory summary
less larStage0.err
cat Stage0.fcl             # resolved fcl -- errors are often visible here
```

Job control:
```bash
jobsub_q  --user <USER> -G icarus
jobsub_rm --jobid <PID>
jobsub_q  --hold --user <USER> -G icarus                              # held codes
jobsub_release --constraint '(JobStatus=?=5) && (Owner=?="<USER>")'  # release held
jobsub_rm      --constraint '(JobStatus=?=5) && (Owner=?="<USER>")'  # remove held
```

> A code tarball is referenced by `<local>` in the XML
> (`.../tarballs/icaruscode-workingarea-<release>.tar.gz`). Build/refresh that tarball
> from your dev area whenever your code changes, or the grid runs stale code.

## The XML, field by field

| Field | Meaning | Model-specific notes |
|-------|---------|---------------|
| `&user;` (entity) | your username | **set this first** |
| `<numevents>` | total events cap | -- |
| `<resource>` | `DEDICATED,OPPORTUNISTIC` | leave as-is |
| `<larsoft><local>` | your code tarball | rebuild when code changes |
| `<inputlist>` | de-duplicated file list (`files_clean.list`) | dup *names* throw art errors |
| `<fcl>` | **one** fcl only (two -> Error 90) | -> the target model `..._eaf.fcl` |
| `<outdir>` / `<workdir>` | your scratch/resilient areas | **must be yours** |
| `<numjobs>` / `<maxfilesperjob>` | scale knobs | files/job is NOT a concurrency knob (docs/06) |
| `<memory>` / `<disk>` | resource request | raise on Error 137 / "disk usage greater than requested" |
| `<jobsub>` | extra condor flags + Singularity image | leave as-is |

ICARUS caps submissions at **10k jobs** at a time.

---

## Extracting logs from failed jobs (`extractLogs.sh`)

When a batch has failures, this collects the per-job `log.tar` files into a local
`bad_logs/` directory so you can grep them.

**Where to run:** on a GPVM, after the jobs finish, from a writable working dir.
**Set up first:** point `BASE` at *your* job output dir and create a `bad.list`
(one job-subdir name per line -- get the failed-job ids from the dashboard or `--check`).

```bash
export BASE=/pnfs/icarus/scratch/users/$USER/v10_06_00_01p01/ng2_eaf_v1   # YOUR outdir
# put the failed job dir names in $BASE/bad.list, then:
./extractLogs.sh
```

Outputs (in `$PWD`): `bad_logs/<job>/...`, plus `missing_logs.txt` and
`extract_failures.txt`. Then scan for failure modes:
```bash
grep -Rni "error\|exception\|failed\|triton\|cannot\|file\|art::Exception" bad_logs/
```
(See `docs/07` for what the common matches mean.)
