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
that the rest of the pinned report avoids a later revert.  Trace construction
therefore requires an independent `fullReportSucceeds` premise supplied by the
caller.  External-call authorization, the truthfulness of oracle calldata, and
that full-success premise remain interface assumptions.  Yul, EVM, runtime
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
by the uint64 destination bound. -/
def checkedTotal256 : List Nat → Option Word
  | [] => some 0
  | x :: xs => do
      let tail ← checkedTotal256 xs
      let next ← safeAdd tail (Verity.Core.Uint256.ofNat x)
      if next.val ≤ uint64Max then some next else none

/-- Natural-number source view of the same checked Verity execution. -/
def checkedTotal64 (xs : List Nat) : Option Nat :=
  (checkedTotal256 xs).map (·.val)

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

/-- Trace projection gated by independently established successful execution
of the *full* pinned report.  `accept` deliberately proves only the earlier
router validation and checked accumulation; it cannot manufacture this premise. -/
def sourceTrace (fullReportSucceeds : ReportInput → Nat → Prop)
    (i : ReportInput) (sharesToMintAsFees : Nat)
    (_ : fullReportSucceeds i sharesToMintAsFees) : Option (List Step) := do
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

theorem checkedTotal256_refines_source (xs : List Nat) (n : Nat)
    (h : checkedTotal64 xs = some n) :
    checkedTotal256 xs = some (Verity.Core.Uint256.ofNat n) := by
  simp [checkedTotal64, Option.map_eq_some_iff] at h
  rcases h with ⟨word, hWord, rfl⟩
  rw [hWord]
  congr 1
  apply Verity.Core.Uint256.ext
  have hw := word.isLt
  simp [Verity.Core.Uint256.modulus] at hw ⊢
  exact (Nat.mod_eq_of_lt hw).symm

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

/-- Critical SOURCE -> VERITY_TX refinement for every fully successful report
whose earlier router validation and checked accumulation also accept. -/
theorem source_to_verityTx
    (fullReportSucceeds : ReportInput → Nat → Prop)
    (i : ReportInput) (sharesToMintAsFees : Nat)
    (hSuccess : fullReportSucceeds i sharesToMintAsFees)
    (accepted : AcceptedReport) (hAccept : accept i = some accepted) :
    checkedTotal256 accepted.balancesGwei = some (Verity.Core.Uint256.ofNat accepted.totalBalanceGwei) ∧
    sourceTrace fullReportSucceeds i sharesToMintAsFees hSuccess =
      some (successfulSteps accepted sharesToMintAsFees) := by
  simp [accept, Option.bind_eq_some_iff] at hAccept
  rcases hAccept with ⟨hValid, total, hTotal, rfl⟩
  constructor
  · exact checkedTotal256_refines_source _ _ hTotal
  · simp [sourceTrace, accept, hValid, hTotal]

end LidoSRv3.Audit.SolidityAccounting
