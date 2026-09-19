import LidoSRv3.Audit.Guarantees.PConsolidation1VaultCalldata
import LidoSRv3.Audit.Source.NoReentry

/-! # P-CONSOLIDATION-1 lazy calldata accessors (caveat C3, 2026-09-19)

`GatewayCall.vaultExternal` decodes the `addConsolidationRequests(bytes[],
bytes[])` argument block eagerly, before the fee quote and the request loop.
The pinned `WithdrawalVaultEIP7685._addConsolidationRequests`
(`WithdrawalVaultEIP7685.sol:56-73`) decodes the two array heads at entry
(solc's calldata `bytes[]` decoder: readable length word, head area within
calldata, reverting with empty data otherwise), quotes the fee, checks the
exact fee, and only then accesses `sourcePubkeys[i]` and `targetPubkeys[i]`
inside the loop, each access reverting with empty data when its offset or
length word does not fit the calldata.

This module models that lazy dispatcher (`vaultLazy`: `lazyEntry`, then the
registered ladder with `lazyLoop` accessing element `i` through
`PConsolidation1VaultCalldata.arrayAccess` at its source position) and proves
the exact relation to the eager one:

* `lazy_eq_eager_wellFormed`: on every argument block the eager decoder
  accepts, the two dispatchers return the same reply (same accept/reject
  decision, world, data and trace);
* `lazy_rejects_malformed`: on every argument block the eager decoder rejects,
  the lazy dispatcher rejects too, so through any CALL both restore the
  caller's world (`eager_caller_restored`, `lazy_caller_restored`);
* the difference on malformed input is confined to the revert data and the
  attempt trace: the eager dispatcher answers `rejected []` before any
  attempt, the lazy one answers the source's revert data after the fee
  STATICCALL and the requests that precede the first failing access.

**Status:** real theorems with complete proofs; axioms `propext`,
`Classical.choice`, `Quot.sound`. -/

set_option autoImplicit false

namespace LidoSRv3.Audit.Guarantees.PConsolidation1VaultLazy
open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live
open audit.trio.consolidation
open PConsolidation1VaultCalldata (elementAccess elementAccess_eq arrayLength arrayAccess
  LazyWellFormed decodeVaultArgs_iff decodeVaultArgs_total vault_rejects_malformed)
open LidoSRv3.Audit.Source.NoReentry (Rejected)

/-- solc's entry-time decoding of the two `bytes[] calldata` parameters: both
head offsets readable, each array's length word readable and its offset table
within the calldata. -/
def lazyEntry (args : Bytes) : Option (Bytes × Nat × Bytes × Nat) :=
  if 64 ≤ args.length then
    match arrayLength (args.drop (decode (args.take 32))) with
    | none => none
    | some n =>
      match arrayLength (args.drop (decode ((args.drop 32).take 32))) with
      | none => none
      | some m =>
        if 32 * n ≤ ((args.drop (decode (args.take 32))).drop 32).length ∧
            32 * m ≤ ((args.drop (decode ((args.drop 32).take 32))).drop 32).length then
          some (args.drop (decode (args.take 32)), n, args.drop (decode ((args.drop 32).take 32)), m)
        else none
  else none

