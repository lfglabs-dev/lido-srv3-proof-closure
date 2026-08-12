import LidoSRv3.Audit.Guarantees.PAlloc1
import LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-! Immediate P-ALLOC-1 consumption of the bounded Phase-3 transaction slice. -/

namespace LidoSRv3.Audit.Guarantees.PAlloc1Phase3

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-- The resolved target is obtained by the mapped
`SRStorage.getIStakingModule(moduleId)` source lookup.  This guarantee ends at
the Verity transaction boundary, with no Yul/EVM closure claim. -/
theorem mapped_summary_call_transaction (moduleAddress : Nat) :
    (CompilationModel.compile spec [entrySelector]).isOk = true ∧
    SourceCallStorageABI consumedSummaryEntry moduleAddress ∧
    CallsIn (sourceCallProgram consumedSummaryEntry moduleAddress)
      { stateTransition := fun _ world => world
        result := fun _ _ => .success (List.replicate summaryReturnBytes 0)
        gasUsed := fun _ _ => 0 } canonicalCallState =
      [sourceSummarySite moduleAddress] ∧
    (∀ adversary data,
      adversary.result (sourceSummarySite moduleAddress) canonicalCallState.world = .revert data →
      (denote (sourceCallProgram consumedSummaryEntry moduleAddress)
        adversary canonicalCallState).1 = false ∧
      (denote (sourceCallProgram consumedSummaryEntry moduleAddress)
        adversary canonicalCallState).2.world = canonicalCallState.world) :=
  consumed_summary_phase3_transaction moduleAddress

end LidoSRv3.Audit.Guarantees.PAlloc1Phase3
