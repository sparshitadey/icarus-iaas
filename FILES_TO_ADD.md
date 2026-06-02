# Files to Add -- Artefact Status

> A compact manifest of what is already real, what lives elsewhere, and what still needs to be added.

Legend: ✅ **Done** = real file in repo; ⏳ **Deferred** = waiting on MinIO/testing; 📝 **Optional** = useful reference material.

---

## 1. FCLs -> `fcl/nugraph/`   ✅ [DONE]

All six real fcls are in. The only edit was placeholdering a dev-path in a comment
(`<USER>`/`<DEV_AREA>`). Structure documented in `fcl/nugraph/README.md`.
`fcl/cvn/README.md` has the concrete NuGraph->CVN knob mapping.

## 2. Triton Server Side -> `server/`

- ✅ [DONE] `setup_tritonserver-nugraph-v0.sh` (interactive local launch)
- ✅ [DONE] `setup_tritonserver-nugraph-v0_grid.sh` (grid launch: port-find + URL inject)
- ⏳ [DEFERRED -- on MinIO] `nugraph2_icarus_mpvmprbnb/config.pbtxt` -- the real Triton
  config. Pull from `triton-models/nugraph2_icarus_mpvmprbnb`
  (<https://minio-eaf.fnal.gov/>) and drop under `server/nugraph2_icarus_mpvmprbnb/`.
  Replaces `config_templates/config.pbtxt.template` (which is the WCT example, not NuGraph).
- ⏳ [DEFERRED -- on MinIO] `nugraph2_icarus_mpvmprbnb/1/model.py` -- same bucket; the
  one with the GPU-confirmation device prints.
- [OPTIONAL] `model_io_contract.json` -- save `curl -s localhost:8000/v2/models/<model>`.

## 3. Grid -> `grid/`

- ✅ [DONE] `testsubmit.xml` -- real, with user folders as the `&user;` entity (set before running).
- ✅ [DONE] `extractLogs.sh` -- real, with `BASE` parameterised (refuses to run on CHANGEME).
- [OPTIONAL, reference] Giuseppe's `testnuml-new.xml`
  (`/exp/icarus/app/users/cerati/icaruscode-v10/srcs/testnuml-new.xml`) and Riccardo's
  full gen->CAF example
  (`/exp/icarus/app/users/rtriozzi/productions/NuGraph/.../Gridjob_..._moreStats.xml`).
- [OPTIONAL] a small sample `fileLists/files_clean.list` (de-duplicated).

## 4. ROOT Dictionaries -> `dictionaries/`   ✅ [DONE]

Full real `classes.h` and `classes_def.xml` are in. NuGraph additions marked
`<!--New Add -->`.

## 5. Analysis -> `analysis/notebooks/`   ⏳ [DEFERRED -- Doing Later]

- the runtime/throughput/VmHWM plotting notebook
- the batch `log.tar` failure-scan notebook
(Per your note, the python plots come after this round.)

## 6. Inference Module .Cc -- Link, Don't Vendor (Unchanged)

- libtorch single -- `larrecodnn/NuGraph/NuGraphInference_module.cc`
- NuSonic single -- `larrecodnn/NuGraph/NuGraphInferenceSonicTriton_module.cc`
- libtorch multi (ICARUS) -- `icaruscode/TPC/NuGraph/ICARUSNuGraphInference_module.cc`
- WCT Triton client (DNN ROI ref) -- `wire-cell-toolkit/pytorch/src/{DNNROIFinding,TorchService}.cxx`

## 7. Multi-slice / Multi-batch   ⏳ [PRESENT but Not Wired]

The multi-slice presets (`NCCSlices*`, `NGMultiSlice*`, `ICARUSNuGraphMultiLoader`,
`ngfilteredhits*`) already exist in the real fcls, commented out of the paths. The
"coming soon" work is enabling + testing them (and the multi-batch config). Add the
finalised versions / any new fcls here when tested.

## 8. Context -> `docs/reference/`   [OPTIONAL]

- the two IaaS slide decks (Meghna's intro; your ICARUS scaling talk) as PDFs
- one example server log + one client log, trimmed

## 9. Cheat Sheets -> `docs/`   ✅ [DONE]

- `docs/09_grep_cheatsheet.md` - common grep patterns for grid logs, fcls, and Triton output.
- `docs/10_job_submission_cheatsheet.md` - short copy-paste guide for `project.py` and `jobsub`.
- `docs/11_triton_eaf_minio_cheatsheet.md` - EAF, MinIO, model locations, and Triton logs.

## 10. Repo Hygiene -> `.gitignore`   ✅ [DONE]

A starter `.gitignore` is included to avoid committing ROOT files, logs, tarballs, local
environments, tokens, and generated outputs.
