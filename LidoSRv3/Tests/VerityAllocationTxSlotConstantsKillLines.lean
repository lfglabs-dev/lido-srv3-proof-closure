import LidoSRv3.Audit.Verity.AllocationTx

/-! # Kill-lines for `Verity.AllocationTx` slot constants + totalStake selector

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Verity-plane AllocationTx storage-slot constants and the
`getTotalModuleStake()` ABI selector against source-model mutants. -/

namespace LidoSRv3.Tests.VerityAllocationTxSlotConstantsKillLines

open LidoSRv3.Audit.Verity.AllocationTx

/-- **Kill-line: SR modules count storage slot.** -/
theorem modulesCountSlot_pinned : modulesCountSlot = 29 := rfl

/-- **Kill-line: module id storage slot.** -/
theorem moduleIdSlot_pinned : moduleIdSlot = 30 := rfl

/-- **Kill-line: module config storage slot.** -/
theorem moduleConfigSlot_pinned : moduleConfigSlot = 31 := rfl

/-- **Kill-line: accounting-exited storage slot.** -/
theorem accountingExitedSlot_pinned : accountingExitedSlot = 35 := rfl

/-- **Kill-line: summary storage slots 36..39.** -/
theorem summaryExitedSlot_pinned : summaryExitedSlot = 36 := rfl
theorem summaryDepositedSlot_pinned : summaryDepositedSlot = 37 := rfl
theorem summaryDepositableSlot_pinned : summaryDepositableSlot = 38 := rfl
theorem summaryStakeSlot_pinned : summaryStakeSlot = 39 := rfl

/-- **Kill-line: allocation/capacity/bound/total storage slots 40..43.** -/
theorem allocationSlot_pinned : allocationSlot = 40 := rfl
theorem capacitySlot_pinned : capacitySlot = 41 := rfl
theorem boundAddressSlot_pinned : boundAddressSlot = 42 := rfl
theorem totalSlot_pinned : totalSlot = 43 := rfl

/-- **Kill-line: `getTotalModuleStake()` ABI selector.** -/
theorem totalStakeSelector_pinned :
    totalStakeSelector = 0x0c852f5c := rfl

/-- **Kill-line: selector fits uint32.** -/
theorem totalStakeSelector_fits_uint32 :
    totalStakeSelector < 2 ^ 32 := by decide

/-- **Kill-line: return-data length pin (uint256 = 32 bytes).** -/
theorem totalStakeReturnBytes_pinned :
    totalStakeReturnBytes = 32 := rfl

/-- **Kill-line: calldata payload matches the selector byte-by-byte.** -/
theorem totalStakeCalldata_pinned :
    totalStakeCalldata = [0x0c, 0x85, 0x2f, 0x5c] := rfl

/-- **Kill-line: summary slots are pairwise distinct from each other.** -/
theorem summary_slots_distinct :
    summaryExitedSlot ≠ summaryDepositedSlot ∧
    summaryDepositedSlot ≠ summaryDepositableSlot ∧
    summaryDepositableSlot ≠ summaryStakeSlot := by
  refine ⟨?_, ?_, ?_⟩ <;> decide

#print axioms modulesCountSlot_pinned
#print axioms summary_slots_distinct
#print axioms totalStakeSelector_pinned
#print axioms totalStakeCalldata_pinned

end LidoSRv3.Tests.VerityAllocationTxSlotConstantsKillLines
