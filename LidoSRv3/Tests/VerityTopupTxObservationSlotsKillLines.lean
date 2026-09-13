import LidoSRv3.Audit.Verity.TopupTx

/-! # Kill-lines for `Verity.TopupTx` observation slot constants

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the three pinned Verity-plane observation storage-slot constants
used to observe the top-up transaction boundary. -/

namespace LidoSRv3.Tests.VerityTopupTxObservationSlotsKillLines

open LidoSRv3.Audit.Verity.TopupTx

/-- **Kill-line: per-allocation observation slot base.** -/
theorem allocationSlot_pinned :
    allocationSlot = 7100 := rfl

/-- **Kill-line: allocation-total observation slot.** -/
theorem allocationTotalSlot_pinned :
    allocationTotalSlot = 7101 := rfl

/-- **Kill-line: pulled-total observation slot.** -/
theorem pulledTotalSlot_pinned :
    pulledTotalSlot = 7102 := rfl

/-- **Kill-line: the three slots are consecutive integers 7100..7102.** -/
theorem consecutive_slots :
    allocationTotalSlot = allocationSlot + 1 ∧
    pulledTotalSlot = allocationSlot + 2 := by
  refine ⟨rfl, rfl⟩

/-- **Kill-line: all three slots fit uint256.** -/
theorem allocationSlot_fits_uint256 : allocationSlot < 2 ^ 256 := by decide
theorem allocationTotalSlot_fits_uint256 : allocationTotalSlot < 2 ^ 256 := by decide
theorem pulledTotalSlot_fits_uint256 : pulledTotalSlot < 2 ^ 256 := by decide

/-- **Kill-line: the three slots are pairwise distinct.** -/
theorem observation_slots_distinct :
    allocationSlot ≠ allocationTotalSlot ∧
    allocationTotalSlot ≠ pulledTotalSlot ∧
    allocationSlot ≠ pulledTotalSlot := by
  refine ⟨?_, ?_, ?_⟩ <;> decide

#print axioms allocationSlot_pinned
#print axioms allocationTotalSlot_pinned
#print axioms pulledTotalSlot_pinned
#print axioms consecutive_slots
#print axioms observation_slots_distinct

end LidoSRv3.Tests.VerityTopupTxObservationSlotsKillLines
