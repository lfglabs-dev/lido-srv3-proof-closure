import LidoSRv3.Audit.Source.DepositCorrespondence
import Verity.Core
import Verity.EVM.Uint256
import Verity.Macro

/-!
# P-DEPOSIT-1: the conservation/rollback core as an official Verity transaction

`LidoSRv3.Audit.Source.DepositCorrespondence` proves stake conservation and
whole-transaction rollback for the pinned deposit push, but its rollback half is
stated against `LidoSRv3.Audit.TxObservation` -- an abstract record in which
`.reverted` is *defined* to restore the pre-state.  That is `A-ABSTRACT-TX`: a
modelling assumption, not an executed fact.

This module discharges that half against Verity's official
`Verity.Contract.run`.  The three-slot ledger below carries the wei balances the
pinned `assert` at `StakingRouter.sol` line 996 actually compares, and the
entrypoint executes the pull at line 983 (`Lido.sol` line 885), the per-key
`DEPOSIT_SIZE` transfer loop at `BeaconChainDepositor.sol` lines 53--63, and
that final balance assert.

Scope, stated rather than hidden:

* This is the **ETH-conservation and rollback core**, not the whole deposit
  transaction.  Module authorization, the allocation helper, `obtainDepositData`
  and its returned byte arrays, per-validator deposit-data-root construction,
  and the multi-contract call graph all remain OPEN; they are enumerated in
  `LidoSRv3.Audit.Verity.DepositRollback.openComponents`.
* Balances are model-local storage slots, not the EVM `address(this).balance`
  and not the deployed proxy layout.  Verity has no faithful primitive for
  composing four contracts and a value-bearing external call into one reverting
  transaction, so the router/Lido/beacon balances are carried as a single
  contract's storage world.
* Execution here is storage-only.  The module issues no external call, so it
  does not rest on Verity's vacuous `externalCallBind := pure ()`.
* No Yul, EVM, gas, or deployed-layout claim is made.
-/

namespace LidoSRv3.Audit.Verity.DepositLedgerTx

open _root_.Verity
open _root_.Verity.Stdlib.Math
open LidoSRv3.Audit.SolidityDeposit

abbrev Word := _root_.Verity.Core.Uint256

/-- The wei ledger the pinned line 996 `assert` observes. -/
structure Ledger where
  routerBalance : Word
  lidoDepositable : Word
  beaconDeposited : Word
  depositsCounter : Word
  deriving DecidableEq, Repr

/-! ## The audited transaction

Slots are model-local.  `depositsCounter` stands for the committed
reentrancy-guard/seed write at `StakingRouter.sol` line 976, which happens
*before* the zero-key early return at line 978 -- so that branch is a commit,
not a rollback, exactly as `SolidityDeposit.committedNoDeposits` records.
-/
verity_contract DepositLedgerContract where
  storage
    routerBalance : Uint256 := slot 0
    lidoDepositable : Uint256 := slot 1
    beaconDeposited : Uint256 := slot 2
    depositsCounter : Uint256 := slot 3

  function no_external_calls pushDeposits (keys : Uint256, maxEBType1 : Uint256,
      depositSize : Uint256) : Uint256 := do
    -- `StakingRouter.sol` line 976: committed before the line 978 early return.
    let counter ← getStorage depositsCounter
    let nextCounter ← requireSomeUint (safeAdd counter 1) "COUNTER_OVERFLOW"
    setStorage depositsCounter nextCounter

    -- Wei pulled from Lido on this branch; stays 0 on the line 978 early return,
    -- which commits the counter write above and moves no ether.
    let mut pulledValue := 0
    if 0 < keys then
      -- `etherBalanceBeforeDeposits = address(this).balance`, line 980.
      let balanceBefore ← getStorage routerBalance

      -- `depositsValue = actualDepositsCount * MAX_EFFECTIVE_BALANCE_WC_TYPE_01`,
      -- line 972; pulled from Lido at line 983 / `Lido.sol` line 885.
      let pulled ← requireSomeUint (safeMul keys maxEBType1) "DEPOSITS_VALUE_OVERFLOW"
      let depositable ← getStorage lidoDepositable
      require (pulled ≤ depositable) "NOT_ENOUGH_ETHER"
      let nextDepositable ← requireSomeUint (safeSub depositable pulled) "LIDO_UNDERFLOW"
      let funded ← requireSomeUint (safeAdd balanceBefore pulled) "ROUTER_BALANCE_OVERFLOW"
      setStorage lidoDepositable nextDepositable
      setStorage routerBalance funded
      pulledValue := pulled

      -- `BeaconChainDepositor.sol` lines 53--63 send one `DEPOSIT_SIZE` per key.
      -- That per-key accumulation shape is a SOURCE-plane fact, discharged by
      -- `SolidityDeposit.loopPushed_eq : loopPushed cfg n = n * cfg.depositSize`.
      -- The transaction executes the equal closed form deliberately; see
      -- `forEach_wrapper_unrolls_once` below for why the loop form is unusable
      -- on this plane.
      let pushed ← requireSomeUint (safeMul keys depositSize) "PUSHED_VALUE_OVERFLOW"
      let spent ← requireSomeUint (safeSub funded pushed) "INSUFFICIENT_ROUTER_BALANCE"
      let deposited ← getStorage beaconDeposited
      let nextDeposited ← requireSomeUint (safeAdd deposited pushed) "BEACON_OVERFLOW"
      setStorage routerBalance spent
      setStorage beaconDeposited nextDeposited

      -- `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)`,
      -- lines 993--996.  A failing Solidity 0.8 `assert` is a `Panic(0x01)`
      -- that aborts the whole transaction.
      let balanceAfter ← getStorage routerBalance
      require (balanceAfter == balanceBefore) "ASSERT_BALANCE_UNCHANGED"
    else
      pulledValue := pulledValue
    return pulledValue

