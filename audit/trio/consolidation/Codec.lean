import audit.trio.consolidation.Spec
import LidoSRv3.Audit.Source.TopupBeaconEffects
import LidoSRv3.Audit.Source.TrioReserve1.ABI

/-!
# Actual 48-byte pubkey codec (reuse `encode_decode_bytes`)

The independent trio `integerBE` / `pubkeyOctets` model is the Nat-list view of
a calldata BLS key. This file is the byte-level correspondence with the
already-proved source codec
`LidoSRv3.Audit.Source.TopupBeaconEffects.encode_decode_bytes`:

* `Live.encode` / `Live.decode` are the physical octet maps;
* `encode_decode_bytes` recovers an arbitrary byte blob from its integer
  decode, so distinct 48-byte keys cannot share an identity;
* wrapping `identity + 2^384` is the same *unrestricted* encoding as
  `identity`, but `pubkeyOfBytes` of those octets yields the canonical
  representative `< 2^384`.

Pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
This file does not close P-CONSOLIDATION and does not import SSZ/site/DEPOSIT.
-/

namespace audit.trio.consolidation

open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.TopupBeaconEffects

/-- Trio `integerBE` is the Nat-list view of `Live.encode`. -/
theorem integerBE_as_bytes (size n : Nat) :
    (integerBE size n).map UInt8.ofNat = encode size n := by
  induction size generalizing n with
  | zero => rfl
  | succ size ih =>
      change
        (integerBE size (n / 256) ++ [n % 256]).map UInt8.ofNat =
          encode (size + 1) n
      rw [List.map_append, ABI.encode_succ, ih]
      rfl

/-- A physical byte string decodes below `256^length`. -/
theorem decode_lt (bytes : Bytes) : decode bytes < 256 ^ bytes.length := by
  induction bytes using List.reverseRecOn with
  | nil => simp [decode]
  | append_singleton bytes b ih =>
      rw [ABI.decode_append_byte, List.length_append, List.length_singleton,
        Nat.pow_succ]
      have hb : b.toNat < 256 := b.toNat_lt
      omega

/-- Reconstruct a trio pubkey from actual calldata bytes. Identity is the
integer of those bytes; length is the blob width. -/
def pubkeyOfBytes (bytes : Bytes) : Pubkey :=
  { identity := decode bytes, length := bytes.length }

/-- Any actual 48-byte blob is a `RawPubkey`: Solidity's length check plus
the 384-bit bound that a 48-octet integer occupies. -/
theorem pubkeyOfBytes_raw (bytes : Bytes) (h : bytes.length = pubkeyLength) :
    RawPubkey (pubkeyOfBytes bytes) := by
  refine ⟨h, ?_⟩
  unfold pubkeyModulus
  rw [← h]
  exact decode_lt bytes

/-- Reuse of `encode_decode_bytes`: the 48-byte representation of a pubkey
built from actual bytes is those bytes. Distinct blobs cannot collapse. -/
theorem pubkeyOctets_pubkeyOfBytes (bytes : Bytes)
    (h : bytes.length = pubkeyLength) :
    (pubkeyOctets (pubkeyOfBytes bytes)).map (List.map UInt8.ofNat) =
      some bytes := by
  have hraw := pubkeyOfBytes_raw bytes h
  rw [pubkeyOctets_some (pubkeyOfBytes bytes) hraw]
  apply congrArg some
  have hround := encode_decode_bytes bytes
  rw [h] at hround
  exact (integerBE_as_bytes pubkeyLength (decode bytes)).trans hround

/-- Distinct actual 48-byte blobs have distinct identities. This is the
modulo-collision control at the physical codec: `encode_decode_bytes`
recovers the original octets, so `decode a = decode b` would imply `a = b`. -/
theorem distinct_raw_bytes_distinct_identities {a b : Bytes}
    (ha : a.length = pubkeyLength) (hb : b.length = pubkeyLength)
    (hne : a ≠ b) :
    (pubkeyOfBytes a).identity ≠ (pubkeyOfBytes b).identity := by
  intro heq
  apply hne
  have ea := encode_decode_bytes a
  have eb := encode_decode_bytes b
  rw [ha] at ea
  rw [hb] at eb
  calc
    a = encode pubkeyLength (decode a) := ea.symm
    _ = encode pubkeyLength (decode b) := by
          change decode a = decode b at heq
          rw [heq]
    _ = b := eb

/-- Unrestricted physical encoding wraps: `1` and `1+2^384` are the same
48 bytes (Nat-list `integerBE_wraps` transported by `integerBE_as_bytes`). -/
theorem wrap_encode_eq :
    encode pubkeyLength 1 = encode pubkeyLength (1 + pubkeyModulus) := by
  have h := congrArg (List.map UInt8.ofNat) (integerBE_wraps pubkeyLength 1)
  rw [integerBE_as_bytes, integerBE_as_bytes] at h
  exact h

theorem wrap_pubkeyOfBytes_eq :
    pubkeyOfBytes (encode pubkeyLength (1 + pubkeyModulus)) =
      pubkeyOfBytes (encode pubkeyLength 1) :=
  congrArg pubkeyOfBytes wrap_encode_eq.symm

/-- 96-byte callee payload from two actual 48-byte keys, matching
`abi.encodePacked(sourcePubkey, targetPubkey)`. -/
theorem encodePackedRequest_of_bytes (source target : Bytes)
    (hs : source.length = pubkeyLength) (ht : target.length = pubkeyLength) :
    (encodePackedRequest (pubkeyOfBytes source) (pubkeyOfBytes target)).map
      (List.map UInt8.ofNat) = some (source ++ target) := by
  have hsrc := pubkeyOctets_pubkeyOfBytes source hs
  have htgt := pubkeyOctets_pubkeyOfBytes target ht
  cases hso : pubkeyOctets (pubkeyOfBytes source) with
  | none => simp [hso] at hsrc
  | some src =>
    cases hto : pubkeyOctets (pubkeyOfBytes target) with
    | none => simp [hto] at htgt
    | some tgt =>
        simp [encodePackedRequest, hso, hto] at hsrc htgt ⊢
        rw [hsrc, htgt]

end audit.trio.consolidation
