import LidoSRv3.Audit.Arithmetic

/-!
Pinned source correspondence for the report-before-reward path at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.

The real external entry point is `AccountingOracle.submitReportData`. Its
main-data helper writes the
module balance vector through StakingRouter before calling
`Accounting.handleOracleReport`.  Accounting obtains the reward distribution
from that router state and calls `reportRewardsMinted` only after fee shares are
minted and distributed.  The source spans are registered in
`audit/source-map.yaml`.

This module models exactly the accounting-relevant guards in the transitive
router write: array lengths and module order, `MAX_VALUE_GWEI`, the uint64 cast,
and the checked uint64 accumulation.  Those partial guards do not establish
that the rest of the pinned report avoids a later revert.  The demoted
constructor-order child now uses `sourceTraceRetired`, which carries no
load-bearing full-report success premise.  The legacy `sourceTrace` adapter is
retained only for API compatibility. External-call authorization and the
truthfulness of oracle calldata remain interface assumptions. Yul, EVM, runtime
identity, cryptography, and end-to-end deployment composition are not claimed.
-/

namespace LidoSRv3.Audit.SolidityAccounting

open Verity Verity.Stdlib.Math

abbrev Word := Verity.Core.Uint256

def maxValueGwei : Nat := 1000000000000000000
def uint64Max : Nat := 18446744073709551615

structure ReportInput where
  registeredModuleIds : List Nat
  reportedModuleIds : List Nat
  balancesGwei : List Nat
  deriving Repr, DecidableEq

structure AcceptedReport where
  moduleIds : List Nat
  balancesGwei : List Nat
  totalBalanceGwei : Nat
  deriving Repr, DecidableEq

inductive Step
  | balancesWritten (balances : List Nat)
  | accountingCalled
  | rewardsRead (balances : List Nat)
  | rewardsMinted
  deriving Repr, DecidableEq

def idsAndBalancesValid (i : ReportInput) : Bool :=
  i.reportedModuleIds.length == i.registeredModuleIds.length &&
  i.balancesGwei.length == i.registeredModuleIds.length &&
  i.reportedModuleIds == i.registeredModuleIds &&
  i.balancesGwei.all (· ≤ maxValueGwei)

/-- Verity-word execution of the checked `+=` at SRLib.sol line 888, followed
by the uint64 destination bound.  This is deliberately separate from
`checkedTotal64`, the pinned Solidity source semantics below. -/
def checkedTotal256 : List Nat → Option Word
  | [] => some 0
  | x :: xs => do
      let tail ← checkedTotal256 xs
      let next ← safeAdd tail (Verity.Core.Uint256.ofNat x)
      if next.val ≤ uint64Max then some next else none

/-- Independent pinned-source semantics for Solidity's checked uint64 `+=`.
It uses only natural-number addition and the uint64 bound: it does not call,
project, or otherwise depend on the Verity execution. -/
def checkedTotal64 : List Nat → Option Nat
  | [] => some 0
  | x :: xs => do
      let tail ← checkedTotal64 xs
      let next := x + tail
      if next ≤ uint64Max then some next else none

def accept (i : ReportInput) : Option AcceptedReport := do
  if idsAndBalancesValid i then pure () else none
  let total ← checkedTotal64 i.balancesGwei
  pure ⟨i.reportedModuleIds, i.balancesGwei, total⟩

/-- Successful source steps after the validated balance write.  The pinned
`Accounting.sol:403-413` call is conditional on strictly positive fee shares. -/
def successfulSteps (accepted : AcceptedReport) (sharesToMintAsFees : Nat) : List Step :=
  [.balancesWritten accepted.balancesGwei, .accountingCalled,
    .rewardsRead accepted.balancesGwei] ++
  if 0 < sharesToMintAsFees then [.rewardsMinted] else []

/-- Independently defined observable transaction steps.  Keeping this target
projection separate makes an ordering mutation on either side falsifiable. -/
def verityTxSuccessfulSteps (accepted : AcceptedReport)
    (sharesToMintAsFees : Nat) : List Step :=
  [.balancesWritten accepted.balancesGwei, .accountingCalled,
    .rewardsRead accepted.balancesGwei] ++
  if 0 < sharesToMintAsFees then [.rewardsMinted] else []

