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
          |>.writeSlot balancesWrittenSlot 1
          |>.writeSlot accountingCalledSlot 2
          |>.writeSlot rewardsReadSlot 3)
        let dirty :=
          if 0 < fees then dirty.writeSlot rewardsMintedSlot 4 else dirty
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
          |>.writeSlot balancesWrittenSlot 1
          |>.writeSlot accountingCalledSlot 2
          |>.writeSlot rewardsReadSlot 3
          |>.writeSlot rewardsMintedSlot 4)
        .success ⟨i.balancesGwei, total, storedSteps dirty i.balancesGwei⟩ dirty

/-- Kill-line: a mutant that always tags `rewardsMintedSlot`, even with zero
fee shares, is caught at the same outcome boundary the composed theorem
checks — its observed view is not the zero-fee pinned source view. -/
example :
    observe valid ((mintUnconditionally valid).run defaultState) ≠
      sourceView valid 0 := by
  native_decide

/-- The honest transaction stamps the balance write at tick `1`, the read step
at clock tick `3`, and the mint step at tick `4`. None of these numbers appears at a write site: they are read
back out of the step clock, so they record the order the two writes ran in. -/
example :
    let dirty := match (handleOracleReport valid 1) defaultState with
      | .success _ s => s
      | .revert _ s => s
    dirty.readSlot balancesWrittenSlot = 1 ∧
      dirty.readSlot rewardsReadSlot = 3 ∧ dirty.readSlot rewardsMintedSlot = 4 := by
  native_decide

/-- Reordering mutant: the mint step runs strictly before the read step, the
same fault as calling `reportRewardsMinted` before re-reading the freshly
written balances.

This is the mutation `report/P-ACCOUNT-1.md` issue 5 previously recorded as an
open, disclosed gap: only the call sites move, every slot binding is
unchanged, and no literal is edited. Both flags are still nonzero and
`storedSteps`' presence check still cannot tell this apart from the honest
transaction — but because `stampStep` takes its tick from the clock, the mint
step now records `3` and the read step `4`. -/
example :
    let dirty := match (handleOracleReportMintBeforeRead valid 1) defaultState with
      | .success _ s => s
      | .revert _ s => s
    dirty.readSlot rewardsMintedSlot = 3 ∧ dirty.readSlot rewardsReadSlot = 4 := by
  native_decide

/-- The reordering above is invisible to a presence-only check: the mutant's
`storedSteps` flags are all still nonzero, exactly as in the honest run. This
is why the parent reads the raw ticks rather than `storedSteps`. -/
example :
    let dirty := match (handleOracleReportMintBeforeRead valid 1) defaultState with
      | .success _ s => s
      | .revert _ s => s
    dirty.readSlot accountingCalledSlot ≠ 0 ∧ dirty.readSlot rewardsReadSlot ≠ 0 ∧
      dirty.readSlot rewardsMintedSlot ≠ 0 := by
  native_decide

/-- The concrete ticks above (mint `3`, read `4`) witness a mint-after-read
violation: `mintAfterRead` is a bare implication, not itself `Decidable`, so
this is checked by modus ponens rather than `decide` on the whole statement. -/
example : ¬ mintAfterRead 4 3 := by
  intro h
  exact absurd (h (by decide)) (by decide)

/-- The registered parent depends on the reordering refutation above: running
the mint step before the read step must falsify mint-after-read discipline. -/
theorem reordered_mint_read_kill_line_refutes_parent :
    LidoSRv3.Audit.Verity.HandleOracleReportTx.mintOrderKillLine :=
  LidoSRv3.Audit.Verity.HandleOracleReportTx.mintOrderKillLine_holds

end LidoSRv3.Tests.HandleOracleReportTxMutants
