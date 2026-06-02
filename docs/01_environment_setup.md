# 01 -- Environment setup

Everything here is **infrastructure** -- identical for NuGraph, CVN, or any model.
Do it once and you have a working dev area.

## Logging in

```bash
kinit -f <you>@FNAL.GOV
ssh -KXY <you>@icarusgpvm01.fnal.gov          # any icarusgpvmNN; VS Code remote works well
```

## Where to put things (disk layout)

| Path | Use |
|------|-----|
| `/nashome/<u>/<you>` | home dir; **do not run code here**, little space -- setup/small txt only |
| `/exp/icarus/app/users/<you>` | **run code here** (your dev areas live here) |
| `/exp/icarus/data/users/<you>` | large data files you keep long-term |
| `/pnfs/icarus/scratch/users/<you>` | large batch outputs; **deleted on weeks-month scale** |
| `/pnfs/icarus/persistent/users/<you>` | shared sim files; avoid unless needed |
| `/pnfs/icarus/resilient/users/<you>` | longer retention than scratch |

## Base setup (every session)

```bash
sh /exp/$(id -ng)/data/users/vito/podman/start_SL7dev_jsl.sh    # enter SL7 container image
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p01 -q e26:prof                    # version used for the NuGraph work
```

## Tokens (needed to run examples / CAFAna / grid)

```bash
# get a token for the session (valid a few hours):
httokensh -a htvaultprod.fnal.gov -i icarus -- /bin/bash
# check validity:
httokendecode -v -H
# alternative used elsewhere:
htgettoken -a htvaultprod.fnal.gov -i icarus
```

> **Tip learned the hard way:** if you make a token mid-session and then hit errors
> sourcing setup scripts, just start a **fresh terminal** -- the token stays valid for
> a few hours, so you don't need to remake it, and the clean shell usually fixes the
> sourcing errors.

## Creating a dev area (MRB) and pulling a feature branch

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

## Re-entering an existing dev area (subsequent sessions)

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

## File access: prefer XRootD over raw PNFS

dCache serves data via XRootD; direct POSIX access bypasses load balancing,
redirection, and fault tolerance, and scales worse for production jobs. Convert a
PNFS path:

```bash
pnfsToXRootD -h                          # show options
pnfsToXRootD /pnfs/.../file.root         # prints a root://fndcadoor.fnal.gov:1094/... path
```

> XRootD paths occasionally fail (error 20 / no file found). If so, fall back to the
> explicit `/pnfs/...` path -- it'll work, just less optimally.
