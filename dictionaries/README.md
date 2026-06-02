# ROOT Dictionary Fixes

> The NuGraph Error-7 fix as a worked example: identify missing art products, register the dictionaries, rebuild, and repeat until the chain is serialisable.

---

When a model writes new data products (art associations), ROOT needs **dictionaries**
for them or the job dies with **Error 7 / `DictionaryNotFound`** (see `docs/07`). For
NuGraph this meant registering the `recob::Hit ↔ anab::FeatureVector<N>` associations
in `icaruscode/IcarusObj/`. This folder documents exactly what was added, as a
worked example to copy the *method* from -- **CVN's products will differ**, so you'll
register CVN's missing classes, not these.

> ✅ The **full real files** are now in this folder: `classes.h` and `classes_def.xml`
> (copied verbatim from `srcs/icaruscode/icaruscode/IcarusObj/`). The NuGraph-specific
> additions are marked with a `<!--New Add -->` comment near the bottom of
> `classes_def.xml`, and the matching headers are the last block of `classes.h`. Diff
> against upstream `IcarusObj` to see exactly what was added.

## Where the Edits Go

Two files in your dev area:
- `srcs/icaruscode/icaruscode/IcarusObj/classes.h`
- `srcs/icaruscode/icaruscode/IcarusObj/classes_def.xml`

Then rebuild: `mrbsetenv && mrb i -j4 && mrbslp`.

The error is **iterative**: each rebuild may reveal the next missing class. Read the
exception -- it names the exact `art::Assns<...>` / `art::Ptr<...>` that's missing.

## NuGraph Worked Example -- What Was Added

### `classes.h` (Added at the Bottom)
```cpp
#include "lardataobj/RecoBase/Hit.h"
#include "lardataobj/AnalysisBase/MVAOutput.h"   // anab::FeatureVector lives here
#include "lardataobj/RecoBase/Slice.h"
#include "lardataobj/RecoBase/Cluster.h"
#include "lardataobj/RecoBase/Track.h"
#include "lardataobj/RecoBase/Shower.h"
```
(The first three were strictly required -- the build kept reporting them missing. The
rest were added pre-emptively to avoid repeated rebuild cycles.)

### `classes_def.xml` (Added at the Bottom)
```xml
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

## Diagnosing What's Missing

```bash
cd $MRB_SOURCE/icaruscode/icaruscode
grep -R "anab::FeatureVector" -n . | grep classes_def.xml | head
LIBDIR=/exp/icarus/app/users/<you>/<dev>/build_slf7.x86_64/icaruscode/slf7.x86_64.e26.prof/lib
ls $LIBDIR | egrep -i "dict|NuGraph" | head
grep -R "FeatureVector<5>" -n $LIBDIR/*.rootmap 2>/dev/null | head
```
Empty results ⇒ no dictionary generated ⇒ add the classes above and rebuild.

> **For another model:** run the job, read the `DictionaryNotFound` exception, and
> register the classes it names (the target model's own associations / vectors).
> Same procedure, different product types; CVN is one example.
