import audit.trio.consolidation.SourceExecution

namespace LidoSRv3.Tests.TrioConsolidation.SourceExecution

open audit.trio.consolidation
open Compiler.CompilationModel.DenoteExternalCalls

private def key (id : Nat) : Pubkey := ⟨id, 48⟩
private def args : ConstructorArgs :=
  ⟨word 1, word 2, word 3, word 4, word 5, word 6⟩
private def deployment : DeployedVault := ⟨args, by decide⟩
private def caller : Word := args.consolidationGateway
private def sources := [key 11, key 12]
private def targets := [key 21, key 22]
private def feeData : List Nat := List.replicate 31 0 ++ [3]

private def entryState : CallState :=
  { world := { Verity.defaultState with selfBalance := word 40 }
    gasRemaining := 100 }

private def debitSuccessfulCall (site : CallSite)
    (world : Verity.ContractState) : Verity.ContractState :=
  { world with selfBalance := word (world.selfBalance.val - site.value) }

private def successAdversary : AdversaryModel :=
  { stateTransition := debitSuccessfulCall
    result := fun site _ => if site.kind = .staticcall then .success feeData else .success []
    gasUsed := fun _ _ => 1 }

private def feeFailureAdversary : AdversaryModel :=
  { successAdversary with
    result := fun site _ => if site.kind = .staticcall then .failure [7] else .success [] }

private def lateCallFailureAdversary : AdversaryModel :=
  { successAdversary with
    result := fun site _ =>
      if site.kind = .staticcall then .success feeData
      else if site.siteId = 2 then .revert [9]
      else .success [] }

private def noDebitAdversary : AdversaryModel :=
  { successAdversary with stateTransition := fun _ world => world }

/-- Constructor rejection belongs to deployment and cannot become a runtime
error arm. -/
example : constructorConditions
    ⟨word 1, word 2, word 3, word 4, word 0, word 6⟩ = false := by decide

example : ¬ ∃ deployed : DeployedVault,
    deployed.args = ⟨word 1, word 2, word 3, word 4, word 0, word 6⟩ := by
  exact rejected_constructor_has_no_deployment _ (by decide)

/-- The successful path consumes the actual STATICCALL returndata and two
successful value-bearing CALL transitions. -/
example : let result := executeSourceBounded 2 deployment caller (word 6) sources targets successAdversary entryState
  result.exit = .committed (sources.zip targets) ∧
    result.state.world.selfBalance = word 40 ∧
    result.state.gasRemaining = 97 := by native_decide

/-- STATICCALL failure is obtained from `denoteCall`, including its returndata;
the transaction restores the pre-credit entry world. -/
example : let result := executeSourceBounded 2 deployment caller (word 6) sources targets feeFailureAdversary entryState
  result.exit = .reverted (.feeReadFailed [7]) ∧
    result.state.world.selfBalance = word 40 ∧
    result.state.gasRemaining = 99 ∧ result.state.returndata = [7] := by native_decide

/-- A later reverting CALL occurs after the first successful CALL transition,
but the outer transaction discards that prefix and restores the entry world. -/
example : let result := executeSourceBounded 2 deployment caller (word 6) sources targets lateCallFailureAdversary entryState
  result.exit = .reverted (.requestAdditionFailed 1 [9]) ∧
    result.state.world.selfBalance = word 40 ∧
    result.state.gasRemaining = 97 ∧ result.state.returndata = [9] := by native_decide

/-- Guard order is source order: a caller failure prevents the adversarial fee
failure from being observed. -/
example : let result := executeSourceBounded 2 deployment (word 99) (word 6) sources targets feeFailureAdversary entryState
  result.exit = .reverted .notConsolidationGateway ∧
    result.state.gasRemaining = 100 := by native_decide

/-- The final balance assertion is `Panic(0x01)`, distinct from the earlier
custom `IncorrectFee` guard. -/
example : let result := executeSourceBounded 2 deployment caller (word 6) sources targets noDebitAdversary entryState
  result.exit = .reverted .modifierAssertionPanic ∧
    result.state.world.selfBalance = word 40 ∧
    result.state.gasRemaining = 97 := by native_decide

/-- Fuel exhaustion is the only open bounded exit and retains the executed
STATICCALL plus successful CALL prefix rather than pretending to revert. -/
example : (executeSourceBounded 1 deployment caller (word 6) sources targets
    successAdversary entryState).state.world.selfBalance = word 43 := by native_decide

end LidoSRv3.Tests.TrioConsolidation.SourceExecution