def decode (s : ContractState) : Ledger :=
  { routerBalance := s.storage DepositLedgerContract.routerBalance.slot
    lidoDepositable := s.storage DepositLedgerContract.lidoDepositable.slot
    beaconDeposited := s.storage DepositLedgerContract.beaconDeposited.slot
    depositsCounter := s.storage DepositLedgerContract.depositsCounter.slot }

/-! ## Why the transfer loop is executed in closed form

The pinned Verity macro's executable `Contract.run` wrapper rewrites a `forEach`
body **once**, with the loop variable fixed to zero; it is not the
compilation-model loop semantics.  `MinFirstCorrespondence` records the same
limitation for its candidate scans.

This is not a footnote here: a per-key transfer loop would pull
`keys * MAX_EFFECTIVE_BALANCE_WC_TYPE_01` but push only a single `DEPOSIT_SIZE`,
so every `keys > 1` run would fail the line 996 balance assert.  Publishing
conservation receipts on top of that would report a wrapper artefact as a
property of the deposit path.  The probe below pins the wrapper behaviour so the
decision stays checked rather than asserted.
-/
verity_contract ForEachProbeContract where
  storage
    ticks : Uint256 := slot 0

  function no_external_calls bump (n : Uint256) : Unit := do
    forEach "i" n (do
      let current ← getStorage ticks
      let next ← requireSomeUint (safeAdd current 1) "TICK_OVERFLOW"
      setStorage ticks next)

/-- Five requested iterations leave one tick behind: the executable wrapper
unrolls the body once.  The per-key loop shape therefore stays a SOURCE-plane
fact (`SolidityDeposit.loopPushed_eq`) and is not claimed on this plane. -/
theorem forEach_wrapper_unrolls_once :
    (match (ForEachProbeContract.bump 5).run defaultState with
     | .success _ after => (after.storage ForEachProbeContract.ticks.slot).val
     | .revert _ _ => 0) = 1 := by decide

/-! ## Rollback, as an executed fact rather than `A-ABSTRACT-TX`

`SolidityDeposit.reverting_outcome_rolls_back` establishes rollback inside
`LidoSRv3.Audit.TxObservation`, where `Result.stateAfter` *returns* the
pre-state on `.revert` by definition.  The theorem below is the same claim about
the official `Verity.Contract.run`: whatever the body did to storage -- the
counter write, the pull, any prefix of the transfer loop -- a reverting outcome
hands back the entry state itself.
-/
theorem verity_revert_rolls_back
    (state : ContractState) (keys maxEBType1 depositSize : Word)
    (reason : String) (rollback : ContractState)
    (h : (DepositLedgerContract.pushDeposits keys maxEBType1 depositSize).run state
      = .revert reason rollback) :
    rollback = state := by
  unfold Contract.run at h
  cases hc : DepositLedgerContract.pushDeposits keys maxEBType1 depositSize state <;>
    simp [hc] at h
  exact h.2.symm

/-- The ledger view of a reverting run is therefore unchanged in every field:
no wei left Lido, none reached the beacon contract, and the line 976 counter
write is undone too. -/
theorem verity_revert_moves_no_ether
    (state : ContractState) (keys maxEBType1 depositSize : Word)
    (reason : String) (rollback : ContractState)
    (h : (DepositLedgerContract.pushDeposits keys maxEBType1 depositSize).run state
      = .revert reason rollback) :
    decode rollback = decode state := by
  rw [verity_revert_rolls_back state keys maxEBType1 depositSize reason rollback h]

/-! ## Branch-wise correspondence with the pinned source outcome

The observation below records exactly the two quantities the guarantee talks
about -- wei pulled from Lido, wei pushed to the beacon deposit contract -- plus
whether the router retained anything, which is what the line 996 `assert`
tests.
-/

