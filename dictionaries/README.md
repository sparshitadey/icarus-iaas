# ROOT Dictionary Fixes

> The NuGraph Error-7 fix as a worked example: identify the missing art products,
> register the dictionaries, rebuild, and repeat until the chain is serialisable.

---

When a model writes new data products (art associations), ROOT needs **dictionaries**
for them, or the job dies with **Error 7 / `DictionaryNotFound`** (see `docs/07`). For
NuGraph this meant registering the `recob::Hit` <-> `anab::FeatureVector<N>`
associations in `icaruscode/IcarusObj/`. This folder documents exactly what was added,
as a worked example to copy the *method* from. CVN's products will differ, so you will
register CVN's missing classes, not these.

The full real files are in this folder: `classes.h` and `classes_def.xml`, copied
from `srcs/icaruscode/icaruscode/IcarusObj/`. The NuGraph additions are marked with a
`<!--New Add -->` comment near the bottom of `classes_def.xml`, and the matching
headers are the last block of `classes.h`. Diff against upstream `IcarusObj` to see
exactly what was added. Branch versions of the edited files:

- `classes.h`: https://github.com/SBNSoftware/icaruscode/blob/feature/rtriozzi_cerati_NuGraph2_Filter/icaruscode/IcarusObj/classes.h
- `classes_def.xml`: https://github.com/SBNSoftware/icaruscode/blob/feature/rtriozzi_cerati_NuGraph2_Filter/icaruscode/IcarusObj/classes_def.xml

## What the Error Looks Like

If the dictionaries are missing, art prints something like this and exits with
status 7:

```
cet::exception caught in art
---- DictionaryNotFound BEGIN
 No dictionary found for the following classes:

   art::Assns<anab::FeatureVector<5>,recob::Hit,void>
   art::Assns<recob::Hit,anab::FeatureVector<5>,void>
   art::Wrapper<art::Assns<anab::FeatureVector<5>,recob::Hit,void> >
   art::Wrapper<art::Assns<recob::Hit,anab::FeatureVector<5>,void> >

 Most likely they were never generated, but it may be that they were generated in
 the wrong package. Please add (or move) the specification

     <class name="MyClassName"/>

 to the appropriate classes_def.xml file.
---- DictionaryNotFound END
 Art has completed and will exit with status 7.
```

A separate line you may see in the same output, `Error: Unsupported GDML Tag Used
:gdml_simple_extension. Please Check Geometry/Schema.`, is a geometry-schema warning
and is not what causes the exit. The `DictionaryNotFound` block is the fatal one
(status 7).

## Why It Happens, and the Upstream Reference

