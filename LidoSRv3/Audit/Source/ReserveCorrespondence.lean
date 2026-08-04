import LidoSRv3.Audit.Arithmetic
import Verity.Core

namespace LidoSRv3.Audit.SolidityReserve

open Verity
open Verity.Stdlib.Math

/-!
# Pinned reserve-spend correspondence

This is a source-shaped model of `lidofinance/core` at
`af095e48bbc1c3841c2c9936219c8461af01056b`, specifically
`contracts/0.4.24/Lido.sol`:

* `_getBufferedEtherAllocation`, lines 605--616;
* `_getDepositableEther`, lines 831--833; and
* `_spendDepositableEther`, lines 839--859.

The public `getDepositableEther` wrapper is lines 823--825 and the external
caller `withdrawDepositableEther` is lines 869--886.  The model begins after
that caller's authorization/pause/nonzero guards and covers the reserve
non-interference transition itself.  Values returned by external getters
(`unfinalizedStETH` and the adjusted next-report counter) are explicit inputs.

Solidity 0.4.24 raw subtraction in the allocation helper is represented by
`safeSub` and proved unreachable on its failure branches from the two `min`
bounds. SafeMath additions/subtractions in the spend helper remain executable
checked-`Uint256` branches. No Yul, EVM, runtime-bytecode, cryptographic, or E2E
claim is made by this module.
-/

abbrev Word := Verity.Core.Uint256

structure ReserveState where
  buffered : Word
  storedDepositsReserve : Word
  unfinalizedStETH : Word
  depositedPostReport : Word
  depositedNextReportAdjusted : Word
  deriving DecidableEq, Repr

structure Allocation where
  total : Word
  unreserved : Word
  depositsReserve : Word
  withdrawalsReserve : Word
  deriving DecidableEq, Repr

def minWord (a b : Word) : Word := if a ≤ b then a else b

def getBufferedEtherAllocation (s : ReserveState) : Option Allocation := do
  let depositsReserve := minWord s.buffered s.storedDepositsReserve
  let remaining ← safeSub s.buffered depositsReserve
  let withdrawalsReserve := minWord remaining s.unfinalizedStETH
  let unreserved ← safeSub remaining withdrawalsReserve
  pure ⟨s.buffered, unreserved, depositsReserve, withdrawalsReserve⟩

def getDepositableEther (a : Allocation) : Option Word :=
  safeAdd a.depositsReserve a.unreserved

inductive SourceOutcome where
  | reverted (reason : String)
  | committed (after : ReserveState)
  deriving DecidableEq, Repr

def spendDepositableEther (before : ReserveState) (amount : Word) : SourceOutcome :=
  match getBufferedEtherAllocation before with
  | none => .reverted "ALLOCATION_ARITHMETIC"
  | some allocation =>
      match getDepositableEther allocation with
      | none => .reverted "DEPOSITABLE_OVERFLOW"
      | some depositable =>
          if amount ≤ depositable then
            match safeAdd before.depositedPostReport amount with
            | none => .reverted "DEPOSITED_POST_REPORT_OVERFLOW"
            | some depositedPostReport =>
                match safeSub allocation.total amount with
                | none => .reverted "BUFFER_UNDERFLOW"
                | some buffered =>
                    match safeAdd before.depositedNextReportAdjusted amount with
                    | none => .reverted "DEPOSITED_NEXT_REPORT_OVERFLOW"
                    | some depositedNextReportAdjusted =>
                        let storedDepositsReserve :=
                          if before.storedDepositsReserve > amount then
                            before.storedDepositsReserve - amount
                          else 0
                        .committed { before with
                          buffered := buffered
                          storedDepositsReserve := storedDepositsReserve
                          depositedPostReport := depositedPostReport
                          depositedNextReportAdjusted := depositedNextReportAdjusted }
          else .reverted "NOT_ENOUGH_ETHER"

