import LidoSRv3.Audit.Guarantees.PConsolidationValue1

/-! # Product-6 kill-lines: official-success conjunct

Parent-shaped mutants for
`PConsolidationValue1.official_denote_succeeds_and_justified_forwards_msg_value`:

* an unlinked environment (the named predeploy does not resolve) makes the
  official widened denote still revert, so the success conjunct fails;
* a zero-value link makes the official widened denote succeed with
  zero-value CALL frames, so the value-bearing and exact-forwarding
  conjuncts fail;
* a rejecting predeploy model shows the `AcceptingPredeploy` premise is
  load-bearing: dropping it refutes the success conjunct.

Each kill-line keeps the parent's premises and substitutes exactly one
mutant into the conclusion shape. -/

namespace LidoSRv3.Tests.PackP6OfficialSuccessMutants

open _root_.Verity
open Compiler.CompilationModel.Denote
open Compiler.CompilationModel.DenoteExternalCalls
open Compiler.CompilationModel.DenoteFunctionCalls
open LidoSRv3.Audit.Verity.ConsolidationCallFragment
open LidoSRv3.Audit.Verity.ConsolidationValueTx
open LidoSRv3.Audit.Verity.ConsolidationOfficialDenoteSuccess

/-- Mutant environment: the named predeploy external does not resolve. -/
def unlinkedEnv (oracle : DenoteOracle) (adversary : AdversaryModel) : CallEnv :=
  { oracle := oracle, adversary := adversary, resolve := fun _ => none }

/-- Mutant predeploy model: the callee rejects every request frame. -/
def rejectingPredeploy : AdversaryModel :=
  { stateTransition := fun _ world => world
    result := fun _ _ => .revert []
    gasUsed := fun _ _ => 0 }

/-- Concrete guard-passing witness transaction: gateway caller, two nonzero
aligned key words, `msg.value = 1 * fee` with `fee = 1`. -/
def witnessTx : DenoteTransaction :=
  { sender := 0xCAFE, msgValue := 1, functionSelector := bindSelector
    args := [1, 2] }

def witnessGateway : Nat := 0xCAFE

private theorem one_lt_modulus : (1 : Nat) < Verity.Core.Uint256.modulus :=
  Nat.one_lt_two_pow (by decide)

private theorem two_lt_modulus : (2 : Nat) < Verity.Core.Uint256.modulus := by
  have : (2 : Nat) = 2 ^ 1 := rfl
  rw [this]
  exact Nat.pow_lt_pow_right (by decide) (by decide)

private theorem witness_funded :
    (Verity.defaultState : ContractState).selfBalance.val + 1 <
      Verity.Core.Uint256.modulus := by
  have hZero : (Verity.defaultState : ContractState).selfBalance.val = 0 := rfl
  rw [hZero]
  simpa using one_lt_modulus

/-- Sanity: the witness satisfies the parent premises and the honest
official denotation succeeds on it (the parent instantiated). -/
theorem witness_official_denote_succeeds :
    (officialDenote
        (officialEnv witnessOracle queueAdversary consolidationPredeploy 1)
        witnessTx Verity.defaultState).success = true :=
  (official_denote_succeeds_on_value_bearing_request_calls
    witnessOracle queueAdversary consolidationPredeploy 1 witnessGateway
    witnessTx Verity.defaultState 1 2 queueAdversary_accepting rfl
    one_lt_modulus two_lt_modulus (by decide) (by decide) rfl
    (fun _ => by decide) rfl witness_funded).1

set_option linter.unusedVariables false in
/-- Parent-shaped kill-line: a mutant official denote that still reverts
(the predeploy link is deleted) fails the success conjunct under the exact
parent premises.  The `target` binder is kept to preserve the parent shape
even though the unlinked mutant ignores it. -/
theorem official_denote_mutant_still_reverts_refutes_parent :
    ¬ (∀ (oracle : DenoteOracle) (adversary : AdversaryModel)
        (target fee gateway : Nat)
        (tx : DenoteTransaction) (world : ContractState)
        (sourceKey targetKey : Nat),
      AcceptingPredeploy adversary →
      tx.args = [sourceKey, targetKey] →
      sourceKey < Verity.Core.Uint256.modulus →
      targetKey < Verity.Core.Uint256.modulus →
      sourceKey ≠ 0 →
      targetKey ≠ 0 →
      tx.sender = gateway →
      (tx.sender = gateway → tx.msgValue ≠ 0) →
      tx.msgValue = 1 * fee →
      world.selfBalance.val + fee < Verity.Core.Uint256.modulus →
      (officialDenote (unlinkedEnv oracle adversary) tx world).success =
        true) := by
  intro h
  have hSuccess := h witnessOracle queueAdversary consolidationPredeploy 1
    witnessGateway witnessTx Verity.defaultState 1 2 queueAdversary_accepting
    rfl one_lt_modulus two_lt_modulus (by decide) (by decide) rfl
    (fun _ => by decide) rfl witness_funded
  have hReverts : (officialDenote
      (unlinkedEnv witnessOracle queueAdversary) witnessTx
      Verity.defaultState).success = false := by
    decide +kernel
  exact Bool.false_ne_true (hReverts.symm.trans hSuccess)

