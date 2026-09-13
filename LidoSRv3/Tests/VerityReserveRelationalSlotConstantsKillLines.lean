import LidoSRv3.Audit.Verity.ReserveRelationalTx

/-! # Kill-lines for `Verity.ReserveRelationalTx` slot constants

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the ten Verity-plane storage-slot constants used by the executable
Reserve.prefinalize/finalize path against source-model mutations. -/

namespace LidoSRv3.Tests.VerityReserveRelationalSlotConstantsKillLines

open LidoSRv3.Audit.Verity.ReserveRelationalTx

/-- **Kill-line: `batchEndsBase` = 0x1000.** -/
theorem batchEndsBase_pinned : batchEndsBase = 0x1000 := rfl

/-- **Kill-line: single-word slot indices 60..69 are consecutive.** -/
theorem lastFinalizedSlot_pinned : lastFinalizedSlot = 60 := rfl
theorem pausedSlot_pinned : pausedSlot = 61 := rfl
theorem bufferSlot_pinned : bufferSlot = 62 := rfl
theorem lockedEtherSlot_pinned : lockedEtherSlot = 63 := rfl
theorem depositsReserveSlot_pinned : depositsReserveSlot = 64 := rfl
theorem batchExistsSlot_pinned : batchExistsSlot = 65 := rfl
theorem batchNominalSlot_pinned : batchNominalSlot = 66 := rfl
theorem batchDiscountedSlot_pinned : batchDiscountedSlot = 67 := rfl
theorem batchSharesSlot_pinned : batchSharesSlot = 68 := rfl
theorem prefinalizedHiSlot_pinned : prefinalizedHiSlot = 69 := rfl

/-- **Kill-line: pairwise distinctness of a few key slot indices.**

A mutant that collapsed two consecutive slots (e.g. paused vs
buffer) would corrupt every downstream read. -/
theorem paused_ne_buffer : pausedSlot ≠ bufferSlot := by decide
theorem buffer_ne_lockedEther : bufferSlot ≠ lockedEtherSlot := by decide
theorem lockedEther_ne_depositsReserve :
    lockedEtherSlot ≠ depositsReserveSlot := by decide

/-- **Kill-line: batchEndsBase is disjoint from the single-word slot region.**

Mapping to 0x1000 for the array data offset avoids collision with
the low-index single-word slots 60..69. -/
theorem batchEndsBase_disjoint_from_slots :
    prefinalizedHiSlot < batchEndsBase := by decide

#print axioms batchEndsBase_pinned
#print axioms lastFinalizedSlot_pinned
#print axioms prefinalizedHiSlot_pinned
#print axioms paused_ne_buffer
#print axioms batchEndsBase_disjoint_from_slots

end LidoSRv3.Tests.VerityReserveRelationalSlotConstantsKillLines