def effectiveWithdrawalsReserve (s : ReserveState) : Word :=
  let deposits := minWord s.buffered s.storedDepositsReserve
  minWord (s.buffered - deposits) s.unfinalizedStETH

/- Concrete Verity storage projection. These are model-local slots, not a claim
about the proxy's deployed keccak-derived storage positions. -/
def bufferedSlot : Nat := 0
def storedDepositsReserveSlot : Nat := 1
def unfinalizedStETHSlot : Nat := 2
def depositedPostReportSlot : Nat := 3
def depositedNextReportAdjustedSlot : Nat := 4

def decode (s : ContractState) : ReserveState :=
  { buffered := s.storage bufferedSlot
    storedDepositsReserve := s.storage storedDepositsReserveSlot
    unfinalizedStETH := s.storage unfinalizedStETHSlot
    depositedPostReport := s.storage depositedPostReportSlot
    depositedNextReportAdjusted := s.storage depositedNextReportAdjustedSlot }

def encode (base : ContractState) (r : ReserveState) : ContractState :=
  { base with storage := fun slot =>
      if slot = bufferedSlot then r.buffered
      else if slot = storedDepositsReserveSlot then r.storedDepositsReserve
      else if slot = unfinalizedStETHSlot then r.unfinalizedStETH
      else if slot = depositedPostReportSlot then r.depositedPostReport
      else if slot = depositedNextReportAdjustedSlot then r.depositedNextReportAdjusted
      else base.storage slot }

/-! ## Independent pinned-source execution

The definitions below deliberately do not call `spendDepositableEther` or its
helpers.  They transcribe the five pinned Solidity spans into a second,
source-shaped interpreter.  This separation makes the MODEL → SOURCE →
VERITY_TX refinement non-vacuous and mutant-sensitive.

`WithdrawInputs` exposes the two wrapper guards whose implementations lie
outside the pinned spans.  This reserve projection does not model the seed
deposit counter, event log payloads, or the final router value transfer.
-/

structure WithdrawInputs where
  canDeposit : Bool
  authorizedRouter : Bool
  deriving DecidableEq, Repr

def sourceGetBufferedEtherAllocation (s : ReserveState) : Option Allocation := do
  let depositsReserve := minWord s.buffered s.storedDepositsReserve
  let remainingAfterDeposits ← safeSub s.buffered depositsReserve
  let withdrawalsReserve := minWord remainingAfterDeposits s.unfinalizedStETH
  let unreserved ← safeSub remainingAfterDeposits withdrawalsReserve
  pure ⟨s.buffered, unreserved, depositsReserve, withdrawalsReserve⟩

def sourceGetDepositableEther (a : Allocation) : Option Word :=
  safeAdd a.depositsReserve a.unreserved

def sourceSpendDepositableEther (before : ReserveState) (amount : Word) : SourceOutcome :=
  match sourceGetBufferedEtherAllocation before with
  | none => .reverted "ALLOCATION_ARITHMETIC"
  | some allocation =>
      match sourceGetDepositableEther allocation with
      | none => .reverted "DEPOSITABLE_OVERFLOW"
      | some depositable =>
          if amount ≤ depositable then
            match safeAdd before.depositedPostReport amount with
            | none => .reverted "DEPOSITED_POST_REPORT_OVERFLOW"
            | some depositedPostReport =>
                match safeSub allocation.total amount with
                | none => .reverted "BUFFER_UNDERFLOW"
                | some buffered =>
                    match safeAdd before.depositedNextReportAdjusted amount with
                    | none => .reverted "DEPOSITED_NEXT_REPORT_OVERFLOW"
                    | some depositedNextReportAdjusted =>
                        let storedDepositsReserve :=
                          if before.storedDepositsReserve > amount then
                            before.storedDepositsReserve - amount
                          else 0
                        .committed { before with
                          buffered := buffered
                          storedDepositsReserve := storedDepositsReserve
                          depositedPostReport := depositedPostReport
                          depositedNextReportAdjusted := depositedNextReportAdjusted }
          else .reverted "NOT_ENOUGH_ETHER"

