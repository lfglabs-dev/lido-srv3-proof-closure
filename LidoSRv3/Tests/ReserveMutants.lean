import LidoSRv3.Audit.Guarantees.PReserve1

namespace LidoSRv3.Tests.ReserveMutants

open Verity
open LidoSRv3.Audit.SolidityReserve

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n

private def vector : ReserveState :=
  { buffered := word 100
    storedDepositsReserve := word 20
    unfinalizedStETH := word 50
    depositedPostReport := word 3
    depositedNextReportAdjusted := word 2 }

/-- Meaningful source mutant: a deposit spend illegally decrements withdrawal
demand as well as the deposits reserve. -/
private def reserveChangingMutant (before : ReserveState) (amount : Word) : SourceOutcome :=
  match spendDepositableEther before amount with
  | .reverted reason => .reverted reason
  | .committed after => .committed { after with
      unfinalizedStETH := after.unfinalizedStETH - amount }

example : spendDepositableEther vector (word 10) = .committed
    { vector with
      buffered := word 90
      storedDepositsReserve := word 10
      depositedPostReport := word 13
      depositedNextReportAdjusted := word 12 } := by decide

/-- This falsifier fails exactly if the prohibited transition is admitted. -/
example : reserveChangingMutant vector (word 10) = .committed
    { vector with
      buffered := word 90
      storedDepositsReserve := word 10
      unfinalizedStETH := word 40
      depositedPostReport := word 13
      depositedNextReportAdjusted := word 12 } := by decide

example : reserveChangingMutant vector (word 10) ≠
    spendDepositableEther vector (word 10) := by decide

/-- A checked-Uint256 overflow after the source-ordered buffer work is still a
whole Verity transaction rollback. -/
example : specTx
    { vector with depositedNextReportAdjusted := (Verity.Core.MAX_UINT256 : Word) }
    (word 1) =
    ⟨TxOutcome.reverted,
      { vector with depositedNextReportAdjusted := (Verity.Core.MAX_UINT256 : Word) },
      { vector with depositedNextReportAdjusted := (Verity.Core.MAX_UINT256 : Word) }⟩ := by decide

end LidoSRv3.Tests.ReserveMutants
