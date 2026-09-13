import LidoSRv3.Audit.Model.AllocCapacity

/-! # Kill-lines for `Model.AllocCapacity.ceilDiv?` division-by-zero

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the OpenZeppelin `Math.ceilDiv` semantics: zero divisor rejected,
composition otherwise. -/

namespace LidoSRv3.Tests.ModelAllocCapacityCeilDivKillLines

open LidoSRv3.Audit.AllocCapacity
open Verity

/-- **Kill-line: `ceilDiv?` on zero divisor returns none.**

Solidity `Math.ceilDiv` reverts on zero divisor; a mutant that
returned `some 0` would silently absorb DIV/0 in the pinned target
formula. -/
theorem ceilDiv_zero_divisor (a : Uint256) :
    ceilDiv? a 0 = none := rfl

/-- **Kill-line: `ceilDiv?` on non-zero divisor is `some (ceilDiv _ _)`.** -/
theorem ceilDiv_nonzero (a b : Uint256) (h : b ≠ 0) :
    ceilDiv? a b = some (Verity.Stdlib.Math.ceilDiv a b) := by
  unfold ceilDiv?
  simp [h]

/-- **Kill-line: `ceilDiv? 0 1 = some 0`.** -/
theorem ceilDiv_zero_over_one : ceilDiv? 0 1 = some 0 := by decide

/-- **Kill-line: `ceilDiv? 10 5 = some 2` (exact division).** -/
theorem ceilDiv_ten_five : ceilDiv? 10 5 = some 2 := by decide

/-- **Kill-line: `ceilDiv? 11 5 = some 3` (rounds up).** -/
theorem ceilDiv_eleven_five : ceilDiv? 11 5 = some 3 := by decide

/-- **Kill-line: `ceilDiv? 1 1 = some 1`.** -/
theorem ceilDiv_one_one : ceilDiv? 1 1 = some 1 := by decide

/-- **Kill-line: `ceilDiv? 0 5 = some 0` (zero numerator).** -/
theorem ceilDiv_zero_five : ceilDiv? 0 5 = some 0 := by decide

#print axioms ceilDiv_zero_divisor
#print axioms ceilDiv_nonzero
#print axioms ceilDiv_zero_over_one
#print axioms ceilDiv_ten_five
#print axioms ceilDiv_eleven_five
#print axioms ceilDiv_one_one
#print axioms ceilDiv_zero_five

end LidoSRv3.Tests.ModelAllocCapacityCeilDivKillLines