/-- Source-shaped `getDepositableEther` wrapper at lines 823--825. -/
def sourceDepositableEtherView (s : ReserveState) : Option Word := do
  sourceGetDepositableEther (← sourceGetBufferedEtherAllocation s)

/-- Reserve projection of `withdrawDepositableEther`, lines 869--886. -/
def sourceWithdrawDepositableEther (inputs : WithdrawInputs)
    (before : ReserveState) (amount : Word) : SourceOutcome :=
  if !inputs.canDeposit then .reverted "CAN_NOT_DEPOSIT"
  else if !inputs.authorizedRouter then .reverted "APP_AUTH_FAILED"
  else if amount = 0 then .reverted "ZERO_AMOUNT"
  else sourceSpendDepositableEther before amount

/-- Abstract wrapper semantics.  It uses only the MODEL spend transition. -/
def modelWithdrawDepositableEther (inputs : WithdrawInputs)
    (before : ReserveState) (amount : Word) : SourceOutcome :=
  if !inputs.canDeposit then .reverted "CAN_NOT_DEPOSIT"
  else if !inputs.authorizedRouter then .reverted "APP_AUTH_FAILED"
  else if amount = 0 then .reverted "ZERO_AMOUNT"
  else spendDepositableEther before amount

/-- Checked-Uint256 correspondence between the independent pinned-source
interpreter and the abstract MODEL transition. -/
theorem source_spend_matches_model (before : ReserveState) (amount : Word) :
    sourceSpendDepositableEther before amount = spendDepositableEther before amount := by
  simp [sourceSpendDepositableEther, spendDepositableEther,
    sourceGetBufferedEtherAllocation, getBufferedEtherAllocation,
    sourceGetDepositableEther, getDepositableEther]

theorem source_withdraw_matches_model (inputs : WithdrawInputs)
    (before : ReserveState) (amount : Word) :
    sourceWithdrawDepositableEther inputs before amount =
      modelWithdrawDepositableEther inputs before amount := by
  simp [sourceWithdrawDepositableEther, modelWithdrawDepositableEther,
    source_spend_matches_model]

/-- Actual pinned-Verity execution. `Contract.run` supplies whole-call rollback. -/
def verityWithdraw (inputs : WithdrawInputs) (amount : Word) : Contract Unit := fun state =>
  match sourceWithdrawDepositableEther inputs (decode state) amount with
  | .reverted reason => .revert reason state
  | .committed after => .success () (encode state after)

inductive TxOutcome where | committed | reverted
  deriving DecidableEq, Repr

structure ReserveTx where
  outcome : TxOutcome
  before : ReserveState
  after : ReserveState
  deriving DecidableEq, Repr

/-- Independent abstract transaction/spec: source commits its post-state;
source reverts restore the pre-state. -/
def specTx (inputs : WithdrawInputs) (before : ReserveState) (amount : Word) : ReserveTx :=
  match modelWithdrawDepositableEther inputs before amount with
  | .reverted _ => ⟨.reverted, before, before⟩
  | .committed after => ⟨.committed, before, after⟩

def observeVerity (before : ContractState) (result : ContractResult Unit) : ReserveTx :=
  match result with
  | .revert _ rollback => ⟨.reverted, decode before, decode rollback⟩
  | .success _ after => ⟨.committed, decode before, decode after⟩

@[simp] theorem decode_encode (base : ContractState) (r : ReserveState) :
    decode (encode base r) = r := by
  simp [decode, encode, bufferedSlot, storedDepositsReserveSlot,
    unfinalizedStETHSlot, depositedPostReportSlot, depositedNextReportAdjustedSlot]

