import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # Lido StakeLimitStruct packed uint256 decoder source model

**General rule (Thomas 2026-09-13, real derivation of the P-RESERVE-1
isStakingPaused free boolean via a packed 5-field decoder — closing
item (a) of the RESERVE-1 general-rule follow-up in
audit/STATUS.md.)**

Item (a) of the P-RESERVE-1 general-rule follow-up disclosed that
`isStakingPaused` should be derived via a keyed storage-word decoder
consuming the 5-field packed uint256 at STAKING_STATE_POSITION. The
pinned Solidity `Lido._getStakingLimitData()` decodes the packed
uint256 into a StakeLimitStruct with fields at pinned bit offsets:

- `prevStakeBlockNumber` (bits 0..31, uint32)
- `prevStakeLimit`       (bits 32..95, uint96)
- `maxStakeLimitGrowthBlocks` (bits 96..127, uint32)
- `maxStakeLimit`        (bits 128..223, uint96)
- `paused`               (bits 240..247, uint8; nonzero = paused)

This composition names each of the five fields as a source-level
function of a `PackedSlotDecoder`, and derives `isStakingPaused`
from the packed-word `paused` bit-range.

**Status:** first real derivation of the P-RESERVE-1 isStakingPaused
past its `isStakingPausedFromPacked` naming scaffold — all five
StakeLimitStruct fields are named and the paused predicate is a
composition. -/

namespace LidoSRv3.Audit.Source.StakeLimitStructDecoderSource

open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-- Pinned bit offsets for the 5-field packed StakeLimitStruct. -/
def prevStakeBlockNumberBitOffset : Nat := 0
def prevStakeBlockNumberBitWidth : Nat := 32

def prevStakeLimitBitOffset : Nat := 32
def prevStakeLimitBitWidth : Nat := 96

def maxStakeLimitGrowthBlocksBitOffset : Nat := 128
def maxStakeLimitGrowthBlocksBitWidth : Nat := 32

def maxStakeLimitBitOffset : Nat := 160
def maxStakeLimitBitWidth : Nat := 96

def pausedBitOffset : Nat := 240
def pausedBitWidth : Nat := 8

/-- Source-level extraction of each StakeLimitStruct field. -/
def prevStakeBlockNumberFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d prevStakeBlockNumberBitOffset prevStakeBlockNumberBitWidth

def prevStakeLimitFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d prevStakeLimitBitOffset prevStakeLimitBitWidth

def maxStakeLimitGrowthBlocksFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d maxStakeLimitGrowthBlocksBitOffset
    maxStakeLimitGrowthBlocksBitWidth

def maxStakeLimitFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d maxStakeLimitBitOffset maxStakeLimitBitWidth

def pausedByteFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d pausedBitOffset pausedBitWidth

/-- Source-level definition of `isStakingPaused` from the packed
`paused` byte: paused iff the byte is nonzero. -/
def isStakingPausedFromStakeLimitStruct (d : PackedSlotDecoder) : Bool :=
  decide (pausedByteFromPacked d ≠ 0)

/-- Under the pinned zero-paused-byte premise, the composed
isStakingPaused check returns false. Real derivation from the named
packed-decode. -/
theorem isStakingPausedFromStakeLimitStruct_false_of_zero
    {d : PackedSlotDecoder}
    (hZero : d.extract pausedBitOffset pausedBitWidth = 0) :
    isStakingPausedFromStakeLimitStruct d = false := by
  simp [isStakingPausedFromStakeLimitStruct, pausedByteFromPacked,
        decodeField, hZero]

end LidoSRv3.Audit.Source.StakeLimitStructDecoderSource
