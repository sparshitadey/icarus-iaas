# Analysis and Scale-Test Plots

> Placeholder area for notebooks that turn job logs and server metrics into timing, memory, throughput, and queueing plots.

---

Notebooks and helpers to turn job logs into the time / memory / throughput / queue
plots used to characterise the server's behaviour (`docs/06`).

## What Goes Here

- `notebooks/scale_plots.ipynb` -- **TODO: add the NuGraph plotting notebook.** Reads
  the per-job time/memory summaries and plots, for a CPU-vs-GPU event-count scan:
  - Runtime (real time) vs number of events
  - Throughput (events/s) vs number of events
  - Memory (VmHWM) vs number of events
- `notebooks/log_failure_scan.ipynb` -- **TODO: add the batch log-scan notebook.**
  Walks the unpacked `log.tar` of many grid jobs and flags
  error/exception/failure/timeout patterns, to find failure modes at scale.

## Data Sources

- Client side: the `larStageN.out` / `TimeTracker` / `MemoryTracker` summaries in each
  job's output dir; unpack `log.tar` for the rest.
- Server side: Triton `:8002/metrics` (via Grafana), and the Landscape Triton-logs and
  MinIO dashboards for EAF.

## Reminder on the "Edge Effect"

Partial files (event counts that aren't a full multiple of the 20-events/file size)
produce a temporary ACLiC ROOT file -> a memory/latency bump. It's **not a bug**.
Filter to full-file multiples or merge inputs when interpreting plots (`docs/06`).

> The canonical NuGraph notebooks + data points live in the original working-area /
> shared notebook. Drop copies here so the same plotting code can be reused for
> any target-model scale test; CVN job outputs are one example.
