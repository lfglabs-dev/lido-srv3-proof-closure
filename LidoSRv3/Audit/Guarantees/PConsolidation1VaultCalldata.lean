import LidoSRv3.Audit.Guarantees.PConsolidation1ActualGatewayVault

/-!
# P-CONSOLIDATION-1 malformed calldata: the vault argument decoder is total

`GatewayCall.vaultExternal` decodes the `addConsolidationRequests(bytes[],
bytes[])` argument block with `decodeVaultArgs` before the inbox fee quote, the
request loop and every state change. So far the decoder was only shown to
invert the gateway's own encoder (`decodeVaultArgs_gatewayVaultArgs`), i.e. on
the well-formed arrays the composed executor produces.

This module characterizes the decoder on **every** calldata against an
independent specification of Solidity's lazy `bytes[] calldata` accessor
(`elementAccess`: offset word `k` of the head area, then the length word and
payload at that offset of the body, each bounds-checked):

* soundness — a decoded array is exactly what index-by-index access returns
  (`decodeOffsetSeq_access`, `decodeBytesArray_some`);
* completeness — if every index accesses successfully, the decoder returns
  those elements (`decodeOffsetSeq_of_access`, `decodeBytesArray_of_access`);
* rejection — a rejected array has an index whose access fails
  (`decodeOffsetSeq_none`, `decodeBytesArray_none`);
* totality — every argument block either decodes to the unique lazily
  well-formed pair or is rejected and no such pair exists
  (`decodeVaultArgs_iff`, `decodeVaultArgs_total`).

Consequently any calldata that is not a lazily well-formed pair of byte arrays
behind the selector is refused by the vault dispatcher with `rejected []`:
no fee quote, no request, no state change (`vault_rejects_malformed`,
`vault_reply_well_formed`). The model decodes eagerly where Solidity accesses
lazily inside the loop; `PConsolidation1VaultLazy` models the lazy accessors
and proves the two dispatchers equal on every well-formed argument block and
both rejecting on every malformed one, so the difference is confined to the
revert data and the attempted-call trace, never the final (reverted) state.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
-/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PConsolidation1VaultCalldata
open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live
open audit.trio.consolidation

/-- Solidity's `bytes[] calldata` element accessor: element `k` is reached
through offset word `k` of the head area, then the framed element at that
offset of the body. Each step is bounds-checked. -/
def elementAccess (body : Bytes) : Bytes → Nat → Option Bytes
  | heads, 0 =>
    if 32 ≤ heads.length then decodeBytesElement (body.drop (decode (heads.take 32))) else none
  | heads, k + 1 => elementAccess body (heads.drop 32) k

/-- Index form of the accessor: offset word `k` sits at octet `32 · k`. -/
theorem elementAccess_eq (body : Bytes) :
    ∀ (k : Nat) (heads : Bytes), elementAccess body heads k =
      if 32 ≤ (heads.drop (32 * k)).length then
        decodeBytesElement (body.drop (decode ((heads.drop (32 * k)).take 32)))
      else none
  | 0, heads => by simp [elementAccess]
  | k + 1, heads => by
    have hd : (heads.drop 32).drop (32 * k) = heads.drop (32 * (k + 1)) := by
      rw [List.drop_drop]
      congr 1
      omega
    rw [elementAccess, elementAccess_eq body k (heads.drop 32), hd]

