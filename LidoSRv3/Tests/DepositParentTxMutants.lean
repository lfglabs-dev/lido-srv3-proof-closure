import LidoSRv3.Audit.Guarantees.PDeposit1
import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.MinFirstAllocation

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
open LidoSRv3.Audit.SolidityDeposit
open LidoSRv3.Audit.Guarantees.PDeposit1

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

/-! ## Kill-line for a hypothetical ALLOC-derived source bridge

The executable allocation witness remains the canonical, checked two-batch
one.  The independent source input contains one key, however, so its
`actualDepositsCount` cannot equal the executable allocation's `2 + 3`.

The statement includes the actual P-ALLOC-1 and P-ALLOC-2 parent premises —
`CheckedBounds` for the allocation capacity loop, and `RowsCorrespond` /
`candidate?` / `hasFreeSpace` / `checkedAmount` for the proportional min-first
step — together with two cross-plane composition premises that tie the ALLOC
pipeline output to the transaction legs:

1. `depositsToAllocate.val = txInputs.first.keys.val + txInputs.second.keys.val`
   — the total allocation demand equals the transaction's key count;
2. `source.map (·.capacity.val) = MathView.capacities allocCfg modules
   depositsToAllocate isTopUp` — P-ALLOC-1's capacity output feeds
   P-ALLOC-2's source rows.

The proof exhibits a single active module (`shareLimit = 10000`,
`depositableCount = 100`, `depositedCount = 10`) with `depositsToAllocate = 5`
matching the executable's `2 + 3` keys, and a one-row min-first witness
`[⟨0, 15⟩]` whose capacity `15 = MathView.capacities` for that module.  The
ALLOC parents constrain capacity rows and proportional amounts; they do not
constrain the source deposit model's `publicKeysBatchLength`, so the
counterexample where all ALLOC and composition premises hold but
`LinksSource.keys` fails remains valid. -/

private def bridgeCounterexampleSourceInput : SourceDepositInput :=
  { canonicalSourceInput with publicKeysBatchLength := 48 }

private def counterexampleAllocModule : LidoSRv3.Audit.AllocCapacity.Module :=
  { moduleId := 1, shareLimit := 10000, isActive := true, isType2 := false,
    depositableCount := 100, depositedCount := 10,
    summaryExitedCount := 0, accountingExitedCount := 0, totalModuleStake := 0 }

open _root_.LidoSRv3.Audit.AllocCapacity in
open _root_.LidoSRv3.Audit.MinFirstAllocation in
/-- A universally claimed bridge from the executable ALLOC premises to
`LinksSource` is false even when the P-ALLOC-1 checked-bounds
(`CheckedBounds`) and P-ALLOC-2 row-correspondence, candidate-selection,
free-space, and checked-amount premises all hold, and even when the ALLOC
outputs are tied to the transaction inputs by cross-plane composition
premises: (1) `depositsToAllocate.val = first.keys + second.keys` and
(2) `source` capacities equal `MathView.capacities`.

The proof exhibits `allocCfg = ⟨32, 64⟩` with one active module
(`shareLimit = 10000, depositableCount = 100, depositedCount = 10`),
`depositsToAllocate = 5` (matching the executable's `2 + 3` keys), and
a one-row min-first witness `[⟨0, 15⟩]` whose capacity `15` equals
`MathView.capacities` for that module.  `bridgeCounterexampleSourceInput`
with `publicKeysBatchLength = 48` has `actualDepositsCount = 1 ≠ 5`,
so `LinksSource.keys` fails.  The gap is exactly the
`depositsToAllocate ≠ actualDepositsCount` inequality that no ALLOC
premise bridges. -/
theorem alloc_derived_linkssource_kill_line_refutes_bridge :
    ¬ (∀ (cfg : SourceDepositConfig) (inp : SourceDepositInput)
        (txInputs : Inputs) (entry : ContractState)
        (allocCfg : Config) (modules : List Module)
        (depositsToAllocate : _root_.Verity.Core.Uint256) (isTopUp : Bool)
        (model : List Model.Bucket) (source : List Source.Row)
        (best : Source.Row) (allocationSize w : Source.Word),
          Preconditions txInputs entry →
          CheckedBounds allocCfg modules depositsToAllocate isTopUp →
          RowsCorrespond model source →
          Source.candidate? source = some best →
          Source.hasFreeSpace best = true →
          source.length < _root_.Verity.Core.Uint256.modulus →
          allocationSize.val ≠ 0 →
          Source.checkedAmount source allocationSize best = some w →
          depositsToAllocate.val =
            txInputs.first.keys.val + txInputs.second.keys.val →
          source.map (fun r => r.capacity.val) =
            MathView.capacities allocCfg modules depositsToAllocate isTopUp →
          LinksSource cfg inp txInputs) := by
  intro derivedBridge
  have hLink := derivedBridge canonicalSourceConfig bridgeCounterexampleSourceInput
    canonicalInputs canonicalState
    ⟨32, 64⟩ [counterexampleAllocModule] 5 false
    [⟨0, 15⟩] [⟨0, 15⟩] ⟨0, 15⟩ 5 5
    canonical_preconditions
    ⟨by decide, by decide, by decide, by decide, by decide⟩
    (List.Forall₂.cons ⟨rfl, rfl⟩ List.Forall₂.nil)
    rfl rfl (by decide) (by decide) rfl
    rfl rfl
  exact absurd hLink.keys (by decide)

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

/-! ### Executable-plane sibling evidence (a Verity debit mutant)

`PDeposit1.verity_tx_composes_deposit_conservation_and_rollback` names the
conserved quantity at exactly this `DepositParentTx` granularity: conjunct (a)
is commit-branch-explicit (`∀ keys pulled pushed balanceAfter, run cfg inp =
.committedDeposits keys pulled pushed balanceAfter → pulled = pushed ∧
depositsValue cfg inp = pushedValue cfg inp`), and conjunct (c) transports
that same equality onto `Observables.pulled` / `Observables.pushed` for the
honest `execute` (`(sourceObservables inputs entry).pulled = (run cfg inp).pulled`
and the `.pushed` sibling). `skipped_lido_debit_rejected` above already shows
the mutant's *entire* observation record disagrees with `sourceObservables`;
the theorem below isolates the *conserved quantity itself* -- `pulled ≠
pushed` on the mutant's own `Observables` -- at the identical
`DepositParentTx.Observables` granularity the registered parent composes
over. This is **executable-plane sibling evidence**, not the kill-line for
the registered parent: it removes the conservation-carrying step (the Lido
debit inside `mutantPull`) from the Verity transaction and shows the equality
the honest transaction satisfies fails for the patched one. The registered
abstract parent's predicate lives on `SolidityDeposit.run`, and its kill-line
is
`LidoSRv3.Tests.DepositVectors.dropped_conservation_assert_refutes_commit_conservation`:
the line-996-assert mutant of that source-shaped model commits the skewed
deployment, refuting the parent's exact universally-quantified first
conjunct. Nor is this the same claim as
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
