import LidoSRv3.Audit.Source.DepositCorrespondence
import Contracts.Common

/-!
# P-DEPOSIT-1 composed executable transaction

This module is the faithful bounded two-batch transaction slice for the pinned
`StakingRouter.deposit` path.  Unlike `DepositLedgerTx`, authorization,
allocation, dynamic deposit data, deposit-data roots, the Lido pull, and the
two beacon value calls execute in one `Verity.Contract.run` program.  Storage
uses `writeSlot`/`writeMapUint`; calls carry concrete targets and values through
`externalCallBindTo`.

The correspondence observation deliberately excludes the complete post-state.
It contains only the guarantee observables: commit/revert, Lido debit, beacon
value, router retention, and the ordered call journal.
-/

namespace LidoSRv3.Audit.Verity.DepositParentTx

open _root_.Verity
open _root_.Contracts

abbrev Word := _root_.Verity.Core.Uint256

def counterSlot : Nat := 0
def lidoDepositableSlot : Nat := 1
def allocationSlot : Nat := 2
def dynamicDataSlot : Nat := 3
def depositRootSlot : Nat := 4

structure Batch where
  moduleId : Word
  keys : Word
  amount : Word
  dynamicDataCommitment : Word
  depositDataRoot : Word
  dataValid : Bool
  rootValid : Bool
  moduleCallOk : Bool
  beaconCallOk : Bool
  deriving Repr, DecidableEq

structure Inputs where
  authorized : Bool
  moduleActive : Bool
  allocationValid : Bool
  lidoCallOk : Bool
  lido : Address
  module : Address
  beacon : Address
  first : Batch
  second : Batch
  deriving Repr, DecidableEq

def callName (ok : Bool) (name : String) : String := if ok then name else "fail"

def writeMap (slotId : Nat) (key value : Word) : Contract Unit :=
  fun state => .success () (state.writeMapUint slotId key value)

def getState : Contract ContractState :=
  fun state => .success state state

def creditRouter (amount : Word) : Contract Unit :=
  fun state => .success () { state with selfBalance := state.selfBalance + amount }

def processBatch (inputs : Inputs) (batch : Batch) : Contract Unit := do
  writeMap allocationSlot batch.moduleId batch.keys
  externalCallBindTo inputs.module 0 [] (callName batch.moduleCallOk "obtainDepositData")
    [batch.moduleId, batch.keys]
  writeMap dynamicDataSlot batch.moduleId batch.dynamicDataCommitment
  require batch.dataValid "INVALID_DYNAMIC_DEPOSIT_DATA"
  writeMap depositRootSlot batch.moduleId batch.depositDataRoot
  require batch.rootValid "INVALID_DEPOSIT_DATA_ROOT"

def pullFromLido (inputs : Inputs) (total : Word) : Contract Unit := do
  externalCallBindTo inputs.lido 0 [] (callName inputs.lidoCallOk "withdrawDepositableEther")
    [total]
  let state ← getState
  require (total ≤ state.readSlot lidoDepositableSlot) "NOT_ENOUGH_ETHER"
  setStorage ⟨lidoDepositableSlot⟩ (state.readSlot lidoDepositableSlot - total)
  creditRouter total

def pushBatch (inputs : Inputs) (batch : Batch) : Contract Unit :=
  externalCallBindTo inputs.beacon batch.amount []
    (callName batch.beaconCallOk "depositToBeacon")
    [batch.moduleId, batch.keys, batch.dynamicDataCommitment, batch.depositDataRoot]

/-- The complete bounded transaction.  The counter/allocation/data/root writes
precede several possible failures, making rollback sensitivity executable. -/
def execute (inputs : Inputs) : Contract Unit := do
  require inputs.authorized "NOT_AUTHORIZED"
  require inputs.moduleActive "MODULE_NOT_ACTIVE"
  require inputs.allocationValid "INVALID_ALLOCATION"
  let state ← getState
  setStorage ⟨counterSlot⟩ (state.readSlot counterSlot + 1)
  processBatch inputs inputs.first
  processBatch inputs inputs.second
  let total := inputs.first.amount + inputs.second.amount
  require (total == (inputs.first.keys + inputs.second.keys) * 32)
    "ALLOCATION_VALUE_MISMATCH"
  pullFromLido inputs total
  pushBatch inputs inputs.first
  pushBatch inputs inputs.second
  let after ← getState
  require (after.selfBalance == state.selfBalance) "ASSERT_BALANCE_UNCHANGED"

inductive Status where | committed | reverted
  deriving Repr, DecidableEq

structure Observables where
  status : Status
  pulledFromLido : Nat
  pushedToBeacon : Nat
  routerRetainsNothing : Bool
  calls : List ExternalCall
  deriving Repr, DecidableEq

