import LidoSRv3.Audit.Verity.Topup2Tx

/-!
# P-TOPUP-2 transaction-plane mutants

Regressions demonstrating the call plane is not vacuous: under a cooperative
adversary the gateway program really performs its planned value-bearing calls;
a double-send or uncapped mutant produces an observed trace that genuinely
breaches the block cap the certified program satisfies for every adversary;
and a reverting adversary cannot leak a tampered world into the caller state.
-/

namespace LidoSRv3.Tests.Topup2TxMutants

open Compiler.CompilationModel.DenoteExternalCalls
open LidoSRv3.Audit.Verity.Topup2Tx
open LidoSRv3.Audit.Guarantees.PTopup2
open LidoSRv3.Audit.Source.Topup2

/-- Cooperative adversary: every call succeeds and commits no world change. -/
def alwaysSuccess : AdversaryModel :=
  { stateTransition := fun _ world => world
    result := fun _ _ => .success []
    gasUsed := fun _ _ => 0 }

/-- Adversary that reverts every call while attempting to publish a tampered
world through its state transition. -/
def revertingTamperer (tampered : _root_.Verity.ContractState) : AdversaryModel :=
  { stateTransition := fun _ _ => tampered
    result := fun _ _ => .revert []
    gasUsed := fun _ _ => 0 }

theorem callsIn_forEach_all_success (sites : List CallSite) (state : CallState) :
    CallsIn (forEachCall gatewayPolicy () sites) alwaysSuccess state = sites :=
  callsIn_all_success_eq_planned sites alwaysSuccess state (fun _ _ => ⟨[], rfl⟩)

/-- Under the cooperative adversary, the gateway performs exactly its planned
value-bearing schedule: the observed trace is neither empty nor synthetic. -/
theorem gateway_calls_are_planned_sites (batch : TopupBatch) (cfg : TopupConfig)
    (state : CallState) :
    CallsIn (gatewayCallProgram batch cfg) alwaysSuccess state =
      plannedSites 0 (execute batch cfg) := by
  unfold gatewayCallProgram
  exact callsIn_forEach_all_success _ state

/-- Mutant gateway that performs the allocation schedule twice. -/
def doubleSendProgram (amounts : List Nat) : CallProgram (TransactionResult Unit) :=
  forEachCall gatewayPolicy () (plannedSites 0 (amounts ++ amounts))

/-- The double-send mutant genuinely breaches a 1-gwei block cap with a 1-gwei
allocation list: its observed trace moves 2 gwei of call value. -/
theorem double_send_rejected (state : CallState) :
    ¬ valueSum (CallsIn (doubleSendProgram [1]) alwaysSuccess state) ≤ 1 * GWEI := by
  unfold doubleSendProgram
  rw [callsIn_forEach_all_success, plannedSites_value_sum]
  decide

/-- Mutant gateway that forwards raw requested amounts, skipping the pinned
budget-consuming transition. -/
def uncappedProgram (requestedGwei : List Nat) : CallProgram (TransactionResult Unit) :=
  forEachCall gatewayPolicy () (plannedSites 0 requestedGwei)

/-- Forwarding a raw 2-gwei request against a 1-gwei cap violates the bound the
certified budget-consuming program satisfies for every adversary. -/
theorem over_cap_aggregate_rejected (state : CallState) :
    ¬ valueSum (CallsIn (uncappedProgram [2]) alwaysSuccess state) ≤ 1 * GWEI := by
  unfold uncappedProgram
  rw [callsIn_forEach_all_success, plannedSites_value_sum]
  decide

/-- A reverting adversary cannot leak its tampered world: the program's final
world is the untouched initial world. -/
theorem reverting_adversary_cannot_leak_state (tampered : _root_.Verity.ContractState)
    (batch : TopupBatch) (cfg : TopupConfig) (state : CallState) :
    (denote (gatewayCallProgram batch cfg) (revertingTamperer tampered) state).2.world =
      state.world := by
  apply tx_all_rollback_preserves_world
  intro entry _
  exact Or.inr (Or.inr ⟨[], rfl⟩)

end LidoSRv3.Tests.Topup2TxMutants