/-- The request loop with the source's lazy element accesses: `rem` requests
remain and the next index is `k`; `sourcePubkeys[i]`, its validation,
`targetPubkeys[i]`, its validation, then the CALL. -/
def lazyLoop (callee : External) (ctx : Context) (inbox : Address) (fee : Live.Word)
    (sRest tRest : Bytes) : Nat → Nat → World → GatewayCall.FrameResult
  | 0, _, w => ⟨.ok (), w, []⟩
  | rem + 1, k, w =>
    match arrayAccess sRest k with
    | none => ⟨.error [], w, []⟩
    | some source =>
      if source.length ≠ 48 then ⟨.error (GatewayCall.errorBytes 0xeb0c68a7 source), w, []⟩
      else match arrayAccess tRest k with
        | none => ⟨.error [], w, []⟩
        | some target =>
          if target.length ≠ 48 then ⟨.error (GatewayCall.errorBytes 0xeb0c68a7 target), w, []⟩
          else
            let p : ProducedPair := ⟨source, target⟩
            let r := lowLevelCall callee ctx inbox (vaultCallPayload p) fee w
            match r.outcome with
            | .error _ =>
                ⟨.error (GatewayCall.errorBytes 0xef36228e (vaultCallPayload p)), r.world,
                  GatewayCall.callTrace r.attempts⟩
            | .ok _ =>
                let next := lazyLoop callee ctx inbox fee sRest tRest rem (k + 1)
                  {r.world with logs := r.world.logs ++ [requestAddedEvent ctx.self (vaultCallPayload p)]}
                ⟨next.outcome, next.world, GatewayCall.callTrace r.attempts ++ next.trace⟩

/-- `GatewayCall.vaultBody` with the array lengths from the entry decoder and
the lazy loop. -/
def vaultBodyLazy (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Address) (value : Live.Word)
    (sRest : Bytes) (n : Nat) (tRest : Bytes) (m : Nat) (w : World) : GatewayCall.FrameResult :=
  if w.balances ctx.self < value.val then ⟨.error (GatewayCall.panic 0x11), w, []⟩
  else if ctx.sender ≠ gateway then ⟨.error (GatewayCall.error0 0xb7d22932), w, []⟩
  else if n = 0 then
    ⟨.error (GatewayCall.errorBytes 0x56e42893 ("sourcePubkeys".toUTF8.toList)), w, []⟩
  else if n ≠ m then
    ⟨.error (GatewayCall.error2 0x4c59bf28 n m), w, []⟩
  else
    let s := lowLevelStaticCall sexternal ctx.self inbox [] w
    match s.outcome with
    | .error _ => ⟨.error (GatewayCall.error0 0x03045050), w, s.attempts⟩
    | .ok data =>
        if data.length ≠ 32 then ⟨.error (GatewayCall.error0 0x8235fc55), w, s.attempts⟩
        else
          let fee := Live.word (decode data)
          let total := n * fee.val
          if total ≥ Verity.Core.UINT256_MODULUS then
            ⟨.error (GatewayCall.panic 0x11), w, s.attempts⟩
          else if total ≠ value.val then
            ⟨.error (GatewayCall.error2 0xdcf6afcb total value.val), w, s.attempts⟩
          else
            let r := lazyLoop callee ctx inbox fee sRest tRest n 0 w
            match r.outcome with
            | .error e => ⟨.error e, r.world, s.attempts ++ r.trace⟩
            | .ok _ =>
                if r.world.balances ctx.self ≠ w.balances ctx.self - value.val then
                  ⟨.error (GatewayCall.panic 1), r.world, s.attempts ++ r.trace⟩
                else ⟨.ok (), r.world, s.attempts ++ r.trace⟩

/-- The vault dispatcher with solc's lazy calldata accessors. -/
def vaultLazy (callee : External) (sexternal : StaticCall.External)
    (gateway inbox : Address) : External := fun request credited =>
  if request.payload.take 4 ≠ GatewayCall.selector then .rejected []
  else match lazyEntry (request.payload.drop 4) with
    | none => .rejected []
    | some (sRest, n, tRest, m) =>
        let r := vaultBodyLazy callee sexternal ⟨request.target, request.caller⟩
          gateway inbox request.value sRest n tRest m credited
        match r.outcome with
        | .error data => .rejectedWithTrace data r.trace
        | .ok _ => .successWithTrace [] r.world r.trace

