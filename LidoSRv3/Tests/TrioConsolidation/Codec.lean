import audit.trio.consolidation.Codec

namespace LidoSRv3.Tests.TrioConsolidation.Codec

open audit.trio.consolidation
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.TopupBeaconEffects

private def blob (id : Nat) : Bytes := encode pubkeyLength id

/-- Reused `encode_decode_bytes`: a 48-byte blob round-trips through decode. -/
example : encode pubkeyLength (decode (blob 1)) = blob 1 :=
  encode_decode_bytes (blob 1)

/-- Distinct identities produce distinct physical 48-byte blobs. -/
example : blob 1 ≠ blob 2 := by native_decide

/-- Wrapping `1+2^384` encodes to the same 48 bytes as `1`. -/
example : blob 1 = encode pubkeyLength (1 + pubkeyModulus) := wrap_encode_eq

/-- Reconstructing a pubkey from those wrapping bytes is the same as from
the canonical blob. Distinct identities do not survive as two raw keys. -/
example : pubkeyOfBytes (encode pubkeyLength (1 + pubkeyModulus)) =
    pubkeyOfBytes (blob 1) := wrap_pubkeyOfBytes_eq

example : pubkeyOctets ⟨1 + pubkeyModulus, 48⟩ = none :=
  pubkeyOctets_none_unbounded ⟨1 + pubkeyModulus, 48⟩
    (Nat.not_lt.mpr (Nat.le_add_left pubkeyModulus 1))

example : pubkeyOctets (pubkeyOfBytes (blob 1)) ≠
    pubkeyOctets ⟨1 + pubkeyModulus, 48⟩ := by
  rw [pubkeyOctets_none_unbounded ⟨1 + pubkeyModulus, 48⟩
    (Nat.not_lt.mpr (Nat.le_add_left pubkeyModulus 1))]
  native_decide

/-- Actual 48-byte representation of a reconstructed key is those bytes. -/
example : (pubkeyOctets (pubkeyOfBytes (blob 11))).map (List.map UInt8.ofNat) =
    some (blob 11) :=
  pubkeyOctets_pubkeyOfBytes (blob 11) (ABI.encode_length _ _)

/-- Packed 96-byte callee payload is the concatenation of the two blobs. -/
example : (encodePackedRequest (pubkeyOfBytes (blob 11)) (pubkeyOfBytes (blob 21))).map
    (List.map UInt8.ofNat) = some (blob 11 ++ blob 21) :=
  encodePackedRequest_of_bytes (blob 11) (blob 21)
    (ABI.encode_length _ _) (ABI.encode_length _ _)

/-! Raw 48-octet adapter. Nat is derived from bytes; round-trip is
`encode_decode_bytes`. No Live CALL. -/

private def raw1 : Raw48 := toRaw48 (blob 1) (ABI.encode_length _ _)

/-- `encode(decode(raw48)) = raw48`. -/
example : encode pubkeyLength (raw48Nat raw1) = raw1.bytes :=
  encode_decode_Raw48 raw1

example : encode pubkeyLength (decode (blob 11)) = blob 11 :=
  encode_decode_raw48 (blob 11) (ABI.encode_length _ _)

/-- Leading-zero mutant: a non-zero first octet is not the width-48
encoding of the remaining 47-byte integer. -/
example :
    let tail : Bytes := List.replicate 47 1
    encode pubkeyLength (decode tail) ≠ (1 : UInt8) :: tail :=
  leading_zero_mutant (List.replicate 47 1) (by native_decide) 1 (by decide)

/-- Endian mutant: reversing a 48-byte blob with distinct ends changes Nat. -/
example :
    let raw : Bytes := encode pubkeyLength 1
    decode raw ≠ decode raw.reverse :=
  endian_mutant (encode pubkeyLength 1) (ABI.encode_length _ _) (by native_decide)

/-- Distinct 48-octet blobs derive distinct Nats. -/
example : decode (blob 1) ≠ decode (blob 2) :=
  raw48_nat_injective (ABI.encode_length _ _) (ABI.encode_length _ _) (by native_decide)

end LidoSRv3.Tests.TrioConsolidation.Codec
