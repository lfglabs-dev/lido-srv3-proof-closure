/-!
# WithdrawalQueue single-request amount mutant

This regression attacks the exact `SingleRequestAmountBound` parent from the
source slice. It is deliberately limited to `_checkWithdrawalRequestAmount`:
it does not assert completeness for approve, transfer, redeem, claim, or any
other token surface.
-/

import LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount

namespace LidoSRv3.Tests.WithdrawalQueueRequestAmountMutants

open LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount

/-- One-conjunct mutant of the pinned predicate: the upper bound check at
`WithdrawalQueue.sol:399-400` is removed, while the lower-bound check remains. -/
def requestWithdrawalsSingleUpperBoundDropped (amount : Nat) : Outcome :=
  if decide (minStethWithdrawalAmount ≤ amount) then .committed else .reverted

/-- Exact-parent kill-line. The mutant accepts `MAX + 1`, so it refutes the
same universal commit-implies-two-sided-bound predicate proved for the honest
single-item source slice. -/
theorem upper_bound_drop_kill_line_refutes_exact_parent :
    ¬ SingleRequestAmountBound requestWithdrawalsSingleUpperBoundDropped := by
  intro h
  have hCommitted : requestWithdrawalsSingleUpperBoundDropped
      (maxStethWithdrawalAmount + 1) = .committed := by
    simp [requestWithdrawalsSingleUpperBoundDropped, minStethWithdrawalAmount,
      maxStethWithdrawalAmount]
  have hBound := h (maxStethWithdrawalAmount + 1) hCommitted
  omega

end LidoSRv3.Tests.WithdrawalQueueRequestAmountMutants
