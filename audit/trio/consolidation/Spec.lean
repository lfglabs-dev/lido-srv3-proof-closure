import Verity.Core

/-!
# Consolidation source specification

An independent, executable specification of the pure parts of the pinned
consolidation path at `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`:

* `ConsolidationBus.addConsolidationRequests` (lines 325--370),
* `ConsolidationGateway._prepareConsolidationPairs` (lines 348--365), and
* `WithdrawalVaultEIP7685._addConsolidationRequests` (lines 56--73).

This file deliberately does not import an existing consolidation model.  Keys
carry their byte length and a content identity.  A raw 48-byte pubkey is
exactly `length = 48` with `identity < 256^48` (the integer of those bytes);
`keccak256` equality of well-formed keys is equality of that identity.
Wrapping `identity` at `2^384` is not a 48-byte representation.  Stateful
role, pending-batch, proof, quota, external-call, and rollback behavior
belongs to later layers.
-/

namespace audit.trio.consolidation

abbrev Word := Verity.Core.Uint256

def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n

def pubkeyLength : Nat := 48

/-- `256^48 = 2^384`. A 48-byte blob interprets as an integer strictly below this. -/
def pubkeyModulus : Nat := 256 ^ pubkeyLength

/-- A calldata `bytes` public key. `identity` is the integer value of its raw
bytes, not a hash: a 48-byte key is exactly `length = 48` and
`identity < 256^48`. -/
structure Pubkey where
  identity : Nat
  length : Nat
  deriving DecidableEq, Repr

/-- Unrestricted big-endian integer encoding (LSB last). Without
`n < 256^size` this map wraps: `n` and `n + 256^size` produce the same
octets. That wrapping map is *not* a pubkey representation. -/
def integerBE : Nat → Nat → List Nat
  | 0, _ => []
  | size + 1, n => integerBE size (n / 256) ++ [n % 256]

/-- A calldata key whose bytes are an actual 48-octet BLS pubkey. Solidity
checks `pubkey.length == 48`; the identity bound is the model fact that a
48-byte blob interprets as an integer `< 2^384`. -/
def RawPubkey (key : Pubkey) : Prop :=
  key.length = pubkeyLength ∧ key.identity < pubkeyModulus

instance (key : Pubkey) : Decidable (RawPubkey key) :=
  inferInstanceAs (Decidable (key.length = pubkeyLength ∧ key.identity < pubkeyModulus))

/-- Actual raw 48-byte representation of a calldata pubkey. `none` unless
`RawPubkey key`. This is the blob `abi.encodePacked` concatenates; it does
not ignore `key.length` and it does not wrap at `2^384`. -/
def pubkeyOctets (key : Pubkey) : Option (List Nat) :=
  if RawPubkey key then some (integerBE pubkeyLength key.identity) else none

/-- Vault `_callAddConsolidationRequest` payload:
`abi.encodePacked(sourcePubkey, targetPubkey)` (`WithdrawalVaultEIP7685.sol:114`).
Defined only when both keys have an actual 48-byte representation. -/
def encodePackedRequest (source target : Pubkey) : Option (List Nat) :=
  match pubkeyOctets source, pubkeyOctets target with
  | some src, some tgt => some (src ++ tgt)
  | _, _ => none

/-- One packed 96-byte callee payload per flattened gateway pair, in
`_prepareConsolidationPairs` order. `none` if any pair is not two raw
48-byte keys. -/
def packedPayloads : List (Pubkey × Pubkey) → Option (List (List Nat))
  | [] => some []
  | pair :: rest =>
      match encodePackedRequest pair.1 pair.2, packedPayloads rest with
      | some payload, some payloads => some (payload :: payloads)
      | _, _ => none

/-- Publisher input to `ConsolidationBus.addConsolidationRequests`. -/
structure PublisherGroup where
  sources : List Pubkey
  target : Pubkey
  deriving DecidableEq, Repr

/-- Gateway input. The proof fields of `ValidatorWitness` are intentionally
opaque here; the target pubkey is the field used by pair preparation. -/
structure WitnessGroup where
  sources : List Pubkey
  target : Pubkey
  deriving DecidableEq, Repr

