# 04 -- (b) Triton via EAF (GPU)

The Elastic Analysis Facility (EAF) hosts GPU nodes (Nvidia A100). Here the client
fcls point at a remote EAF Triton endpoint instead of a local server, so inference
runs on GPU. The client code barely changes from stage (a) -- mostly the **URL** and
**model location**.

Useful EAF docs: <https://eafdocs.fnal.gov/master/01_inference.html>

## Prerequisites (one-time)

- **EAF account** -- request via Service Desk (approval took ~a few days for NuGraph).
- **MinIO access** -- needed to see the model bucket and read server-side logs.
  Check the model is present: <https://minio-eaf.fnal.gov/> ->
  `triton-models/<model_name>` (NuGraph: `triton-models/nugraph2_icarus_mpvmprbnb`).
- **The model must be uploaded + its `config.pbtxt` set up** on EAF. For NuGraph the
  model owner (Giuseppe) did this. **For CVN you must arrange the same** -- the model
  owner uploads the CVN model and config to the bucket.

## Endpoints

- Inference endpoint (what the fcl points at): `triton.fnal.gov:443`
- Server-side logs (Landscape): <https://landscape.fnal.gov/monitor/d/mRzFgCySz/triton-logs?orgId=1>
- Model bucket (MinIO): <https://minio-eaf.fnal.gov/>

## The fcls

Duplicate the stage-(a) Triton fcls to `*_eaf.fcl` and point them at the EAF URL:
- `nugraph_icarus_triton_eaf.fcl`
- `testinference_slice_icarus_triton_eaf.fcl`

(See `fcl/nugraph/` for what changed; `fcl/cvn/` for the CVN template.)

## Run

```bash
sh /exp/$(id -ng)/data/users/vito/podman/start_SL7dev_jsl.sh
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p03 -q e26:prof
cd /exp/icarus/app/users/<you>/<your-dev-area>
source localProducts_larsoft_v10_06_00_e26_prof/setup
mrbslp
export FHICL_FILE_PATH=/exp/icarus/app/users/<you>/<dev>/srcs/icaruscode/icaruscode/TPC/NuGraph:${FHICL_FILE_PATH}
echo $FHICL_FILE_PATH | tr ':' '\n' | grep icaruscode | head     # sanity check

lar -c testinference_slice_icarus_triton_eaf.fcl -n 5 \
    -S /pnfs/icarus/scratch/users/rtriozzi/.../stage1/files.list \
    --process-name redo -o stage1-nugraph_triton_eaf.root > triton_debug.log 2>&1
```
The `> triton_debug.log 2>&1` is optional but gives you a clean **client-side** log.

A good early sign: the first log lines show you can reach the server via EAF and it
searches for the model. If the model loads + runs, you get exit code 0.

## "Am I really on GPU?"

The LArSoft summary prints "CPU Memory/Time" **regardless of CPU/GPU** -- it's a
`lar -c` artifact, not a real indicator. To confirm GPU, add diagnostics to the
server-side `model.py` and re-upload, e.g.:
```python
print("CUDA available:", torch.cuda.is_available())
print("CUDA device count:", torch.cuda.device_count())
print("Model device:", next(self.model.parameters()).device)
```
The server log will then show `CUDA available: True`, `device count: 1`,
`Model device: cuda:0`. (Ignore a `CUDA_VISIBLE_DEVICES: None` line -- it was a buggy
print and was removed.)

> **Why no obvious speedup at 5 events?** Batch size is too small -- CPU and GPU look
> similar at tiny scale. The GPU win appears at scale and is what stress testing
> (`docs/06`) is for.

## Common EAF failures

See `docs/07`: Error 65 (server-side env), Error 1 (model attribute / stale env),
MinIO timeouts, `evhtp ODDITY`, and scheduled-maintenance downtime.