inductive TxStatus where
  | committed | reverted
  deriving DecidableEq, Repr

structure LedgerObservation where
  status : TxStatus
  pulledFromLido : Nat
  pushedToBeacon : Nat
  routerRetainsNothing : Bool
  deriving DecidableEq, Repr

def ledgerView (before after : ContractState) (status : TxStatus) : LedgerObservation :=
  { status := status
    pulledFromLido :=
      (decode before).lidoDepositable.val - (decode after).lidoDepositable.val
    pushedToBeacon :=
      (decode after).beaconDeposited.val - (decode before).beaconDeposited.val
    routerRetainsNothing :=
      (decode after).routerBalance == (decode before).routerBalance }

def observeVerity (before : ContractState) (result : ContractResult Word) : LedgerObservation :=
  match result with
  | .revert _ rollback => ledgerView before rollback .reverted
  | .success _ after => ledgerView before after .committed

/-- The same observation read off the independent pinned-source interpreter.
`SolidityDeposit.committed_balance_preserved` and
`SolidityDeposit.reverting_moves_no_ether` are why the router retains nothing on
every branch. -/
def observeSource (outcome : SolidityDeposit.Outcome) : LedgerObservation :=
  { status := if outcome.reverts then .reverted else .committed
    pulledFromLido := outcome.pulled
    pushedToBeacon := outcome.pushed
    routerRetainsNothing := true }

def ledgerState (routerBalance lidoDepositable : Nat) : ContractState :=
  (defaultState.writeSlot DepositLedgerContract.routerBalance.slot
    (routerBalance : Word)).writeSlot
      DepositLedgerContract.lidoDepositable.slot (lidoDepositable : Word)

/-- A conserving deployment: `MAX_EFFECTIVE_BALANCE_WC_TYPE_01 = DEPOSIT_SIZE`. -/
def conservingConfig : SolidityDeposit.SourceDepositConfig :=
  { maxEBType1 := 32, depositSize := 32, pubkeyLength := 48
    publicKeyLength := 48, signatureLength := 96 }

/-- The same deployment with the router's immutable set apart from the deposit
contract's fixed size -- the falsifier `source_nonconserving_deployment_reverts`
talks about. -/
def nonConservingConfig : SolidityDeposit.SourceDepositConfig :=
  { conservingConfig with maxEBType1 := 64 }

def depositInput (keys : Nat) : SolidityDeposit.SourceDepositInput :=
  { moduleActive := true, maxDepositsPerBlock := 10, moduleDepositableEth := 1000
    publicKeysBatchLength := 48 * keys, signaturesBatchLength := 96 * keys
    routerBalanceBefore := 0, lidoCanDeposit := true, lidoDepositableEther := 1000 }

/-! Named receipts, so the guarantee-level theorem can consume them by name. -/

def verityCommittingPushObservation : LedgerObservation :=
  observeVerity (ledgerState 0 1000)
    ((DepositLedgerContract.pushDeposits 3 32 32).run (ledgerState 0 1000))

def sourceCommittingPushObservation : LedgerObservation :=
  observeSource (SolidityDeposit.run conservingConfig (depositInput 3))

def verityEmptyBatchObservation : LedgerObservation :=
  observeVerity (ledgerState 0 1000)
    ((DepositLedgerContract.pushDeposits 0 32 32).run (ledgerState 0 1000))

def sourceEmptyBatchObservation : LedgerObservation :=
  observeSource (SolidityDeposit.run conservingConfig (depositInput 0))

def verityNonConservingObservation : LedgerObservation :=
  observeVerity (ledgerState 0 1000)
    ((DepositLedgerContract.pushDeposits 1 64 32).run (ledgerState 0 1000))

def sourceNonConservingObservation : LedgerObservation :=
  observeSource (SolidityDeposit.run nonConservingConfig (depositInput 1))

/-- Committing push, three keys: the transaction pulls 96 wei from Lido, pushes
all 96 to the beacon deposit contract, and the router keeps none -- matching the
pinned source branch `committedDeposits`. -/
theorem verity_tx_matches_source_committing_push :
    verityCommittingPushObservation = sourceCommittingPushObservation := by
  decide

/-- Zero-key batch: the pinned early return at line 978 is a commit that moves
no ether, and the executed transaction agrees. -/
theorem verity_tx_matches_source_empty_batch :
    verityEmptyBatchObservation = sourceEmptyBatchObservation := by
  decide

/-- Misconfigured deployment: the source reverts at the line 996 `assert`, and so
does the executed transaction.  The difference is not stranded in the router. -/
theorem verity_tx_matches_source_nonconserving_deployment :
    verityNonConservingObservation = sourceNonConservingObservation := by
  decide

/-! ## Mutation sensitivity