inductive BusAddError where
  | emptyBatch
  | tooManyGroups (actual limit : Nat)
  | emptyGroup (groupIndex : Nat)
  | countOverflow
  | batchTooLarge (actual limit : Nat)
  | invalidTargetLength (groupIndex actual : Nat)
  | invalidSourceLength (groupIndex sourceIndex actual : Nat)
  | sourceEqualsTarget (groupIndex sourceIndex : Nat)
  deriving DecidableEq, Repr

private def checkedAdd (a b : Nat) : Option Nat :=
  if a + b < 2 ^ 256 then some (a + b) else none

/-- First loop of the bus entrypoint: reject an empty source group and compute
`totalCount` with Solidity's checked `uint256` addition. -/
def countSources : List PublisherGroup → Except BusAddError Nat :=
  go 0 0
where
  go (groupIndex total : Nat) : List PublisherGroup → Except BusAddError Nat
    | [] => .ok total
    | group :: rest =>
        if group.sources.isEmpty then .error (.emptyGroup groupIndex)
        else match checkedAdd total group.sources.length with
          | none => .error .countOverflow
          | some next => go (groupIndex + 1) next rest

private def validateSources (groupIndex : Nat) (target : Pubkey) :
    Nat → List Pubkey → Except BusAddError Unit
  | _, [] => .ok ()
  | sourceIndex, source :: rest =>
      if source.length != pubkeyLength then
        .error (.invalidSourceLength groupIndex sourceIndex source.length)
      else if source.identity == target.identity then
        .error (.sourceEqualsTarget groupIndex sourceIndex)
      else validateSources groupIndex target (sourceIndex + 1) rest

/-- Second loop of the bus entrypoint, preserving target-before-source and
length-before-equality error precedence. -/
def validatePubkeys : Nat → List PublisherGroup → Except BusAddError Unit
  | _, [] => .ok ()
  | groupIndex, group :: rest =>
      if group.target.length != pubkeyLength then
        .error (.invalidTargetLength groupIndex group.target.length)
      else match validateSources groupIndex group.target 0 group.sources with
        | .error err => .error err
        | .ok () => validatePubkeys (groupIndex + 1) rest

/-- Pure validation prefix of `ConsolidationBus.addConsolidationRequests`.
The pending-batch lookup/write follows this result in the stateful layer. -/
def validateBusAdd (batchSize maxGroups : Nat)
    (groups : List PublisherGroup) : Except BusAddError Nat := do
  if groups.isEmpty then throw .emptyBatch
  if groups.length > maxGroups then throw (.tooManyGroups groups.length maxGroups)
  let totalCount ← countSources groups
  if totalCount > batchSize then throw (.batchTooLarge totalCount batchSize)
  validatePubkeys 0 groups
  pure totalCount

/-- `ConsolidationGateway._prepareConsolidationPairs`: sources stay in nested
source order and each group's target is repeated once per source. -/
def preparePairs (groups : List WitnessGroup) : List (Pubkey × Pubkey) :=
  groups.flatMap fun group => group.sources.map fun source => (source, group.target)

/-- First array returned by `_prepareConsolidationPairs`. -/
def preparedSources (groups : List WitnessGroup) : List Pubkey :=
  groups.flatMap (·.sources)

/-- Second array returned by `_prepareConsolidationPairs`. -/
def preparedTargets (groups : List WitnessGroup) : List Pubkey :=
  groups.flatMap fun group => List.replicate group.sources.length group.target

inductive VaultError where
  | zeroSources
  | arraysLengthMismatch (sources targets : Nat)
  | feeOverflow
  | incorrectFee (required provided : Word)
  | invalidSourceLength (index actual : Nat)
  | invalidTargetLength (index actual : Nat)
  deriving DecidableEq, Repr

def checkedMulWord (a : Nat) (b : Word) : Option Word :=
  if h : a * b.val < 2 ^ 256 then
    some ⟨a * b.val, h⟩
  else none

