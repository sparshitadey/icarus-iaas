# ICARUS Inference-as-a-Service (IaaS)

Bringing ML inference in the ICARUS reconstruction chain off local CPU and onto
remote GPU servers via the **Triton inference server** (NuSonic), instead of
running models in-process with libtorch.

This repo documents a **working, reproducible pipeline**, first demonstrated for
**NuGraph2**, and is structured so that the same pipeline can be applied to other
ML stages in the chain (**DNN ROI**, **CVN**, ...). The ML inference steps are the
dominant time cost in production (the full chain can take O(months)), so moving
them to a shared, scalable GPU service is the goal.

---

## TL;DR -- what you actually need to know

The pipeline has three deployment targets, in increasing order of scale:

| Stage | What | Status |
|-------|------|--------|
| **(a)** Triton server **locally on a GPVM** (CPU only) | Prove the client/server wiring works | [done] working |
| **(b)** Triton server **via EAF** (GPU nodes) | Real GPU inference, grid-scale | [done] working |
| **(c)** Triton via **NERSC** and/or **American Science Cloud** | Cross-facility, cross-experiment scale | [todo] not started (needs accounts) |

Plus two cross-cutting work items:

- **Batch / multi-slice processing** -- moving the model from single-slice,
  single-batch to multi-slice, multi-batch so we can actually saturate the server.
  *(code is ready, testing in progress -- fcls + module changes coming soon)*
- **Stress testing** -- push load until the server saturates; compare to the
  MicroBooNE scale test (which hit a queue-dominated failure regime at ~8% success).

**The single most important fact for a new model (e.g. CVN):** almost everything
in this repo is reusable infrastructure. Only a small, well-defined set of pieces
are *model-specific*. See [`docs/08_porting_a_new_model.md`](docs/08_porting_a_new_model.md)
-- start there if your job is "do this for CVN."

---


## Access and accounts needed

Before starting from scratch, a new student should check they have:

- Fermilab services account and password.
- ICARUS GPVM access.
- Access to `/exp/icarus/app/users/<USER>` and the relevant PNFS areas.
- Token access for ICARUS: `htgettoken -a htvaultprod.fnal.gov -i icarus`.
- EAF / MinIO access if using remote Triton: request via the Service Desk link in `docs/11`.
- Access to the Landscape Triton logs and FIFE batch dashboards.

For large rebuilds, use `icarusbuild02` rather than a GPVM where possible. The build
node has more resources, so a command such as `mrb i -j20` is reasonable there; on
GPVMs, use a smaller build such as `mrb i -j4`.

## Repo map

```
icarus-iaas/
|---- README.md                  <- you are here
|---- WORKLOG.md                 <- chronological history (what was tried, in order)
|---- docs/                      <- the actual guides, read in order 00 -> 08
|   |---- 00_concepts.md             IaaS / Triton / gRPC background & why
|   |---- 01_environment_setup.md    GPVM, SL7 image, icaruscode, tokens
|   |---- 02_pipeline_overview.md    Stage0->Stage1->CAF, where ML plugs in
|   |---- 03_local_triton.md         (a) spin up Triton on a GPVM (CPU)
|   |---- 04_eaf_triton.md           (b) Triton via EAF (GPU)
|   |---- 05_grid_submission.md      FermiGrid, project.py, XML, job monitoring
|   |---- 06_stress_testing.md       methodology, dashboards, metrics, MicroBooNE
|   |---- 07_troubleshooting.md      * error-code catalogue (saves hours)
|   |---- 08_porting_a_new_model.md  * THE CVN GUIDE: what is model-specific
|   |---- 09_grep_cheatsheet.md      grep patterns for diagnostics
|   |---- 10_job_submission_cheatsheet.md  quick project.py / jobsub commands
|   `---- 11_triton_eaf_minio_cheatsheet.md EAF, MinIO, Triton logs
|---- fcl/
|   |---- nugraph/               reference (working) NuGraph fcls + notes
|   `---- cvn/                   template + checklist for the CVN port
|---- server/                    Triton model_repository layout, config.pbtxt, launch script
|---- dictionaries/              ROOT dictionary changes (classes_def.xml / classes.h)
|---- grid/                      example project.py XML for grid submission
|---- analysis/                  notebooks to parse logs & plot scale-test results
`---- scripts/                   small helper scripts (health checks, log scans)
```

## How to use this repo

- **New to IaaS?** Read `docs/00` -> `docs/02` for the mental model, then `docs/03`.
- **Reproducing the NuGraph result?** `docs/01` -> `03` -> `04`, using `fcl/nugraph/`.
- **Porting to CVN (or any new model)?** Go straight to `docs/08`, keep `docs/07`
  open in another tab.
- **Stuck on an error code?** `docs/07` -- it's indexed by exit code.
- **Need a quick command?** `docs/09` and `docs/10` are the short diagnostic/job-submission cheat sheets.
- **Need the server-side picture?** `docs/11` summarises EAF, MinIO, model locations, and Triton logs.

## Conventions used throughout

- Working area on disk: `/exp/icarus/app/users/<you>/` (run code here, **not** in `/nashome`).
- Main NuGraph test platform: `icaruscode v10_06_00_01p01`, branch
  `feature/rtriozzi_cerati_NuGraph2_Filter`, qualifier `e26:prof`.
- Triton model name (reference): `nugraph2_icarus_mpvmprbnb`.
- Whenever you see **`TODO[CVN]`** in a file, that's a spot the new student must change.
- **Placeholders for paths** (so you never overwrite anyone's files): `<USER>` =
  your Fermilab username, `<DEV_AREA>` = your icaruscode dev directory. In the grid
  XML this is the `&user;` entity (set it before running); `grid/extractLogs.sh`
  refuses to run while its `BASE` still says `CHANGEME`.

### What's real vs still to come

- [done] **Real, in the repo now:** the six NuGraph fcls (`fcl/nugraph/`), both Triton
  launch scripts (`server/`), the full `classes.h` + `classes_def.xml` (`dictionaries/`),
  the grid `testsubmit.xml` + `extractLogs.sh` (`grid/`, with your paths placeholdered).
- [todo] **Deferred to MinIO:** the real `config.pbtxt` and `model.py` live on
  <https://minio-eaf.fnal.gov/> (`triton-models/...`), not the local area -- the
  `config.pbtxt.template` in `server/` is a placeholder until those are pulled.
- [todo] **Coming:** the multi-slice/multi-batch path (the presets already exist in the
  fcls, just commented out of the paths) and the plotting/log-scan notebooks.

See `FILES_TO_ADD.md` for the running checklist of what's in vs outstanding.
