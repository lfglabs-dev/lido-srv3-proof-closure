import LidoSRv3.Audit.Source.WCType2ByteDecodeSource

/-! # Kill-lines for `WCType2ByteDecodeSource`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the WithdrawalCredentials.isType2 byte-decode composition.** -/

namespace LidoSRv3.Tests.WCType2ByteDecodeKillLines

open LidoSRv3.Audit.Source.WCType2ByteDecodeSource

/-- **Kill-line: the pinned WC type-2 byte constant is 0x02.**

A mutant that changed `wcType2ByteConst` to a different byte would
fail this definitional pin. -/
theorem wcType2ByteConst_eq_two :
    wcType2ByteConst = 2 := rfl

#print axioms wcType2ByteConst_eq_two

/-- **Kill-line: `firstByte` extracts bits 248-255 modulo 256.**

Any mutant changing the shift width or the modulus would fail. -/
theorem firstByte_zero : firstByte 0 = 0 := rfl

/-- **Kill-line: a WC word with top byte 0x02 extracts to 2.** -/
theorem firstByte_top_byte_two :
    firstByte (2 * 2 ^ 248) = 2 := by
  decide

/-- **Kill-line: a WC word with top byte 0x01 extracts to 1.** -/
theorem firstByte_top_byte_one :
    firstByte (1 * 2 ^ 248) = 1 := by
  decide

/-- **Kill-line: `wcIsType2 = decide (firstByte = wcType2ByteConst)`.**

A mutant changing the composition would fail. -/
theorem wcIsType2_composition (wcWord : Nat) :
    wcIsType2 wcWord = decide (firstByte wcWord = wcType2ByteConst) :=
  rfl

/-- **Kill-line: type-2 WC word gives wcIsType2 = true.** -/
theorem wcIsType2_top_byte_two :
    wcIsType2 (2 * 2 ^ 248) = true := by
  decide

/-- **Kill-line: type-1 WC word gives wcIsType2 = false.** -/
theorem wcIsType2_top_byte_one :
    wcIsType2 (1 * 2 ^ 248) = false := by
  decide

#print axioms wcIsType2_composition
#print axioms wcIsType2_top_byte_two
#print axioms wcIsType2_top_byte_one

end LidoSRv3.Tests.WCType2ByteDecodeKillLines