private def validateVaultPairs : Nat → List (Pubkey × Pubkey) →
    Except VaultError Unit
  | _, [] => .ok ()
  | index, pair :: rest =>
      if pair.1.length != pubkeyLength then
        .error (.invalidSourceLength index pair.1.length)
      else if pair.2.length != pubkeyLength then
        .error (.invalidTargetLength index pair.2.length)
      else validateVaultPairs (index + 1) rest

private theorem validateVaultPairs_ok (index : Nat)
    (pairs : List (Pubkey × Pubkey))
    (hvalid : ∀ pair ∈ pairs,
      pair.1.length = pubkeyLength ∧ pair.2.length = pubkeyLength) :
    validateVaultPairs index pairs = .ok () := by
  induction pairs generalizing index with
  | nil => rfl
  | cons pair rest ih =>
      have hp := hvalid pair (by simp)
      have hr : ∀ p ∈ rest,
          p.1.length = pubkeyLength ∧ p.2.length = pubkeyLength := by
        intro p hmem
        exact hvalid p (by simp [hmem])
      simp [validateVaultPairs, hp.1, hp.2, ih (index := index + 1) hr]

/-- Pure guards of `_addConsolidationRequests`, including checked fee
multiplication and the exact-fee check before per-pair key validation. -/
def validateVaultAdd (fee msgValue : Word) (sources targets : List Pubkey) :
    Except VaultError (List (Pubkey × Pubkey)) := do
  if sources.isEmpty then throw .zeroSources
  if sources.length != targets.length then
    throw (.arraysLengthMismatch sources.length targets.length)
  let required ← match checkedMulWord sources.length fee with
    | some required => pure required
    | none => throw .feeOverflow
  if required != msgValue then throw (.incorrectFee required msgValue)
  let pairs := sources.zip targets
  validateVaultPairs 0 pairs
  pure pairs

theorem preparePairs_length (groups : List WitnessGroup) :
    (preparePairs groups).length = (groups.map (·.sources.length)).sum := by
  simp [preparePairs]

theorem preparePairs_sources (groups : List WitnessGroup) :
    (preparePairs groups).map Prod.fst = preparedSources groups := by
  unfold preparedSources
  simp [preparePairs, List.map_flatMap, Function.comp_def]

private theorem map_pair_snd (sources : List Pubkey) (target : Pubkey) :
    (sources.map fun source => (source, target)).map Prod.snd =
      List.replicate sources.length target := by
  induction sources with
  | nil => rfl
  | cons source rest ih =>
      simp only [List.map_cons, List.length_cons]
      rw [ih, List.replicate_succ]

theorem preparePairs_targets (groups : List WitnessGroup) :
    (preparePairs groups).map Prod.snd = preparedTargets groups := by
  induction groups with
  | nil => rfl
  | cons group rest ih =>
      change
        ((group.sources.map fun source => (source, group.target)) ++
          preparePairs rest).map Prod.snd =
        List.replicate group.sources.length group.target ++ preparedTargets rest
      rw [List.map_append, map_pair_snd, ih]

/-- Universal gateway-to-vault array correspondence: flattening the groups
as pairs is exactly zipping the two arrays passed to the withdrawal vault. -/
theorem prepared_zip (groups : List WitnessGroup) :
    (preparedSources groups).zip (preparedTargets groups) = preparePairs groups := by
  rw [← preparePairs_sources, ← preparePairs_targets]
  simpa [List.unzip_eq_map] using List.zip_unzip (preparePairs groups)

theorem prepared_lengths_eq (groups : List WitnessGroup) :
    (preparedSources groups).length = (preparedTargets groups).length := by
  rw [← preparePairs_sources, ← preparePairs_targets]
  simp