/-- Soundness: a decoded tail is exactly what index-by-index access returns. -/
theorem decodeOffsetSeq_access (body : Bytes) :
    ∀ (n : Nat) (heads : Bytes) (ps : List Bytes),
      decodeOffsetSeq body heads n = some ps →
      ps.length = n ∧ ∀ k, k < n → elementAccess body heads k = ps[k]?
  | 0, heads, ps, h => by
    simp only [decodeOffsetSeq, Option.some.injEq] at h
    subst h
    exact ⟨rfl, fun k hk => absurd hk (Nat.not_lt_zero k)⟩
  | n + 1, heads, ps, h => by
    unfold decodeOffsetSeq at h
    split at h
    · rename_i h32
      cases hel : decodeBytesElement (body.drop (decode (heads.take 32))) with
      | none => simp [hel] at h
      | some p =>
        simp only [hel] at h
        cases hrest : decodeOffsetSeq body (heads.drop 32) n with
        | none => simp [hrest] at h
        | some qs =>
          simp only [hrest, Option.map, Option.some.injEq] at h
          subst h
          obtain ⟨hlen, hacc⟩ := decodeOffsetSeq_access body n (heads.drop 32) qs hrest
          refine ⟨by simp [hlen], ?_⟩
          intro k hk
          cases k with
          | zero => simp [elementAccess, h32, hel]
          | succ k =>
            simp only [elementAccess, List.getElem?_cons_succ]
            exact hacc k (by omega)
    · cases h

/-- Rejection: a rejected tail has an index whose access fails. -/
theorem decodeOffsetSeq_none (body : Bytes) :
    ∀ (n : Nat) (heads : Bytes), decodeOffsetSeq body heads n = none →
      ∃ k, k < n ∧ elementAccess body heads k = none
  | 0, heads, h => by simp [decodeOffsetSeq] at h
  | n + 1, heads, h => by
    unfold decodeOffsetSeq at h
    split at h
    · rename_i h32
      cases hel : decodeBytesElement (body.drop (decode (heads.take 32))) with
      | none => exact ⟨0, Nat.succ_pos n, by simp [elementAccess, h32, hel]⟩
      | some p =>
        simp only [hel] at h
        cases hrest : decodeOffsetSeq body (heads.drop 32) n with
        | none =>
          obtain ⟨k, hk, hacc⟩ := decodeOffsetSeq_none body n (heads.drop 32) hrest
          refine ⟨k + 1, by omega, ?_⟩
          simp only [elementAccess]
          exact hacc
        | some qs => simp [hrest] at h
    · rename_i h32
      exact ⟨0, Nat.succ_pos n, by simp [elementAccess, h32]⟩

/-- Completeness: if every index accesses successfully, the decoder returns
exactly those elements. -/
theorem decodeOffsetSeq_of_access (body : Bytes) :
    ∀ (n : Nat) (heads : Bytes) (ps : List Bytes), ps.length = n →
      (∀ k, k < n → elementAccess body heads k = ps[k]?) →
      decodeOffsetSeq body heads n = some ps
  | 0, heads, ps, hlen, _ => by
    have hnil : ps = [] := List.eq_nil_of_length_eq_zero hlen
    subst hnil
    rfl
  | n + 1, heads, ps, hlen, hacc => by
    cases ps with
    | nil => simp at hlen
    | cons p qs =>
      have h0 := hacc 0 (Nat.succ_pos n)
      simp only [elementAccess, List.getElem?_cons_zero] at h0
      split at h0
      · rename_i h32
        have hrest : decodeOffsetSeq body (heads.drop 32) n = some qs :=
          decodeOffsetSeq_of_access body n (heads.drop 32) qs (by simpa using hlen)
            (fun k hk => by
              have hk1 := hacc (k + 1) (by omega)
              simpa only [elementAccess, List.getElem?_cons_succ] using hk1)
        unfold decodeOffsetSeq
        simp [h32, h0, hrest]
      · cases h0

/-- The count word of a `bytes[]` tail, bounds-checked. -/
def arrayLength (rest : Bytes) : Option Nat :=
  if 32 ≤ rest.length then some (decode (rest.take 32)) else none

/-- Element `k` of a `bytes[]` tail through its offset table. -/
def arrayAccess (rest : Bytes) (k : Nat) : Option Bytes :=
  elementAccess (rest.drop 32) (rest.drop 32) k

