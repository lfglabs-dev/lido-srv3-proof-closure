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

end LidoSRv3.Tests.TrioConsolidation.Codec