/-- End-to-end pure correspondence for the gateway/vault boundary. Under the
conditions established before the pinned gateway calls the vault (a nonempty,
valid flattened batch and a word-sized exact fee), the independently modeled
vault guards accept exactly the pairs produced by `_prepareConsolidationPairs`.
-/
theorem validateVaultAdd_prepared (groups : List WitnessGroup)
    (fee msgValue : Word)
    (hnonempty : preparedSources groups ≠ [])
    (hvalid : ∀ pair ∈ preparePairs groups,
      pair.1.length = pubkeyLength ∧ pair.2.length = pubkeyLength)
    (hfit : (preparedSources groups).length * fee.val < 2 ^ 256)
    (hvalue : msgValue.val = (preparedSources groups).length * fee.val) :
    validateVaultAdd fee msgValue (preparedSources groups)
      (preparedTargets groups) = .ok (preparePairs groups) := by
  have hmul : checkedMulWord (preparedSources groups).length fee = some msgValue := by
    unfold checkedMulWord
    simp only [hfit, ↓reduceDIte]
    congr 1
    apply Verity.Core.Uint256.ext
    exact hvalue.symm
  have hmulTargets :
      checkedMulWord (preparedTargets groups).length fee = some msgValue := by
    rw [← prepared_lengths_eq groups]
    exact hmul
  unfold validateVaultAdd
  simp [hnonempty, prepared_lengths_eq groups, hmulTargets, prepared_zip,
    validateVaultPairs_ok 0 (preparePairs groups) hvalid]
  rfl

/-! ## Raw 48-byte pubkey representation (no `2^384` wrap) -/

theorem integerBE_length (size n : Nat) : (integerBE size n).length = size := by
  induction size generalizing n with
  | zero => rfl
  | succ size ih => simp [integerBE, ih]

private theorem div_lt_pow_succ {a size : Nat}
    (h : a < 256 ^ (size + 1)) : a / 256 < 256 ^ size := by
  have hmul : 256 ^ (size + 1) = 256 ^ size * 256 := Nat.pow_succ _ _
  have : 0 < 256 := by decide
  exact (Nat.div_lt_iff_lt_mul this).mpr (hmul ▸ h)

/-- Distinct identities below `256^size` produce distinct encodings.
Without the bound, `n` and `n + 256^size` collide. -/
theorem integerBE_injective {size a b : Nat}
    (ha : a < 256 ^ size) (hb : b < 256 ^ size)
    (heq : integerBE size a = integerBE size b) : a = b := by
  induction size generalizing a b with
  | zero =>
      cases Nat.lt_one_iff.mp ha
      cases Nat.lt_one_iff.mp hb
      rfl
  | succ size ih =>
      simp [integerBE] at heq
      have hdiv := ih (div_lt_pow_succ ha) (div_lt_pow_succ hb) heq.1
      have hmod : a % 256 = b % 256 := heq.2
      calc
        a = 256 * (a / 256) + a % 256 := (Nat.div_add_mod a 256).symm
        _ = 256 * (b / 256) + b % 256 := by rw [hdiv, hmod]
        _ = b := Nat.div_add_mod b 256

theorem integerBE48_injective {a b : Nat}
    (ha : a < pubkeyModulus) (hb : b < pubkeyModulus)
    (heq : integerBE pubkeyLength a = integerBE pubkeyLength b) : a = b :=
  integerBE_injective ha hb heq

theorem integerBE_wraps (size n : Nat) :
    integerBE size n = integerBE size (n + 256 ^ size) := by
  induction size generalizing n with
  | zero => rfl
  | succ size ih =>
      have hpow : 256 ^ (size + 1) = 256 ^ size * 256 := Nat.pow_succ _ _
      have hdiv :
          (n + 256 ^ (size + 1)) / 256 = n / 256 + 256 ^ size := by
        rw [hpow, Nat.add_mul_div_right _ _ (by decide : 0 < 256)]
      have hmod : (n + 256 ^ (size + 1)) % 256 = n % 256 := by
        rw [hpow, Nat.add_mul_mod_self_right]
      change integerBE size (n / 256) ++ [n % 256] =
        integerBE size ((n + 256 ^ (size + 1)) / 256) ++
          [(n + 256 ^ (size + 1)) % 256]
      rw [hdiv, hmod, ih]

