import LidoSRv3.Audit.Source.ReserveRelationalCorrespondence

/-! # Kill-lines for `ReserveRelational.sourceRanges` request-id chaining

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned WithdrawalQueueBase.prefinalize request-id range
chaining, where each batch's start is the previous batch's end + 1. -/

namespace LidoSRv3.Tests.ReserveRelationalSourceRangesKillLines

open LidoSRv3.Audit.ReserveRelational

/-- **Kill-line: empty batch list yields no ranges.** -/
theorem sourceRanges_empty (cursor : Nat) :
    sourceRanges cursor [] = [] := rfl

/-- **Kill-line: singleton batch produces one range `(cursor+1, endRequestId)`.**

A mutant that shifted the cursor by any amount other than +1
would refute the pinned Solidity `lastFinalized + 1` shape. -/
theorem sourceRanges_singleton :
    sourceRanges 3 [⟨5, 100, 90, 5⟩] = [(4, 5)] := rfl

/-- **Kill-line: two-batch list chains from cursor via first-batch end.**

The second batch starts at first-batch end + 1 = 6. -/
theorem sourceRanges_two_batches :
    sourceRanges 3 [⟨5, 100, 90, 5⟩, ⟨10, 200, 180, 10⟩]
      = [(4, 5), (6, 10)] := rfl

/-- **Kill-line: cursor 0 corner case still produces (1, end).** -/
theorem sourceRanges_zero_cursor :
    sourceRanges 0 [⟨2, 100, 90, 5⟩] = [(1, 2)] := rfl

/-- **Kill-line: length is preserved from input batches to output ranges.** -/
theorem sourceRanges_length_zero (cursor : Nat) :
    (sourceRanges cursor []).length = 0 := rfl

theorem sourceRanges_length_singleton (cursor : Nat) (batch : Batch) :
    (sourceRanges cursor [batch]).length = 1 := rfl

/-- **Kill-line: three-batch chain uses each end as next-cursor.**

Cursor 3 → 5 (from batch 1) → 10 (from batch 2). -/
theorem sourceRanges_three_batches :
    sourceRanges 3
        [⟨5, 100, 90, 5⟩, ⟨10, 200, 180, 10⟩, ⟨15, 300, 270, 15⟩]
      = [(4, 5), (6, 10), (11, 15)] := rfl

#print axioms sourceRanges_empty
#print axioms sourceRanges_singleton
#print axioms sourceRanges_two_batches
#print axioms sourceRanges_zero_cursor
#print axioms sourceRanges_three_batches

end LidoSRv3.Tests.ReserveRelationalSourceRangesKillLines
