import LidoSRv3.Audit.Source.SRModulePackedDecoderSource

/-! # Kill-lines for `SRModulePackedDecoderSource`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the SR packed moduleId bit-range extraction and moduleExists
composition.** -/

namespace LidoSRv3.Tests.SRModulePackedDecoderKillLines

open LidoSRv3.Audit.Source.SRModulePackedDecoderSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-- **Kill-line: pinned moduleId bit offset is 0.**

A mutant that moved the offset would refute the layout pin. -/
theorem moduleId_offset : moduleIdBitOffset = 0 := rfl

/-- **Kill-line: pinned moduleId bit width is 24 (uint24).** -/
theorem moduleId_width : moduleIdBitWidth = 24 := rfl

/-- **Kill-line: `moduleIdFromPacked` extracts `moduleIdBitOffset ..
moduleIdBitWidth` via `decodeField`.**

A mutant swapping offset/width or bypassing decodeField would refute. -/
theorem moduleIdFromPacked_composition (d : PackedSlotDecoder) :
    moduleIdFromPacked d =
      decodeField d moduleIdBitOffset moduleIdBitWidth :=
  rfl

/-- **Kill-line: `moduleExistsFromPacked` = decide (moduleId ≠ 0).**

A mutant that flipped polarity would refute. -/
theorem moduleExists_composition (d : PackedSlotDecoder) :
    moduleExistsFromPacked d =
      decide (moduleIdFromPacked d ≠ 0) :=
  rfl

/-- Concrete decoder returning 0 for every extract. -/
def zeroDecoder : PackedSlotDecoder :=
  { slotWord := 0, extract := fun _ _ => 0 }

/-- **Kill-line: zero-decoder → moduleExists = false.** -/
theorem zeroDecoder_no_module :
    moduleExistsFromPacked zeroDecoder = false := by
  unfold moduleExistsFromPacked moduleIdFromPacked decodeField
  decide

/-- Concrete decoder returning 42 at (0, 24) and 0 elsewhere. -/
def moduleFortyTwoDecoder : PackedSlotDecoder :=
  { slotWord := 0
  , extract := fun off w => if off = 0 ∧ w = 24 then 42 else 0 }

/-- **Kill-line: moduleId 42 → moduleExists = true.** -/
theorem moduleFortyTwoDecoder_exists :
    moduleExistsFromPacked moduleFortyTwoDecoder = true := by
  unfold moduleExistsFromPacked moduleIdFromPacked decodeField
  decide

#print axioms moduleId_offset
#print axioms moduleId_width
#print axioms moduleIdFromPacked_composition
#print axioms moduleExists_composition
#print axioms zeroDecoder_no_module
#print axioms moduleFortyTwoDecoder_exists

end LidoSRv3.Tests.SRModulePackedDecoderKillLines