def observe (before : ContractState) : ContractResult Unit → Observables
  | .revert _ rollback =>
      { status := .reverted
        pulledFromLido := (before.readSlot lidoDepositableSlot).val -
          (rollback.readSlot lidoDepositableSlot).val
        pushedToBeacon := (rollback.calls.drop before.calls.length).foldl
          (fun n call => n + if call.target = 0 then 0 else call.value) 0
        routerRetainsNothing := rollback.selfBalance == before.selfBalance
        calls := rollback.calls.drop before.calls.length }
  | .success _ after =>
      { status := .committed
        pulledFromLido := (before.readSlot lidoDepositableSlot).val -
          (after.readSlot lidoDepositableSlot).val
        pushedToBeacon := (after.calls.drop before.calls.length).foldl
          (fun n call => n + call.value) 0
        routerRetainsNothing := after.selfBalance == before.selfBalance
        calls := after.calls.drop before.calls.length }

/-! A source-shaped observer independent of `execute`.  It constructs the
successful pinned call order and the exact conservation quantities; reverting
transactions expose no committed calls or value movement. -/
def successfulCalls (inputs : Inputs) : List ExternalCall :=
  [ linkedCallEntryTo "obtainDepositData" inputs.module 0
      [inputs.first.moduleId, inputs.first.keys]
  , linkedCallEntryTo "obtainDepositData" inputs.module 0
      [inputs.second.moduleId, inputs.second.keys]
  , linkedCallEntryTo "withdrawDepositableEther" inputs.lido 0
      [inputs.first.amount + inputs.second.amount]
  , linkedCallEntryTo "depositToBeacon" inputs.beacon inputs.first.amount
      [inputs.first.moduleId, inputs.first.keys, inputs.first.dynamicDataCommitment,
        inputs.first.depositDataRoot]
  , linkedCallEntryTo "depositToBeacon" inputs.beacon inputs.second.amount
      [inputs.second.moduleId, inputs.second.keys, inputs.second.dynamicDataCommitment,
        inputs.second.depositDataRoot]
  ]

def sourceSuccessView (inputs : Inputs) : Observables :=
  { status := .committed
    pulledFromLido := (inputs.first.amount + inputs.second.amount).val
    pushedToBeacon := inputs.first.amount.val + inputs.second.amount.val
    routerRetainsNothing := true
    calls := successfulCalls inputs }

def sourceRevertView : Observables :=
  { status := .reverted, pulledFromLido := 0, pushedToBeacon := 0
    routerRetainsNothing := true, calls := [] }

def batchA : Batch :=
  { moduleId := 7, keys := 2, amount := 64, dynamicDataCommitment := 0xa1
    depositDataRoot := 0xd1, dataValid := true, rootValid := true
    moduleCallOk := true, beaconCallOk := true }

def batchB : Batch :=
  { moduleId := 9, keys := 3, amount := 96, dynamicDataCommitment := 0xa2
    depositDataRoot := 0xd2, dataValid := true, rootValid := true
    moduleCallOk := true, beaconCallOk := true }

def canonicalInputs : Inputs :=
  { authorized := true, moduleActive := true, allocationValid := true,
    lidoCallOk := true, lido := 101, module := 202, beacon := 303,
    first := batchA, second := batchB }

def canonicalState : ContractState :=
  (defaultState.writeSlot lidoDepositableSlot 1000).writeSlot counterSlot 41

/-- Executable two-batch source correspondence.  The run computes allocation,
dynamic data/root storage and the ordered Lido/router/beacon observables in the
same transaction. -/
theorem verity_tx_matches_pinned_source_two_batch :
    observe canonicalState ((execute canonicalInputs).run canonicalState) =
      sourceSuccessView canonicalInputs := by decide

/-- All reverting runs restore the complete Verity snapshot, including writes
performed before dynamic-data, root, Lido, or beacon failures. -/
theorem revert_after_intermediate_writes_restores_snapshot
    (inputs : Inputs) (state rollback : ContractState) (reason : String)
    (h : (execute inputs).run state = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  cases hx : execute inputs state <;> simp [hx] at h
  exact h.2.symm

def badSecondRootInputs : Inputs :=
  { canonicalInputs with second := { batchB with rootValid := false } }

theorem second_batch_root_failure_rolls_back_first_batch :
    observe canonicalState ((execute badSecondRootInputs).run canonicalState) =
      sourceRevertView := by decide

/-! ## Fail-closed chaining mutants -/

/-- Mutant: the second batch aliases the first batch's root instead of carrying
its own root through the chained flow. -/
def aliasedSecondRootInputs : Inputs :=
  { canonicalInputs with second := { batchB with depositDataRoot := batchA.depositDataRoot } }

/-- Mutant: the second batch is dropped from allocation/value chaining. -/
def droppedSecondBatchInputs : Inputs :=
  { canonicalInputs with second := { batchB with keys := 0, amount := 0 } }

theorem aliased_second_root_rejected :
    observe canonicalState ((execute aliasedSecondRootInputs).run canonicalState) ≠
      sourceSuccessView canonicalInputs := by decide

theorem dropped_second_batch_rejected :
    observe canonicalState ((execute droppedSecondBatchInputs).run canonicalState) ≠
      sourceSuccessView canonicalInputs := by decide

end LidoSRv3.Audit.Verity.DepositParentTx
