import LidoSRv3.Audit.Verity.AllocationTx

namespace LidoSRv3.Tests.VerityAllocationTxBindLiveOneDecodesSummaryKillLines

open LidoSRv3.Audit.Verity.AllocationTx
open LidoSRv3.Audit.AllocCapacity
open Verity

/-- Restate the bridge theorem `bindLiveOne_decodes_summary` under a
kill-line so its signature is pinned by direct citation and cannot drift
silently. -/
theorem bindLiveOne_decodes_summary_restated
    (adversary : Compiler.CompilationModel.DenoteExternalCalls.AdversaryModel)
    (state : ContractState) (index : Nat) (data : List Nat)
    (summary : DecodedSummary)
    (hresult : adversary.result
      (_root_.LidoSRv3.Audit.Verity.AllocCapacityPhase3.sourceSummarySite
        (sourceBindConfigOne state index).moduleAddress.val) state =
      .success data)
    (hdecode : decodeSummary data = some summary)
    (htype1 : (sourceBindConfigOne state index).isType2 = false) :
    (bindLiveOne adversary state index) state =
      .success (withSummary (sourceBindConfigOne state index) summary) state :=
  bindLiveOne_decodes_summary adversary state index data summary hresult hdecode htype1

end LidoSRv3.Tests.VerityAllocationTxBindLiveOneDecodesSummaryKillLines
