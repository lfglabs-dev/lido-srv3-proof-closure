import LidoSRv3.Audit.MinFirstAllocation

/-! # Kill-lines for `MinFirstAllocation.Model` primitives

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned `MinFirstAllocationStrategy.allocateToBestCandidate`
Model helpers: `isOpen`, `leastCount`, `ceilDiv`. -/

namespace LidoSRv3.Tests.MinFirstAllocationModelKillLines

open LidoSRv3.Audit.MinFirstAllocation
open LidoSRv3.Audit.MinFirstAllocation.Model

/-- **Kill-line: `isOpen` = decide (allocation < capacity).**

A mutant that swapped `<` for `≤` would refute the pinned
"buckets[i] >= capacities[i]" continue-skip semantics. -/
theorem isOpen_composition (b : Bucket) :
    isOpen b = decide (b.allocation < b.capacity) := rfl

/-- **Kill-line: `isOpen` on full bucket is false.** -/
theorem isOpen_full : isOpen ⟨5, 5⟩ = false := by decide

/-- **Kill-line: `isOpen` on open bucket is true.** -/
theorem isOpen_open : isOpen ⟨2, 5⟩ = true := by decide

/-- **Kill-line: `isOpen` on over-full bucket is false.** -/
theorem isOpen_overfull : isOpen ⟨6, 5⟩ = false := by decide

/-- **Kill-line: `ceilDiv 0 d = 0` for any divisor.**

Zero-numerator base case; a mutant that returned 1 or the divisor
would refute. -/
theorem ceilDiv_zero (d : Nat) : ceilDiv 0 d = 0 := rfl

/-- **Kill-line: `ceilDiv 10 5 = 2` (exact division).** -/
theorem ceilDiv_exact : ceilDiv 10 5 = 2 := by decide

/-- **Kill-line: `ceilDiv 11 5 = 3` (rounds up).** -/
theorem ceilDiv_rounds_up : ceilDiv 11 5 = 3 := by decide

/-- **Kill-line: `leastCount` on empty list is 0.** -/
theorem leastCount_empty (least : Nat) :
    leastCount [] least = 0 := rfl

/-- **Kill-line: `leastCount` counts only open buckets at `least`.**

Two buckets at allocation 1 (both open), one at 2 (open), one full;
count at least=1 must be 2. -/
theorem leastCount_two_matching :
    leastCount [⟨1, 5⟩, ⟨2, 5⟩, ⟨1, 5⟩, ⟨5, 5⟩] 1 = 2 := by decide

/-- **Kill-line: full buckets don't contribute to leastCount.**

Two allocation=1 buckets, one full at 1/1. Only the open ones count. -/
theorem leastCount_ignores_full :
    leastCount [⟨1, 5⟩, ⟨1, 1⟩] 1 = 1 := by decide

#print axioms isOpen_composition
#print axioms isOpen_full
#print axioms ceilDiv_zero
#print axioms ceilDiv_exact
#print axioms ceilDiv_rounds_up
#print axioms leastCount_empty
#print axioms leastCount_two_matching
#print axioms leastCount_ignores_full

end LidoSRv3.Tests.MinFirstAllocationModelKillLines
