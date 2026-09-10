import audit.trio.consolidation.LiveCall

/-!
# Gateway→vault ABI hop (`ConsolidationGateway.sol:220`)

```
IWithdrawalVault(VAULT).addConsolidationRequests{value: totalFee}(
    sourcePubkeys, targetPubkeys);
```

The gateway's committed `VaultHop` (`Gateway.lean`) carries the flattened
`bytes[]` pair arrays as packed 96-octet payloads. This file is the ABI hop
between the two contracts: the Solidity ABI calldata framing of
`addConsolidationRequests(bytes[], bytes[])`, a decoder that follows the
head and element offsets the way Solidity's calldata decoder does, the
round-trip theorem that decoding the encoded hop returns exactly the producer
blobs `_prepareConsolidationPairs` flattened (`Producer.preparePairBytes`),
and the vault entrypoint *on that calldata* (`executeVaultCalldata`): the
vault consumes the ABI-framed payload, not a private packing. Zipping the
decoded arrays is the vault's `pairsOf` input of `LiveCall.lean`.

## ABI layout (Solidity ABI specification, `bytes[]` = dynamic array of the
dynamic type `bytes`)

Argument block of `(bytes[], bytes[])`:

| octets | content |
| --- | --- |
| `0..32` | head offset of the first array (`64`) |
| `32..64` | head offset of the second array (`64 + |first tail|`) |
| `64..` | first tail, then second tail |

Tail of one `bytes[]` with `n` elements (`abiBytesArray`):

| octets | content |
| --- | --- |
| `0..32` | `n` |
| `32..32+32n` | one offset word per element, relative to octet `32` of the tail |
| then | element `i`: 32-octet length word, payload, zero padding to a multiple of 32 |

For two 48-octet keys per array: each element is `32 + 64 = 96` octets, each
tail `32 + 2·32 + 2·96 = 288` octets, the second head offset is `352`
(`0x160`), and the argument block is `640` octets. (The previous encoder of
this file omitted the offset table and the padding and produced 448 octets;
the #295 review of head `94ef159c` reported that defect. It is repaired
here.)

## Decoder discipline

`decodeVaultArgs` follows the two head offsets, then for each array reads
the count word and, per element, the offset word and the element's length
word and payload, exactly as the calldata accessors Solidity emits for
`bytes[] calldata` (`sourcePubkeys[i]`): out-of-range offsets, a count whose
offset table does not fit, and a length that exceeds the remaining calldata
are refused. Like Solidity, the decoder does not check that offsets are
canonical (strictly increasing, contiguous) nor that padding octets are
zero; it accepts every canonical encoding, so it accepts the calldata the
gateway's line-220 call actually puts on the wire.

Residuals (stated, not claimed):

* The 4-octet function selector is a parameter; keccak256 of the signature
  is outside this model. `executeVaultCalldata` compares the calldata prefix
  against that parameter.
* Solidity validates `bytes[] calldata` elements lazily at each
  `sourcePubkeys[i]` / `targetPubkeys[i]` access inside the line-68 loop,
  i.e. after the fee STATICCALL and the exact-fee check; the model decodes
  every element before the body runs. Both revert the whole call, so the
  committed state is identical, but on malformed calldata the fault name and
  the attempt trace preceding the revert differ.
* The decoder refuses what Solidity refuses and accepts every canonical
  encoding; it also accepts some non-canonical layouts Solidity accepts
  (overlapping or reordered elements, non-zero padding). No claim is made
  about non-canonical calldata beyond "decodes to some arrays".

