import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # WithdrawalQueue packed WithdrawalRequest struct decoder source model

**General rule (Thomas 2026-09-13, real derivation naming the pinned
WithdrawalQueueBase.WithdrawalRequest packed struct as source-level
field extractions.)**

The pinned WithdrawalQueueBase struct
```
struct WithdrawalRequest {
    uint128 cumulativeStETH;
    uint128 cumulativeShares;
    address owner;
    uint40  timestamp;
    bool    claimed;
    uint8   reportTimestampMargin;
}
```
packs into two uint256 slot words. This composition names each
field extraction as a source-level function of a `PackedSlotDecoder`
at the pinned bit offsets, so downstream ADDRESS-1 consumers can
route their request reads through named source-level functions
rather than an opaque `Nat`.

**Status:** first real derivation of the WithdrawalRequest struct
past its `readRequest` naming scaffold in
`WithdrawalQueueMappingSource`. -/

namespace LidoSRv3.Audit.Source.WQRequestPackedDecoderSource

open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-- First word: two uint128 fields (cumulativeStETH low, cumulativeShares high). -/
def cumulativeStETHBitOffset : Nat := 0
def cumulativeStETHBitWidth : Nat := 128
def cumulativeSharesBitOffset : Nat := 128
def cumulativeSharesBitWidth : Nat := 128

/-- Second word: owner (160), timestamp (40), claimed (8), margin (8). -/
def ownerBitOffset : Nat := 0
def ownerBitWidth : Nat := 160
def timestampBitOffset : Nat := 160
def timestampBitWidth : Nat := 40
def claimedBitOffset : Nat := 200
def claimedBitWidth : Nat := 8
def marginBitOffset : Nat := 208
def marginBitWidth : Nat := 8

/-- Source-level extractions of each WithdrawalRequest field. -/
def cumulativeStETHFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d cumulativeStETHBitOffset cumulativeStETHBitWidth

def cumulativeSharesFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d cumulativeSharesBitOffset cumulativeSharesBitWidth

def ownerFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d ownerBitOffset ownerBitWidth

def timestampFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d timestampBitOffset timestampBitWidth

def claimedFromPacked (d : PackedSlotDecoder) : Bool :=
  decide (decodeField d claimedBitOffset claimedBitWidth ≠ 0)

def marginFromPacked (d : PackedSlotDecoder) : Nat :=
  decodeField d marginBitOffset marginBitWidth

/-- Under the pinned nonzero-claimed-byte premise, the claimed flag
is true. Real derivation. -/
theorem claimedFromPacked_true_of_nonzero
    {d : PackedSlotDecoder}
    (hClaimed : d.extract claimedBitOffset claimedBitWidth ≠ 0) :
    claimedFromPacked d = true := by
  simp [claimedFromPacked, decodeField, hClaimed]

/-- Under the pinned zero-claimed-byte premise, the claimed flag is
false. Real derivation. -/
theorem claimedFromPacked_false_of_zero
    {d : PackedSlotDecoder}
    (hClaimed : d.extract claimedBitOffset claimedBitWidth = 0) :
    claimedFromPacked d = false := by
  simp [claimedFromPacked, decodeField, hClaimed]

end LidoSRv3.Audit.Source.WQRequestPackedDecoderSource
