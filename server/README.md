# Triton Server Reference

> The server-side pieces: local launch scripts, grid launch mechanics, model-repository layout, and MinIO/EAF provenance.

---

The **server half** of the pipeline. For local/GPVM testing you launch Triton yourself
with the scripts here; for EAF the model owner deploys the model into the EAF bucket
and you just point the fcl at `triton.fnal.gov:443`. Same model-repository structure
either way.

Files here:
- `setup_tritonserver-nugraph-v0.sh` -- interactive local launch.
- `setup_tritonserver-nugraph-v0_grid.sh` -- grid launch (finds a port, injects the URL).
- `config_templates/config.pbtxt.template` -- **placeholder** (real config lives on MinIO; see below).

## The Two Launch Scripts (Real)

Both run NVIDIA Triton inside an **apptainer** container shipped on CVMFS:
`/cvmfs/icarus.opensciencegrid.org/containers/tritonserver/nugraph-v0/`, write a
`tritonserver_nugraph-v0.log`, and block until the log prints `Started`. They unset
`PYTHONHOME`/`PYTHONPATH` and set `APPTAINER_BIND=/etc/hosts,/tmp,/cvmfs`.

**`setup_tritonserver-nugraph-v0.sh`** -- interactive. Just
`apptainer run <container>` (the container's own runscript starts Triton on the
default ports 8000/8001/8002). Use this when testing by hand on a GPVM:
```bash
mrbslp
source setup_tritonserver-nugraph-v0.sh
```

**`setup_tritonserver-nugraph-v0_grid.sh`** -- for grid / co-located server. It:
- picks a free `BASEPORT` (scanning upward in steps of 3 so HTTP/gRPC/metrics don't clash),
- **appends the server URL to the job fcl** at runtime:
  `physics.producers.NuGraphCryoE/W.TritonConfig.serverURL: 'localhost:<grpcport>'`
  (this is why the local/grid fcls don't hardcode `serverURL` -- see `fcl/nugraph/README.md`),
- runs `apptainer exec <container> tritonserver --model-repository /triton-server-config/models --http-port ... --grpc-port ... --metrics-port ...`.
It expects `$FCL` (or `$1`) = the fcl to inject the URL into.

> For another model: copy whichever script you need, point it at the target
> container/model-repository, and change the producer names in the `serverURL`
> injection lines (`NuGraphCryoE/W` -> the target model's module labels). CVN would
> use something like `setup_tritonserver-cvn-v0.sh`, but the port-finding and
> apptainer mechanics stay identical.

## Model_repository Layout

Triton expects a versioned dir per model with a `config.pbtxt`:
```
<model_repository>/            # in the container: /triton-server-config/models
└── <model_name>/              # e.g. nugraph2_icarus_mpvmprbnb
    ├── config.pbtxt           # input/output tensor spec, platform, batch size
    └── 1/                     # version 1
        └── model.py           # python backend (NuGraph)  -- or model.pt for libtorch
```
On EAF the bucket is MinIO: `triton-models/<model_name>` (<https://minio-eaf.fnal.gov/>).

## Config.pbtxt & Model.py -- DEFERRED (on MinIO)

These live on MinIO, not in the local dev area, so they're not in the repo yet.
`config_templates/config.pbtxt.template` is a **placeholder based on the WCT DNN ROI
example** -- it is *not* NuGraph's real tensor spec. When you grab the real
`config.pbtxt` (and the `model.py`, which is where the GPU-confirmation device prints
were added) from `triton-models/nugraph2_icarus_mpvmprbnb`, drop them under
`server/nugraph2_icarus_mpvmprbnb/` and we'll document the real tensor contract.

You can also dump the live model's IO contract for reference:
```bash
curl -s localhost:8000/v2/models/nugraph2_icarus_mpvmprbnb
```

## Server-side Environment Common Issues (Caused Real Failures -- See Docs/07)

- A stray `pynvml` import broke model load (Error 65, "unknown model"); it was unused
  and commented out. another model's `model.py` may have its own broken/unneeded imports.
- A model attribute missing from the deployed env (`FeatureExtension` under
  `nugraph.util`) caused Error 1 *after* reaching `forward()`. Keep the deployed env
  in sync with the model code; the target env must hold that model's exact deps.
- Confirm GPU by adding device prints to `model.py` (`docs/04`).
