import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # WithdrawalQueue Checkpoint packed struct decoder source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
WithdrawalQueueBase.Checkpoint packed struct as source-level field
extractions.)**

The pinned WithdrawalQueueBase Checkpoint struct
```
struct Checkpoint {
    uint256 fromRequestId;
    uint256 maxShareRate;
}
```
occupies two 256-bit words, each carrying a single uint256 field.
This composition names each field extraction as a source-level
function of a `PackedSlotDecoder`, so downstream ADDRESS-1 claim
consumers can route their checkpoint reads through named source-
level functions rather than an opaque `Nat`.

**Status:** first real derivation of the Checkpoint struct past its
`readCheckpoint` naming scaffold in `WithdrawalQueueMappingSource`. -/

namespace LidoSRv3.Audit.Source.WQCheckpointPackedDecoderSource

open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-- First word: `fromRequestId` uint256 (occupies the entire word). -/
def fromRequestIdBitOffset : Nat := 0
def fromRequestIdBitWidth : Nat := 256

/-- Second word: `maxShareRate` uint256 (occupies the entire word). -/
def maxShareRateBitOffset : Nat := 0
def maxShareRateBitWidth : Nat := 256

/-- Source-level extraction of `fromRequestId` from the first
Checkpoint word. -/
def fromRequestIdFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d fromRequestIdBitOffset fromRequestIdBitWidth

/-- Source-level extraction of `maxShareRate` from the second
Checkpoint word. -/
def maxShareRateFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d maxShareRateBitOffset maxShareRateBitWidth

/-- The extracted `fromRequestId` equals the decoder's extract at
the pinned bit range, definitionally. -/
theorem fromRequestIdFromPacked_eq (d : PackedSlotDecoder) :
    fromRequestIdFromPacked d =
      d.extract fromRequestIdBitOffset fromRequestIdBitWidth :=
  rfl

/-- The extracted `maxShareRate` equals the decoder's extract at
the pinned bit range, definitionally. -/
theorem maxShareRateFromPacked_eq (d : PackedSlotDecoder) :
    maxShareRateFromPacked d =
      d.extract maxShareRateBitOffset maxShareRateBitWidth :=
  rfl

end LidoSRv3.Audit.Source.WQCheckpointPackedDecoderSource
