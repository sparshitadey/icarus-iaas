# 06 -- Stress testing & monitoring

The reason for IaaS is scale, so the real test is: **how does the server behave under
load, and where does it saturate?** This doc is the methodology + the metrics that
matter + the reference results to compare against.

## What you're measuring

From the LArSoft job summary and the Triton metrics:

- **Real time** -- wall-clock elapsed (compute + I/O + network + GPU wait + scheduling).
- **TimeReport CPU** -- CPU time actually spent on instructions.
- **Throughput** -- events / real-time.
- **VmHWM** -- peak resident RAM the process used (the memory number to plot).
- **VmPeak** -- peak virtual address space.

Server-side (Triton metrics, port 8002 / Grafana):
- **per-inference compute time** -- is the *model* fast? (NuGraph/ICARUS: ~120-160 ms, stable)
- **nv_inference_request_success / _failure** -- success rate.
- **pending request count** -- backlog. The key saturation signal.
- **queue duration** -- how long requests wait before compute.

## Monitoring stack

- **Prometheus** scrapes the `:8002/metrics` endpoint (counts, durations, GPU/CPU use).
- **Grafana** dashboards visualise it (inference rate, utilisation, latency, queue depth).
- **Landscape** for EAF server-side Triton logs.
- These let you compare CPU vs GPU, measure scalability, and justify production use.

## The plots to make (reproduce these for any target model)

For an event-count scan (NuGraph used up to ~140 events, then grid jobs to 200k):
1. **Runtime** (real time) vs number of events -- CPU (Apptainer) vs GPU (Triton EAF).
2. **Throughput** (events/s) vs number of events.
3. **Memory (VmHWM)** vs number of events.

Notebooks to parse logs and produce these live in `analysis/notebooks/` (the
NuGraph plotting notebook is the template).

> **Watch for edge effects, not bugs.** A memory/latency "bump" at certain event
> counts turned out to be a real edge effect, **not a bug**: when the number of
> events isn't a full multiple of the file size (20 events/file), a temporary ACLiC
> ROOT file is produced for the partial file, using more memory and adding latency.
> Processing **complete** files makes it go away. Concatenate/merge inputs or stick to
> full-file multiples to avoid it.

## Reference results -- the two regimes

These are the comparison points. The whole question is which regime your model lands in.

### ICARUS (NuGraph) -- stable regime (good)
- 1k jobs (20k events): **98.3%** success (17/999 failed).
- 10k jobs (200k events): **96.35%** success (365/10k failed; a few held on disk quota).
- Inference compute stable ~120-160 ms; successful requests **scale with load**; **0
  significant server-side failures**.
- At higher load: queue time rises to ~1-3 s, pending requests appear but only
  **O(10-20)**, per-server queue time still ~ms; **throughput does not collapse**.
- Conclusion: ICARUS is entering a queueing regime but stays **stable -- no runaway
  backlog** within the tested range. ~2.5× speedup on O(100)-scale GPU-via-Triton tests.

### MicroBooNE -- saturated / queue-dominated regime (the failure mode to recognise)
- ~10k jobs, only ~854 successful -> **~8% success**.
- The *model* was **not** the bottleneck (per-inference ~140-180 ms, stable).
- Failure was **system-level saturation**: pending requests grew to **O(1000)**, queue
  durations ~70-80 s, requests dropped at the **~60 s frontend timeout** before
  inference completed -> timeout-driven failures.
- Throughput rose with load, peaked, then **collapsed** as the queue built up.
- Load balancing didn't account for backend load -> uneven work, some slow pods.

**Takeaway:** job count alone is **not** a measure of saturation -- both experiments
ran similar job counts. What matters is the **effective inference request rate and
concurrency**. So pushing another model toward saturation needs *concurrency*, which is why
multi-slice / multi-batch matters.

## Why "more files per job" doesn't stress the server

Tested directly on NuGraph (1 job/1 file vs 1 job/5 files): inference shows up as
**isolated, serial spikes** -- one inference -> wait -> next event. More files just
makes the job longer and improves utilisation slightly; queue time stays ~0, only one
Triton server is active. **Files-per-job is not a concurrency knob.** To create real
concurrent load you need:
- **multi-slice processing** (process all slices, issuing more requests), and/or
- **multi-batch processing** (batch requests to the server).

That work is in progress (see `WORKLOG.md`); the new fcls + module changes are the
path to actually finding ICARUS's saturation limit.

## Batch-scanning many jobs for failures

For large job sets, a notebook that scans the unpacked `log.tar` files across all jobs
for error/exception/failure patterns is far faster than eyeballing logs. A template
lives in `analysis/notebooks/`. (Note: some failed jobs don't write logs at all, which
is itself a signal of infrastructure-level trouble.)
