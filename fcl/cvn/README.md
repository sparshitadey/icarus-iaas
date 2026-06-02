# fcl/cvn -- Example model-adaptation area (CVN)

This directory is an example of how the NuGraph benchmark files can be adapted for
another ML inference stage, using CVN as the concrete case. The repo is not meant
to be CVN-only; CVN is simply a useful example of which knobs would change.

Build the target model's fcls by copying `../nugraph/` and changing only the
model-specific knobs. The NuGraph files are real, so the mapping below is
concrete -- open them side by side with whatever CVN (or other target-model)
reconstruction fcl already exists in `icaruscode`.

## Example files to create (mirror NuGraph)

```
fcl/cvn/
├── cvn_icarus.fcl                        TODO[CVN]  prolog: libtorch (local)
├── testinference_..._cvn.fcl             TODO[CVN]  top-level, #includes the prolog
├── cvn_icarus_triton.fcl                 TODO[CVN]  prolog: Triton (local GPVM)
├── testinference_..._cvn_triton.fcl      TODO[CVN]
├── cvn_icarus_triton_eaf.fcl             TODO[CVN]  prolog: Triton (EAF)
└── testinference_..._cvn_triton_eaf.fcl  TODO[CVN]
```

## Per-knob mapping (NuGraph -> CVN example)

| Knob in the NuGraph fcls | NuGraph value | Example CVN replacement |
|---|---|---|
| upstream prolog `#include` | `nugraph.fcl` | `TODO[CVN]` CVN's base fcl that defines its presets |
| libtorch preset | `@local::NuGraphLibTorch` | `TODO[CVN]` CVN's libtorch preset |
| Triton preset | `@local::ApptainerNuGraphNuSonicTriton` | `TODO[CVN]` CVN's NuSonic/Triton preset (if it exists; else port the module -- `docs/08` item 8) |
| producer label(s) | `NuGraphCryoE` / `NuGraphCryoW` | `TODO[CVN]` (keep per-cryostat if CVN is per-cryostat) |
| `TritonConfig.modelName` | `nugraph2_icarus_mpvmprbnb` | `TODO[CVN]` CVN model name in the bucket |
| libtorch `modelFileName` | `model_mpvmpr_bnb_numu_cos.pt` | `TODO[CVN]` CVN weights file |
| normalisation consts | `avgs_u/v/y`, `devs_u/v/y` | `TODO[CVN]` CVN's input normalisation (if any) |
| loader input labels | `LoaderTool.hitInput/spsInput` | `TODO[CVN]` CVN's input product labels |
| decoder input labels | `DecoderTools.*.hitInput` | `TODO[CVN]` |
| EAF endpoint | `serverURL: "triton.fnal.gov:443"`, `ssl: true` | same (infrastructure, don't change) |
| single-slice loader | `ICARUSNuGraphLoader` | `TODO[CVN]` CVN single loader |
| multi-slice loader | `ICARUSNuGraphMultiLoader` | `TODO[CVN]` CVN multi loader |
| multi-slice module | `ICARUSNuGraphInference` | `TODO[CVN]` |

## Two things to copy *exactly* (don't reinvent -- they're infrastructure)

1. **serverURL handling.** Local/grid: leave `serverURL` **unset** in the fcl and let
   the launch script inject `localhost:<grpcport>` (you'll edit the producer names in
   the script -- `server/README.md`). EAF: set `serverURL`/`ssl`/`modelVersion`/`verbose`
   in the **top-level** `..._eaf.fcl`, exactly as NuGraph does.
2. **Multi-slice wiring.** NuGraph already defines the multi-slice presets and just
   comments them out of `reco`. For a CVN-style adaptation, do the same: define `NCC*`/`NGMultiSlice*`/
   `ngfilteredhits*` analogues, then enable by switching the loader to the Multi loader
   and adding them to the path.

## Done-when

Each phase's "done when" is in `docs/08`. For the fcls specifically: the target-model EAF job runs
with exit code 0 and `curl -s localhost:8002/metrics | egrep "<cvn_model>"` shows
successful inference requests.
