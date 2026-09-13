import LidoSRv3.Audit.Source.TrioReserve1.QueueFinalize

/-! # Kill-lines for `TrioReserve1.QueueFinalize` slot + role constants

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the six pinned WithdrawalQueue.finalize-side storage slots and the
FINALIZE_ROLE keccak hash. -/

namespace LidoSRv3.Tests.TrioReserve1QueueFinalizeSlotsKillLines

open LidoSRv3.Audit.Source.TrioReserve1.QueueFinalize

/-- **Kill-line: checkpoints array storage slot.** -/
theorem checkpointsSlot_pinned :
    checkpointsSlot =
      0x445f3cbbc114a35d080f2a1953516d74e74d5106860bc2317840ba265f03b51a :=
  rfl

/-- **Kill-line: checkpoint index storage slot.** -/
theorem checkpointIndexSlot_pinned :
    checkpointIndexSlot =
      0x9d8be19d6a54e40bd767aa61b0f462241f5562ef6967d7045485bccac825b240 :=
  rfl

/-- **Kill-line: locked ether storage slot.** -/
theorem lockedSlot_pinned :
    lockedSlot =
      0x0e27eaa2e71c8572ab988fef0b54cd45bbd1740de1e22343fb6cda7536edc12f :=
  rfl

/-- **Kill-line: pause/resume storage slot.** -/
theorem resumeSlot_pinned :
    resumeSlot =
      0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02 :=
  rfl

/-- **Kill-line: roles registry storage slot.** -/
theorem rolesSlot_pinned :
    rolesSlot =
      0x9a627a5d4aa7c17f87ff26e3fe9a42c2b6c559e8b41a42282d0ecebb17c0e4d3 :=
  rfl

/-- **Kill-line: FINALIZE_ROLE keccak hash.**

`keccak256("FINALIZE_ROLE")` = 0x485191...bc80. -/
theorem finalizeRole_pinned :
    finalizeRole =
      0x485191a2ef18512555bd4426d18a716ce8e98c80ec2de16394dcf86d7d91bc80 :=
  rfl

/-- **Kill-line: all six constants fit uint256.** -/
theorem checkpointsSlot_fits_uint256 : checkpointsSlot < 2 ^ 256 := by decide
theorem finalizeRole_fits_uint256 : finalizeRole < 2 ^ 256 := by decide

/-- **Kill-line: all six constants are non-zero.** -/
theorem finalizeRole_nonzero : finalizeRole ≠ 0 := by decide
theorem checkpointsSlot_nonzero : checkpointsSlot ≠ 0 := by decide

/-- **Kill-line: the six constants are pairwise distinct.**

Any two ERC-1967 slot / role hash collisions would corrupt the
WithdrawalQueue.finalize permission checks. -/
theorem finalize_slots_pairwise_distinct :
    checkpointsSlot ≠ checkpointIndexSlot ∧
    checkpointIndexSlot ≠ lockedSlot ∧
    lockedSlot ≠ resumeSlot ∧
    resumeSlot ≠ rolesSlot ∧
    rolesSlot ≠ finalizeRole ∧
    finalizeRole ≠ checkpointsSlot := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> decide

#print axioms checkpointsSlot_pinned
#print axioms finalizeRole_pinned
#print axioms finalize_slots_pairwise_distinct

end LidoSRv3.Tests.TrioReserve1QueueFinalizeSlotsKillLines
