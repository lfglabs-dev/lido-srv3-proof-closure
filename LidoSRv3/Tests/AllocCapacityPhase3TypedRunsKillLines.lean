import LidoSRv3.Audit.Verity.AllocCapacityPhase3

namespace LidoSRv3.Tests.AllocCapacityPhase3TypedRunsKillLines

open LidoSRv3.Audit.Verity.AllocCapacityPhase3
open Compiler.CompilationModel.DenoteExternalCalls

/-- Pin `execute_mapped_summary_call_bridge`: the bridge from the typed
`executeMappedSummaryCall` execution into the pinned-source `CallProgram`
denotation. This is definitional (`rfl`) — any drift in the source call
program shape or the `denote` reduction breaks this before it can rot the
P-ALLOC-1 Phase-3 mapped-call refinement. -/
theorem execute_mapped_summary_call_bridge_restated
    (adversary : AdversaryModel) (moduleAddress : Nat)
    (state : _root_.Verity.ContractState) :
    (executeMappedSummaryCall adversary moduleAddress).run state =
      _root_.Verity.ContractResult.success
        (denote (sourceCallProgram consumedSummaryEntry moduleAddress)
          adversary (callStateOfTransaction state)).1 state :=
  execute_mapped_summary_call_bridge adversary moduleAddress state

/-- Pin `typed_success_commits_pre_call_store`: the typed success branch
commits the pre-call store (`lastCapacitySlot ↦ depositable`), witnessing
the actual `Contract.run` (not a synthetic setter). -/
theorem typed_success_commits_pre_call_store_restated
    (depositable : _root_.Verity.Uint256) (state : _root_.Verity.ContractState) :
    ∃ after, (executeSummary depositable true).run state = .success () after ∧
      after.storage lastCapacitySlot.slot = depositable :=
  typed_success_commits_pre_call_store depositable state

/-- Pin `typed_revert_rolls_back_pre_call_store`: the typed revert branch
rolls the pre-call store back to `state` — this is the non-vacuous
rollback theorem consuming `Contract.run`, not a synthetic reset. -/
theorem typed_revert_rolls_back_pre_call_store_restated
    (depositable : _root_.Verity.Uint256)
    (state rollback : _root_.Verity.ContractState) (reason : String)
    (h : (executeSummary depositable false).run state =
      _root_.Verity.ContractResult.revert reason rollback) :
    rollback = state :=
  typed_revert_rolls_back_pre_call_store depositable state rollback reason h

end LidoSRv3.Tests.AllocCapacityPhase3TypedRunsKillLines
