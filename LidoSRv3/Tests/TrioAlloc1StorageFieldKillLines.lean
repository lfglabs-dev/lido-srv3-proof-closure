import LidoSRv3.Audit.Source.TrioAlloc1.Storage

/-! # Kill-lines for `TrioAlloc1.Storage.field` bit-extraction

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned SR ModuleStateConfig packed-storage bit-field extraction:
address20 @0..159, share @192..207, status @224..231, wcType @232..239. -/

namespace LidoSRv3.Tests.TrioAlloc1StorageFieldKillLines

open LidoSRv3.Audit.Source.TrioAlloc1

/-- **Kill-line: `field packed offset width = packed.val / 2^offset % 2^width`.**

A mutant that changed the shift direction or modulus would corrupt
every packed-storage read. -/
theorem field_composition (packed : Word) (offset width : Nat) :
    field packed offset width =
      packed.val / 2 ^ offset % 2 ^ width := rfl

/-- **Kill-line: `field 0 0 8 = 0` (zero word, first byte).** -/
theorem field_zero_first_byte :
    field (word 0) 0 8 = 0 := by decide

/-- **Kill-line: `field 42 0 160 = 42` for small address.** -/
theorem field_small_address :
    field (word 42) 0 160 = 42 := by decide

/-- **Kill-line: `field (2*2^232) 232 8 = 2` (WC type-2 byte).** -/
theorem field_wc_type_two :
    field (word (2 * 2 ^ 232)) 232 8 = 2 := by decide

/-- **Kill-line: `field (255*2^224) 224 8 = 255` (status byte 0xFF).** -/
theorem field_status_max :
    field (word (255 * 2 ^ 224)) 224 8 = 255 := by decide

/-- **Kill-line: `field (0x1234 * 2^192) 192 16 = 0x1234` (share uint16).** -/
theorem field_share_pinned :
    field (word (0x1234 * 2 ^ 192)) 192 16 = 0x1234 := by decide

#print axioms field_composition
#print axioms field_zero_first_byte
#print axioms field_small_address
#print axioms field_wc_type_two
#print axioms field_status_max
#print axioms field_share_pinned

end LidoSRv3.Tests.TrioAlloc1StorageFieldKillLines
