import LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl

/-!
# WithdrawalQueue one-item control mutant (T2)

The mutation deletes only the zero-owner assignment at
`WithdrawalQueue.sol:130`; the amount predicate remains the honest pinned
predicate.  Its witness therefore attacks the exact parent proved for the
one-item control projection rather than a weaker sibling statement.
-/

namespace LidoSRv3.Tests.WithdrawalQueueSingleRequestControlMutants

open LidoSRv3.Audit.Source.WithdrawalQueueRequestAmount
open LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl

/-- Surgical line-130 mutant: retain the supplied zero owner instead of
falling back to `msg.sender`. -/
def requestWithdrawalsSingleControlOwnerFallbackDropped
    (_caller suppliedOwner amount : Nat) :
    LidoSRv3.Audit.Source.WithdrawalQueueSingleRequestControl.Outcome :=
  if checkedWithdrawalRequestAmount amount then .proceeds suppliedOwner
  else .revertedAmount

/-- Exact-parent kill-line.  At an EVM-callable caller and the source minimum
amount, the mutant reaches line 134 with owner zero, while the real line 130
requires owner seven. -/
theorem owner_fallback_drop_kill_line_refutes_exact_parent :
    ¬ SingleRequestControlInvariant
      requestWithdrawalsSingleControlOwnerFallbackDropped := by
  intro h
  have hCommitted : requestWithdrawalsSingleControlOwnerFallbackDropped 7 0
      minStethWithdrawalAmount = .proceeds 0 := by
    simp [requestWithdrawalsSingleControlOwnerFallbackDropped,
      checkedWithdrawalRequestAmount, minStethWithdrawalAmount,
      maxStethWithdrawalAmount]
  have hParent := h 7 0 minStethWithdrawalAmount 0 (by decide) hCommitted
  have hImpossible : (0 : Nat) = 7 := by
    simpa [resolvedOwner] using hParent.2.2
  omega

end LidoSRv3.Tests.WithdrawalQueueSingleRequestControlMutants
