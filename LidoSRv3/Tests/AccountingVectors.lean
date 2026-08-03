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

example : sourceTrace valid = some [
    .balancesWritten [10, 20], .accountingCalled,
    .rewardsRead [10, 20], .rewardsMinted] := by native_decide

end LidoSRv3.Tests.AccountingVectors
