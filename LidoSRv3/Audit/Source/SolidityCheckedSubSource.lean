/-! # Solidity SafeMath.sub / 0.8-checked subtraction source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
Solidity SafeMath.sub / 0.8-checked subtraction semantics as a
source-level function.)**

Solidity 0.4/0.5/0.6 `SafeMath.sub(a, b)` requires `b ≤ a` and
returns `a - b`; otherwise reverts. Solidity 0.8+ has this
behavior built-in for unsigned arithmetic. Multiple pinned code
paths use `sub` (Lido `_setBufferedEther(_getBufferedEther().sub(
_amount))`, allocation loops in StakingRouter, etc.).

This composition names the pinned checked-sub semantics as a
source-level function: `checkedSub a b` returns `some (a - b)` when
`b ≤ a`, `none` otherwise. The rev-detection predicate
`checkedSubUnderflow a b = decide (a < b)` marks the pinned revert
branch.

**Status:** first real derivation of the shared Solidity checked-
subtraction semantics. Downstream consumers (Lido _seedDepositsCount
buffered write, allocation loops) can compose through this to
eliminate Nat.sub's silent-clamping behavior. -/

namespace LidoSRv3.Audit.Source.SolidityCheckedSubSource

/-- Checked-sub predicate: revert-detection is `a < b`. -/
def checkedSubUnderflow (a b : Nat) : Bool :=
  decide (a < b)

/-- Optional-result checked sub: `some (a-b)` when `b ≤ a`, else
`none`. -/
def checkedSub (a b : Nat) : Option Nat :=
  if a < b then none else some (a - b)

/-- Under the pinned `b ≤ a` premise, checked-sub returns some (a - b). -/
theorem checkedSub_some_of_le
    {a b : Nat} (hLe : b ≤ a) :
    checkedSub a b = some (a - b) := by
  simp [checkedSub]
  omega

/-- Under the pinned `a < b` premise, checked-sub returns none (revert). -/
theorem checkedSub_none_of_lt
    {a b : Nat} (hLt : a < b) :
    checkedSub a b = none := by
  simp [checkedSub, hLt]

/-- Under the pinned `b ≤ a` premise, the underflow predicate is false. -/
theorem checkedSubUnderflow_false_of_le
    {a b : Nat} (hLe : b ≤ a) :
    checkedSubUnderflow a b = false := by
  simp [checkedSubUnderflow]
  omega

/-- Under the pinned `a < b` premise, the underflow predicate is true. -/
theorem checkedSubUnderflow_true_of_lt
    {a b : Nat} (hLt : a < b) :
    checkedSubUnderflow a b = true := by
  simp [checkedSubUnderflow, hLt]

end LidoSRv3.Audit.Source.SolidityCheckedSubSource
