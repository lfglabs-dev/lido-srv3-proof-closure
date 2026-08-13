import LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-! P-ALLOC-1's bounded Phase-3 MODEL -> SOURCE -> VERITY_TX evidence. -/

namespace LidoSRv3.Audit.Guarantees.PAlloc1Phase3

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit.Verity.AllocCapacityPhase3

theorem mapped_summary_call_transaction (moduleAddress : Nat) :
    (CompilationModel.compile spec [entrySelector]).isOk = true ∧
    SourceCallStorageABI consumedSummaryEntry moduleAddress ∧
    CallsIn (sourceCallProgram consumedSummaryEntry moduleAddress)
      { stateTransition := fun _ world => world
        result := fun _ _ => .success (List.replicate summaryReturnBytes 0)
        gasUsed := fun _ _ => 0 } canonicalCallState =
      [sourceSummarySite moduleAddress] ∧
    summaryCalldata = [0x9a, 0xbd, 0xdf, 0x09] ∧
    (∀ adversary data depositable state rollback reason,
      adversary.result (sourceSummarySite moduleAddress) canonicalCallState.world = .revert data →
      (executeObservedSummary adversary moduleAddress depositable).run state =
        _root_.Verity.ContractResult.revert reason rollback →
      rollback = state) :=
  consumed_summary_phase3_transaction moduleAddress

end LidoSRv3.Audit.Guarantees.PAlloc1Phase3
