import LidoSRv3.Audit.Guarantees.PAccount1

namespace LidoSRv3.Tests.PAccount1Vectors

open LidoSRv3.Audit.SolidityAccounting
open LidoSRv3.Audit.Verity.HandleOracleReportTx

private def valid : ReportInput :=
  ⟨[1, 2], [1, 2], [10, 20]⟩

/-- Committed vector: the executable report observes the exact pinned-source
view, including the four-tick step trace. -/
example : observe valid ((handleOracleReport valid 1).run Verity.defaultState) =
    ⟨.committed, [10, 20], 30,
      [.balancesWritten [10, 20], .accountingCalled,
        .rewardsRead [10, 20], .rewardsMinted]⟩ := by native_decide

/-- Zero-fee vector: no mint step is stamped and the trace ends at the
rewards read. -/
example : observe valid ((handleOracleReport valid 0).run Verity.defaultState) =
    ⟨.committed, [10, 20], 30,
      [.balancesWritten [10, 20], .accountingCalled,
        .rewardsRead [10, 20]]⟩ := by native_decide

/-- Negative vector: a module-order swap reverts with the empty view. -/
example : observe ⟨[1, 2], [2, 1], [10, 20]⟩
    ((handleOracleReport ⟨[1, 2], [2, 1], [10, 20]⟩ 1).run
      Verity.defaultState) = ⟨.reverted, [], 0, []⟩ := by native_decide

/-- Raw step ticks of a committed run, in slot order
`(balancesWritten, accountingCalled, rewardsRead, rewardsMinted)`. -/
private def ticksOf (r : Verity.ContractResult Result) :
    Option (Nat × Nat × Nat × Nat) :=
  match r with
  | .success _ dirty =>
      some ((dirty.readSlot balancesWrittenSlot).val,
        (dirty.readSlot accountingCalledSlot).val,
        (dirty.readSlot rewardsReadSlot).val,
        (dirty.readSlot rewardsMintedSlot).val)
  | .revert _ _ => none

/-- Reconstructed step trace of a run, empty on revert. -/
private def stepsOf (r : Verity.ContractResult Result) : List Step :=
  match r with
  | .success res _ => res.steps
  | .revert _ _ => []

/-- Revert reason of a run, if any. -/
private def revertReason (r : Verity.ContractResult Result) : Option String :=
  match r with
  | .revert reason _ => some reason
  | .success _ _ => none

/-- Tick vector behind the registered parent `mint_after_read_discipline`:
on the real transaction the balance write is stamped at tick 1, accounting at
2, the rewards read at 3, and the mint at 4. -/
example : ticksOf ((handleOracleReport valid 1).run Verity.defaultState) =
    some (1, 2, 3, 4) := by native_decide

/-- The real transaction's read tick (3) strictly precedes its nonzero mint
tick (4): the `mintAfterRead` predicate holds on those exact ticks. -/
example : mintAfterRead (3 : LidoSRv3.Audit.Verity.HandleOracleReportTx.Word) (4 : LidoSRv3.Audit.Verity.HandleOracleReportTx.Word) := by
  unfold mintAfterRead; decide

/-- Kill-line vector: on the pure call-site reordering mutant the mint step
records tick 3 and the read step tick 4. -/
example : ticksOf ((handleOracleReportMintBeforeRead valid 1).run
    Verity.defaultState) = some (1, 2, 4, 3) := by native_decide

/-- The mutant's ticks falsify the same `mintAfterRead` predicate the
registered parent proves for the real transaction. -/
example : ¬ mintAfterRead (4 : LidoSRv3.Audit.Verity.HandleOracleReportTx.Word) (3 : LidoSRv3.Audit.Verity.HandleOracleReportTx.Word) := by
  unfold mintAfterRead; decide

/-- The same reordering is visible by omission at the `Result.steps`
boundary: the exact-tick checks drop both reordered steps from the
reconstructed trace. -/
example : stepsOf ((handleOracleReportMintBeforeRead valid 1).run
    Verity.defaultState) =
    [.balancesWritten [10, 20], .accountingCalled] := by native_decide

/-- Injected failure after every intermediate write surfaces the injected
reason at the observable boundary. -/
example : revertReason ((handleOracleReport valid 1 true).run
    Verity.defaultState) = some "INJECTED_AFTER_WRITES" := by native_decide

/-- Every reverting execution of the real transaction, including the injected
post-write failure, restores the exact pre-call snapshot. -/
example (state rollback : Verity.ContractState) (reason : String)
    (h : (handleOracleReport valid 1 true).run state = .revert reason rollback) :
    rollback = state :=
  LidoSRv3.Audit.Guarantees.PAccount1.verity_tx_revert_restores_snapshot
    valid 1 true state rollback reason h

/-- Registry surface: the registered P-ACCOUNT-1 parent and its kill-line
remain the theorems this file's concrete vectors exercise. -/
example : mintAfterReadDiscipline :=
  LidoSRv3.Audit.Guarantees.PAccount1.mint_after_read_discipline

example : mintOrderKillLine :=
  LidoSRv3.Audit.Guarantees.PAccount1.mint_order_kill_line

end LidoSRv3.Tests.PAccount1Vectors
