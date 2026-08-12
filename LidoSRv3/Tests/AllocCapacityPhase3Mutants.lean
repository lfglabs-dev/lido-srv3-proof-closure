import LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-! Negative mutation for the P-ALLOC-1 Phase-3 consumed-call slice. -/

namespace LidoSRv3.Tests.AllocCapacityPhase3Mutants

open Compiler
open Compiler.CompilationModel
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

/-! The following family mutates the *compiled FunctionSpec surface* that the
bridge consumes.  These are deliberately separate from `CallProgram` so a
source body, call, calldata, or storage mutation cannot retain the claim by
reusing the canonical external-call record. -/

def bodyRemovalMutant : FunctionSpec :=
  { consumedCapacityEntry with body := consumedCapacityBody.tail }

def callKindMutant : FunctionSpec :=
  { consumedCapacityEntry with
    body :=
      [ .mstore (.literal 0) (.shl (.literal 224) (.literal capacitySelector))
      , .mstore (.literal 4) (.param "moduleId")
      , .setStorage "lastCapacity" (.param "depositable")
      , .letVar "capacityOk"
          (.call (.literal Verity.Core.MAX_UINT256) (.literal moduleAddress)
            (.literal 0) (.literal 0) (.literal 36) (.literal 32) (.literal 32))
      , .require (.eq (.localVar "capacityOk") (.literal 1))
          "ModuleCapacityCallFailed"
      , .letVar "capacity" (.mload (.literal 32))
      , .require (.le (.localVar "capacity") (.param "depositable"))
          "CapacityExceedsDepositable"
      , .return (.localVar "capacity") ] }

def calldataMutant : FunctionSpec :=
  { consumedCapacityEntry with
    body :=
      [ .mstore (.literal 0) (.shl (.literal 224) (.literal capacitySelector))
      , .mstore (.literal 4) (.literal 0)
      , .setStorage "lastCapacity" (.param "depositable")
      , .letVar "capacityOk"
          (.staticcall (.literal Verity.Core.MAX_UINT256) (.literal moduleAddress)
            (.literal 0) (.literal 36) (.literal 32) (.literal 32))
      , .require (.eq (.localVar "capacityOk") (.literal 1))
          "ModuleCapacityCallFailed"
      , .letVar "capacity" (.mload (.literal 32))
      , .require (.le (.localVar "capacity") (.param "depositable"))
          "CapacityExceedsDepositable"
      , .return (.localVar "capacity") ] }

def storageMutant : FunctionSpec :=
  { consumedCapacityEntry with
    body :=
      [ .mstore (.literal 0) (.shl (.literal 224) (.literal capacitySelector))
      , .mstore (.literal 4) (.param "moduleId")
      , .setStorage "wrongCapacity" (.param "depositable")
      , .letVar "capacityOk"
          (.staticcall (.literal Verity.Core.MAX_UINT256) (.literal moduleAddress)
            (.literal 0) (.literal 36) (.literal 32) (.literal 32))
      , .require (.eq (.localVar "capacityOk") (.literal 1))
          "ModuleCapacityCallFailed"
      , .letVar "capacity" (.mload (.literal 32))
      , .require (.le (.localVar "capacity") (.param "depositable"))
          "CapacityExceedsDepositable"
      , .return (.localVar "capacity") ] }

theorem body_mutant_breaks_source_bridge : ¬ SourceCallStorageABI bodyRemovalMutant := by
  simp [SourceCallStorageABI, bodyRemovalMutant, consumedCapacityBody]

theorem call_mutant_breaks_source_bridge : ¬ SourceCallStorageABI callKindMutant := by
  simp [SourceCallStorageABI, callKindMutant, consumedCapacityBody]

theorem calldata_mutant_breaks_source_bridge : ¬ SourceCallStorageABI calldataMutant := by
  simp [SourceCallStorageABI, calldataMutant, consumedCapacityBody]

theorem storage_mutant_breaks_source_bridge : ¬ SourceCallStorageABI storageMutant := by
  simp [SourceCallStorageABI, storageMutant, consumedCapacityBody]

end LidoSRv3.Tests.AllocCapacityPhase3Mutants
