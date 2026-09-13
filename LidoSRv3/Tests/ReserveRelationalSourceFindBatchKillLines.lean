import LidoSRv3.Audit.Source.ReserveRelationalCorrespondence

/-! # Kill-lines for `ReserveRelational.sourceFindBatch` and `sourceSum`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned WithdrawalQueueBase.prefinalize batch-lookup and
per-batch discounted/nominal ETH summation semantics. -/

namespace LidoSRv3.Tests.ReserveRelationalSourceFindBatchKillLines

open LidoSRv3.Audit.ReserveRelational

/-- **Kill-line: empty batch list yields none for every id.** -/
theorem sourceFindBatch_empty (id : Nat) :
    sourceFindBatch id [] = none := rfl

/-- **Kill-line: singleton batch matches on its endRequestId.**

A mutant using a wrong field for comparison would refute. -/
theorem sourceFindBatch_singleton_hit :
    sourceFindBatch 42 [⟨42, 100, 90, 5⟩] = some ⟨42, 100, 90, 5⟩ := rfl

/-- **Kill-line: singleton batch misses when the id differs.** -/
theorem sourceFindBatch_singleton_miss :
    sourceFindBatch 41 [⟨42, 100, 90, 5⟩] = none := by decide

/-- **Kill-line: two-batch list stops at the first match.**

A mutant that continued past the first match or reordered the
scan would refute. -/
theorem sourceFindBatch_two_first_hit :
    sourceFindBatch 3 [⟨3, 100, 90, 5⟩, ⟨5, 200, 180, 10⟩]
      = some ⟨3, 100, 90, 5⟩ := rfl

/-- **Kill-line: two-batch list falls through to second.** -/
theorem sourceFindBatch_two_second_hit :
    sourceFindBatch 5 [⟨3, 100, 90, 5⟩, ⟨5, 200, 180, 10⟩]
      = some ⟨5, 200, 180, 10⟩ := by decide

/-- **Kill-line: `sourceSum false` picks the nominalEth field.** -/
theorem sourceSum_nominal :
    sourceSum false [⟨3, 100, 90, 5⟩, ⟨5, 200, 180, 10⟩] = 300 := by decide

/-- **Kill-line: `sourceSum true` picks the discountedEth field.** -/
theorem sourceSum_discounted :
    sourceSum true [⟨3, 100, 90, 5⟩, ⟨5, 200, 180, 10⟩] = 270 := by decide

/-- **Kill-line: `sourceSum` on empty is zero regardless of discount flag.** -/
theorem sourceSum_empty_nominal : sourceSum false [] = 0 := rfl
theorem sourceSum_empty_discounted : sourceSum true [] = 0 := rfl

/-- **Kill-line: `sourceShareSum` accumulates the shares field.** -/
theorem sourceShareSum_two :
    sourceShareSum [⟨3, 100, 90, 5⟩, ⟨5, 200, 180, 10⟩] = 15 := by decide

/-- **Kill-line: `sourceShareSum` on empty is zero.** -/
theorem sourceShareSum_empty : sourceShareSum [] = 0 := rfl

#print axioms sourceFindBatch_empty
#print axioms sourceFindBatch_singleton_hit
#print axioms sourceFindBatch_two_first_hit
#print axioms sourceSum_nominal
#print axioms sourceSum_discounted
#print axioms sourceShareSum_two

end LidoSRv3.Tests.ReserveRelationalSourceFindBatchKillLines