theorem decodeBytesArray_some (rest : Bytes) (ps : List Bytes)
    (h : decodeBytesArray rest = some ps) :
    arrayLength rest = some ps.length ∧ ∀ k, k < ps.length → arrayAccess rest k = ps[k]? := by
  unfold decodeBytesArray at h
  split at h
  · rename_i h32
    obtain ⟨hlen, hacc⟩ := decodeOffsetSeq_access (rest.drop 32) _ _ ps h
    refine ⟨?_, fun k hk => hacc k (by omega)⟩
    simp [arrayLength, h32, hlen]
  · cases h

theorem decodeBytesArray_none (rest : Bytes) (h : decodeBytesArray rest = none) :
    arrayLength rest = none ∨
      ∃ n, arrayLength rest = some n ∧ ∃ k, k < n ∧ arrayAccess rest k = none := by
  unfold decodeBytesArray at h
  split at h
  · rename_i h32
    obtain ⟨k, hk, hacc⟩ := decodeOffsetSeq_none (rest.drop 32) _ (rest.drop 32) h
    exact Or.inr ⟨_, by simp [arrayLength, h32], k, hk, hacc⟩
  · rename_i h32
    exact Or.inl (by simp [arrayLength, h32])

theorem decodeBytesArray_of_access (rest : Bytes) (ps : List Bytes)
    (hlen : arrayLength rest = some ps.length)
    (hacc : ∀ k, k < ps.length → arrayAccess rest k = ps[k]?) :
    decodeBytesArray rest = some ps := by
  unfold arrayLength at hlen
  split at hlen
  · rename_i h32
    simp only [Option.some.injEq] at hlen
    unfold decodeBytesArray
    rw [if_pos h32, hlen]
    exact decodeOffsetSeq_of_access _ _ _ ps rfl hacc
  · cases hlen

/-- Solidity's lazy accessors succeed at every index of both arrays of the
argument block, and the arrays are exactly what they return. -/
def LazyWellFormed (args : Bytes) (sources targets : List Bytes) : Prop :=
  64 ≤ args.length ∧
  (arrayLength (args.drop (decode (args.take 32))) = some sources.length ∧
    ∀ k, k < sources.length → arrayAccess (args.drop (decode (args.take 32))) k = sources[k]?) ∧
  (arrayLength (args.drop (decode ((args.drop 32).take 32))) = some targets.length ∧
    ∀ k, k < targets.length →
      arrayAccess (args.drop (decode ((args.drop 32).take 32))) k = targets[k]?)

/-- The decoder accepts exactly the lazily well-formed argument blocks, and
returns exactly the lazily accessed arrays. -/
theorem decodeVaultArgs_iff (args : Bytes) (sources targets : List Bytes) :
    decodeVaultArgs args = some (sources, targets) ↔ LazyWellFormed args sources targets := by
  constructor
  · intro h
    unfold decodeVaultArgs at h
    split at h
    · rename_i h64
      cases hs : decodeBytesArray (args.drop (decode (args.take 32))) with
      | none => simp [hs] at h
      | some s =>
        cases ht : decodeBytesArray (args.drop (decode ((args.drop 32).take 32))) with
        | none => simp [hs, ht] at h
        | some t =>
          simp only [hs, ht, Option.some.injEq, Prod.mk.injEq] at h
          obtain ⟨rfl, rfl⟩ := h
          exact ⟨h64, decodeBytesArray_some _ _ hs, decodeBytesArray_some _ _ ht⟩
    · cases h
  · rintro ⟨h64, ⟨hsl, hsa⟩, ⟨htl, hta⟩⟩
    have hsdec := decodeBytesArray_of_access _ _ hsl hsa
    have htdec := decodeBytesArray_of_access _ _ htl hta
    unfold decodeVaultArgs
    simp [h64, hsdec, htdec]

/-- Totality: every argument block either decodes to the unique lazily
well-formed pair, or is rejected and no lazily well-formed pair exists. -/
theorem decodeVaultArgs_total (args : Bytes) :
    (∃ sources targets, decodeVaultArgs args = some (sources, targets) ∧
      LazyWellFormed args sources targets) ∨
    (decodeVaultArgs args = none ∧ ∀ sources targets, ¬ LazyWellFormed args sources targets) := by
  cases h : decodeVaultArgs args with
  | none =>
    refine Or.inr ⟨rfl, fun s t hw => ?_⟩
    have := (decodeVaultArgs_iff args s t).mpr hw
    rw [this] at h
    cases h
  | some pair =>
    rcases pair with ⟨s, t⟩
    exact Or.inl ⟨s, t, rfl, (decodeVaultArgs_iff args s t).mp h⟩

