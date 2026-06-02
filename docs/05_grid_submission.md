# 05 -- Grid Submission

> How to carry the Triton/EAF workflow into LArBatch/project.py, monitor running jobs, and recover timing, memory, and failure information.

---

> 🔗 **Useful references:** [SBN project.py guide](https://sbnsoftware.github.io/sbndcode_wiki/Using_projectpy_for_grid_jobs.html), [FIFE batch dashboard](https://fifemon.fnal.gov/monitor/d/000000116/user-batch-details?orgId=1&var-cluster=fifebatch&from=now-15m&to=now), and [held-job dashboard](https://fifemon.fnal.gov/monitor/d/000000146/why-are-my-jobs-held?orgId=1).

Once a single job works against EAF, you scale out on the grid with
**LArBatch / `project.py`**, driven by an XML stage definition. `project.py` manages
the jobs so you don't track them by hand.

Useful links:
- General grid submission instructions (FIFE).
- Job dashboard: <https://fifemon.fnal.gov/monitor/d/000000116/user-batch-details?orgId=1&var-cluster=fifebatch&var-user=<you>>
- "Why are my jobs held": <https://fifemon.fnal.gov/monitor/d/000000146/why-are-my-jobs-held?orgId=1&var-user=<you>>

## Setup Before Submitting

```bash
sh /exp/$(id -ng)/data/users/vito/podman/start_SL7dev_jsl.sh
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p01 -q e26:prof
cd /exp/icarus/app/users/<you>/<your-dev-area>
source localProducts_larsoft_v10_06_00_e26_prof/setup
mrbslp

# token + the LArBatch version whose project.py understands tokens:
htgettoken -a htvaultprod.fnal.gov -i icarus
unsetup larbatch
setup larbatch v01_61_00
```
> If you skip the LArBatch version bump, `project.py` errors out because the older
> version can't handle the bearer token.

## Submit / Check / Clean

```bash
cd /exp/icarus/app/users/<you>/<dev>/GridWork
project.py --xml /path/to/<file>.xml --stage <stage> --submit   # submit
project.py --xml /path/to/<file>.xml --stage <stage> --check    # how many files processed
project.py --xml /path/to/<file>.xml --stage <stage> --makeup   # retry failed jobs
project.py --xml /path/to/<file>.xml --stage <stage> --clean    # remove unwanted job files
```

## Job Status / Removing / Releasing

```bash
jobsub_q --user <you> -G icarus                                 # status
jobsub_rm --jobid <PID>                                         # remove by id
jobsub_q --hold --user <you> -G icarus                          # held-codes of held jobs
jobsub_release --constraint '(JobStatus=?=5) && (Owner=?="<you>")'   # release held
jobsub_rm      --constraint '(JobStatus=?=5) && (Owner=?="<you>")'   # remove held
# jobsub_rm    --constraint '(Owner=?="<you>")'                 # remove ALL -- BE CAREFUL
```

## Held Jobs

Jobs are usually held when requested resources exceed what the grid grants (e.g.
"disk usage greater than requested", or memory -> Error 137). Simplest path: remove
the held jobs, then `--check` and `--makeup` with adjusted resources in the XML.

## What to Expect While Running

There's a lag between *submitted* -> *running* -> *completed*; jobs sit **idle** in
queue for a while -- don't panic. If they hang too long, lower the requested memory
or the number of jobs.

## Reading Job Statistics & Logs

After a job finishes, in its output dir:
```bash
cat larStage0.out          # time + memory summary
less larStage0.err
cat Stage0.fcl             # the resolved fcl -- errors often visible here

# unpack the bundled logs:
tar -tf log.tar
mkdir -p log_unpack && tar -xf log.tar -C log_unpack && cd log_unpack
grep -Rni "error\|exception\|failed\|triton\|cannot\|file\|art::Exception"
```
Common: **Error 90** (file not found -- e.g. you listed two fcls in the XML when one
was needed), **Error 137** (memory -- raise the quota in the XML).

## Example XML Files (Reference)

- Giuseppe (NG2): `/exp/icarus/app/users/cerati/icaruscode-v10/srcs/testnuml-new.xml`
- Sparshita's NuGraph Triton-via-EAF working XML reference:
  `/exp/icarus/app/users/sdey2/icaruscode-v10_06_00_01p01_rtriozzi/GridWork/testsubmit.xml`

  This is included as a provenance/reference path. A new user should copy the
  template in `grid/testsubmit.xml` and replace the user, output, work, and
  tarball paths before submitting.
- Riccardo (full gen->CAF production chain):
  `/exp/icarus/app/users/rtriozzi/productions/NuGraph/.../Gridjob_NuMI_Nominal_NuGraphReco_AllSlices_HIPTagger_moreStats.xml`

The **real, working** XML (with your paths placeholdered as the `&user;` entity) is
`grid/testsubmit.xml`, and `grid/README.md` walks the full submit/check/extract
workflow field by field.

## Practical Scale Notes (from NuGraph Runs)

- ICARUS caps submissions at **10k jobs** at a time.
- Duplicating an events list to fake scale:
  `awk '{for(i=0;i<300;i++) print}' files.list > files_dup.list`
  (but **duplicate file *names* can throw art errors** -- use a clean, de-duplicated
  list; for NuGraph this was `fileLists/files_clean.list`).
- More **files per job** lengthens jobs but does **not** add concurrency
  (files run sequentially). Concurrency needs multi-slice / multi-batch -- `docs/06`.
