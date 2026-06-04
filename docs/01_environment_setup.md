# 01 -- Environment Setup

> 🔐 **Before running setup commands:** complete the account and permission checklist in [`docs/00_before_you_start.md`](00_before_you_start.md). This includes Fermilab services, ICARUS permissions, EAF/MinIO access, dashboard access, and FNAL Computing Slack.

---

> 📝 **Provenance note:** this page is the cleaned-up setup path. The longer chronological setup record lives in [Sparshita's detailed NuGraph/IaaS setup log](https://docs.google.com/document/d/1qyF87ECWyGI3lJy5Wjoq8Hrr3RefnoGOLZa6wySlyGs/edit?tab=t.0).

---


> The reproducible starting point: accounts, disks, tokens, MRB setup, and the ICARUS development area used by the NuGraph benchmark.

---

Everything here is **infrastructure** -- identical for NuGraph, CVN, or any model.
Do it once and you have a working dev area.

## 🔐 Required Access Before You Start

Before trying to reproduce the workflow, confirm the access chain from Fermilab login through EAF/MinIO. The commands later in this document assume these pieces are already in place.

| Access | Needed For | Where To Go / Who To Ask |
|---|---|---|
| Fermilab services account | SSH, ServiceNow, tokens, dashboards | Fermilab account onboarding / Service Desk |
| ICARUS experiment permissions | ICARUS GPVMs, `/exp/icarus/...`, `/pnfs/icarus/...`, and ICARUS software areas | Ask the ICARUS computing/software contacts to confirm workspace, GPVM, and group permissions |
| ICARUS GPVM access | Interactive setup, light tests, log inspection | Test with `ssh -KXY <USER>@icarusgpvmNN.fnal.gov` |
| Build-node access | Building local ICARUS/LArSoft areas | Use `icarusbuild02` for larger builds; avoid heavy builds on GPVMs where possible |
| Bearer token / HTVault | Grid jobs and protected data access | `htgettoken -a htvaultprod.fnal.gov -i icarus` |
| LArBatch / `project.py` | Submitting grid jobs from XML | [SBN project.py guide](https://sbnsoftware.github.io/sbndcode_wiki/Using_projectpy_for_grid_jobs.html) |
| EAF access | Remote Triton inference on GPU infrastructure | [EAF IaaS documentation](https://eafdocs.fnal.gov/master/01_inference.html) |
| MinIO access | Viewing or modifying Triton model repositories/configs | [MinIO login](https://minio-eaf.fnal.gov/login); request access via [ServiceNow](https://fermi.servicenowservices.com/wp?id=evg-service-item&sys_id=2b7101261b58a950d03aec21f54bcb31) |
| Triton logs / Landscape | Server-side model-load and request diagnostics | [Triton logs](https://landscape.fnal.gov/monitor/d/mRzFgCySz/triton-logs?orgId=1), [Landscape dashboard](https://landscape.fnal.gov/monitor/goto/H9EJX6dDk?orgId=1) |
| FIFE batch dashboard | Grid job progress and held/failure states | [FIFE batch dashboard](https://fifemon.fnal.gov/monitor/d/000000116/user-batch-details?orgId=1&var-cluster=fifebatch&from=now-15m&to=now) |

Checklist for a new user:

- [ ] Fermilab services account is active.
- [ ] User can log into an ICARUS GPVM.
- [ ] User has ICARUS group/workspace permissions.
- [ ] User can work under `/exp/icarus/app/users/<USER>`.
- [ ] User can read/write the appropriate `/pnfs/icarus/...` locations.
- [ ] User can obtain an ICARUS bearer token.
- [ ] User has EAF access if testing remote Triton inference.
- [ ] User has requested MinIO access if they need to inspect, upload, or modify a model/config.
- [ ] User can view the Landscape Triton logs and FIFE dashboards.

> 📝 **Model/config ownership:** if the model should already exist in MinIO but is missing, stale, or failing to load, check with the model owner or the EAF/Triton contact. For the NuGraph benchmark, Giuseppe handled the model/config upload and environment-side updates.

## 🧭 Contacts and Communication

| Topic | Useful Contact / Channel | Notes |
|---|---|---|
| General ICARUS IaaS workflow | Sparshita, Giuseppe, Meghna | Good starting points for the NuGraph benchmark path, the grid/EAF workflow, and adaptation to other inference-heavy reconstruction tasks. |
| NuGraph benchmark model/config | Giuseppe | Ask if the NuGraph model/config is missing, stale, or needs to be updated in MinIO. |
| Triton/EAF server-side information | Burt Holzman | Useful for server-side Triton behaviour, service configuration, model-load failures, and EAF-side diagnostics. |
| FNAL Computing Slack | Ask Giuseppe to add the new user if needed | Useful for quick computing questions, EAF/Triton context, and finding the right service-side contact. |
| ICARUS workspace/GPVM permissions | ICARUS computing/software contacts | Needed for ICARUS GPVM access and the `/exp/icarus/...` and `/pnfs/icarus/...` areas. |

> ⚠️ **Ask early:** if a new user cannot access MinIO, Landscape/Triton logs, FIFE dashboards, or ICARUS workspaces, it is usually faster to resolve the permission path first than to debug around it.

## Logging In

```bash
kinit -f <you>@FNAL.GOV
ssh -KXY <you>@icarusgpvm01.fnal.gov          # any icarusgpvmNN; VS Code remote works well
```

## Where to Put Things (Disk Layout)

| Path | Use |
|------|-----|
| `/nashome/<u>/<you>` | home dir; **do not run code here**, little space -- setup/small txt only |
| `/exp/icarus/app/users/<you>` | **run code here** (your dev areas live here) |
| `/exp/icarus/data/users/<you>` | large data files you keep long-term |
| `/pnfs/icarus/scratch/users/<you>` | large batch outputs; **deleted on weeks-month scale** |
| `/pnfs/icarus/persistent/users/<you>` | shared sim files; avoid unless needed |
| `/pnfs/icarus/resilient/users/<you>` | longer retention than scratch |

## Base Setup (Every Session)

```bash
sh /exp/$(id -ng)/data/users/vito/podman/start_SL7dev_jsl.sh    # enter SL7 container image
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p01 -q e26:prof                    # version used for the NuGraph work
```

## Tokens (Needed to Run Examples / CAFAna / Grid)

```bash
# get a token for the session (valid a few hours):
htgettoken -a htvaultprod.fnal.gov -i icarus
# check validity:
httokendecode -v -H
```

> **Tip learned the hard way:** if you make a token mid-session and then hit errors
> sourcing setup scripts, just start a **fresh terminal** -- the token stays valid for
> a few hours, so you don't need to remake it, and the clean shell usually fixes the
> sourcing errors.

## Creating a Dev Area (MRB) and Pulling a Feature Branch

This is how the NuGraph dev area was built (the rtriozzi/cerati NuGraph2 filter branch):

```bash
cd /exp/icarus/app/users/<you>
mkdir icaruscode-v10_06_00_01p01_<tag> && cd icaruscode-v10_06_00_01p01_<tag>
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p01 -q e26:prof
mrb newDev
source localProducts_larsoft_v10_06_00_e26_prof/setup
cd srcs/
mrb g -t v10_06_00_01p01 icaruscode
cd icaruscode
git remote add rtriozzi https://github.com/SBNSoftware/icaruscode.git
git fetch rtriozzi
git checkout -b feature/rtriozzi_cerati_NuGraph2_Filter -t rtriozzi/feature/rtriozzi_cerati_NuGraph2_Filter
cd $MRB_BUILDDIR/
mrbsetenv
cd ..
mrb i -j4          # build; takes a few minutes with no progress output -- be patient
mrbslp
```

> **For another ML stage:** the only thing that changes here is *which branch* you check out -- find
> the branch that has the target model integrated in the ICARUS chain (ask the ML reco group), and
> use a matching tag/qualifier. CVN is one example; the MRB mechanics are identical.

## Re-entering an Existing Dev Area (Subsequent Sessions)

```bash
sh /exp/$(id -ng)/data/users/vito/podman/start_SL7dev_jsl.sh
cd /exp/icarus/app/users/<you>/<your-dev-area>
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p01 -q e26:prof
source localProducts*/setup
mrbsetenv
mrb i -j4
mrbslp
```

Verify you're really in your local environment (not global `lar`):
```bash
echo $MRB_TOP                                            # -> your dev area
type mrbslp                                              # -> should report it's a function
```
(`type mrbslp` saying "function" is necessary but not sufficient -- also check `$MRB_TOP`.)

## File Access: Prefer XRootD Over Raw PNFS

dCache serves data via XRootD; direct POSIX access bypasses load balancing,
redirection, and fault tolerance, and scales worse for production jobs. Convert a
PNFS path:

```bash
pnfsToXRootD -h                          # show options
pnfsToXRootD /pnfs/.../file.root         # prints a root://fndcadoor.fnal.gov:1094/... path
```

> XRootD paths occasionally fail (error 20 / no file found). If so, fall back to the
> explicit `/pnfs/...` path -- it'll work, just less optimally.