/-- The reviewed #276 wrapping encoder: identities `1` and `1+2^384` collide. -/
theorem integerBE48_collides_unbounded :
    integerBE pubkeyLength 1 = integerBE pubkeyLength (1 + pubkeyModulus) :=
  integerBE_wraps pubkeyLength 1

theorem pubkeyOctets_some (key : Pubkey) (h : RawPubkey key) :
    pubkeyOctets key = some (integerBE pubkeyLength key.identity) := by
  simp [pubkeyOctets, h]

theorem pubkeyOctets_none (key : Pubkey) (h : ¬ RawPubkey key) :
    pubkeyOctets key = none := by
  simp [pubkeyOctets, h]

theorem pubkeyOctets_none_length (key : Pubkey)
    (hlen : key.length ≠ pubkeyLength) : pubkeyOctets key = none :=
  pubkeyOctets_none key (fun h => hlen h.1)

theorem pubkeyOctets_none_unbounded (key : Pubkey)
    (hid : ¬ key.identity < pubkeyModulus) : pubkeyOctets key = none :=
  pubkeyOctets_none key (fun h => hid h.2)

private theorem pubkeyOctets_eq_some {key : Pubkey} {octets : List Nat}
    (h : pubkeyOctets key = some octets) :
    RawPubkey key ∧ octets = integerBE pubkeyLength key.identity := by
  unfold pubkeyOctets at h
  split at h
  · next hraw =>
      exact ⟨hraw, Option.some.inj h.symm⟩
  · contradiction

theorem pubkeyOctets_length (key : Pubkey) (octets : List Nat)
    (h : pubkeyOctets key = some octets) : octets.length = pubkeyLength := by
  rw [(pubkeyOctets_eq_some h).2, integerBE_length]

/-- Distinct raw 48-byte keys do not share a 48-byte encoding. This is the
modulo-collision control: `identity` and `identity + 2^384` are not both
admitted as 48-byte representations. -/
theorem pubkeyOctets_injective {a b : Pubkey} {octets : List Nat}
    (ha : pubkeyOctets a = some octets) (hb : pubkeyOctets b = some octets) :
    a.identity = b.identity ∧ a.length = b.length := by
  have ha' := pubkeyOctets_eq_some ha
  have hb' := pubkeyOctets_eq_some hb
  have hid : a.identity = b.identity :=
    integerBE48_injective ha'.1.2 hb'.1.2 (ha'.2.symm.trans hb'.2)
  exact ⟨hid, ha'.1.1.trans hb'.1.1.symm⟩

/-- Identities that differ by `2^384` cannot both be raw 48-byte keys, so they
cannot encode to the same 48-byte blob through `pubkeyOctets`. -/
theorem pubkeyOctets_rejects_modulus_collision (a b : Pubkey)
    (_hlenA : a.length = pubkeyLength) (_hlenB : b.length = pubkeyLength)
    (hshift : b.identity = a.identity + pubkeyModulus) :
    pubkeyOctets a = none ∨ pubkeyOctets b = none ∨ pubkeyOctets a ≠ pubkeyOctets b := by
  by_cases ha : a.identity < pubkeyModulus
  · right; left
    exact pubkeyOctets_none_unbounded b (by
      intro hb
      have : a.identity + pubkeyModulus < pubkeyModulus := hshift ▸ hb
      exact Nat.not_lt.mpr (Nat.le_add_left pubkeyModulus a.identity) this)
  · left
    exact pubkeyOctets_none_unbounded a ha

private theorem packed_length_96 {src tgt : List Nat}
    (hs : src.length = pubkeyLength) (ht : tgt.length = pubkeyLength) :
    (src ++ tgt).length = 96 := by
  simp [hs, ht, pubkeyLength]

theorem encodePackedRequest_length (source target : Pubkey) (payload : List Nat)
    (h : encodePackedRequest source target = some payload) :
    payload.length = 96 := by
  unfold encodePackedRequest at h
  cases hsrc : pubkeyOctets source with
  | none => simp [hsrc] at h
  | some src =>
      cases htgt : pubkeyOctets target with
      | none => simp [hsrc, htgt] at h
      | some tgt =>
          simp [hsrc, htgt] at h
          subst payload
          exact packed_length_96 (pubkeyOctets_length source src hsrc)
            (pubkeyOctets_length target tgt htgt)