Pin `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
P-CONSOLIDATION remains OPEN.
-/

namespace audit.trio.consolidation

open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-! ## ABI framing of `addConsolidationRequests(bytes[], bytes[])` -/

/-- Zero padding that right-pads `n` payload octets to a multiple of 32. -/
def zeroPad (n : Nat) : Bytes := List.replicate ((32 - n % 32) % 32) 0

theorem zeroPad_length (n : Nat) : (zeroPad n).length = (32 - n % 32) % 32 := by
  simp [zeroPad]

/-- ABI `bytes` element in a tail: 32-octet length word, payload
(`Producer.encodeBytesElement`), then zero padding to a multiple of 32. -/
def abiBytesElement (payload : Bytes) : Bytes :=
  encodeBytesElement payload ++ zeroPad payload.length

theorem abiBytesElement_length (payload : Bytes) :
    (abiBytesElement payload).length =
      32 + payload.length + (32 - payload.length % 32) % 32 := by
  simp [abiBytesElement, encodeBytesElement, zeroPad, ABI.encode_length, Nat.add_assoc]

/-- A 48-octet key occupies `32 + 48 + 16 = 96` octets as an element. -/
theorem abiBytesElement_length_48 (payload : Bytes) (h : payload.length = 48) :
    (abiBytesElement payload).length = 96 := by
  rw [abiBytesElement_length, h]

/-- Element offsets of a `bytes[]` tail, relative to the first octet after
the count word: element `0` sits at `start` (the size of the offset table,
`32 · n`), each next element after the previous element's framed size. -/
def elementOffsets (start : Nat) : List Bytes → List Nat
  | [] => []
  | blob :: rest => start :: elementOffsets (start + (abiBytesElement blob).length) rest

theorem elementOffsets_length (start : Nat) (blobs : List Bytes) :
    (elementOffsets start blobs).length = blobs.length := by
  induction blobs generalizing start with
  | nil => rfl
  | cons blob rest ih => simp [elementOffsets, ih]

/-- Every element offset lies inside the element area. -/
theorem elementOffsets_le (start : Nat) (blobs : List Bytes) :
    ∀ o ∈ elementOffsets start blobs, o ≤ start + ((blobs.map abiBytesElement).flatten).length := by
  induction blobs generalizing start with
  | nil => simp [elementOffsets]
  | cons blob rest ih =>
      intro o ho
      simp only [elementOffsets, List.mem_cons] at ho
      simp only [List.map_cons, List.flatten_cons, List.length_append]
      rcases ho with rfl | ho
      · omega
      · have := ih _ o ho
        omega

/-- The offset table: one 32-octet word per element. -/
def offsetWords (start : Nat) (blobs : List Bytes) : Bytes :=
  ((elementOffsets start blobs).map (encode 32)).flatten

theorem offsetWords_length (start : Nat) (blobs : List Bytes) :
    (offsetWords start blobs).length = 32 * blobs.length := by
  unfold offsetWords
  induction blobs generalizing start with
  | nil => rfl
  | cons blob rest ih =>
      simp only [elementOffsets, List.map_cons, List.flatten_cons, List.length_append,
        ABI.encode_length, List.length_cons, ih]
      omega

/-- The tail of one `bytes[]`: count word, offset table, framed padded
elements. This is the Solidity ABI encoding of a `bytes[]` value. -/
def abiBytesArray (blobs : List Bytes) : Bytes :=
  encode 32 blobs.length ++ offsetWords (32 * blobs.length) blobs ++
    (blobs.map abiBytesElement).flatten

theorem abiBytesArray_length (blobs : List Bytes) :
    (abiBytesArray blobs).length =
      32 + 32 * blobs.length + ((blobs.map abiBytesElement).flatten).length := by
  simp only [abiBytesArray, List.length_append, ABI.encode_length, offsetWords_length]

/-- Element area of an all-48-octet array: `96` octets per key. -/
theorem flatten_abiBytesElement_length_48 (blobs : List Bytes)
    (h : ∀ b ∈ blobs, b.length = 48) :
    ((blobs.map abiBytesElement).flatten).length = 96 * blobs.length := by
  induction blobs with
  | nil => rfl
  | cons blob rest ih =>
      have hb : blob.length = 48 := h blob (by simp)
      have hrest : ∀ b ∈ rest, b.length = 48 := fun b hb => h b (by simp [hb])
      simp only [List.map_cons, List.flatten_cons, List.length_append,
        abiBytesElement_length_48 blob hb, ih hrest, List.length_cons]
      omega

/-- A `bytes[]` of `n` 48-octet keys is `32 + 128 · n` octets on the wire. -/
theorem abiBytesArray_length_48 (blobs : List Bytes) (h : ∀ b ∈ blobs, b.length = 48) :
    (abiBytesArray blobs).length = 32 + 128 * blobs.length := by
  rw [abiBytesArray_length, flatten_abiBytesElement_length_48 blobs h]
  omega

/-- The argument block of `addConsolidationRequests(bytes[], bytes[])`:
head offsets `64` and `64 + |sources tail|`, then the two tails. -/
def gatewayVaultArgs (sources targets : List Bytes) : Bytes :=
  encode 32 64 ++ encode 32 (64 + (abiBytesArray sources).length) ++
    abiBytesArray sources ++ abiBytesArray targets

theorem gatewayVaultArgs_length (sources targets : List Bytes) :
    (gatewayVaultArgs sources targets).length =
      64 + (abiBytesArray sources).length + (abiBytesArray targets).length := by
  simp only [gatewayVaultArgs, List.length_append, ABI.encode_length]

/-- Calldata of the line-220 hop. The selector is a parameter (keccak is
outside this model). -/
def gatewayVaultCalldata (selector : Bytes) (sources targets : List Bytes) : Bytes :=
  selector ++ gatewayVaultArgs sources targets

/-! ## Decoder (Solidity calldata accessor discipline) -/

/-- Framed-element decode with a trailing suffix (the encoder's own output
shape). -/
theorem decodeBytesElement_append (payload rest : Bytes) (hfit : payload.length < 256 ^ 32) :
    decodeBytesElement (encodeBytesElement payload ++ rest) = some payload := by
  unfold decodeBytesElement encodeBytesElement
  have henc : (encode 32 payload.length).length = 32 := ABI.encode_length 32 payload.length
  have hlen : 32 ≤ (encode 32 payload.length ++ payload ++ rest).length := by
    simp only [List.length_append, henc]
    omega
  rw [dif_pos hlen]
  have htake : (encode 32 payload.length ++ payload ++ rest).take 32 =
      encode 32 payload.length := by
    rw [List.append_assoc]
    exact List.take_left' henc
  have hdrop : (encode 32 payload.length ++ payload ++ rest).drop 32 = payload ++ rest := by
    rw [List.append_assoc]
    exact List.drop_left' henc
  simp only [htake, hdrop]
  have hdec : decode (encode 32 payload.length) = payload.length :=
    ABI.decode_encode_bounded 32 payload.length hfit
  rw [hdec]
  have hrest : payload.length ≤ (payload ++ rest).length := by simp
  rw [dif_pos hrest, List.take_left]

/-- Dropping a framed element from the encoder's output leaves the suffix. -/
theorem drop_encodeBytesElement_append (payload rest : Bytes) :
    (encodeBytesElement payload ++ rest).drop (32 + payload.length) = rest := by
  have hlen : (encodeBytesElement payload).length = 32 + payload.length := by
    simp [encodeBytesElement, ABI.encode_length]
  exact List.drop_left' hlen

/-- A padded ABI element decodes to its payload with any suffix: the
padding is part of the suffix the length word ignores. -/
theorem decodeBytesElement_abi_append (payload rest : Bytes)
    (hfit : payload.length < 256 ^ 32) :
    decodeBytesElement (abiBytesElement payload ++ rest) = some payload := by
  unfold abiBytesElement
  rw [List.append_assoc]
  exact decodeBytesElement_append payload _ hfit

/-- Dropping a padded ABI element from the encoder's output leaves the
suffix. -/
theorem drop_abiBytesElement_append (payload rest : Bytes) :
    (abiBytesElement payload ++ rest).drop (abiBytesElement payload).length = rest :=
  List.drop_left' rfl

/-- Solidity's calldata access of the elements of a `bytes[]`: element `i`
is read through the offset word at octet `32 · i` of the array body
(`heads` is the body from that word on), then its length word and payload at
`body[offset..]`. Refuses a missing offset word, an offset past the body, or
a length past the body. -/
def decodeOffsetSeq (body : Bytes) : (heads : Bytes) → (count : Nat) → Option (List Bytes)
  | _, 0 => some []
  | heads, count + 1 =>
      if 32 ≤ heads.length then
        match decodeBytesElement (body.drop (decode (heads.take 32))) with
        | none => none
        | some payload => (decodeOffsetSeq body (heads.drop 32) count).map (payload :: ·)
      else none

/-- Following the encoder's offset table over the encoder's element area
returns exactly the blobs. `start` is the position of the first element in
`body`; the offset words are read from `heads`. -/
theorem decodeOffsetSeq_encoded (body : Bytes) (blobs : List Bytes) (start : Nat)
    (suffix hs : Bytes)
    (hfit : ∀ b ∈ blobs, b.length < 256 ^ 32)
    (hoff : ∀ o ∈ elementOffsets start blobs, o < 256 ^ 32)
    (hbody : body.drop start = (blobs.map abiBytesElement).flatten ++ suffix) :
    decodeOffsetSeq body (offsetWords start blobs ++ hs) blobs.length = some blobs := by
  induction blobs generalizing start suffix with
  | nil => rfl
  | cons blob rest ih =>
      have hb : blob.length < 256 ^ 32 := hfit blob (by simp)
      have hrest : ∀ b ∈ rest, b.length < 256 ^ 32 := fun b hb => hfit b (by simp [hb])
      have hstart : start < 256 ^ 32 := hoff start (by simp [elementOffsets])
      have hoff' : ∀ o ∈ elementOffsets (start + (abiBytesElement blob).length) rest,
          o < 256 ^ 32 := fun o ho => hoff o (by simp [elementOffsets, ho])
      have hbody' : body.drop (start + (abiBytesElement blob).length) =
          (rest.map abiBytesElement).flatten ++ suffix := by
        rw [← List.drop_drop, hbody]
        simp only [List.map_cons, List.flatten_cons, List.append_assoc]
        exact drop_abiBytesElement_append blob _
      simp only [List.length_cons, offsetWords, elementOffsets, List.map_cons, List.flatten_cons,
        List.append_assoc, decodeOffsetSeq]
      have h32 : 32 ≤ (encode 32 start ++
          (((elementOffsets (start + (abiBytesElement blob).length) rest).map
            (encode 32)).flatten ++ hs)).length := by
        simp [ABI.encode_length]
      rw [if_pos h32, List.take_left' (ABI.encode_length 32 start),
        ABI.decode_encode_bounded 32 start hstart, hbody]
      simp only [List.map_cons, List.flatten_cons, List.append_assoc]
      rw [decodeBytesElement_abi_append blob _ hb]
      dsimp only
      rw [List.drop_left' (ABI.encode_length 32 start)]
      have := ih _ suffix hrest hoff' hbody'
      unfold offsetWords at this
      rw [this]
      rfl

/-- Decode one `bytes[]` tail: count word, then the elements through their
offset words (`decodeOffsetSeq` over the body after the count word). -/
def decodeBytesArray (rest : Bytes) : Option (List Bytes) :=
  if 32 ≤ rest.length then
    decodeOffsetSeq (rest.drop 32) (rest.drop 32) (decode (rest.take 32))
  else none

/-- The ABI tail decodes back to the blobs, with any suffix after it. -/
theorem decodeBytesArray_abi (blobs : List Bytes) (suffix : Bytes)
    (hfit : ∀ b ∈ blobs, b.length < 256 ^ 32)
    (harr : (abiBytesArray blobs).length < 256 ^ 32) :
    decodeBytesArray (abiBytesArray blobs ++ suffix) = some blobs := by
  have hlen : blobs.length < 256 ^ 32 := by
    have := abiBytesArray_length blobs
    omega
  have h32 : 32 ≤ (abiBytesArray blobs ++ suffix).length := by
    simp only [List.length_append, abiBytesArray_length]
    omega
  have htake : (abiBytesArray blobs ++ suffix).take 32 = encode 32 blobs.length := by
    unfold abiBytesArray
    simp only [List.append_assoc]
    exact List.take_left' (ABI.encode_length 32 blobs.length)
  have hdrop : (abiBytesArray blobs ++ suffix).drop 32 =
      offsetWords (32 * blobs.length) blobs ++ ((blobs.map abiBytesElement).flatten ++ suffix) := by
    unfold abiBytesArray
    simp only [List.append_assoc]
    exact List.drop_left' (ABI.encode_length 32 blobs.length)
  have hbody : (offsetWords (32 * blobs.length) blobs ++
      ((blobs.map abiBytesElement).flatten ++ suffix)).drop (32 * blobs.length) =
      (blobs.map abiBytesElement).flatten ++ suffix :=
    List.drop_left' (offsetWords_length _ blobs)
  have hoff : ∀ o ∈ elementOffsets (32 * blobs.length) blobs, o < 256 ^ 32 := by
    intro o ho
    have := elementOffsets_le (32 * blobs.length) blobs o ho
    have := abiBytesArray_length blobs
    omega
  unfold decodeBytesArray
  rw [if_pos h32, htake, ABI.decode_encode_bounded 32 blobs.length hlen, hdrop]
  exact decodeOffsetSeq_encoded _ blobs (32 * blobs.length) suffix _ hfit hoff hbody

/-- The ABI tail alone decodes back to the blobs. -/
theorem decodeBytesArray_abi_nil (blobs : List Bytes)
    (hfit : ∀ b ∈ blobs, b.length < 256 ^ 32)
    (harr : (abiBytesArray blobs).length < 256 ^ 32) :
    decodeBytesArray (abiBytesArray blobs) = some blobs := by
  have h := decodeBytesArray_abi blobs [] hfit harr
  rwa [List.append_nil] at h

/-- Decode the argument block of `addConsolidationRequests(bytes[], bytes[])`
by following the two head offsets, as Solidity's calldata decoder does. -/
def decodeVaultArgs (args : Bytes) : Option (List Bytes × List Bytes) :=
  if 64 ≤ args.length then
    match decodeBytesArray (args.drop (decode (args.take 32))),
        decodeBytesArray (args.drop (decode ((args.drop 32).take 32))) with
    | some sources, some targets => some (sources, targets)
    | _, _ => none
  else none

private theorem lt_256_32_of_le_96 (n : Nat) (hn : n ≤ 96) : n < 256 ^ 32 :=
  Nat.lt_of_le_of_lt hn (by decide)

/-- Round trip of the gateway→vault argument block: decoding the ABI-encoded
`bytes[]` pair arrays returns exactly the encoded blobs. -/
theorem decodeVaultArgs_gatewayVaultArgs (sources targets : List Bytes)
    (hs : ∀ b ∈ sources, b.length < 256 ^ 32)
    (ht : ∀ b ∈ targets, b.length < 256 ^ 32)
    (hsfit : 64 + (abiBytesArray sources).length < 256 ^ 32)
    (htfit : (abiBytesArray targets).length < 256 ^ 32) :
    decodeVaultArgs (gatewayVaultArgs sources targets) = some (sources, targets) := by
  have hsarr : (abiBytesArray sources).length < 256 ^ 32 := by omega
  have h64 : (64 : Nat) < 256 ^ 32 := lt_256_32_of_le_96 64 (by omega)
  have hlen64 : 64 ≤ (gatewayVaultArgs sources targets).length := by
    rw [gatewayVaultArgs_length]
    omega
  have hhead1 : decode ((gatewayVaultArgs sources targets).take 32) = 64 := by
    unfold gatewayVaultArgs
    simp only [List.append_assoc]
    rw [List.take_left' (ABI.encode_length 32 64), ABI.decode_encode_bounded 32 64 h64]
  have hhead2 : decode (((gatewayVaultArgs sources targets).drop 32).take 32) =
      64 + (abiBytesArray sources).length := by
    unfold gatewayVaultArgs
    simp only [List.append_assoc]
    rw [List.drop_left' (ABI.encode_length 32 64),
      List.take_left' (ABI.encode_length 32 (64 + (abiBytesArray sources).length)),
      ABI.decode_encode_bounded 32 _ hsfit]
  have hdrop64 : (gatewayVaultArgs sources targets).drop 64 =
      abiBytesArray sources ++ abiBytesArray targets := by
    unfold gatewayVaultArgs
    rw [show encode 32 64 ++ encode 32 (64 + (abiBytesArray sources).length) ++
          abiBytesArray sources ++ abiBytesArray targets =
        (encode 32 64 ++ encode 32 (64 + (abiBytesArray sources).length)) ++
          (abiBytesArray sources ++ abiBytesArray targets) by
      simp [List.append_assoc]]
    exact List.drop_left' (by simp [ABI.encode_length])
  have hdropT : (gatewayVaultArgs sources targets).drop (64 + (abiBytesArray sources).length) =
      abiBytesArray targets := by
    rw [← List.drop_drop, hdrop64]
    exact List.drop_left' rfl
  unfold decodeVaultArgs
  rw [if_pos hlen64, hhead1, hhead2, hdrop64, hdropT,
    decodeBytesArray_abi sources _ hs hsarr, decodeBytesArray_abi_nil targets ht htfit]

/-! ## Hop arrays from the committed gateway vault hop -/

/-- First `bytes[]` array of the line-220 hop from the committed gateway
pairs: each source key as its actual 48-octet big-endian blob. -/
def hopSources (pairs : List (Pubkey × Pubkey)) : List Bytes :=
  pairs.map fun p => (integerBE pubkeyLength p.1.identity).map UInt8.ofNat

/-- Second `bytes[]` array: each target key as its actual 48-octet blob. -/
def hopTargets (pairs : List (Pubkey × Pubkey)) : List Bytes :=
  pairs.map fun p => (integerBE pubkeyLength p.2.identity).map UInt8.ofNat

/-- Every hop blob is an actual 48-octet key (`integerBE` pads to width). -/
theorem hopSources_length (pairs : List (Pubkey × Pubkey)) :
    ∀ b ∈ hopSources pairs, b.length = pubkeyLength := by
  intro b hb
  simp only [hopSources, List.mem_map] at hb
  obtain ⟨p, -, rfl⟩ := hb
  simp [List.length_map, integerBE_length]

theorem hopTargets_length (pairs : List (Pubkey × Pubkey)) :
    ∀ b ∈ hopTargets pairs, b.length = pubkeyLength := by
  intro b hb
  simp only [hopTargets, List.mem_map] at hb
  obtain ⟨p, -, rfl⟩ := hb
  simp [List.length_map, integerBE_length]

theorem hopSources_count (pairs : List (Pubkey × Pubkey)) :
    (hopSources pairs).length = pairs.length := by simp [hopSources]

theorem hopTargets_count (pairs : List (Pubkey × Pubkey)) :
    (hopTargets pairs).length = pairs.length := by simp [hopTargets]

/-- Zipping the hop arrays is the vault's pair list (`pairsOf`). -/
theorem pairsOf_hopArrays (pairs : List (Pubkey × Pubkey)) :
    pairsOf (hopSources pairs) (hopTargets pairs) =
      pairs.map fun p =>
        ({ source := (integerBE pubkeyLength p.1.identity).map UInt8.ofNat,
           target := (integerBE pubkeyLength p.2.identity).map UInt8.ofNat } : ProducedPair) := by
  unfold pairsOf hopSources hopTargets
  rw [List.zip_map', List.map_map]
  simp only [Function.comp_def]

/-- Every pair of the zipped hop arrays passes `_validatePublicKey`'s width
check (`integerBE` pads to 48 octets). -/
theorem widthOk_hopArrays (pairs : List (Pubkey × Pubkey)) :
    ∀ pair ∈ pairsOf (hopSources pairs) (hopTargets pairs), widthOk pair := by
  rw [pairsOf_hopArrays]
  intro pair hp
  simp only [List.mem_map] at hp
  obtain ⟨p, -, rfl⟩ := hp
  exact ⟨by simp [List.length_map, integerBE_length],
    by simp [List.length_map, integerBE_length]⟩

/-- Octets of a raw key are its `integerBE` limbs (`pubkeyOctets` unfolded). -/
private theorem octets_of_some {key : Pubkey} {octets : List Nat}
    (h : pubkeyOctets key = some octets) :
    octets = integerBE pubkeyLength key.identity := by
  unfold pubkeyOctets at h
  split at h
  · exact Option.some.inj h.symm
  · contradiction

/-- The packed payloads of the committed gateway hop are the per-pair
`integerBE` concatenations. -/
theorem packedPayloads_eq_map (pairs : List (Pubkey × Pubkey)) (payloads : List (List Nat))
    (h : packedPayloads pairs = some payloads) :
    payloads = pairs.map fun p =>
      integerBE pubkeyLength p.1.identity ++ integerBE pubkeyLength p.2.identity := by
  induction pairs generalizing payloads with
  | nil =>
      cases h
      rfl
  | cons p rest ih =>
      unfold packedPayloads at h
      cases hpair : encodePackedRequest p.1 p.2 with
      | none => simp [hpair] at h
      | some payload =>
          cases hrest : packedPayloads rest with
          | none => simp [hpair, hrest] at h
          | some restPayloads =>
              simp only [hpair, hrest, Option.some.injEq] at h
              subst h
              simp only [List.map_cons]
              unfold encodePackedRequest at hpair
              cases hsrc : pubkeyOctets p.1 with
              | none => simp [hsrc] at hpair
              | some src =>
                  cases htgt : pubkeyOctets p.2 with
                  | none => simp [hsrc, htgt] at hpair
                  | some tgt =>
                      simp only [hsrc, htgt, Option.some.injEq] at hpair
                      rw [← hpair, octets_of_some hsrc, octets_of_some htgt,
                        ih restPayloads hrest]

/-- The vault hop payloads committed by the gateway, carried over the ABI as
the two `bytes[]` arrays and re-packed by the vault's line-114
`abi.encodePacked`, are the same 96 octets. -/
theorem hop_payloads (pairs : List (Pubkey × Pubkey)) (payloads : List (List Nat))
    (h : packedPayloads pairs = some payloads) :
    (pairsOf (hopSources pairs) (hopTargets pairs)).map vaultCallPayload =
      payloads.map (List.map UInt8.ofNat) := by
  rw [pairsOf_hopArrays, packedPayloads_eq_map pairs payloads h]
  simp [List.map_map, vaultCallPayload, List.map_append, Function.comp_def]

/-! ## The ABI-framed hop on the wire -/

/-- Wire size of the hop's tails for `n` committed pairs: each tail is
`32 + 128 · n` octets. -/
theorem abiBytesArray_hopSources_length (pairs : List (Pubkey × Pubkey)) :
    (abiBytesArray (hopSources pairs)).length = 32 + 128 * pairs.length := by
  rw [abiBytesArray_length_48 _ (hopSources_length pairs), hopSources_count]

theorem abiBytesArray_hopTargets_length (pairs : List (Pubkey × Pubkey)) :
    (abiBytesArray (hopTargets pairs)).length = 32 + 128 * pairs.length := by
  rw [abiBytesArray_length_48 _ (hopTargets_length pairs), hopTargets_count]

/-- Argument block of the committed hop: `64 + 2 · (32 + 128 · n)` octets
(`640` for two pairs). -/
theorem gatewayVaultArgs_hop_length (pairs : List (Pubkey × Pubkey)) :
    (gatewayVaultArgs (hopSources pairs) (hopTargets pairs)).length =
      64 + 2 * (32 + 128 * pairs.length) := by
  rw [gatewayVaultArgs_length, abiBytesArray_hopSources_length, abiBytesArray_hopTargets_length]
  omega

/-- The committed hop, ABI-encoded, decodes back to its own arrays. The pair
count bound keeps every offset word below `2^256`. -/
theorem decodeVaultArgs_hop (pairs : List (Pubkey × Pubkey)) (hn : pairs.length < 2 ^ 248) :
    decodeVaultArgs (gatewayVaultArgs (hopSources pairs) (hopTargets pairs)) =
      some (hopSources pairs, hopTargets pairs) := by
  have hs : ∀ b ∈ hopSources pairs, b.length < 256 ^ 32 := fun b hb => by
    rw [hopSources_length pairs b hb]
    exact lt_256_32_of_le_96 _ (by decide)
  have ht : ∀ b ∈ hopTargets pairs, b.length < 256 ^ 32 := fun b hb => by
    rw [hopTargets_length pairs b hb]
    exact lt_256_32_of_le_96 _ (by decide)
  have hsfit : 64 + (abiBytesArray (hopSources pairs)).length < 256 ^ 32 := by
    rw [abiBytesArray_hopSources_length]
    omega
  have htfit : (abiBytesArray (hopTargets pairs)).length < 256 ^ 32 := by
    rw [abiBytesArray_hopTargets_length]
    omega
  exact decodeVaultArgs_gatewayVaultArgs _ _ hs ht hsfit htfit

/-- The vault entrypoint on the raw calldata of the line-220 hop: the
4-octet selector must match (Solidity's dispatcher; the selector value is a
parameter), the `(bytes[], bytes[])` block is ABI-decoded, then `executeVault`
runs on the decoded arrays. A dispatcher or decoder failure is a revert
before any body code runs: no attempt, no state change. -/
def executeVaultCalldata (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (gateway inbox : Live.Address) (msgValue : Live.Word) (selector : Bytes)
    (calldata : Bytes) (before : World) : Result Unit :=
  if calldata.take 4 = selector then
    match decodeVaultArgs (calldata.drop 4) with
    | none => ⟨.error (.reason "AbiDecodingFailed"), before, []⟩
    | some (sources, targets) =>
        executeVault callee sexternal ctx gateway inbox msgValue sources targets before
  else ⟨.error (.reason "UnknownSelector"), before, []⟩

/-- The gateway's line-220 calldata, consumed by the vault entrypoint through
the ABI decoder, is exactly `executeVault` on the committed hop arrays. The
vault consumes the ABI-framed payload; nothing bypasses the framing. -/
theorem executeVaultCalldata_gateway (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Live.Address) (msgValue : Live.Word) (selector : Bytes)
    (pairs : List (Pubkey × Pubkey)) (before : World)
    (hsel : selector.length = 4) (hn : pairs.length < 2 ^ 248) :
    executeVaultCalldata callee sexternal ctx gateway inbox msgValue selector
        (gatewayVaultCalldata selector (hopSources pairs) (hopTargets pairs)) before =
      executeVault callee sexternal ctx gateway inbox msgValue (hopSources pairs)
        (hopTargets pairs) before := by
  unfold executeVaultCalldata gatewayVaultCalldata
  rw [List.take_left' hsel, List.drop_left' hsel, if_pos rfl, decodeVaultArgs_hop pairs hn]

/-- Committed success of the vault on the gateway's ABI-framed calldata: the
sender, count and width guards held, the fee was read by the line-84
`staticcall("")`, the exact-fee check held for the read word, and the
attempted line-115 requests carry, pair by pair, the gateway's own packed
payloads (`packedPayloads`). -/
theorem executeVaultCalldata_success_payloads (callee : External)
    (sexternal : StaticCall.External) (ctx : Context) (gateway inbox : Live.Address)
    (msgValue : Live.Word) (selector : Bytes) (pairs : List (Pubkey × Pubkey))
    (payloads : List (List Nat)) (before : World)
    (hsel : selector.length = 4) (hn : pairs.length < 2 ^ 248)
    (hp : packedPayloads pairs = some payloads)
    (h : (executeVaultCalldata callee sexternal ctx gateway inbox msgValue selector
        (gatewayVaultCalldata selector (hopSources pairs) (hopTargets pairs)) before).outcome =
      .ok ()) :
    ctx.sender = gateway ∧ pairs ≠ [] ∧
      ∃ feeData sattempts,
        lowLevelStaticCall sexternal ctx.self inbox [] before = ⟨.ok feeData, sattempts⟩ ∧
        feeData.length = 32 ∧
        pairs.length * (Live.word (decode feeData)).val = msgValue.val ∧
        (executeVaultCalldata callee sexternal ctx gateway inbox msgValue selector
            (gatewayVaultCalldata selector (hopSources pairs) (hopTargets pairs))
            before).attempts.map (·.request.payload) =
          payloads.map (List.map UInt8.ofNat) := by
  rw [executeVaultCalldata_gateway callee sexternal ctx gateway inbox msgValue selector pairs
    before hsel hn] at h ⊢
  obtain ⟨hsender, hne, -, feeData, sattempts, hread, hlen, hfee, -, hreq, -⟩ :=
    executeVault_success callee sexternal ctx gateway inbox msgValue (hopSources pairs)
      (hopTargets pairs) before h
  refine ⟨hsender, ?_, feeData, sattempts, hread, hlen, ?_, ?_⟩
  · intro hnil
    apply hne
    simp [hnil, hopSources]
  · rwa [hopSources_count] at hfee
  · have hmap : ((executeVault callee sexternal ctx gateway inbox msgValue (hopSources pairs)
        (hopTargets pairs) before).attempts.map (·.request.payload)) =
        ((executeVault callee sexternal ctx gateway inbox msgValue (hopSources pairs)
          (hopTargets pairs) before).attempts.map (·.request)).map (·.payload) := by
      simp [List.map_map, Function.comp_def]
    rw [hmap, hreq, ← hop_payloads pairs payloads hp]
    simp [hopRequests, hopRequest, List.map_map, Function.comp_def]

end audit.trio.consolidation
