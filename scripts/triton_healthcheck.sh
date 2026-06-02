#!/usr/bin/env bash
# triton_healthcheck.sh -- quick "is the server alive and did inference happen?" checks.
# Usage: ./triton_healthcheck.sh <model_name> [host:httpport]
# Default host:port is localhost:8000 (local GPVM). For EAF the inference endpoint is
# triton.fnal.gov:443, but health/metrics are usually inspected via the Landscape /
# MinIO dashboards rather than curl. See docs/03, docs/06.

set -u
MODEL="${1:?usage: triton_healthcheck.sh <model_name> [host:httpport]}"
HOST="${2:-localhost:8000}"
METRICS_HOST="${HOST%:*}:8002"

echo "== server ready? =="
curl -s "http://${HOST}/v2/health/ready" && echo "  (ready)" || echo "  (NOT ready)"

echo "== model IO contract: ${MODEL} =="
curl -s "http://${HOST}/v2/models/${MODEL}"
echo

echo "== listening ports (tritonserver should own 8000/8001/8002) =="
ss -lntp 2>/dev/null | egrep '8000|8001|8002' || echo "  (ss found nothing -- server down or different host)"

echo "== inference counters for ${MODEL} =="
curl -s "http://${METRICS_HOST}/metrics" | egrep "nv_inference_request_success|nv_inference_request_failure|${MODEL}" \
  || echo "  (no metrics -- check the server is up)"
