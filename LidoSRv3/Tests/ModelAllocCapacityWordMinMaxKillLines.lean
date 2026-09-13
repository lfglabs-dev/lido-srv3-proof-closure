import LidoSRv3.Audit.Model.AllocCapacity

/-! # Kill-lines for `Model.AllocCapacity.wordMax` and `wordMin`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-ALLOC-1 Model wordMax / wordMin Uint256 operations. -/

namespace LidoSRv3.Tests.ModelAllocCapacityWordMinMaxKillLines

open LidoSRv3.Audit.AllocCapacity
open Verity

/-- **Kill-line: `wordMax` composition.**

A mutant that swapped `≤` for `<` on ties would produce a different
outcome. -/
theorem wordMax_composition (a b : Uint256) :
    wordMax a b = if a ≤ b then b else a := rfl

/-- **Kill-line: `wordMin` composition.** -/
theorem wordMin_composition (a b : Uint256) :
    wordMin a b = if a ≤ b then a else b := rfl

/-- **Kill-line: `wordMax` is commutative on distinct inputs.** -/
theorem wordMax_5_10 : wordMax 5 10 = 10 := by decide
theorem wordMax_10_5 : wordMax 10 5 = 10 := by decide

/-- **Kill-line: `wordMin` picks the smaller.** -/
theorem wordMin_5_10 : wordMin 5 10 = 5 := by decide
theorem wordMin_10_5 : wordMin 10 5 = 5 := by decide

/-- **Kill-line: `wordMax a a = a` (idempotence).** -/
theorem wordMax_self (a : Uint256) : wordMax a a = a := by
  unfold wordMax; split <;> rfl

/-- **Kill-line: `wordMin a a = a` (idempotence).** -/
theorem wordMin_self (a : Uint256) : wordMin a a = a := by
  unfold wordMin; split <;> rfl

/-- **Kill-line: `wordMax 0 5 = 5` (concrete zero-left).** -/
theorem wordMax_0_5 : wordMax 0 5 = 5 := by decide

/-- **Kill-line: `wordMin 5 0 = 0` (concrete zero-right).** -/
theorem wordMin_5_0 : wordMin 5 0 = 0 := by decide

/-- **Kill-line: `wordMax` returns one of the inputs.** -/
theorem wordMax_case_split (a b : Uint256) :
    wordMax a b = a ∨ wordMax a b = b := by
  unfold wordMax
  split
  · exact Or.inr rfl
  · exact Or.inl rfl

/-- **Kill-line: `wordMin` returns one of the inputs.** -/
theorem wordMin_case_split (a b : Uint256) :
    wordMin a b = a ∨ wordMin a b = b := by
  unfold wordMin
  split
  · exact Or.inl rfl
  · exact Or.inr rfl

#print axioms wordMax_composition
#print axioms wordMin_composition
#print axioms wordMax_5_10
#print axioms wordMin_10_5
#print axioms wordMax_self
#print axioms wordMin_self
#print axioms wordMax_0_5
#print axioms wordMax_case_split

end LidoSRv3.Tests.ModelAllocCapacityWordMinMaxKillLines