Without these the receipts above could hold for a transaction that never
enforced anything.  Each mutant changes one audited decision and is observed to
change the result for its own reason.
-/
verity_contract DepositLedgerMutants where
  storage
    routerBalance : Uint256 := slot 0
    lidoDepositable : Uint256 := slot 1
    beaconDeposited : Uint256 := slot 2
    depositsCounter : Uint256 := slot 3

  -- Mutant A: drops the line 996 balance assert.
  function no_external_calls pushWithoutAssert (keys : Uint256, maxEBType1 : Uint256,
      depositSize : Uint256) : Uint256 := do
    let counter ← getStorage depositsCounter
    let nextCounter ← requireSomeUint (safeAdd counter 1) "COUNTER_OVERFLOW"
    setStorage depositsCounter nextCounter
    let mut pulledValue := 0
    if 0 < keys then
      let balanceBefore ← getStorage routerBalance
      let pulled ← requireSomeUint (safeMul keys maxEBType1) "DEPOSITS_VALUE_OVERFLOW"
      let depositable ← getStorage lidoDepositable
      require (pulled ≤ depositable) "NOT_ENOUGH_ETHER"
      let nextDepositable ← requireSomeUint (safeSub depositable pulled) "LIDO_UNDERFLOW"
      let funded ← requireSomeUint (safeAdd balanceBefore pulled) "ROUTER_BALANCE_OVERFLOW"
      setStorage lidoDepositable nextDepositable
      setStorage routerBalance funded
      pulledValue := pulled
      let pushed ← requireSomeUint (safeMul keys depositSize) "PUSHED_VALUE_OVERFLOW"
      let spent ← requireSomeUint (safeSub funded pushed) "INSUFFICIENT_ROUTER_BALANCE"
      let deposited ← getStorage beaconDeposited
      let nextDeposited ← requireSomeUint (safeAdd deposited pushed) "BEACON_OVERFLOW"
      setStorage routerBalance spent
      setStorage beaconDeposited nextDeposited
    else
      pulledValue := pulledValue
    return pulledValue

  -- Mutant B: credits the beacon contract without debiting Lido.
  function no_external_calls pushWithoutLidoDebit (keys : Uint256, maxEBType1 : Uint256,
      depositSize : Uint256) : Uint256 := do
    let counter ← getStorage depositsCounter
    let nextCounter ← requireSomeUint (safeAdd counter 1) "COUNTER_OVERFLOW"
    setStorage depositsCounter nextCounter
    let mut pulledValue := 0
    if 0 < keys then
      let balanceBefore ← getStorage routerBalance
      let pulled ← requireSomeUint (safeMul keys maxEBType1) "DEPOSITS_VALUE_OVERFLOW"
      let depositable ← getStorage lidoDepositable
      require (pulled ≤ depositable) "NOT_ENOUGH_ETHER"
      let funded ← requireSomeUint (safeAdd balanceBefore pulled) "ROUTER_BALANCE_OVERFLOW"
      setStorage routerBalance funded
      pulledValue := pulled
      let pushed ← requireSomeUint (safeMul keys depositSize) "PUSHED_VALUE_OVERFLOW"
      let spent ← requireSomeUint (safeSub funded pushed) "INSUFFICIENT_ROUTER_BALANCE"
      let deposited ← getStorage beaconDeposited
      let nextDeposited ← requireSomeUint (safeAdd deposited pushed) "BEACON_OVERFLOW"
      setStorage routerBalance spent
      setStorage beaconDeposited nextDeposited
      let balanceAfter ← getStorage routerBalance
      require (balanceAfter == balanceBefore) "ASSERT_BALANCE_UNCHANGED"
    else
      pulledValue := pulledValue
    return pulledValue

def droppedAssertObservation : LedgerObservation :=
  observeVerity (ledgerState 0 1000)
    ((DepositLedgerMutants.pushWithoutAssert 1 64 32).run (ledgerState 0 1000))

def skippedLidoDebitObservation : LedgerObservation :=
  observeVerity (ledgerState 0 1000)
    ((DepositLedgerMutants.pushWithoutLidoDebit 3 32 32).run (ledgerState 0 1000))

/-- Dropping the line 996 assert lets the misconfigured deployment commit and
strand 32 wei in the router, instead of reverting.  So
`verity_tx_matches_source_nonconserving_deployment` is enforced by that assert
and not true by accident. -/
theorem dropped_assert_commits_nonconserving_deployment :
    droppedAssertObservation ≠ sourceNonConservingObservation := by
  decide

/-- Skipping the Lido debit reports a push with no matching pull, so the
committing receipt genuinely observes conservation rather than only the push. -/
theorem skipped_lido_debit_breaks_conservation :
    skippedLidoDebitObservation ≠ sourceCommittingPushObservation := by
  decide

end LidoSRv3.Audit.Verity.DepositLedgerTx