/-- A wrong selector is refused before decoding. -/
theorem vault_rejects_selector (callee : External) (sexternal : StaticCall.External)
    (gateway inbox : Address) (req : Request) (w : World)
    (hsel : req.payload.take 4 ≠ GatewayCall.selector) :
    GatewayCall.vaultExternal callee sexternal gateway inbox req w = .rejected [] := by
  simp [GatewayCall.vaultExternal, hsel]

/-- Any calldata whose argument block is not a lazily well-formed pair of byte
arrays is refused by the vault dispatcher with `rejected []`: no fee quote, no
request and no state change happen. -/
theorem vault_rejects_malformed (callee : External) (sexternal : StaticCall.External)
    (gateway inbox : Address) (req : Request) (w : World)
    (h : ∀ sources targets, ¬ LazyWellFormed (req.payload.drop 4) sources targets) :
    GatewayCall.vaultExternal callee sexternal gateway inbox req w = .rejected [] := by
  unfold GatewayCall.vaultExternal
  split
  · rfl
  · rcases decodeVaultArgs_total (req.payload.drop 4) with ⟨s, t, _, hw⟩ | ⟨hn, _⟩
    · exact absurd hw (h s t)
    · simp [hn]

/-- Conversely, every reply other than the bare rejection came from the
selector and a lazily well-formed argument block, decoded to exactly the
arrays the body consumed. -/
theorem vault_reply_well_formed (callee : External) (sexternal : StaticCall.External)
    (gateway inbox : Address) (req : Request) (w : World)
    (h : GatewayCall.vaultExternal callee sexternal gateway inbox req w ≠ .rejected []) :
    req.payload.take 4 = GatewayCall.selector ∧
    ∃ sources targets, decodeVaultArgs (req.payload.drop 4) = some (sources, targets) ∧
      LazyWellFormed (req.payload.drop 4) sources targets := by
  unfold GatewayCall.vaultExternal at h
  split at h
  · exact absurd rfl h
  · rename_i hsel
    rcases decodeVaultArgs_total (req.payload.drop 4) with ⟨s, t, hd, hw⟩ | ⟨hn, _⟩
    · exact ⟨by simpa using hsel, s, t, hd, hw⟩
    · simp [hn] at h

/-- The gateway's own argument block is lazily well-formed: the round trip on
the encoder is the special case of the characterization. -/
theorem gateway_args_well_formed (sources targets : List Bytes)
    (hs : ∀ b ∈ sources, b.length < 256 ^ 32) (ht : ∀ b ∈ targets, b.length < 256 ^ 32)
    (hsfit : 64 + (abiBytesArray sources).length < 256 ^ 32)
    (htfit : (abiBytesArray targets).length < 256 ^ 32) :
    LazyWellFormed (gatewayVaultArgs sources targets) sources targets :=
  (decodeVaultArgs_iff _ _ _).mp (decodeVaultArgs_gatewayVaultArgs sources targets hs ht hsfit htfit)

#print axioms elementAccess_eq
#print axioms decodeOffsetSeq_access
#print axioms decodeOffsetSeq_none
#print axioms decodeOffsetSeq_of_access
#print axioms decodeBytesArray_some
#print axioms decodeBytesArray_none
#print axioms decodeBytesArray_of_access
#print axioms decodeVaultArgs_iff
#print axioms decodeVaultArgs_total
#print axioms vault_rejects_selector
#print axioms vault_rejects_malformed
#print axioms vault_reply_well_formed
#print axioms gateway_args_well_formed

end LidoSRv3.Audit.Guarantees.PConsolidation1VaultCalldata
