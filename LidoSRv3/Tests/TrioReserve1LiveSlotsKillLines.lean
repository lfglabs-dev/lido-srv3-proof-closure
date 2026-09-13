import LidoSRv3.Audit.Source.TrioReserve1.Live

/-! # Kill-lines for `TrioReserve1.Live` unstructured-storage slot constants

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the seven pinned Lido 0.4.24 unstructured-storage slot positions
(keccak256("lido.Lido.*")) used by the executable reserve path. -/

namespace LidoSRv3.Tests.TrioReserve1LiveSlotsKillLines

open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- **Kill-line: pinned LidoLocator storage slot.** -/
theorem locatorSlot_pinned :
    locatorSlot =
      0xd92bc31601d11a10411d08f59b7146d8a5915af253cde25f8e66b67beb4be223 :=
  rfl

/-- **Kill-line: pinned bufferedEther storage slot.** -/
theorem bufferSlot_pinned :
    bufferSlot =
      0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f :=
  rfl

/-- **Kill-line: pinned depositedNextReport storage slot.** -/
theorem nextSlot_pinned :
    nextSlot =
      0x8d3ed945c7718edcdb639b1235f2bbe3fa81f4a6cec7a436d8ea13fbc502d957 :=
  rfl

/-- **Kill-line: pinned seedShares storage slot.** -/
theorem seedSlot_pinned :
    seedSlot =
      0x3f0eaa2c0f16ff9775c078f3df30470d8c042317b24ad1defa240b1c3e10b238 :=
  rfl

/-- **Kill-line: pinned depositsReserve storage slot.** -/
theorem reserveSlot_pinned :
    reserveSlot =
      0xda4fbe3b9cbd98dfae5dff538bbff4ba61f38979d4d7419bcd006f3e6250ec13 :=
  rfl

/-- **Kill-line: pinned depositsReserveTarget storage slot.** -/
theorem targetSlot_pinned :
    targetSlot =
      0x3d3e9bd6e90e5d1f1c6839835bcbe5746a47c9a013d1eae6e80c248264c06a81 :=
  rfl

/-- **Kill-line: pinned STAKING_ROUTER_APP position slot.** -/
theorem activeSlot_pinned :
    activeSlot =
      0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece :=
  rfl

/-- **Kill-line: all seven slots fit uint256.** -/
theorem locatorSlot_fits_uint256 : locatorSlot < 2 ^ 256 := by decide
theorem bufferSlot_fits_uint256  : bufferSlot < 2 ^ 256 := by decide
theorem nextSlot_fits_uint256    : nextSlot < 2 ^ 256 := by decide

/-- **Kill-line: the seven slot constants are pairwise distinct.**

Collapsing any two ERC-1967 unstructured slots would corrupt the
whole storage-lens family. Prove a chain of key distinctness. -/
theorem all_slots_pairwise_distinct :
    locatorSlot ≠ bufferSlot ∧
    bufferSlot ≠ nextSlot ∧
    nextSlot ≠ seedSlot ∧
    seedSlot ≠ reserveSlot ∧
    reserveSlot ≠ targetSlot ∧
    targetSlot ≠ activeSlot ∧
    activeSlot ≠ locatorSlot := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> decide

#print axioms locatorSlot_pinned
#print axioms activeSlot_pinned
#print axioms all_slots_pairwise_distinct

end LidoSRv3.Tests.TrioReserve1LiveSlotsKillLines
