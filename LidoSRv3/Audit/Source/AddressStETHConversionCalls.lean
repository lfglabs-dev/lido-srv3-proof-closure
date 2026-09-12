import LidoSRv3.Audit.Guarantees.PAddress1StETHQuoteCalls
/-! Actual Lido getPooledEthByShares executed by WstETH's canonical STATICCALL.
The dynamic target comes from physical slot7 on the actual preburn world. -/
namespace LidoSRv3.Audit.Source.AddressStETHConversionCalls
set_option autoImplicit false
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open AddressStETHQuoteCalls (internalEther internalShares internalEther_bound quote QuoteFormula)
open AddressRequestBatches
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal pooledEthBySharesCalldata erc20TransferCalldata)
def body (target : Address) (amount : Word) (w : World) : Except Fault Word :=
  if amount.val ≥ 2^128-1 then .error (.bubbled (ReplyABI.reason "SHARES_TOO_LARGE"))
  else
    let denominator := internalShares target w
    let numerator := internalEther target w
    let product := (amount.val * numerator) % 2^256
    if denominator = 0 then .error (.bubbled [])
    else .ok (word (product / denominator))

def ConversionFormula (target : Address) (amount : Nat) (shares : Word) (w : World) : Prop :=
  amount < 2^128-1 ∧ internalEther target w < 2^130 ∧ internalShares target w ≠ 0 ∧
    shares = word (((amount * internalEther target w) % 2^256) / internalShares target w)

theorem body_success (target : Address) (amount shares : Word) (w : World)
    (h : body target amount w = .ok shares) : ConversionFormula target amount.val shares w := by
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
def conversion : StaticExternal := fun req w =>
  if req.value.val = 0 ∧ req.payload.take 4 = encode 4 0x7a28fb88 ∧ 36 ≤ req.payload.length then
    match body req.target (word (decode ((req.payload.drop 4).take 32))) w with
    | .error e => .error e
    | .ok shares => .ok (encode 32 shares.val)
  else .error (.bubbled [])

theorem canonical_call (target : Address) (ctx : Context) (amount : Word) (w : World) :
    conversion ⟨ctx.self,target,0,pooledEthBySharesCalldata amount.val⟩ w =
      match body target amount w with
      | .error e => .error e
      | .ok shares => .ok (encode 32 shares.val) := by
  simp only [conversion,pooledEthBySharesCalldata,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.getPooledEthBySharesSelector,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.abiWord]
  have ht : (encode 4 0x7a28fb88 ++ encode 32 amount.val).take 4 = encode 4 0x7a28fb88 := by
    simpa only [ABI.encode_length] using List.take_left (l₁ := encode 4 0x7a28fb88) (l₂ := encode 32 amount.val)
  have hd : (encode 4 0x7a28fb88 ++ encode 32 amount.val).drop 4 = encode 32 amount.val := by
    simpa only [ABI.encode_length] using List.drop_left (l₁ := encode 4 0x7a28fb88) (l₂ := encode 32 amount.val)
  simp only [ht,hd,List.length_append,ABI.encode_length,Verity.Core.Uint256.val_zero,
    Nat.reduceAdd,le_refl,and_self,if_true]
  rw [show (encode 32 amount.val).take 32 = encode 32 amount.val from by simpa only [ABI.encode_length] using List.take_length (l := encode 32 amount.val)]
  rw [AddressWrappedTokenCalls.canonical_decode]


theorem conversion_effect (ctx : Context) (target : Address) (amount received : Word)
    (w : World) (attempts : List Attempt)
    (h : AddressWrappedTokenCalls.StaticEffect conversion ctx target
      (pooledEthBySharesCalldata amount.val) w received attempts) :
    ConversionFormula target amount.val received w := by
  obtain ⟨hc,data,hr,hlen,hs,hj⟩ := h
  rw [canonical_call] at hr
  cases hb : body target amount w with
  | «error» e => simp [hb] at hr
  | ok result =>
    simp only [hb,Except.ok.injEq] at hr
    subst data
    have ht : (encode 32 result.val).take 32 = encode 32 result.val := by
      simpa only [ABI.encode_length] using List.take_length (l := encode 32 result.val)
    rw [ht,AddressWrappedTokenCalls.canonical_decode] at hs
    subst received
    exact body_success target amount result w hb

