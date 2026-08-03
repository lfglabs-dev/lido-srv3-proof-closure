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

end LidoSRv3.Tests.AccountingVectors
