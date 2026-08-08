import LidoSRv3.Audit.Guarantees.PAccount1

namespace LidoSRv3.Tests.AccountingVectors

open LidoSRv3.Audit.SolidityAccounting

private def valid : ReportInput :=
  ⟨[1, 2], [1, 2], [10, 20]⟩

example : accept valid = some ⟨[1, 2], [10, 20], 30⟩ := by native_decide

/-- Mutant: swapping the oracle's module order must be rejected. -/
example : accept ⟨[1, 2], [2, 1], [10, 20]⟩ = none := by native_decide

/-- Mutant: a truncated balance vector must be rejected. -/
example : accept ⟨[1, 2], [1, 2], [10]⟩ = none := by native_decide

/-- Mutant: `_ensureAmountGwei` rejects a value above MAX_VALUE_GWEI. -/
example : accept ⟨[1], [1], [maxValueGwei + 1]⟩ = none := by native_decide

/-- Mutant: individually valid balances can still overflow the uint64 total. -/
example :
    checkedTotal64 (List.replicate 19 maxValueGwei) = none := by native_decide

private def fullReportSucceeds (_ : ReportInput) (_ : Nat) : Prop := True

example : sourceTrace fullReportSucceeds valid 1 trivial = some [
    .balancesWritten [10, 20], .accountingCalled,
    .rewardsRead [10, 20], .rewardsMinted] := by native_decide

/-- Regression: a full successful report with zero fee shares does not call
`reportRewardsMinted` at pinned Accounting.sol:403-413. -/
example : sourceTrace fullReportSucceeds valid 0 trivial = some [
    .balancesWritten [10, 20], .accountingCalled,
    .rewardsRead [10, 20]] := by native_decide

/-- Mutant: the early router guards can accept even though an independent full
source execution rejects later; absent success evidence, no trace is projected. -/
private def rejectedLater (_ : ReportInput) (_ : Nat) : Prop := False

example : accept valid = some ⟨[1, 2], [10, 20], 30⟩ := by native_decide

example : sourceTraceFromResult rejectedLater valid 1 .reverted = none := by
  rfl

/-- Independence mutant: the source accumulator is not a projection of a
wrapped Uint256 result; an out-of-range word input is rejected by the source
uint64 semantics even though `Uint256.ofNat` itself wraps it. -/
example : checkedTotal64 [Verity.Core.Uint256.modulus] = none := by native_decide

/-- Negative mutant: removing the checked-uint64 destination guard produces a
transaction result where the independent pinned-source execution reverts. -/
private def uncheckedUint64Mutant (xs : List Nat) : Option Word :=
  some (Verity.Core.Uint256.ofNat xs.sum)

example : checkedTotal64 [uint64Max, 1] = none ∧
    uncheckedUint64Mutant [uint64Max, 1] =
      some (Verity.Core.Uint256.ofNat (uint64Max + 1)) := by native_decide

/-- Negative observable mutant: reading rewards before the balance write is
distinguishable from the pinned source report. -/
private def reorderedTraceMutant (accepted : AcceptedReport) : List Step :=
  [.rewardsRead accepted.balancesGwei, .balancesWritten accepted.balancesGwei,
    .accountingCalled, .rewardsMinted]

example : reorderedTraceMutant ⟨[1, 2], [10, 20], 30⟩ ≠
    successfulSteps ⟨[1, 2], [10, 20], 30⟩ 1 := by native_decide

/-- The observable transaction is separately executed and agrees on the
pinned successful report, including its checked total. -/
example : verityTxAccept valid = some ⟨[1, 2], [10, 20], 30⟩ := by native_decide

/-- The hybrid entrypoint reaches the generated typed-storage commit only
after executing the accounting-prefix validation and checked accumulation. -/
example :
    match (AccountingContract.submitReportBalances valid).run Verity.defaultState with
    | .success accepted after =>
        accepted == ⟨[1, 2], [10, 20], 30⟩ &&
        after.storage AccountingContract.lastTotalBalanceGwei.slot == 30 &&
        after.storage AccountingContract.lastModuleCount.slot == 2
    | .revert _ _ => false := by rfl

/-- An order mutant reverts before the typed-storage commit. -/
example :
    match (AccountingContract.submitReportBalances
      ⟨[1, 2], [2, 1], [10, 20]⟩).run Verity.defaultState with
    | .revert _ rollback =>
        rollback.storage AccountingContract.lastTotalBalanceGwei.slot == 0 &&
        rollback.storage AccountingContract.lastModuleCount.slot == 0
    | .success _ _ => false := by rfl

example : verityTxTrace fullReportSucceeds valid 1 trivial =
    sourceTrace fullReportSucceeds valid 1 trivial := by native_decide

end LidoSRv3.Tests.AccountingVectors
