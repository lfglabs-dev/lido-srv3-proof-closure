import audit.trio.consolidation.Codec

/-!
# Producer-to-payload (not Live CALL)

The executor/gateway input is grouped `bytes[]` (`ConsolidationBus.sol:383-390`
reconstructs publisher groups from `groups[i].sourcePubkeys` and
`groups[i].targetWitness.pubkey`; `ConsolidationGateway.sol:216-220` /
`_prepareConsolidationPairs` at 348-365 flattens those blobs into the vault
arrays). Each element is a physical `Bytes` blob (`List UInt8`), equivalently
a `ByteArray`; the identity Nat is derived by `Live.decode`. It is not chosen
independently.

Vault `_validatePublicKey` (`WithdrawalVaultEIP7685.sol:97-101`) is the width
check `pubkey.length == 48`. Success implies the existing `Raw48` adapter.

The vault-call payload of `_callAddConsolidationRequest` is
`abi.encodePacked(sourcePubkey, targetPubkey)`
(`WithdrawalVaultEIP7685.sol:113-120` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`). That
concatenation is the input to the existing packed encoder
`encodePackedRequest_of_bytes`.

Callee, world, rollback, log, refund, and Live CALL remain OPEN.
This file does not close P-CONSOLIDATION and does not reopen codec lemmas.
-/

namespace audit.trio.consolidation

open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.TrioReserve1.ABI

/-! ## List / ByteArray calldata framing

A dynamic `bytes` ABI element is a 32-byte big-endian length word followed by
the payload (`arrayElementDynamicDataOffset` returns the first data byte; the
preceding word is the length). The producer consumes that payload, not a Nat.
-/

/-- ABI `bytes` element: length word then payload. -/
def encodeBytesElement (payload : Bytes) : Bytes :=
  encode 32 payload.length ++ payload

/-- Inverse of `encodeBytesElement` on a well-framed blob. -/
def decodeBytesElement (framed : Bytes) : Option Bytes :=
  if _hlen : 32 ≤ framed.length then
    let len := decode (framed.take 32)
    let rest := framed.drop 32
    if _hrest : len ≤ rest.length then some (rest.take len) else none
  else none

/-- Round-trip of the ABI `bytes` framing. Length fits in one word. -/
theorem decode_encode_bytes_element (payload : Bytes)
    (hfit : payload.length < 256 ^ 32) :
    decodeBytesElement (encodeBytesElement payload) = some payload := by
  unfold decodeBytesElement encodeBytesElement
  have henc : (encode 32 payload.length).length = 32 := encode_length 32 payload.length
  have hlen : 32 ≤ (encode 32 payload.length ++ payload).length := by
    rw [List.length_append, henc]; omega
  rw [dif_pos hlen]
  have htake :
      (encode 32 payload.length ++ payload).take 32 = encode 32 payload.length :=
    List.take_left' henc
  have hdrop : (encode 32 payload.length ++ payload).drop 32 = payload :=
    List.drop_left' henc
  simp only [htake, hdrop]
  have hdec : decode (encode 32 payload.length) = payload.length :=
    decode_encode_bounded 32 payload.length hfit
  have hrest : decode (encode 32 payload.length) ≤ payload.length := by
    rw [hdec]
  rw [dif_pos hrest, hdec, List.take_of_length_le (Nat.le_refl _)]

/-- ByteArray view of the same physical `bytes` blob (`data.toList`). -/
def ofByteArray (ba : ByteArray) : Bytes := ba.data.toList

theorem ofByteArray_length (ba : ByteArray) :
    (ofByteArray ba).length = ba.size := by
  simp [ofByteArray, ByteArray.size_data]

/-! ## Executor / gateway byte producer -/

/-- One flattened vault pair, still as calldata blobs. -/
structure ProducedPair where
  source : Bytes
  target : Bytes
  deriving DecidableEq, Repr

/-- Grouped executor/gateway input: `bytes[] sourcePubkeys` plus the target
`bytes` from `targetWitness.pubkey`. -/
structure WitnessGroupBytes where
  sources : List Bytes
  target : Bytes
  deriving DecidableEq, Repr

/-- `_prepareConsolidationPairs` on the physical blobs
(`ConsolidationGateway.sol:348-365`). -/
def preparePairBytes (groups : List WitnessGroupBytes) : List ProducedPair :=
  groups.flatMap fun group =>
    group.sources.map fun source => { source := source, target := group.target }

/-- Derive the Nat-identity `Pubkey` from the producer blob. -/
def toWitnessGroup (g : WitnessGroupBytes) : WitnessGroup :=
  { sources := g.sources.map pubkeyOfBytes, target := pubkeyOfBytes g.target }

/-- Flattening the byte producer and then deriving Nats is `preparePairs` of
the derived groups. The Nats are not independently chosen. -/
private theorem map_produced_pairs (sources : List Bytes) (target : Bytes) :
    (sources.map fun source => ({ source := source, target := target } : ProducedPair)).map
        (fun p => (pubkeyOfBytes p.source, pubkeyOfBytes p.target)) =
      sources.map fun source => (pubkeyOfBytes source, pubkeyOfBytes target) := by
  induction sources with
  | nil => rfl
  | cons _ rest ih => simp [ih]

theorem preparePairs_of_producer (groups : List WitnessGroupBytes) :
    preparePairs (groups.map toWitnessGroup) =
      (preparePairBytes groups).map fun p =>
        (pubkeyOfBytes p.source, pubkeyOfBytes p.target) := by
  induction groups with
  | nil => rfl
  | cons g rest ih =>
      change
        ((g.sources.map pubkeyOfBytes).map fun source =>
            (source, pubkeyOfBytes g.target)) ++
          preparePairs (rest.map toWitnessGroup) =
        ((g.sources.map fun source =>
            ({ source := source, target := g.target } : ProducedPair)) ++
          preparePairBytes rest).map
            fun p => (pubkeyOfBytes p.source, pubkeyOfBytes p.target)
      rw [List.map_append, map_produced_pairs, List.map_map, ih]
      rfl

/-! ## Width check ⇒ Raw48

`_validatePublicKey` (`WithdrawalVaultEIP7685.sol:97-101`):
`if (pubkey.length != PUBLIC_KEY_LENGTH) revert InvalidPublicKeyLength(pubkey);`
with `PUBLIC_KEY_LENGTH = 48`.
-/

def widthOk (pair : ProducedPair) : Prop :=
  pair.source.length = pubkeyLength ∧ pair.target.length = pubkeyLength

instance (pair : ProducedPair) : Decidable (widthOk pair) :=
  inferInstanceAs
    (Decidable (pair.source.length = pubkeyLength ∧ pair.target.length = pubkeyLength))

/-- Successful source width check is the `Raw48` adapter. -/
def sourceRaw48 (pair : ProducedPair) (h : widthOk pair) : Raw48 :=
  toRaw48 pair.source h.1

/-- Successful target width check is the `Raw48` adapter. -/
def targetRaw48 (pair : ProducedPair) (h : widthOk pair) : Raw48 :=
  toRaw48 pair.target h.2

theorem widthOk_source_is_raw48 (pair : ProducedPair) (h : widthOk pair) :
    RawPubkey (raw48Pubkey (sourceRaw48 pair h)) :=
  raw48Pubkey_raw _

theorem widthOk_target_is_raw48 (pair : ProducedPair) (h : widthOk pair) :
    RawPubkey (raw48Pubkey (targetRaw48 pair h)) :=
  raw48Pubkey_raw _

/-- ByteArray width check is the same 48-octet obligation. -/
def widthOkBA (source target : ByteArray) : Prop :=
  source.size = pubkeyLength ∧ target.size = pubkeyLength

theorem widthOkBA_ofByteArray (source target : ByteArray)
    (h : widthOkBA source target) :
    widthOk { source := ofByteArray source, target := ofByteArray target } := by
  refine ⟨?_, ?_⟩
  · simpa [ofByteArray_length] using h.1
  · simpa [ofByteArray_length] using h.2

/-! ## Vault-call payload (`WithdrawalVaultEIP7685.sol:113-120`)

```
function _callAddConsolidationRequest(
    bytes calldata sourcePubkey, bytes calldata targetPubkey, uint256 fee
) internal {
    bytes memory request = abi.encodePacked(sourcePubkey, targetPubkey);
    (bool success,) = CONSOLIDATION_REQUEST.call{value: fee}(request);
    if (!success) { revert RequestAdditionFailed(request); }
    emit ConsolidationRequestAdded(request);
}
```

Only the `encodePacked` concatenation is consumed here. The CALL, revert,
event, fee, and world are OPEN.
-/

/-- Concrete packed payload: source octets then target octets. -/
def vaultCallPayload (pair : ProducedPair) : Bytes :=
  pair.source ++ pair.target

theorem widthOk_payload_length (pair : ProducedPair) (h : widthOk pair) :
    (vaultCallPayload pair).length = 96 := by
  simp [vaultCallPayload, h.1, h.2, pubkeyLength]

/-- The existing packed encoder, fed the producer concatenation, recovers
`source ++ target`. Reuses `encodePackedRequest_of_bytes`; does not reopen
it. -/
theorem vaultCallPayload_is_packed (pair : ProducedPair) (h : widthOk pair) :
    (encodePackedRequest
        (raw48Pubkey (sourceRaw48 pair h))
        (raw48Pubkey (targetRaw48 pair h))).map (List.map UInt8.ofNat) =
      some (vaultCallPayload pair) :=
  encodePackedRequest_of_bytes pair.source pair.target h.1 h.2

/-- Same statement from ByteArray producer blobs. -/
theorem vaultCallPayload_is_packed_byteArray (source target : ByteArray)
    (h : widthOkBA source target) :
    let pair : ProducedPair :=
      { source := ofByteArray source, target := ofByteArray target }
    (encodePackedRequest
        (raw48Pubkey (sourceRaw48 pair (widthOkBA_ofByteArray source target h)))
        (raw48Pubkey (targetRaw48 pair (widthOkBA_ofByteArray source target h)))).map
      (List.map UInt8.ofNat) =
      some (ofByteArray source ++ ofByteArray target) :=
  vaultCallPayload_is_packed
    { source := ofByteArray source, target := ofByteArray target }
    (widthOkBA_ofByteArray source target h)

end audit.trio.consolidation
