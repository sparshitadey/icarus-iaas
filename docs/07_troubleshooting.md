# 07 -- Troubleshooting

> The error catalogue. Start here when something fails; most of the expensive lessons are collected in one place.

---

Indexed by what you'll actually see. Every entry here was hit and solved during the
NuGraph work; the same failures can recur for CVN or any other target model because they're mostly
environment/wiring issues, not model issues.

---

## Quick Environment Sanity Checks (Run These Before Debugging Anything)

```bash
echo "MRB_TOP=$MRB_TOP"                 # must be YOUR dev area, not empty
which lar                               # must NOT be the bare /cvmfs/.../bin/lar
echo $SETUP_ICARUSCODE                  # should name your icaruscode setup
echo $FHICL_FILE_PATH | tr ':' '\n' | grep icaruscode | head    # should include your local dir
echo $CET_PLUGIN_PATH  | tr ':' '\n' | head     # should include a local build dir, not only cvmfs
```

If `MRB_TOP` is empty, your local build is **not** active and you are running global
`lar`. Fix by re-entering the MRB environment (see Error 90 below).

---

## Exit / Error Codes

### Error 90 -- "File Not Found"
**Most common cause: the MRB runtime isn't active in this shell**, so `FHICL_FILE_PATH`
only contains CVMFS paths and `lar` can't see your local fcls (or their `#include`s).

Symptoms: a `.fcl` you know exists isn't found; or it's found but its first
`#include` isn't.

Fix -- re-enter the correct MRB environment from your dev area:
```bash
cd /exp/icarus/app/users/<you>/<your-dev-area>
source /cvmfs/icarus.opensciencegrid.org/products/icarus/setup_icarus.sh
setup icaruscode v10_06_00_01p01 -q e26:prof
source localProducts*/setup
mrbsetenv
mrb i -j4
mrbslp
# verify:
echo $MRB_TOP                                   # -> your dev area
echo $FHICL_FILE_PATH | tr ':' '\n' | grep icaruscode | head
```

If your fcl lives in a dir not on the path, prepend it explicitly:
```bash
export FHICL_FILE_PATH=/exp/icarus/app/users/<you>/<dev>/srcs/icaruscode/icaruscode/TPC/NuGraph:${FHICL_FILE_PATH}
```

On the grid, Error 90 also shows up if you accidentally list **two** fcls in the
XML when only one is needed.

---

### Error 7 -- `DictionaryNotFound`
A ROOT dictionary is missing for one of the model's data products, e.g.
`art::Assns<anab::FeatureVector<5>, recob::Hit>`.

Diagnose:
```bash
cd $MRB_SOURCE/icaruscode/icaruscode
grep -R "anab::FeatureVector" -n . | grep classes_def.xml | head
LIBDIR=/exp/icarus/app/users/<you>/<dev>/build_slf7.x86_64/icaruscode/slf7.x86_64.e26.prof/lib
ls $LIBDIR | egrep -i "dict|NuGraph" | head
grep -R "FeatureVector<5>" -n $LIBDIR/*.rootmap 2>/dev/null | head
```
If these come back empty, no dictionary was generated for those products.

Fix -- register the classes, then rebuild. Add the relevant headers to
`icaruscode/IcarusObj/classes.h` and the class declarations to
`icaruscode/IcarusObj/classes_def.xml`, then:
```bash
mrbsetenv && mrb i -j4 && mrbslp
```
See `dictionaries/` for the exact NuGraph additions as a worked example. **For another
model the missing classes may be different** -- read the error, it tells you which
`art::Assns<...>` / `std::vector<art::Ptr<...>>` are missing, and add those.

> The error is iterative: rebuild and it'll often tell you the *next* missing class.
> NuGraph needed `Hit`, `MVAOutput` (FeatureVector), `Slice`, plus a batch of
> `art::Ptr` vectors/wrappers added as a precaution.

---

### Error 65 -- "Unknown Model" / "Request for Unknown Model ... Has No Available Versions"
The model *is* in the bucket but **failed to load on the server** -- so it's a
**server-side environment** problem, not your client/URL.

Diagnose: check the **server-side** logs (Landscape dashboard / MinIO), not just your
client log. For NuGraph the root cause was a python import failure in the model env:
`ModuleNotFoundError: No module named 'pynvml.smi'`. The fix was to comment out the
unused `pynvml` include in the model env (done by the server maintainers).

Fix path for a target model: if you see this, capture the server log traceback and take it to
whoever maintains the EAF model env -- the fix is almost always "a dependency the
model's `model.py` imports isn't present (or is broken) in the deployed env."

---

### Error 1 -- `AttributeError` Inside the Model
The request reaches the model and enters `forward()`, then fails on a missing
attribute, e.g. `module 'nugraph.util' has no attribute 'FeatureExtension'`.

Meaning: client + server wiring is **correct** (this is actually a good sign -- you're
in the model now), but the deployed environment is missing/stale relative to the
model code. Fix = update the server-side environment to match the model. For a target model,
ensure the deployed env has the exact package versions the checkpoint expects.

> Useful tell: a run that errors here often still prints the time/memory summary,
> which is what you eventually want anyway.

---

### Error 137 -- Out-of-memory (Grid)
The job exceeded the memory it requested. Increase the memory quota in the grid XML
and resubmit. See `docs/05`.

### "Held" Grid Jobs
Usually the requested resources exceed what the grid will give (e.g. "disk usage
greater than requested"). Simplest fix: remove the held jobs and resubmit with
adjusted resources (`--check` then `--makeup`). Commands in `docs/05`.

---

## Infrastructure-level Flakiness (Not Your Fault)

- **EAF maintenance / downtime**: EAF goes down for scheduled maintenance; jobs will
  fail wholesale during these windows. Confirm EAF is up before debugging your code.
- **MinIO timeouts** (server log: `failed to poll model repository ... curlCode: 28,
  Timeout was reached`) and **`evhtp ODDITY`** HTTP-layer warnings in the client log
  indicate transient EAF/Triton instability, not a config error. Retry later.
- **GPVM overload**: if a local run hangs, the GPVM may be saturated. Check with
  `who <user>@<gpvm>.fnal.gov` and consider switching GPVMs.

## Validating a Run Actually Worked

```bash
# server is alive and model is ready:
curl -s localhost:8000/v2/health/ready
curl -s localhost:8000/v2/models/<model_name>
ss -lntp | egrep '8000|8001|8002'        # ports listening under tritonserver

# inference actually happened:
curl -s localhost:8002/metrics | egrep "nv_inference_request_success|<model_name>"

# output ROOT file is non-empty and has the expected trees:
root -l <output>.root
root [0] .ls
root [1] TTree* t=(TTree*)_file0->Get("Events"); t->Print();
```
