# 03 -- Local Triton on a GPVM

> Stage (a): prove the client/server wiring locally. This is CPU-only, but it is the cleanest place to debug FHiCL and request-path mistakes.

---

Goal of this stage: prove the **client↔server wiring** works end-to-end. The GPVM has
no GPU, so this runs CPU-only -- that's expected and fine. The point is to validate
the fcls and the request path before going to EAF.

## Spin Up the Server

In one terminal (your dev area), launch Triton via the setup script:

```bash
sh /exp/$(id -ng)/data/users/vito/podman/start_SL7dev_jsl.sh
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p01 -q e26:prof
httokensh -a htvaultprod.fnal.gov -i icarus -- /bin/bash     # first time only, while valid
cd /exp/icarus/app/users/<you>/<your-dev-area>
source localProducts_larsoft_v10_06_00_e26_prof/setup        # needed for mrbslp to work
mrbslp
source setup_tritonserver-nugraph-v0.sh                      # launches Triton (see server/)
```

What that launch script does:
- unsets `PYTHONHOME` / `PYTHONPATH`, sets `APPTAINER_BIND`,
- launches Triton via **apptainer**,
- blocks until the server prints `Started` in the log.

> There's **no success message on stdout** -- confirmation lives in the log file
> (e.g. `tritonserver_nugraph-v0.log`, written in the dir you launched from).
> `tail -f tritonserver_nugraph-v0.log` to watch it.

In the log you want to see:
- the model (`nugraph2_icarus_mpvmprbnb`) **loads successfully**, status **READY**,
- services started: **HTTP 0.0.0.0:8000**, **gRPC 0.0.0.0:8001**, **Metrics 0.0.0.0:8002**.

On a GPVM you'll also see `nvidia-smi: command not found` and NVML/CUDA warnings --
**this is normal**, it just means no GPU is visible. CPU-only is expected here.

## Health Checks (Manual)

```bash
curl -s localhost:8000/v2/health/ready
curl -s localhost:8000/v2/models/<model_name>          # dumps the model's IO config
ss -lntp | egrep '8000|8001|8002'                      # ports owned by tritonserver
```

## Run the Client (the Inference FCL) Against It

In a **second terminal** (set up the same dev environment), run the Triton-flavoured
fcl. Make sure your fcl dir is on the path (Error 90 in `docs/07` if not):

```bash
export FHICL_FILE_PATH=/exp/icarus/app/users/<you>/<dev>/srcs/icaruscode/icaruscode/TPC/NuGraph:${FHICL_FILE_PATH}

lar -c testinference_slice_icarus_triton.fcl -n 5 \
    -S "$TEST_LIST" \      # current test list, set per docs/02
    --process-name redo -o stage1-nugraph_triton.root
```

## Confirm Inference Actually Happened

```bash
curl -s localhost:8002/metrics | egrep "nv_inference_request_success|<model_name>"
```
You want `nv_inference_request_success{...} = N` and
`nv_inference_request_failure{...} = 0`. For the NuGraph 5-event reference run this
was 4 successful requests, 0 failures.

## Kill the Server When Done

```bash
killall -9 /cvmfs/oasis.opensciencegrid.org/mis/apptainer/1.3.2/x86_64/libexec/apptainer/libexec/starter
```

## Debugging FCL Includes

```bash
lar -c <your>.fcl --debug-config=full.fcl     # dumps the fully-resolved config
```

> **For another target model:** make model-specific copies of the launch script and the two fcls. For CVN, use the `fcl/cvn/` examples (model name +
> tensor names change; the server-launch mechanics don't). See `fcl/cvn/` and
> `server/`.
