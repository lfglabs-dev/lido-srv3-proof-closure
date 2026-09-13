import LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount

/-! # Kill-lines for `WithdrawalQueueRequestAmount` bounds

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned WithdrawalQueue.sol:395-402 `_checkWithdrawalRequestAmount`
per-request bounds (100 ≤ amount ≤ 1000 * 10^18). -/

namespace LidoSRv3.Tests.WithdrawalQueueRequestAmountKillLines

open LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount

/-- **Kill-line: MIN_STETH_WITHDRAWAL_AMOUNT = 100.**

Pinned WithdrawalQueue.sol:52 constant. A mutant that changed the
lower bound would refute the guard's semantics. -/
theorem minStethWithdrawalAmount_pinned :
    minStethWithdrawalAmount = 100 := rfl

/-- **Kill-line: MAX_STETH_WITHDRAWAL_AMOUNT = 1000 * 10^18.**

Pinned WithdrawalQueue.sol:57 constant (1000 ether). -/
theorem maxStethWithdrawalAmount_pinned :
    maxStethWithdrawalAmount = 1000 * 10 ^ 18 := rfl

/-- **Kill-line: MAX decimal is 10^21.** -/
theorem maxStethWithdrawalAmount_decimal :
    maxStethWithdrawalAmount = 10 ^ 21 := by decide

/-- **Kill-line: MIN < MAX (guard interval non-empty).** -/
theorem min_lt_max :
    minStethWithdrawalAmount < maxStethWithdrawalAmount := by decide

/-- **Kill-line: `checkedWithdrawalRequestAmount 0 = false` (below min).** -/
theorem checked_zero_reject : checkedWithdrawalRequestAmount 0 = false := by decide

/-- **Kill-line: `checkedWithdrawalRequestAmount 99 = false` (just below min).** -/
theorem checked_99_reject :
    checkedWithdrawalRequestAmount 99 = false := by decide

/-- **Kill-line: `checkedWithdrawalRequestAmount 100 = true` (min boundary).** -/
theorem checked_100_accept :
    checkedWithdrawalRequestAmount 100 = true := by decide

/-- **Kill-line: `checkedWithdrawalRequestAmount 10^21 = true` (max
boundary).** -/
theorem checked_max_accept :
    checkedWithdrawalRequestAmount (10 ^ 21) = true := by decide

/-- **Kill-line: `checkedWithdrawalRequestAmount (10^21 + 1) = false` (just
above max).** -/
theorem checked_over_max_reject :
    checkedWithdrawalRequestAmount (10 ^ 21 + 1) = false := by decide

#print axioms minStethWithdrawalAmount_pinned
#print axioms maxStethWithdrawalAmount_pinned
#print axioms maxStethWithdrawalAmount_decimal
#print axioms min_lt_max
#print axioms checked_100_accept
#print axioms checked_max_accept
#print axioms checked_over_max_reject

end LidoSRv3.Tests.WithdrawalQueueRequestAmountKillLines