/-- Verity transaction acceptance, executing `safeAdd`/Uint256 independently
and exposing the checked uint64 result as the transaction observation. -/
def verityTxAccept (i : ReportInput) : Option AcceptedReport := do
  if idsAndBalancesValid i then pure () else none
  let total ← checkedTotal256 i.balancesGwei
  pure ⟨i.reportedModuleIds, i.balancesGwei, total.val⟩

/-- Trace projection gated by independently established successful execution
of the *full* pinned report.  `accept` deliberately proves only the earlier
router validation and checked accumulation; it cannot manufacture this premise. -/
def sourceTrace (fullReportSucceeds : ReportInput → Nat → Prop)
    (i : ReportInput) (sharesToMintAsFees : Nat)
    (_ : fullReportSucceeds i sharesToMintAsFees) : Option (List Step) := do
  let accepted ← accept i
  pure (successfulSteps accepted sharesToMintAsFees)

/-- Explicit marker for the retired success premise.  It is intentionally
`True` and is not used by the demoted constructor-order child. -/
def FullReportSucceedsRetired : ReportInput → Nat → Prop := fun _ _ => True

/-- Premise-free trace projection for the demoted source child.  This says only
what constructor order follows when the locally modeled `accept` succeeds; it
does not claim that the full live oracle report succeeds. -/
def sourceTraceRetired (i : ReportInput) (sharesToMintAsFees : Nat) :
    Option (List Step) := do
  let accepted ← accept i
  pure (successfulSteps accepted sharesToMintAsFees)

/-- Result supplied by an independent full-source executor or validator. -/
inductive FullReportResult (successful : Prop) : Type
  | reverted
  | succeeded (evidence : successful)

/-- Boundary adapter for a source executor/validator that may fail to provide
the full-success evidence.  A later-reverted report has no trace. -/
def sourceTraceFromResult (fullReportSucceeds : ReportInput → Nat → Prop)
    (i : ReportInput) (sharesToMintAsFees : Nat)
    (result : FullReportResult (fullReportSucceeds i sharesToMintAsFees)) :
    Option (List Step) :=
  match result with
  | .reverted => none
  | .succeeded evidence =>
      sourceTrace fullReportSucceeds i sharesToMintAsFees evidence

/-- Observable Verity transaction, separately executed from `sourceTrace`. -/
def verityTxTrace (fullReportSucceeds : ReportInput → Nat → Prop)
    (i : ReportInput) (sharesToMintAsFees : Nat)
    (_ : fullReportSucceeds i sharesToMintAsFees) : Option (List Step) := do
  let accepted ← verityTxAccept i
  pure (verityTxSuccessfulSteps accepted sharesToMintAsFees)

theorem checkedTotal64_le (xs : List Nat) (n : Nat)
    (h : checkedTotal64 xs = some n) : n ≤ uint64Max := by
  induction xs with
  | nil => simp [checkedTotal64] at h; omega
  | cons x xs ih =>
      simp [checkedTotal64, Option.bind_eq_some_iff] at h
      rcases h with ⟨tail, hTail, hNext⟩
      exact hNext.2 ▸ hNext.1

theorem checkedTotal256_refines_source (xs : List Nat) (n : Nat)
    (h : checkedTotal64 xs = some n) :
    checkedTotal256 xs = some (Verity.Core.Uint256.ofNat n) := by
  induction xs generalizing n with
  | nil => simp [checkedTotal64, checkedTotal256] at h ⊢; exact h.symm ▸ rfl
  | cons x xs ih =>
      simp [checkedTotal64, Option.bind_eq_some_iff] at h
      rcases h with ⟨tail, hTail, hNext⟩
      rcases hNext with ⟨hFit, rfl⟩
      have h64mod : uint64Max < Verity.Core.Uint256.modulus := by decide
      have hx : x < Verity.Core.Uint256.modulus :=
        Nat.lt_of_le_of_lt (Nat.le_add_right x tail)
          (Nat.lt_of_le_of_lt hFit h64mod)
      have ht : tail < Verity.Core.Uint256.modulus :=
        Nat.lt_of_le_of_lt (Nat.le_add_left tail x)
          (Nat.lt_of_le_of_lt hFit h64mod)
      have hsum : x + tail ≤ Verity.Core.MAX_UINT256 := by
        have hmax : uint64Max ≤ Verity.Core.MAX_UINT256 := by decide
        exact Nat.le_trans hFit hmax
      have hsumlt : x + tail < Verity.Core.Uint256.modulus :=
        Nat.lt_of_le_of_lt hFit h64mod
      have hSafe : safeAdd (Verity.Core.Uint256.ofNat tail)
          (Verity.Core.Uint256.ofNat x) =
          some (Verity.Core.Uint256.ofNat (x + tail)) := by
        simp [safeAdd, Nat.mod_eq_of_lt hx, Nat.mod_eq_of_lt ht,
          Nat.not_lt.mpr hsum, Nat.add_comm, Verity.Core.Uint256.ofNat_add]
      have hVal : (Verity.Core.Uint256.ofNat x +
          Verity.Core.Uint256.ofNat tail).val = x + tail := by
        simp [HAdd.hAdd, Verity.Core.Uint256.add, Nat.mod_eq_of_lt hx,
          Nat.mod_eq_of_lt ht]
        exact Nat.mod_eq_of_lt hsumlt
      simp [checkedTotal256, ih tail hTail, hSafe, hVal, hFit,
        Verity.Core.Uint256.ofNat_add]

