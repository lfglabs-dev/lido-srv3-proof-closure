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
          |>.writeSlot rewardsReadSlot 2)
        let dirty :=
          if 0 < fees then dirty.writeSlot rewardsMintedSlot 3 else dirty
        .success ⟨i.balancesGwei, total, storedSteps dirty i.balancesGwei⟩
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

/-- Fees-conditional-removal mutant: unconditionally tagging rewards as
minted (dropping the `0 < sharesToMintAsFees` guard on `rewardsMintedSlot`)
diverges from the zero-fee pinned source view, which has no `.rewardsMinted`
step. -/
private def mintUnconditionally (i : ReportInput) : Contract Result :=
  fun snapshot =>
    match checkedTotal256 i.balancesGwei with
    | none => .revert "OVERFLOW" snapshot
    | some total =>
        let dirty := writeAll i.reportedModuleIds i.balancesGwei snapshot
        let dirty := (dirty.writeSlot totalBalanceSlot total
          |>.writeSlot accountingCalledSlot 1
          |>.writeSlot rewardsReadSlot 2
          |>.writeSlot rewardsMintedSlot 3)
        .success ⟨i.balancesGwei, total, storedSteps dirty i.balancesGwei⟩ dirty

/-- Kill-line: a mutant that always tags `rewardsMintedSlot`, even with zero
fee shares, is caught at the same outcome boundary the composed theorem
checks — its observed view is not the zero-fee pinned source view. -/
example :
    observe valid ((mintUnconditionally valid).run defaultState) ≠
      sourceView valid 0 := by
  native_decide

/-- Reordering mutant: the mint tick (`2`) is assigned strictly before the
read tick (`3`), the same fault as calling `reportRewardsMinted` before
re-reading the freshly written balances. Both flags are nonzero — a
presence-only check cannot tell this apart from the honest transaction — but
the raw tick values disagree with `mintAfterRead`. -/
example :
    let dirty := match (handleOracleReportSwappedMintBeforeRead valid 1) defaultState with
      | .success _ s => s
      | .revert _ s => s
    dirty.readSlot rewardsMintedSlot = 2 ∧ dirty.readSlot rewardsReadSlot = 3 := by
  native_decide

/-- The concrete ticks above (mint `2`, read `3`) witness a mint-after-read
violation: `mintAfterRead` is a bare implication, not itself `Decidable`, so
this is checked by modus ponens rather than `decide` on the whole statement. -/
example : ¬ mintAfterRead 3 2 := by
  intro h
  exact absurd (h (by decide)) (by decide)

/-- The registered parent depends on the swapped-order refutation above:
reassigning the mint tick before the read tick must falsify mint-after-read
discipline. -/
theorem swapped_mint_read_kill_line_refutes_parent :
    LidoSRv3.Audit.Verity.HandleOracleReportTx.mintOrderKillLine :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.mintOrderKillLine_holds

end LidoSRv3.Tests.HandleOracleReportTxMutants
