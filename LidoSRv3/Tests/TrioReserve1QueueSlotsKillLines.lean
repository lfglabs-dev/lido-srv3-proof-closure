import LidoSRv3.Audit.Source.TrioReserve1.Queue

/-! # Kill-lines for `TrioReserve1.Queue` unstructured-storage slot constants

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the four pinned WithdrawalQueue.sol unstructured-storage slot
positions used by the executable reserve path. -/

namespace LidoSRv3.Tests.TrioReserve1QueueSlotsKillLines

open LidoSRv3.Audit.Source.TrioReserve1.Queue

/-- **Kill-line: pinned WithdrawalQueue main-array storage slot.** -/
theorem queueSlot_pinned :
    queueSlot =
      0xe21b95c4eb1b99fd548b219e3b5c175a8efb31f910cb76456b20e14eba8cfe43 :=
  rfl

/-- **Kill-line: pinned lastRequestId storage slot.** -/
theorem lastSlot_pinned :
    lastSlot =
      0x8ee26abbbdf533de3953ccf2204279e845eecb5ab51f8398522746e4ea068041 :=
  rfl

/-- **Kill-line: pinned lastFinalizedRequestId storage slot.** -/
theorem finalizedSlot_pinned :
    finalizedSlot =
      0x992f2e0c24ce59a21f2dab8bba13b25c2f872129df7f4d45372155e717db0c48 :=
  rfl

/-- **Kill-line: pinned bunker-mode storage slot.** -/
theorem bunkerSlot_pinned :
    bunkerSlot =
      0x1450eb8d0693284079f6627b2c1c6bb2e076066e44df1b18ba6ea7cc507e9bcb :=
  rfl

/-- **Kill-line: all four slots fit uint256.** -/
theorem queueSlot_fits_uint256 : queueSlot < 2 ^ 256 := by decide
theorem lastSlot_fits_uint256 : lastSlot < 2 ^ 256 := by decide
theorem finalizedSlot_fits_uint256 : finalizedSlot < 2 ^ 256 := by decide
theorem bunkerSlot_fits_uint256 : bunkerSlot < 2 ^ 256 := by decide

/-- **Kill-line: all four slots are non-zero.** -/
theorem queueSlot_nonzero : queueSlot ≠ 0 := by decide
theorem lastSlot_nonzero : lastSlot ≠ 0 := by decide
theorem finalizedSlot_nonzero : finalizedSlot ≠ 0 := by decide
theorem bunkerSlot_nonzero : bunkerSlot ≠ 0 := by decide

/-- **Kill-line: the four slot constants are pairwise distinct.**

Collapsing any two ERC-1967 slots would corrupt the storage lenses. -/
theorem queue_slots_pairwise_distinct :
    queueSlot ≠ lastSlot ∧
    lastSlot ≠ finalizedSlot ∧
    finalizedSlot ≠ bunkerSlot ∧
    bunkerSlot ≠ queueSlot := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> decide

#print axioms queueSlot_pinned
#print axioms bunkerSlot_pinned
#print axioms queue_slots_pairwise_distinct

end LidoSRv3.Tests.TrioReserve1QueueSlotsKillLines
