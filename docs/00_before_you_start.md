# Before You Get Started

> ⚠️ **Start with access, not code.** Many failures in this workflow look like FHiCL, C++, Triton, or grid problems, but are actually missing permissions, expired tokens, missing MinIO access, or unavailable dashboard visibility. Confirm this checklist before debugging the reconstruction chain.

---

> 🧭 **Detailed setup history:** for the longer chronological NuGraph/IaaS setup log behind this cleaned-up workflow, see [Sparshita's detailed NuGraph/IaaS setup log](https://docs.google.com/document/d/1qyF87ECWyGI3lJy5Wjoq8Hrr3RefnoGOLZa6wySlyGs/edit?tab=t.0).

---

## Access Checklist

| Check | Access / Account | Needed For | Where To Go / Who To Ask |
|---|---|---|---|
| [ ] | Fermilab services account | SSH, ServiceNow requests, tokens, dashboards, and general FNAL computing access | Fermilab onboarding / Service Desk |
| [ ] | ICARUS experiment permissions | ICARUS GPVMs, `/exp/icarus/...`, `/pnfs/icarus/...`, and ICARUS software areas | Ask the ICARUS computing/software contacts to confirm workspace and GPVM access |
| [ ] | ICARUS GPVM access | Interactive setup, light tests, file inspection, log checks | Test with `ssh -KXY <USER>@icarusgpvmNN.fnal.gov` |
| [ ] | ICARUS build-node access | Larger MRB builds without overloading GPVMs | Use `icarusbuild02` for heavier builds where possible |
| [ ] | CVMFS / ICARUS software setup | Access to `setup_icarus.sh`, `icaruscode`, LArSoft products, and dependencies | Check `/cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh` is visible |
| [ ] | HTVault / bearer-token setup | Protected data access and grid submission | `htgettoken -a htvaultprod.fnal.gov -i icarus` |
| [ ] | LArBatch / `project.py` setup | Submitting and checking grid jobs | [SBN `project.py` guide](https://sbnsoftware.github.io/sbndcode_wiki/Using_projectpy_for_grid_jobs.html) |
| [ ] | EAF access | Remote Triton inference on EAF GPU infrastructure | [EAF IaaS documentation](https://eafdocs.fnal.gov/master/01_inference.html) |
| [ ] | MinIO access | Viewing, uploading, or modifying Triton model repositories and configs | [MinIO login](https://minio-eaf.fnal.gov/login), request via [ServiceNow](https://fermi.servicenowservices.com/wp?id=evg-service-item&sys_id=2b7101261b58a950d03aec21f54bcb31) |
| [ ] | Triton server-side log access | Diagnosing model-load failures, import errors, queueing, and server-side instability | [Triton logs](https://landscape.fnal.gov/monitor/d/mRzFgCySz/triton-logs?orgId=1) |
| [ ] | FIFE / Landscape dashboard access | Monitoring job status, queueing, request rates, failures, and throughput | [Landscape dashboard](https://landscape.fnal.gov/monitor/goto/H9EJX6dDk?orgId=1), [FIFE batch dashboard](https://fifemon.fnal.gov/monitor/d/000000116/user-batch-details?orgId=1&var-cluster=fifebatch&from=now-15m&to=now) |
| [ ] | FNAL Computing Slack | Fast debugging with people who know the grid, EAF, and Triton infrastructure | Ask Giuseppe to add the new user if needed |

---

## People And Channels

| Area | Who / Where | Notes |
|---|---|---|
| General ICARUS IaaS workflow | Sparshita, Giuseppe, Meghna | Useful for the NuGraph benchmark path, grid workflow, and generalising the pattern to other ML inference components |
| NuGraph benchmark model/config | Giuseppe | Ask if the model/config is missing, stale, or needs to be uploaded/updated on MinIO |
| Triton/EAF server-side information | Burt Holzman | Useful for model-load failures, server-side logs, EAF behaviour, and infrastructure-level questions |
| FNAL Computing Slack | Ask Giuseppe to add new users if needed | Useful for EAF, Triton, grid, token, and dashboard debugging |

---

## First Sanity Checks

Before building or submitting anything, run a few checks to make sure the shell is actually in the right universe.

```bash
# confirm identity and host
whoami
hostname

# confirm ICARUS setup area is visible
ls /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh

# confirm token path works
htgettoken -a htvaultprod.fnal.gov -i icarus

# confirm the user can see their ICARUS working area
ls /exp/icarus/app/users/<USER>
```

If any of these fail, fix access or environment setup before debugging FHiCL, ROOT dictionaries, or Triton configuration.

---

## Where To Work

| Area | Use | Notes |
|---|---|---|
| `/nashome/...` | Small files, shell setup, lightweight notes | Do not run large jobs or store large outputs here |
| `/exp/icarus/app/users/<USER>/` | Code checkouts, MRB development areas, workflow repos | Main place to keep this repository and ICARUS working areas |
| `/exp/icarus/data/users/<USER>/` | Longer-lived data products | Use when outputs need to persist beyond scratch lifetime |
| `/pnfs/icarus/scratch/users/<USER>/` | Temporary grid outputs and large test products | Good for batch outputs; can be cleaned on week/month timescales |
| `/pnfs/icarus/resilient/users/<USER>/` | Longer-lived large files | Use deliberately; avoid cluttering shared storage |

> 📝 **Reference paths:** paths under `/exp/icarus/app/users/sdey2/...` in this repository are provenance paths from the original NuGraph2 benchmark setup. They are useful to inspect the working example, but new users should replace output and working paths with their own `<USER>` area.

---

## Build-Node Note

Use GPVMs for interactive work, small validation tests, file checks, and log inspection. For larger local builds, prefer `icarusbuild02` rather than a GPVM. In practice, this is the difference between a cautious build such as:

```bash
mrb i -j4
```

on a GPVM, and a larger build such as:

```bash
mrb i -j20
```

on `icarusbuild02`, assuming the node is healthy and the working area is set up correctly.

---

## MinIO And Triton Model Checks

MinIO access is required if the user needs to inspect or modify the Triton model repository/config used by EAF.

For the NuGraph2 benchmark, check whether the model exists under the relevant `triton-models/...` path, for example:

```text
triton-models/nugraph2_icarus_mpvmprbnb
```

Check that the model repository contains the expected structure, including the model implementation and `config.pbtxt`. If Triton reports an unknown model, do not assume the FHiCL is wrong immediately. In the NuGraph benchmark setup, one apparent unknown-model failure was actually a server-side Python environment/import issue visible in the Triton logs.

---

## When To Stop And Ask

Ask for help before sinking time into local debugging if:

- MinIO is inaccessible;
- the model is missing from the Triton model repository;
- the model exists but server-side logs show import/environment failures;
- the user cannot obtain an ICARUS bearer token;
- the job dashboard shows held jobs with resource or disk issues;
- a large grid campaign starts failing in a way not reproduced by a one-job validation test.

The fastest path is usually: check access -> validate one small local/EAF job -> inspect client logs -> inspect server logs -> only then scale up.