/-- Parent-shaped kill-line: a mutant official denote whose link carries
zero value succeeds, but its CALL frames are not value-bearing and it does
not forward `msg.value`; both conjuncts fail under the exact parent
premises. -/
theorem zero_value_link_mutant_refutes_value_bearing_conjunct :
    ¬ (∀ (oracle : DenoteOracle) (adversary : AdversaryModel)
        (target fee gateway : Nat)
        (tx : DenoteTransaction) (world : ContractState)
        (sourceKey targetKey : Nat),
      AcceptingPredeploy adversary →
      tx.args = [sourceKey, targetKey] →
      sourceKey < Verity.Core.Uint256.modulus →
      targetKey < Verity.Core.Uint256.modulus →
      sourceKey ≠ 0 →
      targetKey ≠ 0 →
      tx.sender = gateway →
      (tx.sender = gateway → tx.msgValue ≠ 0) →
      tx.msgValue = 1 * fee →
      world.selfBalance.val + fee < Verity.Core.Uint256.modulus →
      ((freshCalls (withPayableCallContext world tx)
          (officialExec (officialEnv oracle adversary target 0) tx
            world).world).map (fun call => call.value)) = [fee] ∧
      forwardedValue (withPayableCallContext world tx)
          (officialExec (officialEnv oracle adversary target 0) tx
            world).world = tx.msgValue) := by
  intro h
  obtain ⟨hValues, hForwarded⟩ := h witnessOracle queueAdversary
    consolidationPredeploy 1 witnessGateway witnessTx Verity.defaultState 1 2
    queueAdversary_accepting rfl one_lt_modulus two_lt_modulus (by decide)
    (by decide) rfl (fun _ => by decide) rfl witness_funded
  have hZero : forwardedValue
      (withPayableCallContext Verity.defaultState witnessTx)
      (officialExec
        (officialEnv witnessOracle queueAdversary consolidationPredeploy 0)
        witnessTx Verity.defaultState).world = 0 := by
    decide +kernel
  rw [hForwarded] at hZero
  exact absurd hZero (by decide)

/-- Premise necessity: dropping `AcceptingPredeploy` admits a rejecting
predeploy model, and the official denote then reverts instead of
succeeding. -/
theorem rejecting_predeploy_refutes_unpremised_success :
    ¬ (∀ (oracle : DenoteOracle) (adversary : AdversaryModel)
        (target fee gateway : Nat)
        (tx : DenoteTransaction) (world : ContractState)
        (sourceKey targetKey : Nat),
      tx.args = [sourceKey, targetKey] →
      sourceKey < Verity.Core.Uint256.modulus →
      targetKey < Verity.Core.Uint256.modulus →
      sourceKey ≠ 0 →
      targetKey ≠ 0 →
      tx.sender = gateway →
      (tx.sender = gateway → tx.msgValue ≠ 0) →
      tx.msgValue = 1 * fee →
      world.selfBalance.val + fee < Verity.Core.Uint256.modulus →
      (officialDenote (officialEnv oracle adversary target fee) tx
        world).success = true) := by
  intro h
  have hSuccess := h witnessOracle rejectingPredeploy consolidationPredeploy 1
    witnessGateway witnessTx Verity.defaultState 1 2 rfl one_lt_modulus
    two_lt_modulus (by decide) (by decide) rfl (fun _ => by decide) rfl
    witness_funded
  have hReverts : (officialDenote
      (officialEnv witnessOracle rejectingPredeploy consolidationPredeploy 1)
      witnessTx Verity.defaultState).success = false := by
    decide +kernel
  exact Bool.false_ne_true (hReverts.symm.trans hSuccess)

end LidoSRv3.Tests.PackP6OfficialSuccessMutants
