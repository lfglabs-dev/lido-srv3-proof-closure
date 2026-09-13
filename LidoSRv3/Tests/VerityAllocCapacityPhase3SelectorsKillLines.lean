import LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-! # Kill-lines for `Verity.AllocCapacityPhase3` selectors and return-length

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the phase-3 SRLib `_getStakingModuleSummary` ABI selector, its
byte-decomposition, and the pinned return-data length. -/

namespace LidoSRv3.Tests.VerityAllocCapacityPhase3SelectorsKillLines

open LidoSRv3.Audit.Verity.AllocCapacityPhase3

/-- **Kill-line: pinned `_getStakingModuleSummary` selector.**

`bytes4(keccak256("_getStakingModuleSummary(uint256)"))` = 0x9abddf09. -/
theorem summarySelector_pinned :
    summarySelector = 0x9abddf09 := rfl

/-- **Kill-line: pinned entrySelector.** -/
theorem entrySelector_pinned :
    entrySelector = 0x6a70ca02 := rfl

/-- **Kill-line: byte 0 of summary selector = 0x9a.** -/
theorem selectorByte_zero : selectorByte 0 = 0x9a := by decide

/-- **Kill-line: byte 1 of summary selector = 0xbd.** -/
theorem selectorByte_one : selectorByte 1 = 0xbd := by decide

/-- **Kill-line: byte 2 of summary selector = 0xdf.** -/
theorem selectorByte_two : selectorByte 2 = 0xdf := by decide

/-- **Kill-line: byte 3 of summary selector = 0x09.** -/
theorem selectorByte_three : selectorByte 3 = 0x09 := by decide

/-- **Kill-line: summary return-data length is 96 bytes (three uint256
words for `exitedValidators`, `depositedValidators`, `depositableCount`).** -/
theorem summaryReturnBytes_pinned :
    summaryReturnBytes = 96 := rfl

/-- **Kill-line: summary calldata byte-by-byte = big-endian selector.** -/
theorem summaryCalldata_pinned :
    summaryCalldata = [0x9a, 0xbd, 0xdf, 0x09] := by decide

/-- **Kill-line: summary and entry selectors are distinct.** -/
theorem selectors_distinct :
    summarySelector ≠ entrySelector := by decide

/-- **Kill-line: summary selector fits uint32.** -/
theorem summarySelector_fits_uint32 :
    summarySelector < 2 ^ 32 := by decide

#print axioms summarySelector_pinned
#print axioms entrySelector_pinned
#print axioms selectorByte_zero
#print axioms summaryReturnBytes_pinned
#print axioms summaryCalldata_pinned
#print axioms selectors_distinct

end LidoSRv3.Tests.VerityAllocCapacityPhase3SelectorsKillLines
