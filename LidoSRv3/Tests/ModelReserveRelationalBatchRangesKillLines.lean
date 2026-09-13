import LidoSRv3.Audit.Model.ReserveRelational

/-! # Kill-lines for `Model.ReserveRelational.batchRanges` and `requestedRange`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the abstract-plane batch-range chaining and requested-range
projection semantics. -/

namespace LidoSRv3.Tests.ModelReserveRelationalBatchRangesKillLines

open LidoSRv3.Audit.ReserveRelational

/-- **Kill-line: `batchRanges` on empty list yields nothing.** -/
theorem batchRanges_empty (cursor : Nat) :
    batchRanges cursor [] = [] := rfl

/-- **Kill-line: singleton batch produces one range with cursor+1 start.** -/
theorem batchRanges_singleton :
    batchRanges 3 [⟨5, 100, 90, 5⟩] = [(4, 5)] := rfl

/-- **Kill-line: two-batch chain uses first-batch end as next cursor.**

The second batch starts at first-end + 1 = 6. -/
theorem batchRanges_two_batches :
    batchRanges 3 [⟨5, 100, 90, 5⟩, ⟨10, 200, 180, 10⟩]
      = [(4, 5), (6, 10)] := rfl

/-- **Kill-line: zero-cursor produces (1, end).** -/
theorem batchRanges_zero_cursor :
    batchRanges 0 [⟨2, 100, 90, 5⟩] = [(1, 2)] := rfl

/-- **Kill-line: three-batch chain preserves per-batch structure.**

Cursor 3 → 5 → 10 → 15. -/
theorem batchRanges_three_batches :
    batchRanges 3
        [⟨5, 100, 90, 5⟩, ⟨10, 200, 180, 10⟩, ⟨15, 300, 270, 15⟩]
      = [(4, 5), (6, 10), (11, 15)] := rfl

/-- **Kill-line: `requestedRange` with empty batchEnds returns none.** -/
theorem requestedRange_empty (queue : Queue) :
    requestedRange queue ⟨[], false⟩ = none := rfl

/-- **Kill-line: `requestedRange` last-id = single batchEnd.** -/
theorem requestedRange_singleton :
    requestedRange ⟨3, [], false⟩ ⟨[5], false⟩ = some (4, 5) := rfl

/-- **Kill-line: `requestedRange` last-id picks the last element (not first).** -/
theorem requestedRange_two_ends :
    requestedRange ⟨0, [], false⟩ ⟨[3, 5], false⟩ = some (1, 5) := rfl

#print axioms batchRanges_empty
#print axioms batchRanges_singleton
#print axioms batchRanges_two_batches
#print axioms batchRanges_three_batches
#print axioms requestedRange_empty
#print axioms requestedRange_singleton
#print axioms requestedRange_two_ends

end LidoSRv3.Tests.ModelReserveRelationalBatchRangesKillLines
