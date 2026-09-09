import audit.trio.consolidation.Producer

namespace LidoSRv3.Tests.TrioConsolidation.Producer

open audit.trio.consolidation
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.TrioReserve1.ABI

private def blob (id : Nat) : Bytes := encode pubkeyLength id

private def pair11_21 : ProducedPair :=
  { source := blob 11, target := blob 21 }

private def groups : List WitnessGroupBytes :=
  [⟨[blob 11, blob 12], blob 21⟩, ⟨[blob 13], blob 22⟩]

/-- ABI `bytes` framing round-trips a 48-octet producer blob. -/
example : decodeBytesElement (encodeBytesElement (blob 11)) = some (blob 11) :=
  decode_encode_bytes_element (blob 11) (by
    have : (blob 11).length = 48 := encode_length _ _
    simp [this])

/-- Flattening the byte producer is the gateway pair order. -/
example : preparePairBytes groups =
    [⟨blob 11, blob 21⟩, ⟨blob 12, blob 21⟩, ⟨blob 13, blob 22⟩] := by
  native_decide

/-- Derived Nats come from the producer blobs, not an independent choice. -/
example : preparePairs (groups.map toWitnessGroup) =
    (preparePairBytes groups).map fun p =>
      (pubkeyOfBytes p.source, pubkeyOfBytes p.target) :=
  preparePairs_of_producer groups

/-- Width-48 source/target checks are `Raw48`. -/
example : widthOk pair11_21 := by
  constructor <;> exact encode_length _ _

example : RawPubkey (raw48Pubkey (sourceRaw48 pair11_21 (by
    constructor <;> exact encode_length _ _))) :=
  widthOk_source_is_raw48 pair11_21 (by constructor <;> exact encode_length _ _)

example : RawPubkey (raw48Pubkey (targetRaw48 pair11_21 (by
    constructor <;> exact encode_length _ _))) :=
  widthOk_target_is_raw48 pair11_21 (by constructor <;> exact encode_length _ _)

/-- Length-47 source fails the vault width check. -/
example : ¬ widthOk { source := List.replicate 47 1, target := blob 21 } := by
  native_decide

/-- Packed vault payload is source++target (`WithdrawalVaultEIP7685.sol:114`). -/
example :
    (encodePackedRequest
        (raw48Pubkey (sourceRaw48 pair11_21 (by constructor <;> exact encode_length _ _)))
        (raw48Pubkey (targetRaw48 pair11_21 (by constructor <;> exact encode_length _ _)))).map
      (List.map UInt8.ofNat) =
      some (blob 11 ++ blob 21) :=
  vaultCallPayload_is_packed pair11_21 (by constructor <;> exact encode_length _ _)

example : (vaultCallPayload pair11_21).length = 96 :=
  widthOk_payload_length pair11_21 (by constructor <;> exact encode_length _ _)

/-- ByteArray framing is the same physical blob. -/
example :
    ofByteArray (ByteArray.mk (blob 11).toArray) = blob 11 := by
  native_decide

end LidoSRv3.Tests.TrioConsolidation.Producer
