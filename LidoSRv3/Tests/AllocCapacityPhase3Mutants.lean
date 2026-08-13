import LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-! Negative mutations for the actual Phase-3 source-to-transaction bridge. -/

namespace LidoSRv3.Tests.AllocCapacityPhase3Mutants

open Compiler
open Compiler.CompilationModel
open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit.Verity.AllocCapacityPhase3

def callKindMutant : FunctionSpec :=
  { consumedSummaryEntry with
    body := consumedSummaryBody.set 2
      (.letVar "summaryOk"
        (.call (.literal maxGas) (.param "moduleAddress") (.literal 0)
          (.literal 0) (.literal 4) (.literal 0) (.literal summaryReturnBytes))) }

def selectorMutant : FunctionSpec :=
  { consumedSummaryEntry with
    body := consumedSummaryBody.set 0
      (.mstore (.literal 0) (.shl (.literal 224) (.literal 0))) }

def returnLayoutMutant : FunctionSpec :=
  { consumedSummaryEntry with
    body := consumedSummaryBody.set 2
      (.letVar "summaryOk"
        (.staticcall (.literal maxGas) (.param "moduleAddress")
          (.literal 0) (.literal 4) (.literal 0) (.literal 32))) }

def preCallStoreMutant : FunctionSpec :=
  { consumedSummaryEntry with
    body := consumedSummaryBody.set 1
      (.setStorage "lastCapacity" (.literal 0)) }

/-- These mutations target the same source relation and extractor consumed by
the P-ALLOC-1 guarantee.  The call-kind mutant removes the extracted call;
selector and return-layout mutants falsify the checked source ABI. -/
theorem call_mutant_breaks_actual_bridge (moduleAddress : Nat) :
    sourceCallProgram callKindMutant moduleAddress = .pure false := by rfl

theorem selector_mutant_breaks_actual_bridge (moduleAddress : Nat) :
    ¬ SourceCallStorageABI selectorMutant moduleAddress := by
  rintro ⟨_, _, hbody, _⟩
  simp [selectorMutant, consumedSummaryBody] at hbody
  have hselector : summarySelector ≠ 0 := by native_decide
  exact hselector hbody.symm

theorem return_layout_mutant_breaks_actual_bridge (moduleAddress : Nat) :
    ¬ SourceCallStorageABI returnLayoutMutant moduleAddress := by
  rintro ⟨_, _, hbody, _⟩
  simp [returnLayoutMutant, consumedSummaryBody] at hbody
  have hneq : (32 : Nat) ≠ summaryReturnBytes := by native_decide
  exact hneq hbody

theorem call_mutant_cannot_satisfy_source_bridge (moduleAddress : Nat) :
    ¬ SourceCallStorageABI callKindMutant moduleAddress := by
  rintro ⟨_, _, hbody, _⟩
  simp [callKindMutant, consumedSummaryBody] at hbody

theorem pre_call_store_mutant_breaks_actual_bridge (moduleAddress : Nat) :
    ¬ SourceCallStorageABI preCallStoreMutant moduleAddress := by
  rintro ⟨_, _, hbody, _⟩
  simp [preCallStoreMutant, consumedSummaryBody] at hbody

private def state : _root_.Verity.ContractState :=
  { _root_.Verity.defaultState with sender := 17 }

/-- This adversary succeeds only at the observed mapped address.  Changing
that target is a negative regression at the executable contract boundary,
not merely a source-extractor mismatch. -/
private def mappedAddressAdversary : AdversaryModel :=
  { stateTransition := fun _ world => world
    result := fun site _ =>
      if site.target = 17 then .success (List.replicate summaryReturnBytes 0) else .revert [0]
    gasUsed := fun _ _ => 0 }

/-- A successful call with no returndata must fail the same explicit
`returndataSize` guard represented in the checked source body. -/
private def shortReturndataAdversary : AdversaryModel :=
  { stateTransition := fun _ world => world
    result := fun _ _ => .success []
    gasUsed := fun _ _ => 0 }

/-- The 96-byte ABI shape alone is insufficient: the copied depositable word
at offset 64 must also pass the source capacity bound. -/
private def excessiveCapacityAdversary : AdversaryModel :=
  { stateTransition := fun _ world => world
    result := fun _ _ => .success (List.replicate 95 0 ++ [8])
    gasUsed := fun _ _ => 0 }

#guard match (executeObservedSummary mappedAddressAdversary 17 7).run state with
  | _root_.Verity.ContractResult.success () after =>
      after.storage lastCapacitySlot.slot == 7
  | _ => false

/- Mutation-negative regression: changing the mapped target makes the exact
`CallProgram` observation revert inside the same `Contract.run` transaction,
which restores the pre-call state. -/
#guard match (executeObservedSummary mappedAddressAdversary 18 7).run state with
  | _root_.Verity.ContractResult.revert "StakingModuleSummaryCallFailed" rollback =>
      rollback.sender == state.sender && rollback.storage lastCapacitySlot.slot == 0
  | _ => false

/- Mutation-negative executable regressions for the post-call source guards:
neither malformed successful returndata nor a capacity word over the bound may
commit the pre-call store. -/
#guard match (executeObservedSummary shortReturndataAdversary 17 7).run state with
  | _root_.Verity.ContractResult.revert "StakingModuleSummaryMalformedReturn" rollback =>
      rollback.sender == state.sender && rollback.storage lastCapacitySlot.slot == 0
  | _ => false

#guard match (executeObservedSummary excessiveCapacityAdversary 17 7).run state with
  | _root_.Verity.ContractResult.revert "CapacityExceedsDepositable" rollback =>
      rollback.sender == state.sender && rollback.storage lastCapacitySlot.slot == 0
  | _ => false

#guard match (executeSummary 7 false).run state with
  | _root_.Verity.ContractResult.revert "StakingModuleSummaryCallFailed" rollback =>
      rollback.sender == state.sender
  | _ => false

end LidoSRv3.Tests.AllocCapacityPhase3Mutants
