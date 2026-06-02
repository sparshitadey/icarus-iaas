#include "canvas/Persistency/Common/Wrapper.h"
#include "canvas/Persistency/Common/Ptr.h"
#include "canvas/Persistency/Common/Assns.h"

#include "icaruscode/IcarusObj/SimEnergyDepositSummary.h"
#include "icaruscode/IcarusObj/CRTTPCMatchingInfo.h"
#include "icaruscode/IcarusObj/OpDetWaveformMeta.h"
#include "icaruscode/IcarusObj/PMTWaveformTimeCorrection.h"
#include "icaruscode/IcarusObj/PMTBeamSignal.h"
#include "icaruscode/IcarusObj/Hit.h"
//#include "icaruscode/IcarusObj/CRTPMTMatching.h"

#include "sbnobj/ICARUS/PMT/Trigger/Data/OpticalTriggerGate.h"
#include "sbnobj/ICARUS/PMT/Trigger/Data/TriggerGateData.h"
#include "sbnobj/ICARUS/TPC/ChannelROI.h"

#include "lardataobj/AnalysisBase/T0.h"
#include "lardataobj/RecoBase/OpFlash.h"
#include "lardataobj/RecoBase/PFParticle.h"
#include "lardataobj/Simulation/BeamGateInfo.h"
#include "sbnobj/Common/CRT/CRTHit.hh"
#include "lardataobj/RawData/OpDetWaveform.h"
#include <vector>

#include "lardataobj/RecoBase/Hit.h"
#include "lardataobj/AnalysisBase/MVAOutput.h"
#include "lardataobj/RecoBase/Slice.h"
#include "lardataobj/RecoBase/Cluster.h"
#include "lardataobj/RecoBase/Track.h"
#include "lardataobj/RecoBase/Shower.h"


namespace {
  icarus::SimEnergyDepositSummary EDepSum;
}
