# fcl/nugraph -- reference (working) NuGraph fcls

These are the **real, working** NuGraph fcls (author: G. Cerati; Triton/EAF variants:
S. Dey). They are the benchmark files to compare against when adapting the workflow to another model. The only path that was
edited is a comment in `testinference_slice_icarus_triton.fcl`, where the dev-area
path is shown as `/exp/icarus/app/users/<USER>/<DEV_AREA>/...`.

Each `testinference_slice_*` file is the **top-level job**; it `#include`s the matching
`nugraph_*` prolog file, which configures the producers.

| top-level job | prolog it includes | deployment |
|---------------|--------------------|------------|
| `testinference_slice_icarus.fcl` | `nugraph_icarus.fcl` | local **libtorch** (no Triton) |
| `testinference_slice_icarus_triton.fcl` | `nugraph_icarus_triton.fcl` | Triton on **local GPVM** |
| `testinference_slice_icarus_triton_eaf.fcl` | `nugraph_icarus_triton_eaf.fcl` | Triton via **EAF** |

## How the three flavours actually differ (this is the whole trick)

All three share the same structure: per-cryostat slice-hit producers
(`nuslhitsCryoE/W`) feed a NuGraph producer (`NuGraphCryoE/W`), with `NuGraphAnalyzer`
analyzers. The differences are tiny and localised:

1. **libtorch vs Triton is a one-line preset swap** (both presets come from the
   upstream `nugraph.fcl` that each prolog `#include`s):
   - libtorch: `NuGraphCryoE: @local::NuGraphLibTorch` (+ `modelFileName: "model_mpvmpr_bnb_numu_cos.pt"`)
   - Triton:   `NuGraphCryoE: @local::ApptainerNuGraphNuSonicTriton` (+ `TritonConfig.modelName: "nugraph2_icarus_mpvmprbnb"`)

2. **Where `serverURL` is set differs by deployment:**
   - **local / grid:** the fcl does **not** set `serverURL`. The launch script
     (`server/setup_tritonserver-nugraph-v0_grid.sh`) finds a free port and *appends*
     `physics.producers.NuGraphCryoE/W.TritonConfig.serverURL: 'localhost:<grpcport>'`
     to the fcl at runtime.
   - **EAF:** the top-level `..._eaf.fcl` sets it explicitly:
     `TritonConfig.serverURL: "triton.fnal.gov:443"`, `ssl: true`, `modelVersion: ""`,
     `verbose: true`. The `..._eaf` prolog deliberately leaves `serverURL`/`ssl` unset
     and tells you to set them in the top-level file.

3. **Model normalisation constants** (`avgs_u/v/y`, `devs_u/v/y`) and input labels
   (`LoaderTool.hitInput/spsInput`, `DecoderTools.*.hitInput`) are set per cryostat.

## Single-slice vs multi-slice -- already present, just not wired in

The prolog files **already define** the multi-slice chain; it's just commented out of
the producer paths. To enable it you switch the loader and add the producers to the
path. The relevant presets:
- `NCCSlices` -> `NCCSlicesCryoE/W` (`ICARUSNCCSlicesProducer`) -- builds the slices.
- `NGMultiSliceCryoE/W` = the NuGraph producer with
  `module_type: ICARUSNuGraphInference`, `LoaderTool.tool_type: "ICARUSNuGraphMultiLoader"`
  (vs single-slice `ICARUSNuGraphLoader`), reading `cluster3D*`/`NCCSlices*` labels.
- `ngfilteredhitsCryoE/W` (`ICARUSFilteredNuSliceHitsProducer`, `ScoreCut: 0.5`) --
  filtered hits downstream.

So "multi-slice" is mostly: swap loader tool, point the decoder/loader labels at the
NCC slices, and add `NCCSlices* -> NGMultiSlice* -> ngfilteredhits*` into `reco`.
(The EAF top-level file has these lines stubbed/commented ready to uncomment.)

## Quick map of the model-specific knobs

| knob | value (NuGraph) |
|------|-----------------|
| libtorch preset | `@local::NuGraphLibTorch` |
| Triton preset | `@local::ApptainerNuGraphNuSonicTriton` |
| `TritonConfig.modelName` | `nugraph2_icarus_mpvmprbnb` |
| libtorch `modelFileName` | `model_mpvmpr_bnb_numu_cos.pt` |
| EAF `serverURL` / `ssl` | `triton.fnal.gov:443` / `true` |
| single-slice loader | `ICARUSNuGraphLoader` |
| multi-slice loader | `ICARUSNuGraphMultiLoader` |
| multi-slice module | `ICARUSNuGraphInference` |

For another model, find the equivalents of these and change only them. `../cvn/README.md` shows CVN as one concrete adaptation example; `docs/08` gives the general recipe.
