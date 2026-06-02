# 11 - Triton, EAF, and MinIO cheat sheet

This is the short operational guide for the server-side pieces of IaaS.

## What is running where?

- The art/LArSoft job is the **client**.
- Triton is the **server**.
- The client sends inference requests over gRPC.
- For local tests, you can run Triton yourself on a GPVM, normally CPU-only.
- For EAF, the model is deployed through the EAF Triton service and runs on GPU nodes.

## Useful links

- EAF IaaS documentation: <https://eafdocs.fnal.gov/master/01_inference.html>
- MinIO model bucket: <https://minio-eaf.fnal.gov/login>
- MinIO / EAF access request: <https://fermi.servicenowservices.com/wp?id=evg-service-item&sys_id=2b7101261b58a950d03aec21f54bcb31>
- Server-side Triton logs: <https://landscape.fnal.gov/monitor/d/mRzFgCySz/triton-logs?orgId=1>
- Landscape monitoring dashboard: <https://landscape.fnal.gov/monitor/goto/H9EJX6dDk?orgId=1>

## Access needed

A new user will probably need:

- Fermilab services account and password.
- ICARUS GPVM access.
- Access to the relevant `/exp/icarus/...` workspace areas.
- EAF / MinIO access through the ServiceNow request above.
- Access to view the Landscape Triton logs.

## Model location

The model should eventually appear in MinIO under something like:

```text
triton-models/<MODEL_NAME>/
```

For the NuGraph worked example:

```text
triton-models/nugraph2_icarus_mpvmprbnb/
```

If the model exists but is not visible or not loading, check MinIO and the server-side logs. If the model has not been uploaded yet, ask the model owner or the EAF contact to upload it. For the NuGraph workflow, Giuseppe handled the model/config side.

## What files matter on the server side?

A Triton model repository normally looks like:

```text
<MODEL_NAME>/
  config.pbtxt
  1/
    model.py     # Python backend, e.g. NuGraph
    model.pt     # possible libtorch/PyTorch model file for other workflows
```

`config.pbtxt` defines the model name, backend/platform, max batch size, inputs, and outputs. For any target model, this file is one of the main things to diff against the NuGraph worked example. CVN is one concrete example.

## Quick checks

For a local Triton server:

```bash
curl -s localhost:8000/v2/health/ready
curl -s localhost:8000/v2/models/<MODEL_NAME>
ss -lntp | egrep '8000|8001|8002'
```

For request counters:

```bash
curl -s localhost:8002/metrics | egrep "nv_inference_request_success|nv_inference_request_failure|<MODEL_NAME>"
```

For EAF, the local health checks may not apply in the same way because the service is remote. Use the client logs, the Landscape Triton logs, and the dashboards.

## Common failure pattern

If the client says `Unknown Model`, do not assume the fcl model name is wrong immediately. In the NuGraph case, this happened when the model existed in MinIO but failed to load on the server because of a Python environment issue. The useful diagnostic came from the server-side logs, not the local client log.

