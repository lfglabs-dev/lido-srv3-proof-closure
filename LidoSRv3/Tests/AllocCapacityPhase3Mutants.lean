import LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-! Negative mutation for the P-ALLOC-1 Phase-3 consumed-call slice. -/

namespace LidoSRv3.Tests.AllocCapacityPhase3Mutants

open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-- Mutant: change the source-shaped read-only capacity query into a mutable
`call`.  Under a successful adversary response it can now commit a world
transition, so it cannot satisfy the canonical staticcall post-state. -/
def mutableCallMutant (moduleId : Nat) : CallProgram Bool :=
  .bind { sourceDerivedCapacitySite moduleId with kind := .call } fun observation =>
    .pure observation.result.succeeded

def writingAdversary : AdversaryModel :=
  { stateTransition := fun _ world =>
      { world with storage := fun slot => if slot = 0 then 99 else world.storage slot }
    result := fun _ _ => .success []
    gasUsed := fun _ _ => 0 }

theorem mutable_call_mutant_rejected (moduleId : Nat) :
    (denote (mutableCallMutant moduleId) writingAdversary canonicalCallState).2.world.storage 0 ≠
      canonicalCallState.world.storage 0 := by
  change 99 ≠ 0
  decide

end LidoSRv3.Tests.AllocCapacityPhase3Mutants
