import LidoSRv3.Audit.Source.StakeLimitStructDecoderSource

/-! # Kill-lines for `StakeLimitStructDecoderSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned 5-field StakeLimitStruct bit offsets and paused-byte
derivation.** -/

namespace LidoSRv3.Tests.StakeLimitStructDecoderKillLines

open LidoSRv3.Audit.Source.StakeLimitStructDecoderSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-- **Kill-line: prevStakeBlockNumber occupies bits 0..31 (uint32).**

Any mutant moving the offset or shrinking/growing the width would
refute the layout pin. -/
theorem prevStakeBlockNumber_offset : prevStakeBlockNumberBitOffset = 0 := rfl
theorem prevStakeBlockNumber_width  : prevStakeBlockNumberBitWidth = 32 := rfl

/-- **Kill-line: prevStakeLimit occupies bits 32..127 (uint96).** -/
theorem prevStakeLimit_offset : prevStakeLimitBitOffset = 32 := rfl
theorem prevStakeLimit_width  : prevStakeLimitBitWidth = 96 := rfl

/-- **Kill-line: maxStakeLimitGrowthBlocks occupies bits 128..159 (uint32).** -/
theorem maxStakeLimitGrowthBlocks_offset :
    maxStakeLimitGrowthBlocksBitOffset = 128 := rfl
theorem maxStakeLimitGrowthBlocks_width :
    maxStakeLimitGrowthBlocksBitWidth = 32 := rfl

/-- **Kill-line: maxStakeLimit occupies bits 160..255 (uint96).** -/
theorem maxStakeLimit_offset : maxStakeLimitBitOffset = 160 := rfl
theorem maxStakeLimit_width  : maxStakeLimitBitWidth = 96 := rfl

/-- **Kill-line: paused byte occupies bits 240..247 (uint8).** -/
theorem paused_offset : pausedBitOffset = 240 := rfl
theorem paused_width  : pausedBitWidth = 8 := rfl

/-- **Kill-line: `isStakingPausedFromStakeLimitStruct` = decide (pausedByte ≠ 0).**

A mutant that flipped the polarity or dropped the check would
refute this. -/
theorem isStakingPausedFromStakeLimitStruct_composition (d : PackedSlotDecoder) :
    isStakingPausedFromStakeLimitStruct d =
      decide (pausedByteFromPacked d ≠ 0) :=
  rfl

/-- Concrete zero-decoder witness: every field returns 0. -/
def zeroDecoder : PackedSlotDecoder :=
  { slotWord := 0, extract := fun _ _ => 0 }

/-- **Kill-line: zero-decoder gives isStakingPaused = false.** -/
theorem zeroDecoder_not_paused :
    isStakingPausedFromStakeLimitStruct zeroDecoder = false := by
  apply isStakingPausedFromStakeLimitStruct_false_of_zero
  rfl

/-- Concrete paused-decoder witness: paused byte at offset 240 is 1. -/
def pausedDecoder : PackedSlotDecoder :=
  { slotWord := 0
  , extract := fun off _ => if off = 240 then 1 else 0 }

/-- **Kill-line: with paused byte = 1, isStakingPaused = true.** -/
theorem pausedDecoder_paused :
    isStakingPausedFromStakeLimitStruct pausedDecoder = true := by
  unfold isStakingPausedFromStakeLimitStruct pausedByteFromPacked decodeField
  decide

#print axioms prevStakeBlockNumber_offset
#print axioms paused_offset
#print axioms paused_width
#print axioms isStakingPausedFromStakeLimitStruct_composition
#print axioms zeroDecoder_not_paused
#print axioms pausedDecoder_paused

end LidoSRv3.Tests.StakeLimitStructDecoderKillLines
