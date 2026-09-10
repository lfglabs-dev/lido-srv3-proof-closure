import audit.trio.consolidation.GatewayCall

/-!
Same-world settlement suffix of ConsolidationGateway.sol:209–222 at core
17005714f151e5502c559932319a3f2f74ac2436, with its pure checked count transition
(189–199), fee helpers (285–307), and balance modifier (118–122).

The input world is already payable-credited. Role/pause/DSM/witness/quota and
locator admission are outside this executor: the pure count is replayed from
these same raw groups and does not stand for executing that intervening prefix.
The configured vault getter executes its nested inbox STATICCALL. Then the
existing actual vault CALL consumes the derived total and raw-byte producer;
refundFee consumes the world returned by that CALL. No callee frame premise.

Source-array allocation extents, lazy malformed ABI behavior, LOG ABI,
precompile dispatch, gas, deployment and the omitted prefix are not proved.
-/
namespace audit.trio.consolidation.GatewaySettlement
open LidoSRv3.Audit.Source.TrioReserve1
open LidoSRv3.Audit.Source.TrioReserve1.Live

/-- Number of source keys in the actual grouped input. -/
def requestCount (groups : List WitnessGroupBytes) : Nat :=
  (groups.map fun g => g.sources.length).sum

/-- The counted keys are exactly those used by the existing byte producer. -/
theorem requestCount_sourceArray (groups : List WitnessGroupBytes) :
    (GatewayCall.sourceArray groups).length = requestCount groups := by
  induction groups with
  | nil => rfl
  | cons g gs ih =>
    simp [GatewayCall.sourceArray, preparePairBytes, requestCount]

/-- Source checked-count loop, including the empty-group error. -/
def countGroups : List WitnessGroupBytes → Nat → Nat → Except Fault Nat
  | [], _, total => .ok total
  | g :: gs, index, total =>
      if g.sources.length = 0 then
        .error (.bubbled (encode 4 0x86f1b39a ++ encode 32 index))
      else if total + g.sources.length ≥ Verity.Core.UINT256_MODULUS then
        .error (.bubbled (GatewayCall.panic 0x11))
      else countGroups gs (index + 1) (total + g.sources.length)

theorem countGroups_success (groups : List WitnessGroupBytes) (index total n : Nat)
    (ht : total < Verity.Core.UINT256_MODULUS)
    (h : countGroups groups index total = .ok n) :
    n = total + requestCount groups ∧ n < Verity.Core.UINT256_MODULUS := by
  induction groups generalizing index total with
  | nil => simp [countGroups] at h; subst n; simp [requestCount, ht]
  | cons g gs ih =>
      unfold countGroups at h
      split at h
      · contradiction
      · split at h
        · contradiction
        · rename_i hb
          obtain ⟨he,hn⟩ := ih (index+1) (total+g.sources.length) (by omega) h
          exact ⟨by simpa [requestCount, Nat.add_assoc] using he,hn⟩

/-- Observations include the typed getter as depth1 and its inbox read as
static depth2; no intermediate writable world is erased. -/
structure QuoteResult where
  outcome : Except Fault Word
  trace : List NestedAttempt

def quoteSelector : Nat := 0x1e515533

def quoteRequest (ctx : Context) (vault : Address) : Request :=
  ⟨ctx.self, vault, Live.word 0, encode 4 quoteSelector⟩

def quoteTrace (ctx : Context) (vault : Address) (accepted : Bool)
    (returned : Bytes) (nested : List NestedAttempt) : List NestedAttempt :=
  ⟨quoteRequest ctx vault, true, accepted, returned, 1⟩ ::
    nested.map (fun n => {n with depth := n.depth+1})

