# ICARUS Inference as a Service Workflow

> As ML methods move deeper into the reconstruction chain, inference is no longer a small downstream detail: it becomes part of the production infrastructure. This repository records the ICARUS IaaS workflow developed around NuGraph2, with the aim of making the same pattern reusable for CVN and other inference-heavy reconstruction tasks.

![Status](https://img.shields.io/badge/status-work--in--progress-yellow)
![Experiment](https://img.shields.io/badge/experiment-ICARUS-blue)
![Workflow](https://img.shields.io/badge/workflow-IaaS%20%7C%20Triton%20%7C%20EAF-purple)

---

## ⚠️ Work in Progress

This repository is a live technical handoff, not a frozen production manual. The NuGraph2 benchmark path is documented from local validation through EAF/grid submission and stress testing, while multi-slice and multi-batch extensions are still being tested. Treat commands as reproducible starting points, then check the latest commits and `WORKLOG.md` before launching large jobs.

> 📝 **Reference-path note:** paths under `/exp/icarus/app/users/sdey2/...` are provenance locations from the original NuGraph2 setup. They are useful places to inspect the benchmark files, but they should not be used as writable output areas by a new user. Runnable templates use placeholders such as `<USER>`, `<DEV_AREA>`, and `&user;`.

---

## Contents

- [Overview](#overview)
- [Workflow Snapshot](#workflow-snapshot)
- [Status At A Glance](#status-at-a-glance)
- [Repository Map](#repository-map)
- [Documentation Index](#documentation-index)
- [Quick Start](#quick-start)
- [What Is Reusable?](#what-is-reusable)
- [Known Working Benchmark](#known-working-benchmark)
- [Figures And Reference Slides](#figures-and-reference-slides)
- [Conventions](#conventions)

---

## Overview

This repository documents a reusable ICARUS workflow for deploying ML inference through Triton and the Elastic Analysis Facility (EAF). NuGraph2 is used as the benchmark implementation because it exercises the full chain: FHiCL configuration, Triton model access, EAF deployment, grid submission, diagnostics, and stress testing.

The broader aim is not to build a NuGraph-only handoff. The aim is to separate the infrastructure that should be reusable from the model-specific pieces that change between algorithms. CVN is included as one concrete adaptation example; the same pattern should apply wherever ML-based inference becomes a bottleneck in ICARUS or related reconstruction workflows, including DNN ROI, NuGraph, CVN, and future models.

---

## Workflow Snapshot

![ICARUS NuGraph2 Reconstruction Chain](assets/nugraph_reconstruction_chain.png)

The core pattern is simple: keep the reconstruction job as the client, move the expensive model execution to a Triton server, and use EAF GPU resources when local CPU inference becomes the bottleneck.

![IaaS Client Server Pattern](assets/iaas_client_server.png)

---

## Status at a Glance

| Stage | Deployment Target | Purpose | Status |
|---|---|---|---|
| **(a)** | Local Triton on a GPVM | Validate client/server wiring; CPU-only sanity test | ✅ Working |
| **(b)** | Triton through EAF | GPU inference and grid-scale running | ✅ Working |
| **(c)** | NERSC and/or American Science Cloud | Cross-facility scaling path | ⏳ Not started |
| **Next** | Multi-slice / multi-batch | Increase request concurrency and push towards saturation | 🚧 Testing |
| **Next** | Stress testing | Map the stable-to-saturated transition | 🚧 In progress |

### ✅ Known Working Benchmark

The NuGraph2 Triton-via-EAF path has been demonstrated from small validation jobs through larger grid submissions. In the tested range, ICARUS remains in a stable operating regime: inference compute time stays around 120-160 ms, request counts scale with load, and there is no evidence yet of a runaway backlog.

![Stress Test Summary](assets/stress_test_summary.png)

---

## Repository Map

```text
icarus-iaas/
├── README.md                  <- orientation and contents
├── WORKLOG.md                 <- chronological record of what was tried
├── FILES_TO_ADD.md            <- status of real artefacts and deferred pieces
├── assets/                    <- small documentation figures extracted from slides
├── docs/                      <- ordered technical guides
│   ├── 00_concepts.md
│   ├── 01_environment_setup.md
│   ├── 02_pipeline_overview.md
│   ├── 03_local_triton.md
│   ├── 04_eaf_triton.md
│   ├── 05_grid_submission.md
│   ├── 06_stress_testing.md
│   ├── 07_troubleshooting.md
│   ├── 08_porting_a_new_model.md
│   ├── 09_grep_cheatsheet.md
│   ├── 10_job_submission_cheatsheet.md
│   └── 11_triton_eaf_minio_cheatsheet.md
├── fcl/
│   ├── nugraph/               <- real NuGraph benchmark FHiCL files
│   └── cvn/                   <- concrete example adaptation area
├── server/                    <- Triton launch scripts and model-repository notes
├── dictionaries/              <- ROOT dictionary changes for NuGraph products
├── grid/                      <- project.py XML and log extraction helper
├── analysis/                  <- plotting/log-scan notebook placeholders
└── scripts/                   <- small health-check helpers
```

---

## Documentation Index

| Document | Purpose |
|---|---|
| [`docs/00_concepts.md`](docs/00_concepts.md) | IaaS, Triton, gRPC, and why inference belongs in the production infrastructure |
| [`docs/01_environment_setup.md`](docs/01_environment_setup.md) | ICARUS account, GPVM/build-node, MRB, token, and disk-area setup |
| [`docs/02_pipeline_overview.md`](docs/02_pipeline_overview.md) | Stage0 -> Stage1 -> NuGraph -> CAF workflow and where ML plugs in |
| [`docs/03_local_triton.md`](docs/03_local_triton.md) | Local Triton validation on a GPVM; CPU-only but useful for wiring checks |
| [`docs/04_eaf_triton.md`](docs/04_eaf_triton.md) | Triton through EAF GPU infrastructure and server-side diagnostics |
| [`docs/05_grid_submission.md`](docs/05_grid_submission.md) | LArBatch/project.py grid submission workflow and log extraction |
| [`docs/06_stress_testing.md`](docs/06_stress_testing.md) | Scaling tests, queueing behaviour, dashboard interpretation, and MicroBooNE comparison |
| [`docs/07_troubleshooting.md`](docs/07_troubleshooting.md) | Error-code catalogue and high-value diagnostics |
| [`docs/08_porting_a_new_model.md`](docs/08_porting_a_new_model.md) | General adaptation guide, with CVN as one concrete example |
| [`docs/09_grep_cheatsheet.md`](docs/09_grep_cheatsheet.md) | Fast grep patterns for logs, FHiCL, and Triton output |
| [`docs/10_job_submission_cheatsheet.md`](docs/10_job_submission_cheatsheet.md) | Compact `project.py` and `jobsub` command reference |
| [`docs/11_triton_eaf_minio_cheatsheet.md`](docs/11_triton_eaf_minio_cheatsheet.md) | EAF, MinIO, Triton logs, model locations, and access notes |

---

## Quick Start

### 1. Check Access

Before starting from scratch, make sure you have:

- ✅ Fermilab services account and password.
- ✅ ICARUS GPVM access.
- ✅ Access to `/exp/icarus/app/users/<USER>` and the relevant PNFS areas.
- ✅ ICARUS bearer-token access: `htgettoken -a htvaultprod.fnal.gov -i icarus`.
- ✅ EAF / MinIO access for remote Triton work.
- ✅ Access to the Landscape Triton logs and FIFE batch dashboards.

For large rebuilds, use `icarusbuild02` rather than a GPVM where possible. The build node has more resources, so `mrb i -j20` is reasonable there; on a GPVM, use something smaller such as `mrb i -j4`.

### 2. Follow the Path

| If You Want To... | Start Here |
|---|---|
| Understand the architecture | `docs/00_concepts.md` |
| Build or re-enter the ICARUS dev area | `docs/01_environment_setup.md` |
| Reproduce the NuGraph benchmark | `docs/01` -> `docs/03` -> `docs/04` with `fcl/nugraph/` |
| Submit jobs through the grid | `docs/05_grid_submission.md` and `grid/` |
| Diagnose failures | `docs/07_troubleshooting.md` plus `docs/09_grep_cheatsheet.md` |
| Adapt the pattern to another model | `docs/08_porting_a_new_model.md` |

---

## What Is Reusable?

The reusable part is the scaffolding: environment setup, Triton connection, EAF deployment, grid submission, monitoring, log extraction, and stress-test methodology.

The model-specific part is deliberately small and visible:

| Component | Reusable Infrastructure | Model-Specific Surface |
|---|---|---|
| FHiCL | Same client/server pattern | Producer labels, model name, tensor names, product labels |
| Triton | Same model repository pattern | `config.pbtxt`, backend, `model.py` / `model.pt`, input/output tensors |
| Grid | Same `project.py` / XML strategy | Target FHiCL, file lists, resource requests |
| Diagnostics | Same logs, metrics, dashboards | Expected products and failure signatures |
| Dictionaries | Same method | The missing product classes differ by model |

CVN is included as a concrete adaptation example, not as the only intended endpoint. The organising principle is broader: once inference becomes a production bottleneck, the same IaaS pattern can be tested, monitored, and scaled.

---

## Figures and Reference Slides

The `assets/` folder contains small documentation figures extracted from the reference slide decks:

- `assets/nugraph_reconstruction_chain.png` -- where NuGraph2 sits in the reconstruction chain.
- `assets/iaas_client_server.png` -- the IaaS client/server pattern.
- `assets/stress_test_summary.png` -- stable ICARUS NuGraph2 stress-test behaviour.
- `assets/queueing_regime.png` -- onset of queueing at higher load.

> 📝 Replace these with final collaboration-approved figures if this repository becomes a public-facing or archived deliverable.

---

## Conventions

- Working area on disk: `/exp/icarus/app/users/<USER>/`.
- Do **not** run large jobs in `/nashome`.
- Main NuGraph benchmark platform: `icaruscode v10_06_00_01p01`, branch `feature/rtriozzi_cerati_NuGraph2_Filter`, qualifier `e26:prof`.
- Triton model name for the benchmark: `nugraph2_icarus_mpvmprbnb`.
- `TODO[CVN]` marks a concrete CVN adaptation point, not the whole purpose of the repository.
- `grid/extractLogs.sh` refuses to run while `BASE` still says `CHANGEME`.

---

## What Is Real Vs Still to Come

| Status | Item |
|---|---|
| ✅ In repo | Six NuGraph FHiCL files, Triton launch scripts, dictionary additions, grid XML, log-extraction helper |
| ⏳ On MinIO | Real `config.pbtxt` and `model.py` for `triton-models/nugraph2_icarus_mpvmprbnb` |
| 🚧 Testing | Multi-slice and multi-batch path |
| ⏳ To add | Plotting notebooks and large-scale log-scan notebooks |

