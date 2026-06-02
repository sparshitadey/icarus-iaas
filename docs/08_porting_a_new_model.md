# 08 -- Porting the pipeline to a new model (the CVN guide)

> **Read this first if your job is "do what was done for NuGraph, but for CVN."**
> You do **not** need to rebuild the infrastructure. The Triton/EAF/grid machinery
> is model-agnostic. Your work is to swap in a small set of model-specific pieces
> and then re-run the same validation and stress tests.

---

## The mental model

A model runs through Triton in two halves:

```
   ICARUS / LArSoft job (CLIENT)                 Triton server (SERVER)
   -----------------------------                 ----------------------
   an art module + its .fcl    -- gRPC over -->   model_repository/
   (e.g. NuGraphInferenceSonic)   the network     <model>/1/model.py (+ weights)
                                                   <model>/config.pbtxt
```

To port to CVN you touch **both halves**, but only the parts that describe *this
model's* tensors, name, and output products. Everything about *how* the client
talks to the server, *where* the server runs, and *how* you submit grid jobs is
reused unchanged.

---

## What is MODEL-SPECIFIC (you change these for CVN)

| # | Component | NuGraph reference | What CVN needs | Lives in |
|---|-----------|-------------------|----------------|----------|
| 1 | **Triton model name** | `nugraph2_icarus_mpvmprbnb` | a CVN model name (ask whoever deploys it) | server bucket + your fcl |
| 2 | **`config.pbtxt`** (server) | NuGraph input/output tensor names, shapes, dtypes | CVN's tensors (e.g. image dims, class scores) | `server/<model>/config.pbtxt` |
| 3 | **`model.py` + weights** (server) | NuGraph checkpoint + forward() | CVN checkpoint + its forward()/preprocessing | `server/<model>/1/` (deployed by model owner) |
| 4 | **Server-side python env** | needed `pynvml` workaround, `FeatureExtension` in `nugraph.util` | CVN's own deps must be in the env | server image / models-env |
| 5 | **Inference module fcl** | `nugraph_icarus_triton*.fcl` sets the module + URL + model name | point the CVN module at the CVN model | `fcl/cvn/` |
| 6 | **Top-level test fcl** | `testinference_slice_icarus_triton*.fcl` (#includes the above) | the CVN equivalent | `fcl/cvn/` |
| 7 | **ROOT dictionary entries** | had to add `art::Assns<anab::FeatureVector<N>, recob::Hit>` etc. to `IcarusObj/classes_def.xml` + `classes.h` | whatever data products CVN writes (only if you hit Error 7) | `dictionaries/` + `srcs/.../IcarusObj/` |
| 8 | **The inference module .cc** | porting `libtorch single-slice` -> `NuSonic multi-slice` | same port for CVN's module | `icaruscode` / `larrecodnn` |

That's the whole list. If you've handled 1-8, you've ported the model.

> The reference fcls are now real (`fcl/nugraph/`), so the field-by-field mapping for
> items 1, 5, 6 is concrete -- see **`fcl/cvn/README.md`** for the per-knob NuGraph->CVN
> table (presets, `TritonConfig.modelName`, `serverURL` handling, loader/decoder labels,
> single vs multi-slice). `dictionaries/` now holds the full real `classes_def.xml` for
> item 7, with the NuGraph additions marked `<!--New Add -->`.

## What is INFRASTRUCTURE (reuse as-is, do NOT reinvent)

- GPVM login, SL7 container, `setup_icarus.sh`, `setup icaruscode`, token auth -- see `docs/01`.
- The Triton **launch mechanism** (apptainer, the `setup_tritonserver-*.sh` pattern) -- `docs/03`.
- The **EAF deployment** pattern and `triton.fnal.gov:443` endpoint -- `docs/04`.
- **Grid submission** via `project.py` + an XML stage definition -- `docs/05`.
- **Monitoring**: Prometheus/Grafana, Landscape, MinIO dashboards -- `docs/06`.
- The **stress-test methodology** and the metrics that matter (queue time, pending
  requests, per-inference compute time, success rate) -- `docs/06`.

---

## The four modules you should know (single->multi, libtorch->NuSonic)

There are four flavours of the inference module. The axes are **(libtorch vs NuSonic/Triton)**
and **(single-slice vs multi-slice)**:

| | single slice | multi slice |
|--|--------------|-------------|
| **libtorch (local)** | `larrecodnn` `NuGraphInference_module.cc` | `icaruscode` `ICARUSNuGraphInference_module.cc` |
| **NuSonic (Triton)** | `larrecodnn` `NuGraphInferenceSonicTriton_module.cc` | **the goal -- being built** |

- We started from **libtorch, single slice** and reached **NuSonic, single slice** (stages a + b).
- We want **NuSonic, multi slice**, which is needed to push enough concurrent
  requests to actually saturate the server.
- For **CVN**: find CVN's equivalents of these modules. If CVN already has a
  Sonic/Triton module, you may be able to skip straight to the fcl-level work.
  If it only has a libtorch module, the .cc port is part of the job (item 8).

Reference links (NuGraph):
- libtorch single: `larrecodnn/NuGraph/NuGraphInference_module.cc`
- NuSonic single: `larrecodnn/NuGraph/NuGraphInferenceSonicTriton_module.cc`
- libtorch multi (ICARUS): `icaruscode/TPC/NuGraph/ICARUSNuGraphInference_module.cc`

---

## Step-by-step checklist for CVN

> Tick these in order. Each step has a "done when" so you know to move on.

### Phase 0 -- environment (one-time, identical to NuGraph)
- [ ] Get onto a GPVM and into the SL7 image -- `docs/01`.
- [ ] Set up `icaruscode` + your dev area, get a token -- `docs/01`.
- [ ] **Done when:** `echo $MRB_TOP` points at *your* dev area, not `/cvmfs/...`
      (see Error 90 in `docs/07`).

### Phase 1 -- get a working CVN reference chain (no Triton yet)
- [ ] Find the branch / code that already runs CVN in the ICARUS chain. (For
      NuGraph this was Riccardo & Giuseppe's branch.) Ask the ML reco group.
- [ ] Run CVN locally (libtorch) end-to-end on ~5 events; confirm exit code 0.
- [ ] **Done when:** you can produce a valid output ROOT file with CVN's products
      and inspect its TTrees (`docs/02`).

### Phase 2 -- (a) CVN via local Triton on the GPVM (CPU)
- [ ] Deploy / locate the CVN model in a Triton `model_repository` with a
      `config.pbtxt` -- `server/`. Get its **model name** and tensor spec.
- [ ] Create `fcl/cvn/cvn_icarus_triton.fcl` and a top-level
      `testinference_..._cvn_triton.fcl` from the NuGraph templates; set the model
      name + `localhost` URL.
- [ ] Spin up the local Triton server, run the client fcl.
- [ ] **Done when:** the server log shows the CVN model `READY` and the metrics
      endpoint reports successful inference requests (`docs/03`, `docs/06`).

### Phase 3 -- (b) CVN via EAF (GPU)
- [ ] Ask the model owner to upload the CVN model to the EAF `triton-models` bucket
      and fix its `config.pbtxt` -- `docs/04`.
- [ ] Request EAF + MinIO access via Service Desk if you don't have it.
- [ ] Duplicate your fcls to `..._eaf.fcl`, point them at `triton.fnal.gov:443`.
- [ ] **Done when:** a job runs against EAF with exit code 0 and the **server-side**
      dashboard (Landscape) shows it running on GPU.

### Phase 4 -- validate + stress test
- [ ] Run the standard event-count scans; reproduce the time/memory/throughput plots
      (`analysis/notebooks`, `docs/06`).
- [ ] Submit grid jobs and scale up (1k -> 10k jobs) -- `docs/05`.
- [ ] Watch for the saturation signatures (queue time, pending request count) and
      compare CVN's behaviour to NuGraph and to the MicroBooNE failure regime.
- [ ] **Done when:** you can state whether CVN stays in the stable regime or hits
      saturation, with dashboard evidence.

### Phase 5 -- (c) NERSC / ASC *(future, blocked on accounts)*
- [ ] Get NERSC / American Science Cloud accounts.
- [ ] Re-point the server URL; the client fcls should otherwise be unchanged.
- [ ] **Done when:** the same job runs against a non-EAF GPU endpoint.

---

## Common issues that will bite you (learned the hard way on NuGraph)

- **Most "file not found" (Error 90) errors are environment problems, not missing
  files.** If `$MRB_TOP` is empty you're running global `lar`, not your local build.
  Re-source `localProducts*/setup` + `mrbsetenv` + `mrbslp`. See `docs/07`.
- **A missing ROOT dictionary (Error 7)** for a model's output associations means
  you must register those classes in `IcarusObj/classes_def.xml` and `classes.h`,
  then rebuild. CVN's output products will differ from NuGraph's. See `dictionaries/`.
- **"Unknown model" (Error 65) is usually a server-side environment failure**, not a
  bad URL -- check the *server* logs (Landscape), not just your client log.
- **The "CPU Memory/Time" label in the LArSoft summary is misleading** -- it prints
  the same string regardless of CPU/GPU. Add a print of `torch.cuda.is_available()`
  / device in `model.py` to confirm you're actually on GPU.
- **More files-per-job != more concurrency.** Files run sequentially within a job; to
  raise concurrency you need multi-slice / multi-batch processing, not bigger jobs.
- **Small batches hide the GPU speedup.** At 5 events CPU and GPU look similar; the
  win shows up at scale.
