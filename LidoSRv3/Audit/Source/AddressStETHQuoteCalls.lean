import LidoSRv3.Audit.Guarantees.PAddress1PermitRequestCalls

/-! Actual Lido0.4.24 getSharesByPooledEth quote on contract-qualified physical
words, consumed by the existing request/unwrap/batch/permit chain. No supplied
totals, T>=E, result-fit, stage-success or callback-frame premise. -/
namespace LidoSRv3.Audit.Source.AddressStETHQuoteCalls
set_option autoImplicit false
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressRequestCalls (resolvedOwner)
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal stETHSharesCalldata)

def sharesSlot : Nat := 0x6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6
def bufferedSlot : Nat := 0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f
def clSlot : Nat := 0x096e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112

def low (w : Word) : Nat := w.val % 2^128
def high (w : Word) : Nat := w.val / 2^128

def internalEther (target : Address) (w : World) : Nat :=
  let b := w.core.readContractSlot target.val bufferedSlot
  let c := w.core.readContractSlot target.val clSlot
  low b + low c + high c + high b

def internalShares (target : Address) (w : World) : Nat :=
  let s := w.core.readContractSlot target.val sharesSlot
  (low s + 2^256 - high s) % 2^256

/-- Four actual uint128 fields bound all three source SafeMath additions;
no physical storage invariant is required. -/
theorem internalEther_bound (target : Address) (w : World) : internalEther target w < 2^130 := by
  have blo := Nat.mod_lt (w.core.readContractSlot target.val bufferedSlot).val (by decide : 0 < 2^128)
  have clo := Nat.mod_lt (w.core.readContractSlot target.val clSlot).val (by decide : 0 < 2^128)
  have bh := (w.core.readContractSlot target.val bufferedSlot).isLt
  have ch := (w.core.readContractSlot target.val clSlot).isLt
  change (w.core.readContractSlot target.val bufferedSlot).val < 2^256 at bh
  change (w.core.readContractSlot target.val clSlot).val < 2^256 at ch
  unfold internalEther low high
  norm_num at blo clo bh ch ⊢
  omega

/-- Actual raw uint256 multiplication/subtraction, not SafeMath operations.
Division by zero follows the 0.4.24 exceptional/empty-return category. -/
def body (target : Address) (amount : Word) (w : World) : Except Fault Word :=
  if amount.val ≥ 2^128-1 then .error (.bubbled (ReplyABI.reason "ETH_TOO_LARGE"))
  else
    let numerator := internalEther target w
    let denominator := internalShares target w
    let product := (amount.val * denominator) % 2^256
    if numerator = 0 then .error (.bubbled [])
    else .ok (word (product / numerator))

def QuoteFormula (target : Address) (amount : Nat) (shares : Word) (w : World) : Prop :=
  amount < 2^128-1 ∧ internalEther target w < 2^130 ∧ internalEther target w ≠ 0 ∧
    shares = word (((amount * internalShares target w) % 2^256) / internalEther target w)

theorem body_success (target : Address) (amount shares : Word) (w : World)
    (h : body target amount w = .ok shares) : QuoteFormula target amount.val shares w := by
  unfold body at h
  split at h
  · contradiction
  · rename_i ha
    dsimp only at h
    split at h
    · contradiction
    · rename_i hi
      exact ⟨Nat.lt_of_not_ge ha,internalEther_bound target w,hi,(Except.ok.inj h).symm⟩

/-- Canonical selector/typed argument adapter. No generic malformed ABI equivalence
claim. STATICCALL caller transport/codeguard remains the accepted implementation. -/
def quote (target : Address) : StaticExternal := fun req w =>
  if req.target = target ∧ req.value.val = 0 ∧ req.payload.take 4 = encode 4 0x19208451 ∧ 36 ≤ req.payload.length then
    match body target (word (decode ((req.payload.drop 4).take 32))) w with
    | .error e => .error e
    | .ok shares => .ok (encode 32 shares.val)
  else .error (.bubbled [])

theorem canonical_call (target : Address) (ctx : Context) (amount : Word) (w : World) :
    quote target ⟨ctx.self,target,0,stETHSharesCalldata amount.val⟩ w =
      match body target amount w with
      | .error e => .error e
      | .ok shares => .ok (encode 32 shares.val) := by
  simp only [quote,stETHSharesCalldata,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.getSharesByPooledEthSelector,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.abiWord]
  have ht : (encode 4 0x19208451 ++ encode 32 amount.val).take 4 = encode 4 0x19208451 := by
    simpa only [ABI.encode_length] using List.take_left (l₁ := encode 4 0x19208451) (l₂ := encode 32 amount.val)
  have hd : (encode 4 0x19208451 ++ encode 32 amount.val).drop 4 = encode 32 amount.val := by
    simpa only [ABI.encode_length] using List.drop_left (l₁ := encode 4 0x19208451) (l₂ := encode 32 amount.val)
  simp only [ht,hd,List.length_append,ABI.encode_length,Verity.Core.Uint256.val_zero,
    Nat.reduceAdd,le_refl,and_self,if_true]
  rw [show (encode 32 amount.val).take 32 = encode 32 amount.val from by simpa only [ABI.encode_length] using List.take_length (l := encode 32 amount.val)]
  rw [AddressWrappedTokenCalls.canonical_decode]

