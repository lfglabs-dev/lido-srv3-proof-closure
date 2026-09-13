import LidoSRv3.Audit.Source.ReserveCorrespondence

/-!
Kill-lines pinning `Source.ReserveCorrespondence` primitives
(`minWord`, `getBufferedEtherAllocation`, `getDepositableEther`,
`SourceOutcome`) at Lido core pin 17005714, Lido.sol:605-616 + 832.
-/

namespace LidoSRv3.Tests.SourceReserveCorrespondencePrimitivesKillLines

open LidoSRv3.Audit.SolidityReserve

private def zeroState : ReserveState :=
  { buffered := 0, storedDepositsReserve := 0, unfinalizedStETH := 0
    depositedPostReport := 0, depositedNextReportAdjusted := 0 }

private def zeroAllocation : Allocation :=
  { total := 0, unreserved := 0, depositsReserve := 0, withdrawalsReserve := 0 }

/-! ## `minWord` — word-comparison min. -/

theorem minWord_zero_zero : minWord 0 0 = 0 := rfl

theorem minWord_small_first :
    minWord (3 : Word) (5 : Word) = (3 : Word) := by decide

theorem minWord_small_second :
    minWord (5 : Word) (3 : Word) = (3 : Word) := by decide

theorem minWord_equal :
    minWord (7 : Word) (7 : Word) = (7 : Word) := by decide

/-! ## `getBufferedEtherAllocation` — Lido.sol:605-616. -/

theorem getBufferedEtherAllocation_zero_state :
    getBufferedEtherAllocation zeroState = some zeroAllocation := rfl

/-! ## `getDepositableEther` — Lido.sol:832 (unreserved + depositsReserve). -/

theorem getDepositableEther_zero :
    getDepositableEther zeroAllocation = some 0 := rfl

/-! ## `SourceOutcome` — two-arm inductive distinctness. -/

theorem sourceOutcome_reverted_ne_committed :
    SourceOutcome.reverted "X" ≠ SourceOutcome.committed zeroState := by decide

theorem sourceOutcome_decEq_reverted_self :
    (decide (SourceOutcome.reverted "X" = SourceOutcome.reverted "X"))
      = true := by decide

theorem sourceOutcome_decEq_committed_self :
    (decide (SourceOutcome.committed zeroState =
             SourceOutcome.committed zeroState)) = true := by decide

/-! ## `ReserveState` five-field structure. -/

theorem reserveState_buffered :
    ({ buffered := 42, storedDepositsReserve := 0, unfinalizedStETH := 0
       depositedPostReport := 0, depositedNextReportAdjusted := 0
       : ReserveState }).buffered = (42 : Word) := rfl

theorem reserveState_decEq_self :
    (decide (zeroState = zeroState)) = true := by decide

/-! ## `Allocation` four-field structure. -/

theorem allocation_decEq_self :
    (decide (zeroAllocation = zeroAllocation)) = true := by decide

/-! ## `spendDepositableEther` on zero-state + zero amount commits. -/

theorem spendDepositableEther_zero_amount :
    spendDepositableEther zeroState 0 = .committed zeroState := by decide

end LidoSRv3.Tests.SourceReserveCorrespondencePrimitivesKillLines