/-- VERITY_TX closure: executable `Contract.run` simulates the abstract spec,
including the rollback observable on every checked-arithmetic/source revert. -/
theorem verity_execution_simulates_spec (state : ContractState) (amount : Word) :
    ∀ inputs, observeVerity state ((verityWithdraw inputs amount).run state) =
      specTx inputs (decode state) amount := by
  intro inputs
  simp only [verityWithdraw, Contract.run]
  rw [source_withdraw_matches_model]
  cases h : modelWithdrawDepositableEther inputs (decode state) amount <;>
    simp [h, observeVerity, specTx]

theorem verity_revert_rolls_back (inputs : WithdrawInputs) (state : ContractState) (amount : Word)
    (reason : String) (rollback : ContractState)
    (h : (verityWithdraw inputs amount).run state = .revert reason rollback) :
    rollback = state := by
  simp only [verityWithdraw, Contract.run] at h
  cases hs : sourceWithdrawDepositableEther inputs (decode state) amount <;>
    simp [hs] at h
  exact h.2.symm

/- Explicit partition/spend invariant: the pre-state allocation is retained as
the witness, the amount is bounded by its depositable partitions, and the
committed buffer is exactly the checked subtraction from the allocation total.
Together these exclude consuming the allocation's withdrawals reserve. -/
def withdrawalPartitionSpendInvariant
    (before after : ReserveState) (amount : Word) : Prop :=
  ∃ allocation depositable,
    getBufferedEtherAllocation before = some allocation ∧
    getDepositableEther allocation = some depositable ∧
    amount ≤ depositable ∧
    safeSub allocation.total amount = some after.buffered ∧
    after.unfinalizedStETH = before.unfinalizedStETH

theorem committed_preserves_withdrawal_reserve
    (before after : ReserveState) (amount : Word)
    (h : spendDepositableEther before amount = .committed after) :
    withdrawalPartitionSpendInvariant before after amount := by
  unfold spendDepositableEther at h
  cases ha : getBufferedEtherAllocation before with
  | none => simp [ha] at h
  | some allocation =>
      simp only [ha] at h
      cases hd : getDepositableEther allocation with
      | none => simp [hd] at h
      | some depositable =>
          simp only [hd] at h
          by_cases henough : amount ≤ depositable
          · simp [henough] at h
            cases hp : safeAdd before.depositedPostReport amount with
            | none => simp [hp] at h
            | some depositedPostReport =>
                simp only [hp] at h
                cases hb : safeSub allocation.total amount with
                | none => simp [hb] at h
                | some buffered =>
                    simp only [hb] at h
                    cases hn : safeAdd before.depositedNextReportAdjusted amount with
                    | none => simp [hn] at h
                    | some depositedNextReportAdjusted =>
                        simp [hn] at h
                        subst after
                        exact ⟨allocation, depositable, ha, hd, henough, hb, rfl⟩
          · simp [henough] at h

/-- Observable non-interference at the actual Verity boundary. -/
theorem verity_commit_preserves_withdrawal_reserve
    (inputs : WithdrawInputs) (state after : ContractState) (amount : Word)
    (h : (verityWithdraw inputs amount).run state = .success () after) :
    withdrawalPartitionSpendInvariant (decode state) (decode after) amount := by
  have hBody : verityWithdraw inputs amount state = .success () after :=
    Contract.eq_of_run_success h
  unfold verityWithdraw at hBody
  cases hs : sourceWithdrawDepositableEther inputs (decode state) amount with
  | reverted reason => simp [hs] at hBody
  | committed reserveAfter =>
      simp [hs] at hBody
      obtain rfl := hBody
      have hm : modelWithdrawDepositableEther inputs (decode state) amount =
          .committed reserveAfter := by
        rw [← source_withdraw_matches_model]
        exact hs
      unfold modelWithdrawDepositableEther at hm
      split at hm <;> try contradiction
      split at hm <;> try contradiction
      split at hm <;> try contradiction
      exact committed_preserves_withdrawal_reserve _ _ amount hm

end LidoSRv3.Audit.SolidityReserve
