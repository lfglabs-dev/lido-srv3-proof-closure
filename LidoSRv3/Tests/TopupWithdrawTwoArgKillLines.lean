import LidoSRv3.Audit.Source.TopupWithdrawTwoArgSource

/-! # Kill-lines for `TopupWithdrawTwoArgSource`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned two-argument `withdrawDepositableEther(amount, 0)`
calldata shape (grok #414 D-CALL-1 chantier-2 disclosure).** -/

namespace LidoSRv3.Tests.TopupWithdrawTwoArgKillLines

open LidoSRv3.Audit.Source.TopupWithdrawTwoArgSource

/-- **Kill-line: `withdrawArgs total` has exactly 2 words.**

A mutant that dropped or added a word would refute the pinned
`withdrawDepositableEther(amount, 0)` shape. -/
theorem withdrawArgs_length_pin (total : Nat) :
    (withdrawArgs total).length = 2 :=
  withdrawArgs_length total

/-- **Kill-line: first word = amount.**

A mutant that swapped positions or hard-coded the amount would refute. -/
theorem withdrawArgs_first_pin (total : Nat) :
    (withdrawArgs total)[0]? = some total :=
  withdrawArgs_first total

/-- **Kill-line: second word = 0 (the hard-coded Solidity uint256).**

A mutant that changed the second slot to a nonzero constant would
refute the pinned two-argument shape. -/
theorem withdrawArgs_second_pin (total : Nat) :
    (withdrawArgs total)[1]? = some 0 :=
  withdrawArgs_second total

/-- **Kill-line: withdrawArgs 42 = [42, 0] concretely.**

A definitional pin exhibiting the full 2-word list. -/
theorem withdrawArgs_forty_two :
    withdrawArgs 42 = [42, 0] := rfl

/-- **Kill-line: withdrawArgs 0 = [0, 0] concretely.**

Even the zero-amount call carries two words. -/
theorem withdrawArgs_zero :
    withdrawArgs 0 = [0, 0] := rfl

#print axioms withdrawArgs_length_pin
#print axioms withdrawArgs_first_pin
#print axioms withdrawArgs_second_pin
#print axioms withdrawArgs_forty_two
#print axioms withdrawArgs_zero

end LidoSRv3.Tests.TopupWithdrawTwoArgKillLines
