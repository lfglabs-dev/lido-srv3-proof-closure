import LidoSRv3.Audit.Verity.DepositParentTx

/-! # P-DEPOSIT-1 faithful-plane fail-closed vectors

Every mutant here mutates the *executable transaction*: it runs the same
`writeMapUint` storage channel and the same `externalCallBindTo` call frames
through `Verity.Contract.run`, and is rejected by exactly the observable
equality `execute_observes_source` asserts.  `mutant_none_reproduces_execute`
pins `Mutation.none` to the production `execute`, so each rejection is the
rejection of a mutated *execution* rather than of a hand-written journal list or
of a doctored input record.

The per-module mapping mutants (`skipAllocationWrite`, `skipDynamicDataWrite`,
`skipRootWrite`) are the ones an aggregates-only observable would have missed:
they leave every wei total and the whole call journal intact. -/

namespace LidoSRv3.Tests.DepositParentTxMutants

open Verity
open Contracts
open LidoSRv3.Audit.Verity.DepositParentTx

private def inputs : Inputs := canonicalInputs

private def frame : ContractState := canonicalState

inductive Mutation where
  | none
  | skipAllocationWrite
  | skipDynamicDataWrite
  | skipRootWrite
  | skipCounterBump
  | skipLidoDebit
  | dropSecondPush
  | misroutePush
  | corruptPushAmount
  | swapPushOrder
  | duplicateFirstPush
  deriving DecidableEq, Repr

/-- Per-module bookkeeping mutations.  The call frames and the wei totals are
untouched, so only the mapping-word observables can reject these. -/
private def mutantProcessBatch (m : Mutation) (inputs : Inputs) (batch : Batch) :
    Contract Unit := do
  match m with
  | .skipAllocationWrite => Verity.pure ()
  | _ => writeMap allocationSlot batch.moduleId batch.keys
  externalCallBindTo inputs.module 0 [] (callName batch.moduleCallOk "obtainDepositData")
    [batch.moduleId, batch.keys]
  match m with
  | .skipDynamicDataWrite => Verity.pure ()
  | _ => writeMap dynamicDataSlot batch.moduleId batch.dynamicDataCommitment
  require batch.dataValid "INVALID_DYNAMIC_DEPOSIT_DATA"
  match m with
  | .skipRootWrite => Verity.pure ()
  | _ => writeMap depositRootSlot batch.moduleId batch.depositDataRoot
  require batch.rootValid "INVALID_DEPOSIT_DATA_ROOT"

/-- Ledger mutation: the router still credits itself the aggregate, but Lido's
depositable balance is never debited, so ether is minted rather than moved. -/
private def mutantPull (m : Mutation) (inputs : Inputs) (total : Word) : Contract Unit := do
  externalCallBindTo inputs.lido 0 [] (callName inputs.lidoCallOk "withdrawDepositableEther")
    [total]
  let state ← getState
  require (total ≤ state.readSlot lidoDepositableSlot) "NOT_ENOUGH_ETHER"
  match m with
  | .skipLidoDebit => Verity.pure ()
  | _ => setStorage ⟨lidoDepositableSlot⟩ (state.readSlot lidoDepositableSlot - total)
  creditRouter total

/-- Destination and value mutations of one beacon frame. -/
private def mutantPush (m : Mutation) (inputs : Inputs) (batch : Batch) : Contract Unit :=
  match m with
  | .misroutePush =>
      externalCallBindTo inputs.lido batch.amount []
        (callName batch.beaconCallOk "depositToBeacon")
        [batch.moduleId, batch.keys, batch.dynamicDataCommitment, batch.depositDataRoot]
  | .corruptPushAmount =>
      externalCallBindTo inputs.beacon (batch.amount - 1) []
        (callName batch.beaconCallOk "depositToBeacon")
        [batch.moduleId, batch.keys, batch.dynamicDataCommitment, batch.depositDataRoot]
  | _ => pushBatch inputs batch

/-- Schedule mutations of the beacon leg. -/
private def mutantPushes (m : Mutation) (inputs : Inputs) : Contract Unit :=
  match m with
  | .dropSecondPush => mutantPush m inputs inputs.first
  | .swapPushOrder => do
      mutantPush m inputs inputs.second
      mutantPush m inputs inputs.first
  | .duplicateFirstPush => do
      mutantPush m inputs inputs.first
      mutantPush m inputs inputs.first
      mutantPush m inputs inputs.second
  | _ => do
      mutantPush m inputs inputs.first
      mutantPush m inputs inputs.second

private def mutantExecute (m : Mutation) (inputs : Inputs) : Contract Unit := do
  require inputs.authorized "NOT_AUTHORIZED"
  require inputs.moduleActive "MODULE_NOT_ACTIVE"
  require inputs.allocationValid "INVALID_ALLOCATION"
  let state ← getState
  match m with
  | .skipCounterBump => Verity.pure ()
  | _ => setStorage ⟨counterSlot⟩ (state.readSlot counterSlot + 1)
  mutantProcessBatch m inputs inputs.first
  mutantProcessBatch m inputs inputs.second
  let total := inputs.first.amount + inputs.second.amount
  require (total == (inputs.first.keys + inputs.second.keys) * inputs.depositSize)
    "ALLOCATION_VALUE_MISMATCH"
  mutantPull m inputs total
  mutantPushes m inputs
  let after ← getState
  require (after.selfBalance == state.selfBalance) "ASSERT_BALANCE_UNCHANGED"

/-- The unmutated mutant *is* the production transaction. -/
theorem mutant_none_reproduces_execute :
    (mutantExecute .none inputs).run frame = (execute inputs).run frame := by
  rfl