/-- Every index accessible up to the array length puts the offset table inside
the calldata: the entry-time check of solc. -/
theorem headFit {rest : Bytes} {l : List Bytes}
    (h : ∀ k, k < l.length → arrayAccess rest k = l[k]?) :
    32 * l.length ≤ (rest.drop 32).length := by
  cases hl : l.length with
  | zero => simp
  | succ n =>
    have hk := h n (by omega)
    rw [List.getElem?_eq_some_iff.mpr ⟨by omega, rfl⟩] at hk
    unfold arrayAccess at hk
    rw [elementAccess_eq] at hk
    split at hk
    · rename_i hle
      rw [List.length_drop] at hle
      omega
    · cases hk

theorem lazyEntry_of_wellFormed (args : Bytes) (s t : List Bytes)
    (hw : LazyWellFormed args s t) :
    lazyEntry args = some (args.drop (decode (args.take 32)), s.length,
      args.drop (decode ((args.drop 32).take 32)), t.length) := by
  obtain ⟨h64, ⟨hsl, hsa⟩, ⟨htl, hta⟩⟩ := hw
  unfold lazyEntry
  rw [if_pos h64]
  simp only [hsl, htl]
  rw [if_pos ⟨headFit hsa, headFit hta⟩]

/-- The lazy loop over accessible arrays is the eager loop over the accessed
elements. -/
theorem lazyLoop_eq_loop (callee : External) (ctx : Context) (inbox : Address) (fee : Live.Word)
    (sRest tRest : Bytes) (s t : List Bytes)
    (hs : ∀ k, k < s.length → arrayAccess sRest k = s[k]?)
    (ht : ∀ k, k < t.length → arrayAccess tRest k = t[k]?) (hlen : s.length = t.length) :
    ∀ (rem k : Nat) (w : World), k + rem = s.length →
      lazyLoop callee ctx inbox fee sRest tRest rem k w =
        GatewayCall.loop callee ctx inbox fee (pairsOf (s.drop k) (t.drop k)) w
  | 0, k, w, hk => by
      have hks : k = s.length := by omega
      subst hks
      rw [List.drop_length, hlen, List.drop_length]
      rfl
  | rem + 1, k, w, hk => by
      have hks : k < s.length := by omega
      have hkt : k < t.length := by omega
      have hsk := hs k hks
      have htk := ht k hkt
      rw [List.getElem?_eq_some_iff.mpr ⟨hks, rfl⟩] at hsk
      rw [List.getElem?_eq_some_iff.mpr ⟨hkt, rfl⟩] at htk
      have ih : ∀ w', lazyLoop callee ctx inbox fee sRest tRest rem (k + 1) w' =
          GatewayCall.loop callee ctx inbox fee (pairsOf (s.drop (k + 1)) (t.drop (k + 1))) w' :=
        fun w' => lazyLoop_eq_loop callee ctx inbox fee sRest tRest s t hs ht hlen rem (k + 1) w'
          (by omega)
      rw [List.drop_eq_getElem_cons hks, List.drop_eq_getElem_cons hkt]
      simp only [lazyLoop, GatewayCall.loop, pairsOf, List.zip_cons_cons, List.map_cons, hsk, htk, ih]
        <;> rfl