/-- Extract the returned physical formula from the ACTUAL old quote effect. -/
theorem quote_effect (ctx : Context) (target : Address) (amount : Nat) (w : World)
    (shares : Word) (attempts : List Attempt) (hfit : amount < 2^256)
    (h : AddressRequestCalls.QuoteEffect (quote target) ctx target amount w shares attempts) :
    QuoteFormula target amount shares w := by
  obtain ⟨hc,data,hr,hlen,hs,hj⟩ := h
  have hv : (word amount).val = amount := Nat.mod_eq_of_lt hfit
  have canonical := canonical_call target ctx (word amount) w
  rw [hv] at canonical
  rw [canonical] at hr
  cases hb : body target (word amount) w with
  | «error» e => simp [hb] at hr
  | ok result =>
    simp only [hb,Except.ok.injEq] at hr
    subst data
    have htake : (encode 32 result.val).take 32 = encode 32 result.val := by
      simpa only [ABI.encode_length] using List.take_length (l := encode 32 result.val)
    rw [htake,AddressWrappedTokenCalls.canonical_decode] at hs
    subst shares
    simpa only [hv] using body_success target (word amount) result w hb

/-- An item keeps its ENTIRE old effect and identifies the physical quote on
its actual post-transfer/unwrap world; casts and enqueue remain the old effects. -/
def StItem (callee : External) (ctx : Context) (target owner : Address)
    (amount : Word) (id : Nat) (before after : World) (attempts : List Attempt) : Prop :=
  stETHEffect callee (quote target) ctx target owner amount id before after attempts ∧
    ∃ called shares ta qa,
      AddressRequestCalls.TransferEffect callee ctx target amount.val before called ta ∧
      QuoteFormula target amount.val shares called ∧
      AddressRequestCalls.QuoteEffect (quote target) ctx target amount.val called shares qa ∧
      AddressRequestCalls.EnqueueEffect ctx (resolvedOwner ctx owner) amount.val (shares.val % 2^128) id before.core.blockTimestamp called after ∧
      attempts = ta ++ qa

def WrappedItem (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (ctx : Context) (wstETH target owner : Address) (amount : Word) (id : Nat)
    (before after : World) (attempts : List Attempt) : Prop :=
  wrappedEffect conversion tokenTransfer otherCalls (quote target) ctx wstETH target owner amount id before after attempts ∧
    ∃ (unwrapped : World) (received shares : Word) (qa : List Attempt),
      QuoteFormula target received.val shares unwrapped ∧
      AddressRequestCalls.QuoteEffect (quote target) ctx target received.val unwrapped shares qa ∧
      AddressRequestCalls.EnqueueEffect ctx (resolvedOwner ctx owner) received.val (shares.val % 2^128) id before.core.blockTimestamp unwrapped after

theorem st_item (callee : External) (ctx : Context) (target owner : Address)
    (amount : Word) (id : Nat) (before after : World) (attempts : List Attempt)
    (h : stETHEffect callee (quote target) ctx target owner amount id before after attempts) :
    StItem callee ctx target owner amount id before after attempts := by
  refine ⟨h,?_⟩
  obtain ⟨hl,hh,hfit,called,shares,ta,qa,ht,hq,he,hj⟩ := h
  exact ⟨called,shares,ta,qa,ht,quote_effect ctx target amount.val called shares qa (by have hi := amount.isLt; exact hi) hq,hq,he,hj⟩

theorem wrapped_item (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (ctx : Context) (wstETH target owner : Address) (amount : Word) (id : Nat)
    (before after : World) (attempts : List Attempt)
    (h : wrappedEffect conversion tokenTransfer otherCalls (quote target) ctx wstETH target owner amount id before after attempts) :
    WrappedItem conversion tokenTransfer otherCalls ctx wstETH target owner amount id before after attempts := by
  refine ⟨h,?_⟩
  obtain ⟨transferred,unwrapped,received,shares,ta,ua,qa,inner,ht,hta,hu,he,hl,hh,hfit,hq,hen,hj⟩ := h.2
  exact ⟨unwrapped,received,shares,qa,quote_effect ctx target received.val unwrapped shares qa received.isLt hq,hq,hen⟩

theorem transcript_map {old new : Word → Nat → World → World → List Attempt → Prop}
    (f : ∀ amount id before after attempts, old amount id before after attempts → new amount id before after attempts)
    {amounts : List Word} {ids : List Nat} {before after : World} {attempts : List Attempt}
    (h : Transcript old amounts ids before after attempts) : Transcript new amounts ids before after attempts := by
  induction h with
  | nil w => exact Transcript.nil w
  | cons hi _ ih => exact Transcript.cons (f _ _ _ _ _ hi) ih

end LidoSRv3.Audit.Source.AddressStETHQuoteCalls