These association and `art::Ptr` dictionaries live in `lardataobj` (AnalysisBase), so
the fix registers the same specialisations locally in `IcarusObj`. The set added
mirrors an upstream `lardataobj` change (thanks to Leonard Lena's pointer):

- where they live upstream:
  https://github.com/LArSoft/lardataobj/blob/develop/lardataobj/AnalysisBase/classes_def.xml
- the change to follow:
  https://github.com/LArSoft/lardataobj/commits/v10_01_00/lardataobj/AnalysisBase/classes_def.xml

## Where the Edits Go

Two files in your dev area:

- `srcs/icaruscode/icaruscode/IcarusObj/classes.h`
- `srcs/icaruscode/icaruscode/IcarusObj/classes_def.xml`

The error is iterative: each rebuild may reveal the next missing class. Read the
exception, it names the exact `art::Assns<...>` / `art::Ptr<...>` that is missing.

## NuGraph Worked Example - What Was Added

### `classes.h` (Added at the Bottom)

```cpp
#include "lardataobj/RecoBase/Hit.h"
#include "lardataobj/AnalysisBase/MVAOutput.h"   // anab::FeatureVector lives here
#include "lardataobj/RecoBase/Slice.h"
#include "lardataobj/RecoBase/Cluster.h"
#include "lardataobj/RecoBase/Track.h"
#include "lardataobj/RecoBase/Shower.h"
```

The first three were strictly required: each rebuild reported one of these class names
missing in turn. The rest were added pre-emptively to avoid repeated rebuild cycles
(they may or may not be needed for a given workflow).

### `classes_def.xml` (Added at the Bottom, Under a `<!--New Add -->` Comment)

```xml
<!--New Add -->
<!-- NuGraph: recob::Hit <-> anab::FeatureVector associations -->
<class name="art::Assns<recob::Hit, anab::FeatureVector<1>, void>" />
<class name="art::Assns<recob::Hit, anab::FeatureVector<5>, void>" />
<class name="art::Wrapper<art::Assns<recob::Hit, anab::FeatureVector<1>, void>>" />
<class name="art::Wrapper<art::Assns<recob::Hit, anab::FeatureVector<5>, void>>" />

<class name="art::Assns<anab::FeatureVector<1>, recob::Hit, void>" />
<class name="art::Assns<anab::FeatureVector<5>, recob::Hit, void>" />
<class name="art::Wrapper<art::Assns<anab::FeatureVector<1>, recob::Hit, void>>" />
<class name="art::Wrapper<art::Assns<anab::FeatureVector<5>, recob::Hit, void>>" />

<class name="std::pair<art::Ptr<recob::Hit>, art::Ptr<anab::FeatureVector<1>>>" />
<class name="std::pair<art::Ptr<recob::Hit>, art::Ptr<anab::FeatureVector<5>>>" />
<class name="std::pair<art::Ptr<anab::FeatureVector<1>>, art::Ptr<recob::Hit>>" />
<class name="std::pair<art::Ptr<anab::FeatureVector<5>>, art::Ptr<recob::Hit>>" />

<class name="std::vector<art::Ptr<recob::Slice>>"/>
<class name="art::Wrapper<std::vector<art::Ptr<recob::Slice>>>"/>
<class name="std::vector<art::Ptr<recob::PFParticle>>"/>
<class name="art::Wrapper<std::vector<art::Ptr<recob::PFParticle>>>"/>
<class name="std::vector<art::Ptr<recob::Cluster>>"/>
<class name="art::Wrapper<std::vector<art::Ptr<recob::Cluster>>>"/>
<class name="std::vector<art::Ptr<recob::Hit>>"/>
<class name="art::Wrapper<std::vector<art::Ptr<recob::Hit>>>"/>
<class name="std::vector<art::Ptr<recob::Track>>"/>
<class name="art::Wrapper<std::vector<art::Ptr<recob::Track>>>"/>
<class name="std::vector<art::Ptr<recob::Shower>>"/>
<class name="art::Wrapper<std::vector<art::Ptr<recob::Shower>>>"/>
```

### Then Rebuild and Test

```bash
# save both files, then:
mrbsetenv
mrb i -j4
mrbslp
lar -c testinference_slice_icarus.fcl -n 5 \
    -S /pnfs/icarus/scratch/users/rtriozzi/NuGraph_NuMI_Nom_v10_06_00_01p01_1D_NuGraphReco_MultiSlice_Filter_FixForCAFs_NoYZSim/stage1/files.list \
    --process-name redo -o stage1-nugraph.root
```

This is a compiled-code change, so it does need a rebuild (`mrbsetenv` + `mrb i`).
Build on `icarusbuild02` for more cores (e.g. `mrb i -j20`) rather than `-j4` on a
gpvm. It should now exit with status 0, and runs quickly on 5 events.

Current test input (as of June 2026): the file list to use lives at
`/exp/icarus/app/users/sdey2/icaruscode-v10_06_00_01p01_rtriozzi/GridWork/fileLists/backup062026`.
Substitute it for the `-S ...` path above. The `rtriozzi` scratch path shown is from
the original run and may be gone, since scratch areas are cleared on a weeks-to-month
timescale.

## Diagnosing What's Missing

```bash
cd $MRB_SOURCE/icaruscode/icaruscode
grep -R "anab::FeatureVector" -n . | grep classes_def.xml | head
LIBDIR=/exp/icarus/app/users/<you>/<dev>/build_slf7.x86_64/icaruscode/slf7.x86_64.e26.prof/lib
ls $LIBDIR | egrep -i "dict|NuGraph" | head
grep -R "FeatureVector<5>" -n $LIBDIR/*.rootmap 2>/dev/null | head
```

Empty results mean no dictionary was generated, so add the classes above and rebuild.

## For Another Model

Run the job, read the `DictionaryNotFound` exception, and register the classes it
names (the target model's own associations and `art::Ptr` vectors). Same procedure,
different product types; CVN is one example.