/-- Positive control: the executable transaction reproduces the pinned-source
observables, per-module mapping words and journal destinations included. -/
theorem honest_run_matches_source :
    observe frame (probes inputs) ((execute inputs).run frame)
      = sourceObservables inputs frame :=
  execute_observes_source inputs frame canonical_preconditions

/-! ## Per-module bookkeeping mutants

These three move exactly the right wei through exactly the right call frames.
Only the per-deposit mapping observables reject them. -/

theorem skipped_allocation_write_rejected :
    observe frame (probes inputs) ((mutantExecute .skipAllocationWrite inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

theorem skipped_dynamic_data_write_rejected :
    observe frame (probes inputs) ((mutantExecute .skipDynamicDataWrite inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

theorem skipped_root_write_rejected :
    observe frame (probes inputs) ((mutantExecute .skipRootWrite inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

/-- Omitting the reentrancy-counter bump is rejected. -/
theorem skipped_counter_bump_rejected :
    observe frame (probes inputs) ((mutantExecute .skipCounterBump inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

/-! ## Conservation mutants -/

/-- Crediting the router without debiting Lido mints ether: the pulled aggregate
no longer matches the pushed aggregate. -/
theorem skipped_lido_debit_rejected :
    observe frame (probes inputs) ((mutantExecute .skipLidoDebit inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

/-! ### Kill-line for the registered P-DEPOSIT-1 parent

`PDeposit1.verity_tx_composes_deposit_conservation_and_rollback` names the
conserved quantity at exactly this `DepositParentTx` granularity: conjunct (a)
is `(run cfg inp).pulled = (run cfg inp).pushed`, and conjunct (c) transports
that same equality onto `Observables.pulled` / `Observables.pushed` for the
honest `execute` (`(sourceObservables inputs entry).pulled = (run cfg inp).pulled`
and the `.pushed` sibling). `skipped_lido_debit_rejected` above already shows
the mutant's *entire* observation record disagrees with `sourceObservables`;
the theorem below isolates the *conserved quantity itself* -- `pulled ≠
pushed` on the mutant's own `Observables` -- at the identical
`DepositParentTx.Observables` granularity the registered parent composes
over. This is the kill-line: it removes the conservation-carrying step (the
Lido debit inside `mutantPull`) and shows the very equality the registered
parent asserts for the honest transaction fails for the patched one. It is
*not* the same claim as
`LidoSRv3.Audit.Verity.DepositLedgerTx.dropped_assert_commits_nonconserving_deployment`,
which mutates a different, disconnected single-batch ledger model that
`PDeposit1.lean` never imports and the `P-DEPOSIT-1` reproduction command
never builds. -/
theorem skipped_lido_debit_breaks_pulled_eq_pushed :
    (observe frame (probes inputs) ((mutantExecute .skipLidoDebit inputs).run frame)).pulled
      ≠ (observe frame (probes inputs) ((mutantExecute .skipLidoDebit inputs).run frame)).pushed := by
  decide

/-- Omitting the second beacon frame leaves the pulled ether stranded on the
router, and `ASSERT_BALANCE_UNCHANGED` closes the transaction out. -/
theorem dropped_push_rejected :
    observe frame (probes inputs) ((mutantExecute .dropSecondPush inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

/-- Sending a deposit to Lido instead of the beacon depositor is rejected even
though the wei total is unchanged. -/
theorem misrouted_push_rejected :
    observe frame (probes inputs) ((mutantExecute .misroutePush inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

/-- Short-paying each beacon frame by one wei is rejected. -/
theorem corrupted_amount_rejected :
    observe frame (probes inputs) ((mutantExecute .corruptPushAmount inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

/-- Reordering the batch is rejected: the journal records call order. -/
theorem swapped_order_rejected :
    observe frame (probes inputs) ((mutantExecute .swapPushOrder inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

/-- Replaying the first deposit overspends the pull, and the ETH-aware call
frame reverts rather than minting wei. -/
theorem duplicated_push_rejected :
    observe frame (probes inputs) ((mutantExecute .duplicateFirstPush inputs).run frame)
      ≠ sourceObservables inputs frame := by decide

/-! ## Rollback after real prefix effects

The guard-driven failure of `badSecondRootInputs` is not a mutation: it is the
production `execute` reverting on its own `INVALID_DEPOSIT_DATA_ROOT` guard.
These vectors show the prefix writes were real before the boundary undid
them. -/

private def finalState : ContractResult Unit → ContractState
  | .revert _ state => state
  | .success _ state => state

theorem first_batch_prefix_is_real :
    (finalState (execute badSecondRootInputs frame)).readMapUint allocationSlot batchA.moduleId
        = (2 : Word) ∧
      (finalState (execute badSecondRootInputs frame)).readMapUint dynamicDataSlot
          batchA.moduleId = (0xa1 : Word) ∧
      (finalState (execute badSecondRootInputs frame)).calls.map (·.name)
        = ["obtainDepositData", "obtainDepositData"] := by
  refine ⟨rfl, rfl, rfl⟩

theorem second_batch_prefix_is_real :
    (finalState (execute badSecondRootInputs frame)).readMapUint allocationSlot batchB.moduleId
        = (3 : Word) ∧
      (finalState (execute badSecondRootInputs frame)).readSlot counterSlot = (42 : Word) := by
  refine ⟨rfl, rfl⟩

/-- And the transaction boundary normalizes all of it back to the entry
snapshot. -/
theorem root_failure_rolls_back :
    (execute badSecondRootInputs).run frame = .revert "INVALID_DEPOSIT_DATA_ROOT" frame := by
  rfl

theorem root_failure_observes_idle :
    observe frame (probes inputs) ((execute badSecondRootInputs).run frame)
      = idleObservables frame (probes inputs) :=
  second_batch_root_failure_rolls_back_first_batch

end LidoSRv3.Tests.DepositParentTxMutants
