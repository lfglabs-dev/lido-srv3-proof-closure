import LidoSRv3.Audit.Verity.AllocCapacityPhase3

namespace LidoSRv3.Tests.AllocCapacityPhase3ReturnDataOutcomesKillLines

open LidoSRv3.Audit.Verity.AllocCapacityPhase3
open Compiler.CompilationModel.DenoteExternalCalls

/-- Pin `typed_external_revert_rolls_back_pre_call_store`: a
`.revert` from the adversary on the source summary site rolls the
pre-call `lastCapacitySlot ↦ depositable` write back to `state`. -/
theorem typed_external_revert_rolls_back_pre_call_store_restated
    (adversary : AdversaryModel) (moduleAddress : Nat) (data : List Nat)
    (depositable : _root_.Verity.Uint256) (state : _root_.Verity.ContractState)
    (hresult : adversary.result (sourceSummarySite moduleAddress)
      (state.writeSlot lastCapacitySlot.slot depositable) = .revert data) :
    ∃ reason, (executeObservedSummary adversary moduleAddress depositable).run state =
      _root_.Verity.ContractResult.revert reason state :=
  typed_external_revert_rolls_back_pre_call_store adversary moduleAddress data
    depositable state hresult

/-- Pin `typed_short_returndata_rolls_back_pre_call_store`: a successful
mapped call with insufficient returndata rolls the pre-call store back
through the source-shaped size guard — non-zero-success-bit rejection. -/
theorem typed_short_returndata_rolls_back_pre_call_store_restated
    (adversary : AdversaryModel) (moduleAddress : Nat) (data : List Nat)
    (depositable : _root_.Verity.Uint256) (state : _root_.Verity.ContractState)
    (hresult : adversary.result (sourceSummarySite moduleAddress)
      (state.writeSlot lastCapacitySlot.slot depositable) = .success data)
    (hshort : ¬ summaryReturnBytes <= data.length) :
    (executeObservedSummary adversary moduleAddress depositable).run state =
      _root_.Verity.ContractResult.revert "StakingModuleSummaryMalformedReturn" state :=
  typed_short_returndata_rolls_back_pre_call_store adversary moduleAddress data
    depositable state hresult hshort

/-- Pin `typed_complete_returndata_commits_pre_call_store`: the payload is
otherwise unconstrained — this transaction slice does not invent a
`capacity ≤ depositable` guard. -/
theorem typed_complete_returndata_commits_pre_call_store_restated
    (adversary : AdversaryModel) (moduleAddress : Nat) (data : List Nat)
    (depositable : _root_.Verity.Uint256) (state : _root_.Verity.ContractState)
    (hresult : adversary.result (sourceSummarySite moduleAddress)
      (state.writeSlot lastCapacitySlot.slot depositable) = .success data)
    (hcomplete : summaryReturnBytes <= data.length) :
    (executeObservedSummary adversary moduleAddress depositable).run state =
      _root_.Verity.ContractResult.success ()
        (state.writeSlot lastCapacitySlot.slot depositable) :=
  typed_complete_returndata_commits_pre_call_store adversary moduleAddress data
    depositable state hresult hcomplete

end LidoSRv3.Tests.AllocCapacityPhase3ReturnDataOutcomesKillLines