/-- Typed 0.8.25 getter: a code-less target returns empty bytes and fails
caller-side uint256 ABI decoding. A configured code-present vault executes
_getFeeFromContract on this same world, with its exact32-byte check and errors.
The source getter's returned word is ABI-encoded for the outer STATICCALL. -/
def quote (sexternal : StaticCall.External) (ctx : Context) (vault inbox : Address)
    (before : World) : QuoteResult :=
  if (before.core.codeSize vault.val).val = 0 then
    ⟨.error .empty, quoteTrace ctx vault true [] []⟩
  else
    let s := lowLevelStaticCall sexternal vault inbox [] before
    match s.outcome with
    | .error _ =>
        let e := GatewayCall.error0 0x03045050
        ⟨.error (.bubbled e), quoteTrace ctx vault false e s.attempts⟩
    | .ok data =>
        if data.length ≠ 32 then
          let e := GatewayCall.error0 0x8235fc55
          ⟨.error (.bubbled e), quoteTrace ctx vault false e s.attempts⟩
        else
          let fee := Live.word (decode data)
          ⟨.ok fee, quoteTrace ctx vault true (encode 32 fee.val) s.attempts⟩

theorem quote_success (sexternal : StaticCall.External) (ctx : Context)
    (vault inbox : Address) (before : World) (fee : Word)
    (h : (quote sexternal ctx vault inbox before).outcome = .ok fee) :
    (before.core.codeSize vault.val).val ≠ 0 ∧
    ∃ data attempts,
      lowLevelStaticCall sexternal vault inbox [] before = ⟨.ok data,attempts⟩ ∧
      data.length = 32 ∧ fee = Live.word (decode data) ∧
      (quote sexternal ctx vault inbox before).trace =
        quoteTrace ctx vault true (encode 32 fee.val) attempts := by
  unfold quote at h ⊢
  split at h
  · contradiction
  · rename_i hc
    simp only [hc,if_false]
    cases hs : lowLevelStaticCall sexternal vault inbox [] before with
    | mk out ats =>
      cases out with
      | «error» e => simp [hs] at h
      | ok data =>
        simp only [hs] at h ⊢
        split at h
        · contradiction
        · rename_i hl
          have hl' : data.length = 32 := by simpa using hl
          simp only [hl',ne_eq,not_true_eq_false,if_false] at h ⊢
          cases h
          exact ⟨hc,data,ats,rfl,hl',rfl,rfl⟩

structure Result where
  outcome : Except Fault Unit
  world : World
  trace : List NestedAttempt

/-- After quote and fee checks, the two actual calls are sequential in one
world. Gateway's final modifier assertion follows the refund, not the vault. -/
def settle (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address)
    (msgValue totalFee refund : Word) (groups : List WitnessGroupBytes)
    (before : World) : Result :=
  let v := GatewayCall.execute callee staticExternal ctx vault gateway inbox totalFee groups before
  match v.outcome with
  | .error e => ⟨.error e,v.world,GatewayCall.callTrace v.attempts⟩
  | .ok _ =>
    let r := refundFee refundExternal ctx refund recipient v.world
    match r.outcome with
    | .error e => ⟨.error e,r.world,GatewayCall.callTrace v.attempts ++ GatewayCall.callTrace r.attempts⟩
    | .ok _ =>
      if r.world.balances ctx.self ≠ before.balances ctx.self - msgValue.val then
        ⟨.error (.bubbled (GatewayCall.panic 1)),r.world,
          GatewayCall.callTrace v.attempts ++ GatewayCall.callTrace r.attempts⟩
      else ⟨.ok (),r.world,GatewayCall.callTrace v.attempts ++ GatewayCall.callTrace r.attempts⟩

/-- The quoted fee is multiplied by the executed request count with Solidity's
checked uint256 multiplication, then _checkFee computes the exact remainder. -/
def afterQuote (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (count : Nat) (before : World) : Result :=
  let q := quote staticExternal ctx vault inbox before
  match q.outcome with
  | .error e => ⟨.error e,before,q.trace⟩
  | .ok fee =>
    let total := count * fee.val
    if total ≥ Verity.Core.UINT256_MODULUS then
      ⟨.error (.bubbled (GatewayCall.panic 0x11)),before,q.trace⟩
    else if msgValue.val < total then
      ⟨.error (.bubbled (GatewayCall.error2 0xa458261b total msgValue.val)),before,q.trace⟩
    else
      let s := settle callee refundExternal staticExternal ctx vault gateway inbox recipient
        msgValue (Live.word total) (Live.word (msgValue.val-total)) groups before
      ⟨s.outcome,s.world,q.trace ++ s.trace⟩

/-- The payable modifier's checked entry subtraction precedes the body.
Pure guards/count are replayed; omitted stateful admission is not simulated. -/
def body (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) : Result :=
  if before.balances ctx.self < msgValue.val then
    ⟨.error (.bubbled (GatewayCall.panic 0x11)),before,[]⟩
  else if msgValue.val = 0 then
    ⟨.error (.bubbled (GatewayCall.errorBytes 0x56e42893 "msg.value".toUTF8.toList)),before,[]⟩
  else if groups.length = 0 then
    ⟨.error (.bubbled (GatewayCall.errorBytes 0x56e42893 "groups".toUTF8.toList)),before,[]⟩
  else match countGroups groups 0 0 with
    | .error e => ⟨.error e,before,[]⟩
    | .ok count => afterQuote callee refundExternal staticExternal ctx vault gateway inbox recipient
        msgValue groups count before

/-- Root rollback is the declared whole-world model semantics; traces retain
attempts even when the earlier vault effects are reverted by refund failure. -/
def execute (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) : Result :=
  let r := body callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before
  match r.outcome with
  | .ok () => r
  | .error e => ⟨.error e,before,r.trace⟩

theorem failure_restores (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) (fault : Fault)
    (h : (execute callee refundExternal staticExternal ctx vault gateway inbox recipient
      msgValue groups before).outcome = .error fault) :
    (execute callee refundExternal staticExternal ctx vault gateway inbox recipient
      msgValue groups before).world = before := by
  unfold execute at h ⊢
  dsimp only at h ⊢
  split <;> simp_all


/-- Necessary effects of the two actual calls, extracted from settle success. -/
structure SettlementEffects (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address)
    (msgValue totalFee refund : Word) (groups : List WitnessGroupBytes) (before : World) : Prop where
  vaultOk : ∃ returned,
    (GatewayCall.execute callee staticExternal ctx vault gateway inbox totalFee groups before).outcome = .ok returned
  refundOk : (refundFee refundExternal ctx refund recipient
    (GatewayCall.execute callee staticExternal ctx vault gateway inbox totalFee groups before).world).outcome = .ok ()
  world : (settle callee refundExternal staticExternal ctx vault gateway inbox recipient
    msgValue totalFee refund groups before).world =
    (refundFee refundExternal ctx refund recipient
      (GatewayCall.execute callee staticExternal ctx vault gateway inbox totalFee groups before).world).world
  trace : (settle callee refundExternal staticExternal ctx vault gateway inbox recipient
    msgValue totalFee refund groups before).trace =
    GatewayCall.callTrace (GatewayCall.execute callee staticExternal ctx vault gateway inbox totalFee groups before).attempts ++
    GatewayCall.callTrace (refundFee refundExternal ctx refund recipient
      (GatewayCall.execute callee staticExternal ctx vault gateway inbox totalFee groups before).world).attempts
  balance : (refundFee refundExternal ctx refund recipient
      (GatewayCall.execute callee staticExternal ctx vault gateway inbox totalFee groups before).world).world.balances ctx.self =
    before.balances ctx.self - msgValue.val

theorem settle_success (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address)
    (msgValue totalFee refund : Word) (groups : List WitnessGroupBytes) (before : World)
    (h : (settle callee refundExternal staticExternal ctx vault gateway inbox recipient
      msgValue totalFee refund groups before).outcome = .ok ()) :
    SettlementEffects callee refundExternal staticExternal ctx vault gateway inbox recipient
      msgValue totalFee refund groups before := by
  cases hv : GatewayCall.execute callee staticExternal ctx vault gateway inbox totalFee groups before with
  | mk out after ats =>
    cases out with
    | «error» e => simp [settle,hv] at h
    | ok data =>
      cases hr : refundFee refundExternal ctx refund recipient after with
      | mk out' final rats =>
        cases out' with
        | «error» e => simp [settle,hv,hr] at h
        | ok u =>
          cases u
          have hb : final.balances ctx.self = before.balances ctx.self - msgValue.val := by
            by_contra hn
            simp [settle,hv,hr,hn] at h
          constructor
          · exact ⟨data,by simp [hv]⟩
          · simp [hv,hr]
          · simp [settle,hv,hr,hb]
          · simp [settle,hv,hr,hb]
          · simp [hv,hr,hb]

/-- Necessary quote/check/settlement facts. Neither fee nor stage receipts are
input assumptions: each is extracted from the executed afterQuote result. -/
theorem afterQuote_success (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (count : Nat) (before : World)
    (h : (afterQuote callee refundExternal staticExternal ctx vault gateway inbox recipient
      msgValue groups count before).outcome = .ok ()) :
    ∃ fee,
      (quote staticExternal ctx vault inbox before).outcome = .ok fee ∧
      count * fee.val < Verity.Core.UINT256_MODULUS ∧
      count * fee.val ≤ msgValue.val ∧
      let total := Live.word (count * fee.val)
      let refund := Live.word (msgValue.val - count * fee.val)
      total.val = count * fee.val ∧
      total.val + refund.val = msgValue.val ∧
      checkFee msgValue total = .ok refund ∧
      SettlementEffects callee refundExternal staticExternal ctx vault gateway inbox recipient
        msgValue total refund groups before ∧
      (afterQuote callee refundExternal staticExternal ctx vault gateway inbox recipient
        msgValue groups count before).world =
        (settle callee refundExternal staticExternal ctx vault gateway inbox recipient
          msgValue total refund groups before).world ∧
      (afterQuote callee refundExternal staticExternal ctx vault gateway inbox recipient
        msgValue groups count before).trace =
        (quote staticExternal ctx vault inbox before).trace ++
        (settle callee refundExternal staticExternal ctx vault gateway inbox recipient
          msgValue total refund groups before).trace := by
  cases hq : (quote staticExternal ctx vault inbox before).outcome with
  | «error» e => simp [afterQuote,hq] at h
  | ok fee =>
    unfold afterQuote at h
    simp only [hq] at h
    split at h
    · contradiction
    · rename_i ht
      split at h
      · contradiction
      · rename_i hm
        have ht' : count * fee.val < Verity.Core.UINT256_MODULUS := by omega
        have hm' : count * fee.val ≤ msgValue.val := by omega
        have hw : (Live.word (count * fee.val)).val = count * fee.val := by
          exact Nat.mod_eq_of_lt ht'
        have hr : (Live.word (msgValue.val - count * fee.val)).val = msgValue.val - count * fee.val := by
          exact Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.sub_le _ _) msgValue.isLt)
        refine ⟨fee,rfl,ht',hm',hw,?_,?_,settle_success _ _ _ _ _ _ _ _ _ _ _ _ _ h,?_,?_⟩
        · rw [hw,hr]; omega
        · have hcf := checkFee_refund msgValue (Live.word (count * fee.val)) (by simpa only [hw] using hm')
          rw [hw] at hcf
          exact hcf
        · simp [afterQuote,hq,ht,hm]
        · simp [afterQuote,hq,ht,hm]

/-- A successful body actually counted these groups, then ran afterQuote.
The pure entry guards are derived rather than supplied. -/
theorem body_success (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (body callee refundExternal staticExternal ctx vault gateway inbox recipient
      msgValue groups before).outcome = .ok ()) :
    msgValue.val ≤ before.balances ctx.self ∧ msgValue.val ≠ 0 ∧ groups.length ≠ 0 ∧
    countGroups groups 0 0 = .ok (requestCount groups) ∧
    requestCount groups < Verity.Core.UINT256_MODULUS ∧
    (afterQuote callee refundExternal staticExternal ctx vault gateway inbox recipient
      msgValue groups (requestCount groups) before).outcome = .ok () ∧
    body callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before =
      afterQuote callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups (requestCount groups) before := by
  unfold body at h
  split at h
  · contradiction
  · rename_i hb
    split at h
    · contradiction
    · rename_i hm
      split at h
      · contradiction
      · rename_i hg
        cases hc : countGroups groups 0 0 with
        | «error» e => simp [hc] at h
        | ok n =>
          simp only [hc] at h
          obtain ⟨hn,hlt⟩ := countGroups_success groups 0 0 n (by decide) hc
          simp only [Nat.zero_add] at hn
          subst n
          exact ⟨by omega,hm,hg,rfl,hlt,h,by simp [body,hb,hm,hg,hc]⟩

theorem execute_success_body (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (execute callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before).outcome = .ok ()) :
    (body callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before).outcome = .ok () ∧
    execute callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before =
      body callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before := by
  unfold execute at h ⊢
  dsimp only at h ⊢
  split <;> simp_all

/-- Main necessary-success certificate, intentionally retaining executable
stage equalities and same-world wiring. No aggregate recipient-credit claim. -/
structure Success (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) : Prop where
  credited : msgValue.val ≤ before.balances ctx.self
  nonzero : msgValue.val ≠ 0
  nonempty : groups.length ≠ 0
  counted : countGroups groups 0 0 = .ok (requestCount groups)
  countFits : requestCount groups < Verity.Core.UINT256_MODULUS
  effects : ∃ fee data quoteAttempts,
    (quote staticExternal ctx vault inbox before).outcome = .ok fee ∧
    lowLevelStaticCall staticExternal vault inbox [] before = ⟨.ok data,quoteAttempts⟩ ∧
    data.length = 32 ∧ fee = Live.word (decode data) ∧
    (quote staticExternal ctx vault inbox before).trace = quoteTrace ctx vault true (encode 32 fee.val) quoteAttempts ∧
    requestCount groups * fee.val < Verity.Core.UINT256_MODULUS ∧
    requestCount groups * fee.val ≤ msgValue.val ∧
    let total := Live.word (requestCount groups * fee.val)
    let refund := Live.word (msgValue.val - requestCount groups * fee.val)
    total.val = requestCount groups * fee.val ∧ total.val + refund.val = msgValue.val ∧
    checkFee msgValue total = .ok refund ∧
    SettlementEffects callee refundExternal staticExternal ctx vault gateway inbox recipient
      msgValue total refund groups before ∧
    let v := GatewayCall.execute callee staticExternal ctx vault gateway inbox total groups before
    let r := refundFee refundExternal ctx refund recipient v.world
    (∀ a ∈ r.attempts, a.request = refundRequest ctx refund recipient) ∧
    (refund.val = 0 → r = ⟨.ok (),v.world,[]⟩) ∧
    (execute callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before).world = r.world ∧
    (execute callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before).trace =
      quoteTrace ctx vault true (encode 32 fee.val) quoteAttempts ++
      (GatewayCall.callTrace v.attempts ++ GatewayCall.callTrace r.attempts)

theorem execute_success (callee refundExternal : External) (staticExternal : StaticCall.External)
    (ctx : Context) (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (execute callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before).outcome = .ok ()) :
    Success callee refundExternal staticExternal ctx vault gateway inbox recipient msgValue groups before := by
  obtain ⟨hb,he⟩ := execute_success_body _ _ _ _ _ _ _ _ _ _ _ h
  obtain ⟨hpay,hm,hg,hc,hfit,ha,hba⟩ := body_success _ _ _ _ _ _ _ _ _ _ _ hb
  obtain ⟨fee,hq,hprod,hle,ht,hsplit,hcheck,hsettle,hw,htrace⟩ := afterQuote_success _ _ _ _ _ _ _ _ _ _ _ _ ha
  obtain ⟨_,data,qats,hread,hlen,hfee,hqt⟩ := quote_success _ _ _ _ _ _ hq
  refine ⟨hpay,hm,hg,hc,hfit,fee,data,qats,hq,hread,hlen,hfee,hqt,hprod,hle,ht,hsplit,hcheck,hsettle,?_,?_,?_,?_⟩
  · exact fun a ha => refund_attempt_request _ _ _ _ _ a ha
  · exact fun hz => refund_zero _ _ _ _ _ hz
  · rw [he,hba,hw,hsettle.world]
  · rw [he,hba,htrace,hqt,hsettle.trace]

#print axioms countGroups_success
#print axioms quote_success
#print axioms settle_success
#print axioms afterQuote_success
#print axioms body_success
#print axioms execute_success
#print axioms failure_restores
end audit.trio.consolidation.GatewaySettlement
