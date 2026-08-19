import LidoSRv3.Audit.Verity.HandleOracleReportTx

/-! P-ACCOUNT-1 faithful-plane fail-closed vectors. -/

namespace LidoSRv3.Tests.HandleOracleReportTxMutants

open Verity
open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Verity.HandleOracleReportTx

private def valid : ReportInput := ⟨[1, 2], [1, 2], [10, 20]⟩

private def overflowInput : ReportInput :=
  ⟨List.replicate 19 1, List.replicate 19 1, List.replicate 19 maxValueGwei⟩

private def swapped : ReportInput := ⟨[1, 2], [2, 1], [10, 20]⟩

private def runView (i : ReportInput) (fees : Nat) : View :=
  observe i ((handleOracleReport i fees).run defaultState)

/-- Happy path: balances are written, accounting is called, rewards are read
from that snapshot, then minted. -/
example :
    runView valid 1 =
      ⟨.committed, [10, 20], 30,
        [.balancesWritten [10, 20], .accountingCalled,
          .rewardsRead [10, 20], .rewardsMinted]⟩ := by native_decide

/-- Zero fee shares skip `reportRewardsMinted`, matching Accounting.sol:403-413. -/
example :
    runView valid 0 =
      ⟨.committed, [10, 20], 30,
        [.balancesWritten [10, 20], .accountingCalled,
          .rewardsRead [10, 20]]⟩ := by native_decide

/-- Overflow mutant: 19 × MAX_VALUE_GWEI overflows the uint64 total. -/
example : runView overflowInput 1 = ⟨.reverted, [], 0, []⟩ := by native_decide

/-- Bypass-guard mutant: skipping the registered-order check accepts a
report the real transaction rejects. -/
private def bypassOrderGuard (i : ReportInput) (fees : Nat) : Contract Result :=
  fun snapshot =>
    match checkedTotal256 i.balancesGwei with
    | none => .revert "OVERFLOW" snapshot
    | some total =>
        let dirty := writeAll i.reportedModuleIds i.balancesGwei snapshot
        let dirty := (dirty.writeSlot totalBalanceSlot total
          |>.writeSlot accountingCalledSlot 1
          |>.writeSlot rewardsReadSlot 1)
        let dirty :=
          if 0 < fees then dirty.writeSlot rewardsMintedSlot 1 else dirty
        .success ⟨i.balancesGwei, total,
          successfulSteps ⟨i.reportedModuleIds, i.balancesGwei, total.val⟩ fees⟩
          dirty

example :
    runView swapped 1 = ⟨.reverted, [], 0, []⟩ ∧
      observe swapped ((bypassOrderGuard swapped 1).run defaultState) =
        ⟨.committed, [10, 20], 30,
          [.balancesWritten [10, 20], .accountingCalled,
            .rewardsRead [10, 20], .rewardsMinted]⟩ := by native_decide

/-- Overflow after prefix `writeArray` stores is rolled back by
`Contract.run` to the exact pre-call snapshot. -/
example :
    (handleOracleReport overflowInput 1).run defaultState =
      .revert "OVERFLOW" defaultState := by rfl

/-- Dropped-snapshot mutant: the raw body (without `Contract.run`) keeps
the prefix writes that `run` would discard. -/
example :
    (match (handleOracleReport overflowInput 1) defaultState with
     | .revert _ dirty => (dirty.readArray moduleBalancesSlot).headD 0 |>.val
     | .success _ _ => 0) = maxValueGwei := by native_decide

/-- Failure after every balance, total, and step-flag write is rolled back
by `Contract.run`, not merely hidden by the observation. -/
example :
    (handleOracleReport valid 1 true).run defaultState =
      .revert "INJECTED_AFTER_WRITES" defaultState := by rfl

private def second : ReportInput := ⟨[1, 2], [1, 2], [15, 25]⟩

private def afterFirst : ContractState :=
  match (handleOracleReport valid 1).run defaultState with
  | .success _ s => s
  | .revert _ s => s

/-- Two-batch chaining: a second report starts from the first report's
committed storage and overwrites the same module mapping. -/
example :
    runView valid 1 =
        ⟨.committed, [10, 20], 30,
          [.balancesWritten [10, 20], .accountingCalled,
            .rewardsRead [10, 20], .rewardsMinted]⟩ ∧
      observe second ((handleOracleReport second 1).run afterFirst) =
        ⟨.committed, [15, 25], 40,
          [.balancesWritten [15, 25], .accountingCalled,
            .rewardsRead [15, 25], .rewardsMinted]⟩ := by native_decide

/-- Independence: the source view is not a projection of the transaction
body; a reordered-step mutant disagrees with both. -/
example :
    sourceView valid 1 =
      observe valid ((handleOracleReport valid 1).run defaultState) := by
  native_decide

end LidoSRv3.Tests.HandleOracleReportTxMutants
