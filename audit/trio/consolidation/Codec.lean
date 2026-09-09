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

/-! ## Raw 48-octet adapter

Codec only. `Bytes = List UInt8`. Nat is derived from the octets by
`Live.decode`; `TopupBeaconEffects.encode_decode_bytes` recovers the
blob: `encode(decode(raw48)) = raw48`. No Live CALL, no vault hop.
-/

/-- Actual 48-octet calldata blob. Identity is derived from the bytes. -/
structure Raw48 where
  bytes : Bytes
  length_eq : bytes.length = pubkeyLength

/-- Nat derived from the raw 48 octets (`Live.decode`, MSB first). -/
def raw48Nat (raw : Raw48) : Nat := decode raw.bytes

def toRaw48 (bytes : Bytes) (h : bytes.length = pubkeyLength) : Raw48 :=
  ⟨bytes, h⟩

/-- Adapter: a 48-octet blob is a `RawPubkey` whose identity is `decode`. -/
def raw48Pubkey (raw : Raw48) : Pubkey := pubkeyOfBytes raw.bytes

theorem raw48Pubkey_raw (raw : Raw48) : RawPubkey (raw48Pubkey raw) :=
  pubkeyOfBytes_raw raw.bytes raw.length_eq

/-- Reuse of `TopupBeaconEffects.lean:86 encode_decode_bytes` at width 48. -/
theorem encode_decode_raw48 (raw : Bytes) (h : raw.length = pubkeyLength) :
    encode pubkeyLength (decode raw) = raw := by
  have hround := encode_decode_bytes raw
  rwa [h] at hround

theorem encode_decode_Raw48 (raw : Raw48) :
    encode pubkeyLength (raw48Nat raw) = raw.bytes :=
  encode_decode_raw48 raw.bytes raw.length_eq

/-- `Live.encode` of an integer strictly below `256^47` has a leading zero
octet: the MSB of a 48-byte big-endian word is unused. -/
theorem encode48_head_zero {n : Nat} (h : n < 256 ^ (pubkeyLength - 1)) :
    (encode pubkeyLength n).head? = some 0 := by
  have hsucc : pubkeyLength = (pubkeyLength - 1) + 1 := by simp [pubkeyLength]
  have hdiv : n / 256 ^ (pubkeyLength - 1) = 0 := Nat.div_eq_of_lt h
  unfold encode
  rw [hsucc, List.range_succ_eq_map]
  simp [hdiv]

/-- Leading-zero mutant: width-48 padding is observable. Encoding the
integer of a 47-octet tail cannot produce a 48-octet blob whose first
byte is non-zero. -/
theorem leading_zero_mutant (tail : Bytes) (h : tail.length = pubkeyLength - 1)
    (b : UInt8) (hb : b ≠ 0) :
    encode pubkeyLength (decode tail) ≠ b :: tail := by
  intro heq
  have hsmall : decode tail < 256 ^ (pubkeyLength - 1) := by
    have := decode_lt tail
    rwa [h] at this
  have hzero := encode48_head_zero hsmall
  have hhead : (b :: tail).head? = some b := rfl
  have : some (0 : UInt8) = some b := by
    rw [← hzero, heq, hhead]
  exact hb (Option.some.inj this).symm

private theorem getLast?_eq_reverse_head? {α : Type _} (l : List α) :
    l.getLast? = l.reverse.head? := by
  induction l using List.reverseRecOn with
  | nil => rfl
  | append_singleton xs x => simp

/-- Endian mutant: reversing a 48-byte blob with distinct first/last
octets yields a different Nat, so it is a different key.
`encode_decode_bytes` recovers both orientations. -/
theorem endian_mutant (raw : Bytes) (h : raw.length = pubkeyLength)
    (hends : raw.head? ≠ raw.getLast?) :
    decode raw ≠ decode raw.reverse := by
  intro heq
  have hr : raw.reverse.length = pubkeyLength := by simp [h]
  have hraw := encode_decode_raw48 raw h
  have hrev := encode_decode_raw48 raw.reverse hr
  have hbytes : raw = raw.reverse :=
    hraw.symm.trans ((congrArg (encode pubkeyLength) heq).trans hrev)
  have : raw.head? = raw.getLast? :=
    (congrArg List.head? hbytes).trans (getLast?_eq_reverse_head? raw).symm
  exact hends this

/-- Distinct raw 48-octet blobs remain distinct after Nat derivation.
This is `encode_decode_bytes` instantiated at width 48. -/
theorem raw48_nat_injective {a b : Bytes}
    (ha : a.length = pubkeyLength) (hb : b.length = pubkeyLength)
    (hne : a ≠ b) : decode a ≠ decode b :=
  distinct_raw_bytes_distinct_identities ha hb hne

end audit.trio.consolidation
