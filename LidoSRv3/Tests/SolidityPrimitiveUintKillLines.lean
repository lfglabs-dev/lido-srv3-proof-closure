import LidoSRv3.Audit.Source.SolidityPrimitiveUintSource

/-! # Kill-lines for `SolidityPrimitiveUintSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
Solidity primitive uint type widths.** -/

namespace LidoSRv3.Tests.SolidityPrimitiveUintKillLines

open LidoSRv3.Audit.Source.SolidityPrimitiveUintSource

/-- **Kill-line: uintNMax = 2^width - 1.** -/
theorem uintNMax_formula (width : Nat) :
    uintNMax width = 2 ^ width - 1 := rfl

/-- **Kill-line: uintNModulus = 2^width.** -/
theorem uintNModulus_formula (width : Nat) :
    uintNModulus width = 2 ^ width := rfl

/-- **Kill-line: uintNMax pinned at various widths.** -/
theorem uint8Max_pinned : uintNMax 8 = 255 := by decide
theorem uint16Max_pinned : uintNMax 16 = 65535 := by decide
theorem uint32Max_pinned : uintNMax 32 = 4294967295 := by decide
theorem uint64Max_pinned : uintNMax 64 = 2^64 - 1 := by decide

/-- **Kill-line: toUint8 truncates at 256.** -/
theorem toUint8_wraps :
    toUint8 256 = 0 := by unfold toUint8 toUintN uintNModulus; decide

/-- **Kill-line: toUint8 identity within range.** -/
theorem toUint8_identity :
    toUint8 128 = 128 := by unfold toUint8 toUintN uintNModulus; decide

#print axioms uintNMax_formula
#print axioms uintNModulus_formula
#print axioms uint8Max_pinned
#print axioms uint16Max_pinned
#print axioms uint32Max_pinned
#print axioms uint64Max_pinned
#print axioms toUint8_wraps
#print axioms toUint8_identity

end LidoSRv3.Tests.SolidityPrimitiveUintKillLines
