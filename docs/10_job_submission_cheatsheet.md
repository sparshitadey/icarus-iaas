# 10 - Job submission cheat sheet

This is the short copy-paste version of `docs/05_grid_submission.md`. Use the longer guide when something fails.

## Start an SL7 session and set up ICARUS

```bash
sh /exp/$(id -ng)/data/users/vito/podman/start_SL7dev_jsl.sh
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p01 -q e26:prof
cd /exp/icarus/app/users/<USER>/<DEV_AREA>
source localProducts_larsoft_v10_06_00_e26_prof/setup
mrbslp
```

For a full rebuild, prefer `icarusbuild02` rather than a GPVM. On GPVMs you may be restricted to fewer cores; on the build node you can use a larger build command such as:

```bash
mrb i -j20
```

## Token and LArBatch

```bash
htgettoken -a htvaultprod.fnal.gov -i icarus
unsetup larbatch
setup larbatch v01_61_00
```

The LArBatch version matters because this version of `project.py` handles the bearer-token workflow.

## Submit, check, retry

```bash
cd /exp/icarus/app/users/<USER>/<DEV_AREA>/GridWork

project.py --xml testsubmit.xml --stage ng2test --submit
project.py --xml testsubmit.xml --stage ng2test --check
project.py --xml testsubmit.xml --stage ng2test --makeup
project.py --xml testsubmit.xml --stage ng2test --clean
```

## Job status

```bash
jobsub_q --user <USER> -G icarus
jobsub_q --hold --user <USER> -G icarus
jobsub_rm --jobid <PID>
```

Release or remove held jobs:

```bash
jobsub_release --constraint '(JobStatus=?=5) && (Owner=?="<USER>")'
jobsub_rm      --constraint '(JobStatus=?=5) && (Owner=?="<USER>")'
```

Be careful with this one; it removes all jobs owned by the user:

```bash
jobsub_rm --constraint '(Owner=?="<USER>")'
```

## After a job finishes

In the job output directory:

```bash
cat larStage0.out
less larStage0.err
cat Stage0.fcl

tar -tf log.tar
mkdir -p log_unpack
tar -xf log.tar -C log_unpack
cd log_unpack

grep -Rni "error\|exception\|failed\|triton\|cannot\|file\|art::Exception" .
```

## Dashboard links

- User batch dashboard: <https://fifemon.fnal.gov/monitor/d/000000116/user-batch-details?orgId=1&var-cluster=fifebatch&var-user=<USER>&from=now-15m&to=now>
- Held jobs: <https://fifemon.fnal.gov/monitor/d/000000146/why-are-my-jobs-held?orgId=1&var-user=<USER>>

## Scaling notes

- ICARUS currently limits submissions to about 10k jobs at a time.
- More files per job usually means longer jobs, not more parallel inference requests.
- For true concurrency pressure, move towards multi-slice or multi-batch processing.
- Save dashboard snapshots or exported data after each stress test so timing, queueing, and failure behaviour can be compared later.

