# 02 -- Pipeline overview (where ML plugs in)

## The standard production chain

```
 MC sim / Data ─▶ Stage0 ─▶ Stage1 ─▶ CAF Maker ─▶ SBN ML CAF Maker ─▶ analysis
                    │          │
       noise filter,│          │ 3D space-points, PANDORA reconstruction
       deconvolution│          │
       /ROIs, hit   │          └─▶ (Larcv files) ─▶ ML reconstruction (SPINE)
       finding      │
```

- **Stage0 -> Stage1** is the part we care about for NuGraph. NuGraph runs *after*
  Pandora slicing + flash matching, between Stage0 and Stage1, and writes its
  outputs into the Stage1 product.
- **CAF Maker** turns Stage1 output into CAF / flatCAF files for downstream physics
  (selections, variables) in python.
- ML is embedded at **multiple stages** (DNN ROI in signal processing, NuGraph after
  Pandora, SPINE, BDTs for vertex / track-shower). Each is a candidate for IaaS;
  each is a place inference becomes the bottleneck.

## What NuGraph2 is (so you can find CVN's analogue)

NuGraph2 is a Graph Neural Network for low-level reconstruction of neutrino
interactions in a LArTPC. It enhances Pandora and outputs:
- **slice-level filter scores** (signal vs background), and
- **hit-level semantic classification** (MIP / HIP / shower / Michel / diffuse).

Its outputs are stored as art associations between `recob::Hit` and
`anab::FeatureVector<N>` -- which is exactly why the ROOT dictionary work
(`dictionaries/`, Error 7) was needed. **Another model may write different products**,
so expect a different (but analogous) set of dictionary entries.

## Reference run: standard Stage0 -> Stage1 (no Triton, no ML)

Always confirm the plain chain runs before adding inference. Run a few events:

```bash
# pick a file and (optionally) convert to an XRootD path first -- see docs/01
lar -c stage1_run2_larcv_icarus.fcl -n 5 -s <input>.root --process-name redo -o stage1-test1.root
```
Look for **exit code 0** and a `TrigReport` showing events passed. Then make CAFs:
```bash
lar -c cafmakerjob_icarus_data.fcl -n -5 -s stage1-test.root
```

> Use a small `-n` (e.g. 5) while wiring things up -- you're testing that the pipeline
> works, not collecting statistics. Larger jobs can get killed on a busy GPVM.

## Reference run: NuGraph in the chain (libtorch, local)

Once the dictionary work is done (see `dictionaries/`), the local NuGraph inference
runs with something like:
```bash
lar -c testinference_slice_icarus.fcl -n 5 \
    -S /pnfs/icarus/scratch/users/rtriozzi/.../stage1/files.list \
    --process-name redo -o stage1-nugraph.root
```
Exit code 0 = the model->Stage1 path works locally. From here you swap the local
inference for Triton (`docs/03`).

## Inspecting output

```bash
root -l stage1-nugraph.root
root [0] .ls
root [1] TTree* t=(TTree*)_file0->Get("Events"); t->Print();   # branches + contents
```