/-- With the entry decoder's lengths and accessible arrays, the lazy body is
the registered body. -/
theorem bodyLazy_eq_body (callee : External) (sexternal : StaticCall.External)
    (ctx : Context) (gateway inbox : Address) (value : Live.Word) (args : Bytes)
    (s t : List Bytes) (hw : LazyWellFormed args s t) (w : World) :
    vaultBodyLazy callee sexternal ctx gateway inbox value (args.drop (decode (args.take 32)))
        s.length (args.drop (decode ((args.drop 32).take 32))) t.length w =
      GatewayCall.vaultBody callee sexternal ctx gateway inbox value s t w := by
  obtain ⟨_, ⟨_, hsa⟩, ⟨_, hta⟩⟩ := hw
  unfold vaultBodyLazy GatewayCall.vaultBody
  by_cases h1 : w.balances ctx.self < value.val
  · simp only [if_pos h1]
  simp only [if_neg h1]
  by_cases h2 : ctx.sender ≠ gateway
  · simp only [if_pos h2]
  simp only [if_neg h2]
  by_cases h3 : s.length = 0
  · simp only [if_pos h3]
  simp only [if_neg h3]
  by_cases h4 : s.length ≠ t.length
  · simp only [if_pos h4]
  simp only [if_neg h4]
  have hlen : s.length = t.length := by omega
  have key : ∀ (fee : Live.Word) (w' : World),
      lazyLoop callee ctx inbox fee (args.drop (decode (args.take 32)))
        (args.drop (decode ((args.drop 32).take 32))) s.length 0 w' =
      GatewayCall.loop callee ctx inbox fee (pairsOf s t) w' := by
    intro fee w'
    rw [lazyLoop_eq_loop callee ctx inbox fee _ _ s t hsa hta hlen s.length 0 w' (by omega),
      List.drop_zero, List.drop_zero]
  simp only [key]
  try rfl

/-- On a lazily well-formed argument block the two dispatchers agree. -/
theorem lazy_eq_eager_wellFormed (callee : External) (sexternal : StaticCall.External)
    (gateway inbox : Address) (req : Request) (w : World) (s t : List Bytes)
    (hd : decodeVaultArgs (req.payload.drop 4) = some (s, t)) :
    vaultLazy callee sexternal gateway inbox req w =
      GatewayCall.vaultExternal callee sexternal gateway inbox req w := by
  have hw := (decodeVaultArgs_iff _ _ _).mp hd
  unfold vaultLazy GatewayCall.vaultExternal
  split
  · rfl
  · rw [hd, lazyEntry_of_wellFormed _ s t hw]
    simp only []
    rw [bodyLazy_eq_body _ _ _ _ _ _ _ s t hw]
    rfl

/-- A successful lazy loop accessed every index of both arrays. -/
theorem lazyLoop_ok_access (callee : External) (ctx : Context) (inbox : Address) (fee : Live.Word)
    (sRest tRest : Bytes) :
    ∀ (rem k : Nat) (w : World),
      (lazyLoop callee ctx inbox fee sRest tRest rem k w).outcome = .ok () →
      ∀ j, k ≤ j → j < k + rem →
        (∃ x, arrayAccess sRest j = some x) ∧ (∃ y, arrayAccess tRest j = some y)
  | 0, k, w, _, j, hkj, hj => absurd hj (by omega)
  | rem + 1, k, w, h, j, hkj, hj => by
      unfold lazyLoop at h
      cases hsk : arrayAccess sRest k with
      | none => simp [hsk] at h
      | some source =>
        simp only [hsk] at h
        by_cases hsl : source.length ≠ 48
        · simp [hsl] at h
        simp only [hsl, if_false] at h
        cases htk : arrayAccess tRest k with
        | none => simp [htk] at h
        | some target =>
          simp only [htk] at h
          by_cases htl : target.length ≠ 48
          · simp [htl] at h
          simp only [htl, if_false] at h
          cases hr : (lowLevelCall callee ctx inbox (vaultCallPayload ⟨source, target⟩) fee w).outcome with
          | «error» e => simp [hr] at h
          | ok u =>
            simp only [hr] at h
            by_cases hjk : j = k
            · subst hjk
              exact ⟨⟨source, hsk⟩, ⟨target, htk⟩⟩
            · exact lazyLoop_ok_access callee ctx inbox fee sRest tRest rem (k + 1) _ h j
                (by omega) (by omega)

/-- On an argument block with no lazily well-formed reading, the lazy body
cannot commit. -/
theorem vaultBodyLazy_not_ok (args : Bytes) (hm : ∀ s t, ¬ LazyWellFormed args s t)
    (sRest tRest : Bytes) (n m : Nat) (hentry : lazyEntry args = some (sRest, n, tRest, m))
    (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (gateway inbox : Address) (value : Live.Word) (w : World) :
    (vaultBodyLazy callee sexternal ctx gateway inbox value sRest n tRest m w).outcome ≠ .ok () := by
  intro h
  unfold vaultBodyLazy at h
  by_cases h1 : w.balances ctx.self < value.val
  · simp [h1] at h
  simp only [h1, if_false] at h
  by_cases h2 : ctx.sender ≠ gateway
  · simp [h2] at h
  simp only [h2, if_false] at h
  by_cases h3 : n = 0
  · simp [h3] at h
  simp only [h3, if_false] at h
  by_cases h4 : n ≠ m
  · simp [h4] at h
  simp only [h4, if_false] at h
  cases hsc : (lowLevelStaticCall sexternal ctx.self inbox [] w).outcome with
  | «error» e => simp [hsc] at h
  | ok data =>
    simp only [hsc] at h
    by_cases h5 : data.length ≠ 32
    · simp [h5] at h
    simp only [h5, if_false] at h
    by_cases h6 : n * (Live.word (decode data)).val ≥ Verity.Core.UINT256_MODULUS
    · simp [h6] at h
    simp only [h6, if_false] at h
    by_cases h7 : n * (Live.word (decode data)).val ≠ value.val
    · simp [h7] at h
    simp only [h7, if_false] at h
    cases hl : (lazyLoop callee ctx inbox (Live.word (decode data)) sRest tRest n 0 w).outcome with
    | «error» e => simp [hl] at h
    | ok u =>
      have hacc := lazyLoop_ok_access callee ctx inbox (Live.word (decode data)) sRest tRest n 0 w hl
      unfold lazyEntry at hentry
      by_cases h64 : 64 ≤ args.length
      · rw [if_pos h64] at hentry
        cases hn : arrayLength (args.drop (decode (args.take 32))) with
        | none => simp [hn] at hentry
        | some n' =>
          simp only [hn] at hentry
          cases hm' : arrayLength (args.drop (decode ((args.drop 32).take 32))) with
          | none => simp [hm'] at hentry
          | some m' =>
            simp only [hm'] at hentry
            by_cases hfit : 32 * n' ≤ ((args.drop (decode (args.take 32))).drop 32).length ∧
                32 * m' ≤ ((args.drop (decode ((args.drop 32).take 32))).drop 32).length
            · rw [if_pos hfit] at hentry
              simp only [Option.some.injEq, Prod.mk.injEq] at hentry
              obtain ⟨rfl, rfl, rfl, rfl⟩ := hentry
              have hnm : n' = m' := by omega
              apply hm ((List.range n').map fun j =>
                  (arrayAccess (args.drop (decode (args.take 32))) j).getD [])
                ((List.range m').map fun j =>
                  (arrayAccess (args.drop (decode ((args.drop 32).take 32))) j).getD [])
              refine ⟨h64, ⟨?_, ?_⟩, ⟨?_, ?_⟩⟩
              · simp only [List.length_map, List.length_range]
                exact hn
              · intro k hk
                simp only [List.length_map, List.length_range] at hk
                rw [List.getElem?_map, List.getElem?_range hk]
                obtain ⟨x, hx⟩ := (hacc k (by omega) (by omega)).1
                simp [hx]
              · simp only [List.length_map, List.length_range]
                exact hm'
              · intro k hk
                simp only [List.length_map, List.length_range] at hk
                rw [List.getElem?_map, List.getElem?_range hk]
                obtain ⟨y, hy⟩ := (hacc k (by omega) (by omega)).2
                simp [hy]
            · rw [if_neg hfit] at hentry
              cases hentry
      · rw [if_neg h64] at hentry
        cases hentry

/-- On an argument block the eager decoder rejects, the lazy dispatcher
rejects too. -/
theorem lazy_rejects_malformed (callee : External) (sexternal : StaticCall.External)
    (gateway inbox : Address) (req : Request) (w : World)
    (hm : ∀ s t, ¬ LazyWellFormed (req.payload.drop 4) s t) :
    Rejected (vaultLazy callee sexternal gateway inbox req w) := by
  unfold vaultLazy
  split
  · exact ⟨fun _ _ h => Reply.noConfusion h, fun _ _ _ h => Reply.noConfusion h⟩
  · cases he : lazyEntry (req.payload.drop 4) with
    | none => exact ⟨fun _ _ h => Reply.noConfusion h, fun _ _ _ h => Reply.noConfusion h⟩
    | some q =>
      rcases q with ⟨sRest, n, tRest, m⟩
      cases hb : (vaultBodyLazy callee sexternal ⟨req.target, req.caller⟩ gateway inbox req.value
          sRest n tRest m w).outcome with
      | «error» e =>
        simp only [hb]
        exact ⟨fun _ _ h => Reply.noConfusion h, fun _ _ _ h => Reply.noConfusion h⟩
      | ok u =>
        cases u
        exact absurd hb (vaultBodyLazy_not_ok _ hm sRest tRest n m he callee sexternal _ gateway inbox
          req.value w)

/-- Through any CALL into the vault with code, malformed calldata leaves the
caller's world untouched under the eager dispatcher, with empty revert data
and no attempt before the rejection. -/
theorem eager_caller_restored (callee : External) (sexternal : StaticCall.External)
    (gateway inbox : Address) (ctx : Context) (target : Address) (payload : Bytes)
    (value : Live.Word) (w : World)
    (hm : ∀ s t, ¬ LazyWellFormed (payload.drop 4) s t)
    (hcode : ¬ emptyCodeAccount w target) (hbal : ¬ w.balances ctx.self < value.val) :
    lowLevelCall (GatewayCall.vaultExternal callee sexternal gateway inbox) ctx target payload
        value w =
      ⟨.error (.bubbled []), w, [⟨⟨ctx.self, target, value, payload⟩, false, [], []⟩]⟩ := by
  unfold lowLevelCall
  rw [if_neg hbal, if_neg hcode, vault_rejects_malformed callee sexternal gateway inbox _ _ hm]

/-- Through the same CALL, malformed calldata leaves the caller's world
untouched under the lazy dispatcher too; only the revert data and the recorded
attempt differ. -/
theorem lazy_caller_restored (callee : External) (sexternal : StaticCall.External)
    (gateway inbox : Address) (ctx : Context) (target : Address) (payload : Bytes)
    (value : Live.Word) (w : World)
    (hm : ∀ s t, ¬ LazyWellFormed (payload.drop 4) s t)
    (hcode : ¬ emptyCodeAccount w target) (hbal : ¬ w.balances ctx.self < value.val) :
    (lowLevelCall (vaultLazy callee sexternal gateway inbox) ctx target payload value w).world = w ∧
    ∃ d, (lowLevelCall (vaultLazy callee sexternal gateway inbox) ctx target payload value w).outcome =
      .error (.bubbled d) := by
  have hr := lazy_rejects_malformed callee sexternal gateway inbox ⟨ctx.self, target, value, payload⟩
    (transfer w ctx.self target value.val) hm
  unfold lowLevelCall
  rw [if_neg hbal, if_neg hcode]
  cases hl : vaultLazy callee sexternal gateway inbox ⟨ctx.self, target, value, payload⟩
      (transfer w ctx.self target value.val) with
  | rejected d => exact ⟨rfl, d, rfl⟩
  | rejectedWithTrace d n => exact ⟨rfl, d, rfl⟩
  | success d after => exact absurd hl (hr.1 d after)
  | successWithTrace d after n => exact absurd hl (hr.2 d after n)

#print axioms lazy_eq_eager_wellFormed
#print axioms lazy_rejects_malformed
#print axioms eager_caller_restored
#print axioms lazy_caller_restored

end LidoSRv3.Audit.Guarantees.PConsolidation1VaultLazy