theorem encodePackedRequest_source_prefix (source target : Pubkey)
    (payload src tgt : List Nat)
    (hs : pubkeyOctets source = some src)
    (ht : pubkeyOctets target = some tgt)
    (hp : encodePackedRequest source target = some payload) :
    payload.take pubkeyLength = src := by
  simp [encodePackedRequest, hs, ht] at hp
  subst payload
  simp [pubkeyOctets_length source src hs]

theorem encodePackedRequest_target_suffix (source target : Pubkey)
    (payload src tgt : List Nat)
    (hs : pubkeyOctets source = some src)
    (ht : pubkeyOctets target = some tgt)
    (hp : encodePackedRequest source target = some payload) :
    payload.drop pubkeyLength = tgt := by
  simp [encodePackedRequest, hs, ht] at hp
  subst payload
  simp [pubkeyOctets_length source src hs]

/-- Distinct source/target identities below `2^384` produce distinct 96-byte
callee payloads. Concatenation does not reintroduce the wrap. -/
theorem encodePackedRequest_injective {s₁ t₁ s₂ t₂ : Pubkey} {payload : List Nat}
    (h₁ : encodePackedRequest s₁ t₁ = some payload)
    (h₂ : encodePackedRequest s₂ t₂ = some payload) :
    s₁.identity = s₂.identity ∧ t₁.identity = t₂.identity := by
  unfold encodePackedRequest at h₁ h₂
  cases hs₁ : pubkeyOctets s₁ with
  | none => simp [hs₁] at h₁
  | some src₁ =>
    cases ht₁ : pubkeyOctets t₁ with
    | none => simp [hs₁, ht₁] at h₁
    | some tgt₁ =>
      cases hs₂ : pubkeyOctets s₂ with
      | none => simp [hs₂] at h₂
      | some src₂ =>
        cases ht₂ : pubkeyOctets t₂ with
        | none => simp [hs₂, ht₂] at h₂
        | some tgt₂ =>
          simp [hs₁, ht₁] at h₁
          simp [hs₂, ht₂] at h₂
          have hsrcLen := pubkeyOctets_length s₁ src₁ hs₁
          have hsrcLen₂ := pubkeyOctets_length s₂ src₂ hs₂
          have heq : src₁ ++ tgt₁ = src₂ ++ tgt₂ := h₁.trans h₂.symm
          have hinj := List.append_inj heq (hsrcLen.trans hsrcLen₂.symm)
          have hidS := (pubkeyOctets_injective (octets := src₁) hs₁
            (hinj.1 ▸ hs₂)).1
          have hidT := (pubkeyOctets_injective (octets := tgt₁) ht₁
            (hinj.2 ▸ ht₂)).1
          exact ⟨hidS, hidT⟩

theorem packedPayloads_nil : packedPayloads [] = some [] := rfl

theorem packedPayloads_each_96 (pairs : List (Pubkey × Pubkey))
    (payloads : List (List Nat))
    (h : packedPayloads pairs = some payloads) :
    payloads.length = pairs.length ∧
      ∀ payload ∈ payloads, payload.length = 96 := by
  induction pairs generalizing payloads with
  | nil =>
      cases h
      simp
  | cons pair rest ih =>
      unfold packedPayloads at h
      cases hpair : encodePackedRequest pair.1 pair.2 with
      | none => simp [hpair] at h
      | some payload =>
          cases hrest : packedPayloads rest with
          | none => simp [hpair, hrest] at h
          | some restPayloads =>
              simp [hpair, hrest] at h
              subst payloads
              have ih' := ih restPayloads hrest
              refine ⟨by simp [ih'.1], ?_⟩
              intro p hp
              simp at hp
              cases hp with
              | inl heq =>
                  subst p
                  exact encodePackedRequest_length pair.1 pair.2 payload hpair
              | inr hmem =>
                  exact ih'.2 p hmem

end audit.trio.consolidation