theorem source_report_before_reward
    (fullReportSucceeds : ReportInput → Nat → Prop)
    (i : ReportInput) (sharesToMintAsFees : Nat)
    (hSuccess : fullReportSucceeds i sharesToMintAsFees)
    (hFees : 0 < sharesToMintAsFees) (trace : List Step)
    (h : sourceTrace fullReportSucceeds i sharesToMintAsFees hSuccess = some trace) :
    ∃ balances, trace = [.balancesWritten balances, .accountingCalled,
      .rewardsRead balances, .rewardsMinted] := by
  simp [sourceTrace, successfulSteps, hFees, Option.bind_eq_some_iff] at h
  rcases h with ⟨accepted, hAccepted, rfl⟩
  exact ⟨accepted.balancesGwei, rfl⟩

/-- Replacement demoted child with no caller-supplied full-success binder. -/
theorem source_report_before_reward_retired
    (i : ReportInput) (sharesToMintAsFees : Nat)
    (hFees : 0 < sharesToMintAsFees) (trace : List Step)
    (h : sourceTraceRetired i sharesToMintAsFees = some trace) :
    ∃ balances, trace = [.balancesWritten balances, .accountingCalled,
      .rewardsRead balances, .rewardsMinted] := by
  simp [sourceTraceRetired, successfulSteps, hFees, Option.bind_eq_some_iff] at h
  rcases h with ⟨accepted, hAccepted, rfl⟩
  exact ⟨accepted.balancesGwei, rfl⟩

/-- Critical SOURCE -> VERITY_TX refinement for every fully successful report
whose earlier router validation and checked accumulation also accept. -/
theorem source_to_verityTx
    (fullReportSucceeds : ReportInput → Nat → Prop)
    (i : ReportInput) (sharesToMintAsFees : Nat)
    (hSuccess : fullReportSucceeds i sharesToMintAsFees)
    (accepted : AcceptedReport) (hAccept : accept i = some accepted) :
    checkedTotal256 accepted.balancesGwei = some (Verity.Core.Uint256.ofNat accepted.totalBalanceGwei) ∧
    verityTxAccept i = some accepted ∧
    verityTxTrace fullReportSucceeds i sharesToMintAsFees hSuccess =
      sourceTrace fullReportSucceeds i sharesToMintAsFees hSuccess := by
  simp [accept, Option.bind_eq_some_iff] at hAccept
  rcases hAccept with ⟨hValid, total, hTotal, rfl⟩
  constructor
  · exact checkedTotal256_refines_source _ _ hTotal
  · have hWord := checkedTotal256_refines_source _ _ hTotal
    have hTotalLe := checkedTotal64_le _ _ hTotal
    have h64mod : uint64Max < Verity.Core.Uint256.modulus := by decide
    have hTotalLt : total < Verity.Core.Uint256.modulus :=
      Nat.lt_of_le_of_lt hTotalLe h64mod
    constructor
    · simp [verityTxAccept, hValid, hWord, Nat.mod_eq_of_lt hTotalLt]
    · simp [verityTxTrace, sourceTrace, verityTxAccept, accept, hValid,
        hWord, hTotal, verityTxSuccessfulSteps, successfulSteps]

end LidoSRv3.Audit.SolidityAccounting
