import audit.trio.consolidation.LiveCall

/-!
# Gateway→vault ABI hop (`ConsolidationGateway.sol:220`)

```
IWithdrawalVault(VAULT).addConsolidationRequests{value: totalFee}(
    sourcePubkeys, targetPubkeys);
```

The gateway's committed `VaultHop` (`Gateway.lean`) carries the flattened
`bytes[]` pair arrays as packed 96-octet payloads. This file is the ABI hop
between the two contracts: the actual `addConsolidationRequests(bytes[],
bytes[])` calldata framing (head offsets, count words, framed `bytes`
elements), a decoder, and the round-trip theorem that decoding the encoded
hop returns exactly the producer blobs `_prepareConsolidationPairs` flattened
(`Producer.preparePairBytes`). Zipping the decoded arrays is the vault's
`pairsOf` input of `LiveCall.lean`.

Residuals (stated, not claimed):

* The selector below is the solc-0.8.25 ABI selector for the pinned
  signature. This model records the resulting four octets; it does not prove
  Keccak256.
* Solidity's ABI decoder also bounds-checks head/tail lengths against the
  calldata size; the decoder here refuses short heads and unframed elements,
  and the round trip is stated for the encoder's own output.

Pin `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
P-CONSOLIDATION remains OPEN.
-/

namespace audit.trio.consolidation

open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-! ## ABI framing of `addConsolidationRequests(bytes[], bytes[])` -/

/-- A `bytes[]` tail: count word, then the framed elements
(`Producer.encodeBytesElement`: 32-octet length word, then payload). -/
def framedBytesArray (blobs : List Bytes) : Bytes :=
  encode 32 blobs.length ++ (blobs.map encodeBytesElement).flatten

/-- Length of a framed `bytes[]` tail. -/
theorem framedBytesArray_length (blobs : List Bytes) :
    (framedBytesArray blobs).length = 32 + ((blobs.map encodeBytesElement).flatten).length := by
  simp [framedBytesArray, ABI.encode_length, List.length_append]

/-- The argument block of `addConsolidationRequests(bytes[], bytes[])`:
head offsets `64` and `64 + |sources tail|`, then the two tails. -/
def gatewayVaultArgs (sources targets : List Bytes) : Bytes :=
  encode 32 64 ++ encode 32 (64 + (framedBytesArray sources).length) ++
    framedBytesArray sources ++ framedBytesArray targets

/-- The concrete 4-octet selector used by line 220. -/
def gatewayVaultSelector : Nat := 0xa75ac640

/-- `keccak256("addConsolidationRequests(bytes[],bytes[])")[0:4]`, as emitted
by solc 0.8.25 for the pinned `IWithdrawalVault` interface. -/
def gatewayVaultSelectorBytes : Bytes := encode 4 gatewayVaultSelector

/-- Complete line-220 calldata, including the concrete interface selector. -/
def gatewayVaultCalldata (sources targets : List Bytes) : Bytes :=
  gatewayVaultSelectorBytes ++ gatewayVaultArgs sources targets

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

/-- Decode `count` framed `bytes` elements; returns the payloads and the
consumed octet count. -/
def decodeFramedSeq : (count : Nat) → (rest : Bytes) → Option (List Bytes × Nat)
  | 0, _ => some ([], 0)
  | count + 1, rest =>
      match decodeBytesElement rest with
      | none => none
      | some payload =>
          (decodeFramedSeq count (rest.drop (32 + payload.length))).map
            fun (payloads, consumed) => (payload :: payloads, 32 + payload.length + consumed)

/-- The framed-element sequence decodes back to the blobs, consuming exactly
the flattened framing. -/
theorem decodeFramedSeq_flatten (blobs : List Bytes) (suffix : Bytes)
    (hfit : ∀ b ∈ blobs, b.length < 256 ^ 32) :
    decodeFramedSeq blobs.length ((blobs.map encodeBytesElement).flatten ++ suffix) =
      some (blobs, ((blobs.map encodeBytesElement).flatten).length) := by
  induction blobs generalizing suffix with
  | nil => rfl
  | cons blob rest ih =>
      have hb : blob.length < 256 ^ 32 := hfit blob (by simp)
      have hrest : ∀ b ∈ rest, b.length < 256 ^ 32 := fun b hb => hfit b (by simp [hb])
      simp only [List.length_cons, decodeFramedSeq, List.map_cons, List.flatten_cons,
        List.append_assoc]
      rw [decodeBytesElement_append blob _ hb]
      dsimp only
      rw [drop_encodeBytesElement_append, ih _ hrest]
      simp only [Option.map_some, List.length_append, List.length_flatten, List.map_map,
        encodeBytesElement, ABI.encode_length]

/-- Decode one framed `bytes[]` tail: count word then the framed elements. -/
def decodeBytesArray (rest : Bytes) : Option (List Bytes × Nat) :=
  if 32 ≤ rest.length then
    decodeFramedSeq (decode (rest.take 32)) (rest.drop 32)
  else none

/-- The framed tail decodes back to the blobs, consuming exactly the
flattened framing. -/
theorem decodeBytesArray_framed (blobs : List Bytes) (suffix : Bytes)
    (hlen : blobs.length < 256 ^ 32) (hfit : ∀ b ∈ blobs, b.length < 256 ^ 32) :
    decodeBytesArray (framedBytesArray blobs ++ suffix) =
      some (blobs, ((blobs.map encodeBytesElement).flatten).length) := by
  have h32 : 32 ≤ (framedBytesArray blobs ++ suffix).length := by
    simp only [List.length_append, framedBytesArray_length]
    omega
  have htake : (framedBytesArray blobs ++ suffix).take 32 = encode 32 blobs.length := by
    unfold framedBytesArray
    rw [List.append_assoc, List.take_left' (ABI.encode_length 32 blobs.length)]
  have hdrop : (framedBytesArray blobs ++ suffix).drop 32 =
      (blobs.map encodeBytesElement).flatten ++ suffix := by
    unfold framedBytesArray
    rw [List.append_assoc, List.drop_left' (ABI.encode_length 32 blobs.length)]
  unfold decodeBytesArray
  rw [if_pos h32, htake, ABI.decode_encode_bounded 32 blobs.length hlen, hdrop]
  exact decodeFramedSeq_flatten blobs suffix hfit

/-- The framed tail alone decodes back to the blobs. -/
theorem decodeBytesArray_framed_nil (blobs : List Bytes)
    (hlen : blobs.length < 256 ^ 32) (hfit : ∀ b ∈ blobs, b.length < 256 ^ 32) :
    decodeBytesArray (framedBytesArray blobs) =
      some (blobs, ((blobs.map encodeBytesElement).flatten).length) := by
  have h := decodeBytesArray_framed blobs [] hlen hfit
  rwa [List.append_nil] at h

/-- Decode the argument block of `addConsolidationRequests(bytes[], bytes[])`.
Checks the head offsets against the actual framed tails. -/
def decodeVaultArgs (args : Bytes) : Option (List Bytes × List Bytes) :=
  if 64 ≤ args.length ∧ decode (args.take 32) = 64 then
    match decodeBytesArray (args.drop 64) with
    | none => none
    | some (sources, consumed) =>
        if decode ((args.drop 32).take 32) = 64 + 32 + consumed then
          match decodeBytesArray (((args.drop 64).drop 32).drop consumed) with
          | none => none
          | some (targets, _) => some (sources, targets)
        else none
  else none

private theorem lt_256_32_of_le_96 (n : Nat) (hn : n ≤ 96) : n < 256 ^ 32 :=
  Nat.lt_of_le_of_lt hn (by decide)

/-- Round trip of the gateway→vault argument block: decoding the encoded
`bytes[]` pair arrays returns exactly the encoded blobs. -/
theorem decodeVaultArgs_gatewayVaultArgs (sources targets : List Bytes)
    (hslen : sources.length < 256 ^ 32) (htlen : targets.length < 256 ^ 32)
    (hs : ∀ b ∈ sources, b.length < 256 ^ 32)
    (ht : ∀ b ∈ targets, b.length < 256 ^ 32)
    (hsfit : 64 + (framedBytesArray sources).length < 256 ^ 32) :
    decodeVaultArgs (gatewayVaultArgs sources targets) = some (sources, targets) := by
  unfold decodeVaultArgs gatewayVaultArgs
  have h64 : (64 : Nat) < 256 ^ 32 := lt_256_32_of_le_96 64 (by omega)
  have hhead1 : decode ((encode 32 64 ++ encode 32 (64 + (framedBytesArray sources).length) ++
      framedBytesArray sources ++ framedBytesArray targets).take 32) = 64 := by
    simp only [List.append_assoc]
    rw [List.take_left' (ABI.encode_length 32 64), ABI.decode_encode_bounded 32 64 h64]
  have hlen64 : 64 ≤ (encode 32 64 ++ encode 32 (64 + (framedBytesArray sources).length) ++
      framedBytesArray sources ++ framedBytesArray targets).length := by
    simp only [List.length_append, ABI.encode_length, framedBytesArray_length]
    omega
  rw [if_pos ⟨hlen64, hhead1⟩]
  have hdrop64 : (encode 32 64 ++ encode 32 (64 + (framedBytesArray sources).length) ++
      framedBytesArray sources ++ framedBytesArray targets).drop 64 =
      framedBytesArray sources ++ framedBytesArray targets := by
    rw [show encode 32 64 ++ encode 32 (64 + (framedBytesArray sources).length) ++
          framedBytesArray sources ++ framedBytesArray targets =
        (encode 32 64 ++ encode 32 (64 + (framedBytesArray sources).length)) ++
          (framedBytesArray sources ++ framedBytesArray targets) by
      simp [List.append_assoc]]
    exact List.drop_left' (by simp [ABI.encode_length])
  rw [hdrop64, decodeBytesArray_framed sources (framedBytesArray targets) hslen hs]
  dsimp only
  have hhead2 : decode (((encode 32 64 ++
      encode 32 (64 + (framedBytesArray sources).length) ++ framedBytesArray sources ++
      framedBytesArray targets).drop 32).take 32) =
      64 + (framedBytesArray sources).length := by
    simp only [List.append_assoc]
    rw [List.drop_left' (ABI.encode_length 32 64),
      List.take_left' (ABI.encode_length 32 (64 + (framedBytesArray sources).length)),
      ABI.decode_encode_bounded 32 (64 + (framedBytesArray sources).length) hsfit]
  rw [hhead2]
  have hconsumed : 64 + (framedBytesArray sources).length =
      64 + 32 + ((sources.map encodeBytesElement).flatten).length := by
    rw [framedBytesArray_length, Nat.add_assoc]
  rw [hconsumed]
  rw [if_pos rfl]
  have hdrop32 : ∀ S : Bytes, (framedBytesArray sources ++ S).drop 32 =
      ((sources.map encodeBytesElement).flatten) ++ S := by
    intro S
    unfold framedBytesArray
    rw [List.append_assoc, List.drop_left' (ABI.encode_length 32 sources.length)]
  have htrest : (((framedBytesArray sources ++ framedBytesArray targets).drop 32).drop
      ((sources.map encodeBytesElement).flatten).length) = framedBytesArray targets := by
    rw [hdrop32]
    exact List.drop_left' rfl
  rw [htrest, decodeBytesArray_framed_nil targets htlen ht]

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

/-! ## Executed high-level gateway → vault bridge -/

/-- Context at the body of a high-level `IWithdrawalVault` call.  In
particular, `address(this)` is the request target (the vault) and
`msg.sender` is the request caller (the gateway); neither is a free choice of
the bridge. -/
def vaultContext (request : Request) : Context :=
  ⟨request.target, request.caller⟩

/-- Solc's high-level interface call has an `extcodesize` check before the
CALL.  This is deliberately distinct from `lowLevelCall`, used by the vault
for its EIP-7251 and refund low-level calls. -/
def highLevelVaultCall (external : External) (ctx : Context) (vault : Address)
    (value : Word) (sources targets : List Bytes) : Exec Bytes := fun w =>
  let request : Request := ⟨ctx.self, vault, value, gatewayVaultCalldata sources targets⟩
  if (w.core.codeSize vault.val).val = 0 then ⟨.error .empty, w, []⟩
  else if w.balances ctx.self < value.val then
    ⟨.error (.bubbled []), w, [⟨request, false, [], []⟩]⟩
  else match external request (transfer w ctx.self vault value.val) with
    | .rejected data => ⟨.error (.bubbled data), w, [⟨request, false, data, []⟩]⟩
    | .success data after => ⟨.ok data, after, [⟨request, true, data, []⟩]⟩
    | .successWithTrace data after nested =>
        ⟨.ok data, after, [⟨request, true, data, nested⟩]⟩
    | .rejectedWithTrace data nested =>
        ⟨.error (.bubbled data), w, [⟨request, false, data, nested⟩]⟩

/-- Preserve the root vault execution as a nested trace instead of replacing
it with an uninformative `success []` / `rejected []` oracle answer. -/
def vaultTrace (result : Result Unit) : List NestedAttempt :=
  result.attempts.map fun attempt =>
    ⟨attempt.request, false, attempt.accepted, attempt.returned, 2⟩

/-- A compact observable encoding of a vault root fault.  The bridge keeps
the detailed internal attempts in `vaultTrace`; panic and named source faults
are not silently relabelled as an empty rejection. -/
def vaultFaultData : Fault → Bytes
  | .empty => [0]
  | .reason text => text.toList.map fun c => UInt8.ofNat c.toNat
  | .bubbled data => data

/-- The public vault body reached by the compiled high-level interface CALL.
It decodes the actual selector-plus-arguments, derives the vault context from
the request, and delegates the callee transaction to the already reviewed
`LiveCall.executeVault_*` root semantics.  The gateway quota/pause/role and
witness prefix occur before this call in `ConsolidationGateway.sol` and remain
explicitly OPEN; this bridge does not replace them with booleans. -/
def executeVaultExternal (callee : External) (sexternal : StaticCall.External)
    (vault inbox : Address) : External := fun request credited =>
  if request.target ≠ vault then .rejected [1]
  else if request.payload.take 4 ≠ gatewayVaultSelectorBytes then .rejected [2]
  else match decodeVaultArgs (request.payload.drop 4) with
    | none => .rejected [3]
    | some (sources, targets) =>
        let result := executeVault callee sexternal (vaultContext request) request.caller inbox
          request.value sources targets credited
        match result.outcome with
        | .ok _ => .successWithTrace [] result.world (vaultTrace result)
        | .error fault => .rejectedWithTrace (vaultFaultData fault) (vaultTrace result)

/-- Successful outer interface call is an actual successful vault root, with
the public context `self = request.target`, `sender = request.caller`. -/
theorem executeVaultExternal_success_root (callee : External) (sexternal : StaticCall.External)
    (vault inbox : Address) (request : Request) (credited after : World) (nested : List NestedAttempt)
    (h : executeVaultExternal callee sexternal vault inbox request credited =
      .successWithTrace [] after nested) :
    request.target = vault ∧ request.payload.take 4 = gatewayVaultSelectorBytes ∧
      ∃ sources targets result,
        decodeVaultArgs (request.payload.drop 4) = some (sources, targets) ∧
        result = executeVault callee sexternal (vaultContext request) request.caller inbox
          request.value sources targets credited ∧
        result.outcome = .ok () ∧ after = result.world ∧ nested = vaultTrace result := by
  unfold executeVaultExternal at h
  split at h
  · contradiction
  rename_i htarget
  split at h
  · contradiction
  rename_i hselector
  split at h <;> try contradiction
  rename_i sources targets hargs
  generalize hresult : executeVault callee sexternal (vaultContext request) request.caller inbox
    request.value sources targets credited = result at h
  cases hout : result.outcome with
  | error fault => simp [hout] at h
  | ok unit =>
      cases unit
      simp [hout] at h
      subst after
      subst nested
      exact ⟨by simpa using htarget, by simpa using hselector,
        sources, targets, result, hargs, hresult.symm, hout, rfl, rfl⟩

/-- The compiled line-220 call's code check is load-bearing: an address with
no code creates no attempt and cannot enter `executeVault`. -/
theorem highLevelVaultCall_no_code (external : External) (ctx : Context) (vault : Address)
    (value : Word) (sources targets : List Bytes) (w : World)
    (hcode : (w.core.codeSize vault.val).val = 0) :
    highLevelVaultCall external ctx vault value sources targets w = ⟨.error .empty, w, []⟩ := by
  simp [highLevelVaultCall, hcode]

end audit.trio.consolidation
