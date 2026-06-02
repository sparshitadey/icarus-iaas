# WORKLOG -- chronological history

A distilled timeline of what was actually done, in order, so the next person can see
*how* the working state was reached (not just the final recipe). Detail lives in the
original lab log; this is the index. Dates are 2026.

| Date | What happened | Outcome / lesson |
|------|---------------|------------------|
| Jan 6 | First GPVM login + basic CAFAna setup | Established disk layout & base setup (`docs/01`) |
| Feb 4 | Mapped the production chain; got standard Stage0->Stage1 running (no NuGraph) | Baseline chain works; XRootD preferred over raw PNFS |
| Feb 4 | First local Triton server on GPVM (CPU); validated HTTP/gRPC/metrics, health checks | Server wiring works CPU-only; no GPU on GPVM (expected) |
| Feb 9 | Plan: pull Riccardo's branch, run full chain *with* NuGraph, then via Triton | -- |
| Feb 11 | Built dev area from `feature/rtriozzi_cerati_NuGraph2_Filter`; ran NuGraph local | Hit **Error 90** -> MRB env not active; fixed by re-sourcing local build |
| Feb 11-19 | NuGraph local inference debugging | Hit **Error 7** DictionaryNotFound; fixed by adding classes to `IcarusObj/classes_def.xml` + `classes.h` (`dictionaries/`). Then exit 0 |
| Feb 23 | Wired NuGraph through **local Triton** (new `*_triton.fcl`) | Server handled inference requests, 0 failures (CPU still) |
| Feb 26 | EAF + MinIO access approved; model visible at `triton-models/nugraph2_icarus_mpvmprbnb` | Model owner set up config on EAF |
| Feb 27 | Pointed fcls at **EAF** (`*_triton_eaf.fcl`, `triton.fnal.gov:443`) | Could reach server; model search OK |
| Mar 3 | **Error 65** unknown model | Server-side env: `pynvml.smi` import failure; unused `pynvml` commented out (Burt) |
| Mar 3 | Re-ran with updated env -> **Error 1** AttributeError (`FeatureExtension`) | Reached `forward()`; env stale -> owner updated env. Then exit 0 |
| Mar 4 | Confirmed actually on **GPU** via device prints in `model.py` | "CPU Memory/Time" label is misleading; GPU confirmed (`docs/04`) |
| Mar 5-19 | Event-count scans; chased a memory/timing bump | **Not a bug** -- ACLiC edge effect on partial files (`docs/06`) |
| Mar 19 | Consolidated test platform | `/exp/.../IaaS-TritonEAF/...`; single-batch only so far |
| Mar 30-31 | Grid submission set up (`project.py`, LArBatch `v01_61_00`, XML) | Token-aware project.py; submitted small jobs |
| Apr 1 | 6000 events (300 jobs, 1 file/job) on grid | Worked fine |
| Apr 2-3 | First real stress tests; some large runs had many failures | Investigating failure modes; wrote a batch log-scan notebook |
| Apr 8 | Compared to **MicroBooNE** scale test (~8% success, saturation) | Identified the saturation/queue-dominated regime to watch for (`docs/06`) |
| Apr 9-12 | EAF maintenance/downtime; MinIO timeouts, `evhtp ODDITY` warnings | Infra flakiness, not config (`docs/07`) |
| Apr 13 | EAF back; **1k jobs -> 98.3%**, **10k jobs -> 96.35%** success | ICARUS stays in the **stable** regime, unlike MicroBooNE |
| Apr 16 | Presented results: stable regime, no runaway backlog, inference ~120-160 ms | Job count != saturation; concurrency/request-rate is the real axis |
| Apr 17 | Plan with Giuseppe: move toward **NuSonic multi-slice** | Have libtorch single-slice + NuSonic single-slice; need NuSonic multi-slice |
| Apr 18-22 | Re-writing fcls for multi-batch / multi-slice | In progress |
| Apr 21 | Confirmed **files-per-job is not a concurrency knob** | Need multi-slice/multi-batch to create concurrent load (`docs/06`) |
| May 31 | Paused IaaS meetings (DUNE collab meeting etc.); resuming | Next: test new batch-processing fcls |

## Where things stand now

- [done] (a) local Triton on GPVM, [done] (b) Triton via EAF on GPU -- both reproducible.
- [in progress] Multi-slice / multi-batch fcls + module work -- **code ready, testing in progress**
  (will be added to `fcl/` and the module references when validated).
- [todo] Stress test to actual saturation; then (c) NERSC / American Science Cloud (needs accounts).

## Coming soon (to be added to this repo)

- The multi-slice / multi-batch fcls (-> `fcl/`) and the NuSonic-multi-slice module reference.
- The plotting + log-scan notebooks (-> `analysis/notebooks/`).
- Real copies of the working fcls / launch script / XML (currently documented as
  pointers to their on-disk canonical locations).
