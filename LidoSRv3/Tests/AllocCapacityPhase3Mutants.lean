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

#guard match (executeSummary 7 false).run state with
  | _root_.Verity.ContractResult.revert "StakingModuleSummaryCallFailed" rollback =>
      rollback.sender == state.sender
  | _ => false

end LidoSRv3.Tests.AllocCapacityPhase3Mutants
