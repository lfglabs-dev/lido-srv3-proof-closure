import LidoSRv3.Audit.Model.ReserveRelational

/-! # Kill-lines for `Model.ReserveRelational.lookupBatch` and `batchEth`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the abstract-plane batch-lookup and discount-selection semantics
that the P-RESERVE-RELATIONAL Source/Verity planes are proved
against. -/

namespace LidoSRv3.Tests.ModelReserveRelationalLookupKillLines

open LidoSRv3.Audit.ReserveRelational

/-- **Kill-line: `lookupBatch []` is always none.** -/
theorem lookupBatch_empty (id : Nat) :
    lookupBatch [] id = none := rfl

/-- **Kill-line: singleton batch matches on `endRequestId`.**

A mutant using a different projection to compare would refute. -/
theorem lookupBatch_singleton_hit :
    lookupBatch [⟨42, 100, 90, 5⟩] 42 = some ⟨42, 100, 90, 5⟩ := rfl

/-- **Kill-line: singleton batch misses when id differs.** -/
theorem lookupBatch_singleton_miss :
    lookupBatch [⟨42, 100, 90, 5⟩] 41 = none := by decide

/-- **Kill-line: two-batch first-match wins.** -/
theorem lookupBatch_first_match :
    lookupBatch [⟨3, 100, 90, 5⟩, ⟨5, 200, 180, 10⟩] 3
      = some ⟨3, 100, 90, 5⟩ := rfl

/-- **Kill-line: two-batch fall-through to second when first misses.** -/
theorem lookupBatch_second_match :
    lookupBatch [⟨3, 100, 90, 5⟩, ⟨5, 200, 180, 10⟩] 5
      = some ⟨5, 200, 180, 10⟩ := by decide

/-- **Kill-line: `batchEth false` picks `nominalEth`.** -/
theorem batchEth_nominal :
    batchEth false ⟨42, 100, 90, 5⟩ = 100 := rfl

/-- **Kill-line: `batchEth true` picks `discountedEth`.** -/
theorem batchEth_discounted :
    batchEth true ⟨42, 100, 90, 5⟩ = 90 := rfl

/-- **Kill-line: `batchEth` swaps the two Eth fields on the discount flag.** -/
theorem batchEth_flag_swaps
    (batch : Batch) :
    batchEth true batch = batch.discountedEth ∧
    batchEth false batch = batch.nominalEth := ⟨rfl, rfl⟩

#print axioms lookupBatch_empty
#print axioms lookupBatch_singleton_hit
#print axioms lookupBatch_first_match
#print axioms lookupBatch_second_match
#print axioms batchEth_nominal
#print axioms batchEth_discounted
#print axioms batchEth_flag_swaps

end LidoSRv3.Tests.ModelReserveRelationalLookupKillLines