/-- Old token effect binds this output to the actual burn, fresh slot7 reread,
mutable transfer payload and returned captured value on the exact same worlds. -/
def TokenEffect (callee : External) (ctx : Context) (amount received : Word)
    (before after : World) (attempts : List Attempt) : Prop :=
  AddressWrappedTokenCalls.TokenEffect conversion callee ctx amount received before after attempts ∧
    ConversionFormula (AddressWrappedTokenCalls.stETHAddress ctx.self before) amount.val received before

theorem token_effect (callee : External) (ctx : Context) (amount received : Word)
    (before after : World) (attempts : List Attempt)
    (h : AddressWrappedTokenCalls.TokenEffect conversion callee ctx amount received before after attempts) :
    TokenEffect callee ctx amount received before after attempts := by
  refine ⟨h,?_⟩
  obtain ⟨hpos,burned,transferReturn,qa,ta,hq,hb,ht,hj⟩ := h
  exact conversion_effect ctx _ amount received before qa hq

/-- Entire enhanced forward quote item plus reverse conversion on the actual
preburn world and the SAME received value feeding unwrap, guards, forward quote,
uint128 casts, enqueue and ordered attempts. No equal-target/rate assumption. -/
def Item (tokenTransfer otherCalls : External) (ctx : Context) (wstETH target owner : Address)
    (amount : Word) (id : Nat) (before after : World) (attempts : List Attempt) : Prop :=
  AddressStETHQuoteCalls.WrappedItem conversion tokenTransfer otherCalls ctx wstETH target owner amount id before after attempts ∧
  ∃ transferred unwrapped received shares ta ua qa inner,
    AddressWrappedTransferCalls.TransferFromEffect ⟨wstETH,ctx.self⟩ ctx.sender ctx.self amount
      (transfer before ctx.self wstETH 0) transferred ∧
    AddressWrappedRequestCalls.UnwrapEffect
      (AddressWrappedTokenCalls.calleeFor wstETH conversion tokenTransfer (AddressWrappedTransferCalls.calleeFor wstETH otherCalls))
      ctx wstETH amount received transferred unwrapped ua ∧
    TokenEffect tokenTransfer ⟨wstETH,ctx.self⟩ amount received
      (transfer transferred ctx.self wstETH 0) unwrapped inner ∧
    100 ≤ received.val ∧ received.val ≤ 1000*10^18 ∧ received.val < 2^128 ∧
    QuoteFormula target received.val shares unwrapped ∧
    AddressRequestCalls.QuoteEffect (quote target) ctx target received.val unwrapped shares qa ∧
    AddressRequestCalls.EnqueueEffect ctx (AddressRequestCalls.resolvedOwner ctx owner)
      received.val (shares.val % 2^128) id before.core.blockTimestamp unwrapped after ∧
    attempts = ta ++ ua ++ qa

theorem item_effect (tokenTransfer otherCalls : External) (ctx : Context) (wstETH target owner : Address)
    (amount : Word) (id : Nat) (before after : World) (attempts : List Attempt)
    (h : AddressStETHQuoteCalls.WrappedItem conversion tokenTransfer otherCalls ctx wstETH target owner amount id before after attempts) :
    Item tokenTransfer otherCalls ctx wstETH target owner amount id before after attempts := by
  refine ⟨h,?_⟩
  obtain ⟨transferred,unwrapped,received,shares,ta,ua,qa,inner,ht,hta,hu,he,hl,hh,hfit,hq,hen,hj⟩ := h.1.2
  exact ⟨transferred,unwrapped,received,shares,ta,ua,qa,inner,ht,hu,
    token_effect tokenTransfer ⟨wstETH,ctx.self⟩ amount received _ unwrapped inner he,
    hl,hh,hfit,AddressStETHQuoteCalls.quote_effect ctx target received.val unwrapped shares qa received.isLt hq,hq,hen,hj⟩
end LidoSRv3.Audit.Source.AddressStETHConversionCalls
