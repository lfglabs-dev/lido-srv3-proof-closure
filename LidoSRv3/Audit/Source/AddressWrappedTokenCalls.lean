import LidoSRv3.Audit.Guarantees.PAddress1WrappedRequestCalls
import LidoSRv3.Audit.Source.TrioReserve1.ReplyABI
import LidoSRv3.Audit.Source.TrioReserve1.ABI

/-! Actual WstETH.unwrap callee consumed by WithdrawalQueue's existing CALL.
Contract-qualified physical storage, pinned OZ3.4.0/solc0.6.12 ordering, and no
frame/nonalias premise. transferFrom and stETH callees remain explicit externals.
No standalone root-lens unwrap adapter or deployed-token conservation claim. -/
namespace LidoSRv3.Audit.Source.AddressWrappedTokenCalls
set_option autoImplicit false
open _root_.Verity (Uint256 zeroAddress)
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge
  (StaticExternal callWithCalldata staticCallWithCalldata pooledEthBySharesCalldata erc20TransferCalldata)

@[simp] private theorem exec_bind {α β : Type} (x : Exec α) (f : α → Exec β) :
    (x >>= f) = bindExec x f := rfl
@[simp] private theorem exec_pure {α : Type} (x : α) : (pure x : Exec α) = pureExec x := rfl

def balanceSlot (owner : Address) : Nat := Compiler.Proofs.mappingSlotLocation 0 owner.val 0
def supplySlot : Nat := 2
def stETHSlot : Nat := 7

def stETHAddress (self : Address) (w : World) : Address :=
  .ofNat (w.core.readContractSlot self.val stETHSlot).val

/-- Actual OZ3.4 _burn. Read supply AFTER the balance write, retaining arbitrary
physical alias behavior. The hook is empty in the concrete pinned inheritance. -/
def burn (ctx : Context) (amount : Word) : Exec Unit := fun before =>
  if ctx.sender = zeroAddress then fail (.reason "ERC20: burn from the zero address") before else
  let balance := before.core.readContractSlot ctx.self.val (balanceSlot ctx.sender)
  if amount.val > balance.val then fail (.reason "ERC20: burn amount exceeds balance") before else
  let debited := {before with core := (before.core.writeContractSlot ctx.self.val
    (balanceSlot ctx.sender) (word (balance.val-amount.val)))}
  let supply := debited.core.readContractSlot ctx.self.val supplySlot
  if amount.val > supply.val then fail (.reason "SafeMath: subtraction overflow") debited else
  ⟨.ok (), {debited with core := debited.core.writeContractSlot ctx.self.val supplySlot (word (supply.val-amount.val)), logs := debited.logs ++ [⟨ctx.self,"Transfer",[word ctx.sender.val,0,amount]⟩]}, []⟩

def BurnEffect (ctx : Context) (amount : Word) (before after : World) : Prop :=
  ctx.sender ≠ zeroAddress ∧
  let balance := before.core.readContractSlot ctx.self.val (balanceSlot ctx.sender)
  amount.val ≤ balance.val ∧
  let debited := {before with core := (before.core.writeContractSlot ctx.self.val
    (balanceSlot ctx.sender) (word (balance.val-amount.val)))}
  let supply := debited.core.readContractSlot ctx.self.val supplySlot
  amount.val ≤ supply.val ∧
  after = {debited with core := debited.core.writeContractSlot ctx.self.val supplySlot (word (supply.val-amount.val)), logs := debited.logs ++ [⟨ctx.self,"Transfer",[word ctx.sender.val,0,amount]⟩]}

theorem burn_success (ctx : Context) (amount : Word) (w : World)
    (h : (burn ctx amount w).outcome = .ok ()) :
    BurnEffect ctx amount w (burn ctx amount w).world ∧ (burn ctx amount w).attempts = [] := by
  unfold burn at h ⊢
  dsimp only at h ⊢
  split at h
  · contradiction
  · rename_i hz
    simp only [if_neg hz]
    split at h
    · contradiction
    · rename_i hb
      simp only [if_neg hb]
      split at h
      · contradiction
      · rename_i hs
        simp only [if_neg hs]
        exact ⟨⟨hz,Nat.le_of_not_gt hb,Nat.le_of_not_gt hs,rfl⟩,trivial⟩

def staticWord (callee : StaticExternal) (ctx : Context) (target : Address) (payload : Bytes) : Exec Word := do
  let data ← staticCallWithCalldata callee ctx target payload
  decodeWord data

def wordCall (callee : External) (ctx : Context) (target : Address) (payload : Bytes) : Exec Word := do
  let data ← callWithCalldata callee ctx target payload
  decodeWord data

/-- solc0.6.12 accepts noncanonical bool words here and discards their value.
Its minimum32 decoder remains; solc0.8.9 transferFrom in the caller differs. -/
def transferStage (callee : External) (ctx : Context) (received : Word) : Exec Word := fun before =>
  wordCall callee ctx (stETHAddress ctx.self before) (erc20TransferCalldata ctx.sender received.val) before

def tokenProgram (quote : StaticExternal) (callee : External) (ctx : Context) (amount : Word) : Exec Word := fun before => (do
  require (decide (amount.val > 0)) (.reason "wstETH: zero amount unwrap not allowed")
  let received ← staticWord quote ctx (stETHAddress ctx.self before) (pooledEthBySharesCalldata amount.val)
  burn ctx amount
  let _ ← transferStage callee ctx received
  pure received) before

def StaticEffect (callee : StaticExternal) (ctx : Context) (target : Address) (payload : Bytes)
    (before : World) (received : Word) (attempts : List Attempt) : Prop :=
  let req : Request := ⟨ctx.self,target,0,payload⟩
  (before.core.codeSize target.val).val ≠ 0 ∧ ∃ data,
    callee req before = .ok data ∧ 32 ≤ data.length ∧
    received = word (decode (data.take 32)) ∧ attempts = [⟨req,true,data,[]⟩]

def CallEffect (callee : External) (ctx : Context) (target : Address) (payload : Bytes)
    (before after : World) (decoded : Word) (attempts : List Attempt) : Prop :=
  let req : Request := ⟨ctx.self,target,0,payload⟩
  (before.core.codeSize target.val).val ≠ 0 ∧ ∃ data nested,
    32 ≤ data.length ∧ decoded = word (decode (data.take 32)) ∧
    ((callee req (transfer before ctx.self target 0) = .success data after ∧ nested = []) ∨
     callee req (transfer before ctx.self target 0) = .successWithTrace data after nested) ∧
    attempts = [⟨req,true,data,nested⟩]

private theorem bind_success {α β : Type} (first : Exec α) (next : α → Exec β)
    (before : World) (value : β) (h : (bindExec first next before).outcome = .ok value) :
    ∃ a, (first before).outcome = .ok a ∧
      (next a (first before).world).outcome = .ok value ∧
      (bindExec first next before).world = (next a (first before).world).world ∧
      (bindExec first next before).attempts =
        (first before).attempts ++ (next a (first before).world).attempts := by
  cases hx : (first before).outcome with
  | «error» fault => simp [bindExec, hx] at h
  | ok a => exact ⟨a, rfl, by simpa [bindExec, hx] using h,
      by simp [bindExec, hx], by simp [bindExec, hx]⟩

private theorem decode_success (data : Bytes) (w : World) (v : Uint256)
    (h : (decodeWord data 0 w).outcome = .ok v) :
    32 ≤ data.length ∧ v = word (decode (data.take 32)) ∧
      (decodeWord data 0 w).world = w ∧ (decodeWord data 0 w).attempts = [] := by
  by_cases hl : 32 ≤ data.length
  · simp [decodeWord, require, hl, bindExec, pureExec] at h ⊢
    exact h.symm
  · simp [decodeWord, require, hl, bindExec, fail] at h

private theorem call_success (callee : External) (ctx : Context) (target : _root_.Verity.Address)
    (payload data : Bytes) (w : World)
    (h : (callWithCalldata callee ctx target payload 0 w).outcome = .ok data) :
    (w.core.codeSize target.val).val ≠ 0 ∧ ∃ nested,
      ((callee ⟨ctx.self, target, 0, payload⟩ (transfer w ctx.self target 0) =
          .success data (callWithCalldata callee ctx target payload 0 w).world ∧ nested = []) ∨
       callee ⟨ctx.self, target, 0, payload⟩ (transfer w ctx.self target 0) =
          .successWithTrace data (callWithCalldata callee ctx target payload 0 w).world nested) ∧
      (callWithCalldata callee ctx target payload 0 w).attempts =
        [⟨⟨ctx.self, target, 0, payload⟩, true, data, nested⟩] := by
  by_cases hc : (w.core.codeSize target.val).val = 0
  · simp [callWithCalldata, hc] at h
  cases hr : callee ⟨ctx.self, target, 0, payload⟩ (transfer w ctx.self target 0) with
  | rejected bytes => simp [callWithCalldata, hc, hr] at h
  | rejectedWithTrace bytes nested => simp [callWithCalldata, hc, hr] at h
  | success bytes after =>
    simp [callWithCalldata, hc, hr] at h
    subst data
    simp only [callWithCalldata, if_neg hc]
    simp only [Verity.Core.Uint256.val_zero, Nat.not_lt_zero, ↓reduceIte, hr]
    exact ⟨hc, [], Or.inl ⟨trivial, rfl⟩, rfl⟩
  | successWithTrace bytes after nested =>
    simp [callWithCalldata, hc, hr] at h
    subst data
    simp only [callWithCalldata, if_neg hc]
    simp only [Verity.Core.Uint256.val_zero, Nat.not_lt_zero, ↓reduceIte, hr]
    exact ⟨hc, nested, Or.inr rfl, rfl⟩

private theorem require_success (condition : Bool) (fault : Fault) (w : World)
    (h : (require condition fault w).outcome = .ok ()) :
    condition = true ∧ (require condition fault w).world = w ∧
      (require condition fault w).attempts = [] := by
  cases condition <;> simp [require, pureExec, fail] at h ⊢

theorem static_success (callee : StaticExternal) (ctx : Context) (target : Address) (payload : Bytes)
    (w : World) (received : Word) (h : (staticWord callee ctx target payload w).outcome = .ok received) :
    StaticEffect callee ctx target payload w received (staticWord callee ctx target payload w).attempts ∧
    (staticWord callee ctx target payload w).world = w := by
  obtain ⟨data,hc,hd,hw,ha⟩ := bind_success _ _ _ _ h
  have hc0 : (w.core.codeSize target.val).val ≠ 0 := by
    intro hz
    simp [staticCallWithCalldata,hz] at hc
  cases hr : callee ⟨ctx.self,target,0,payload⟩ w with
  | «error» e => simp [staticCallWithCalldata,hc0,hr] at hc
  | ok bytes =>
    simp only [staticCallWithCalldata,if_neg hc0,hr,Except.ok.injEq] at hc
    subst data
    simp only [staticCallWithCalldata,if_neg hc0,hr] at hd hw ha
    obtain ⟨hl,hv,hdw,hda⟩ := decode_success _ _ _ hd
    exact ⟨⟨hc0,bytes,hr,hl,hv,by simpa only [staticWord,exec_bind,hda,List.append_nil] using ha⟩,hw.trans hdw⟩

theorem wordCall_success (callee : External) (ctx : Context) (target : Address) (payload : Bytes)
    (w : World) (received : Word) (h : (wordCall callee ctx target payload w).outcome = .ok received) :
    CallEffect callee ctx target payload w (wordCall callee ctx target payload w).world received
      (wordCall callee ctx target payload w).attempts := by
  obtain ⟨data,hc,hd,hw,ha⟩ := bind_success _ _ _ _ h
  obtain ⟨hl,hv,hdw,hda⟩ := decode_success _ _ _ hd
  obtain ⟨hcode,nested,hr,hat⟩ := call_success _ _ _ _ _ _ hc
  have finalw : (wordCall callee ctx target payload w).world =
      (callWithCalldata callee ctx target payload 0 w).world := hw.trans hdw
  exact ⟨hcode,data,nested,hl,hv,by simpa only [finalw] using hr,
    by simpa only [wordCall,exec_bind,hda,List.append_nil] using ha.trans (by simpa only [hda,List.append_nil] using hat)⟩

def TokenEffect (quote : StaticExternal) (callee : External) (ctx : Context) (amount received : Word)
    (before after : World) (attempts : List Attempt) : Prop :=
  0 < amount.val ∧ ∃ burned transferReturn qa ta,
    StaticEffect quote ctx (stETHAddress ctx.self before) (pooledEthBySharesCalldata amount.val) before received qa ∧
    BurnEffect ctx amount before burned ∧
    CallEffect callee ctx (stETHAddress ctx.self burned) (erc20TransferCalldata ctx.sender received.val)
      burned after transferReturn ta ∧ attempts = qa ++ ta

theorem token_success (quote : StaticExternal) (callee : External) (ctx : Context) (amount received : Word)
    (w : World) (h : (tokenProgram quote callee ctx amount w).outcome = .ok received) :
    TokenEffect quote callee ctx amount received w (tokenProgram quote callee ctx amount w).world
      (tokenProgram quote callee ctx amount w).attempts := by
  obtain ⟨u,hpos,h1,hw0,ha0⟩ := bind_success _ _ _ _ h
  cases u
  obtain ⟨hpos,hwp,hap⟩ := require_success _ _ _ hpos
  simp only [hwp] at h1 hw0 ha0
  obtain ⟨converted,hq,h2,hw1,ha1⟩ := bind_success _ _ _ _ h1
  obtain ⟨hqe,hqw⟩ := static_success _ _ _ _ _ _ hq
  simp only [hqw] at h2 hw1 ha1
  obtain ⟨u,hb,h3,hw2,ha2⟩ := bind_success _ _ _ _ h2
  cases u
  obtain ⟨hbe,hba⟩ := burn_success _ _ _ hb
  obtain ⟨decoded,ht,hpure,hw3,ha3⟩ := bind_success _ _ _ _ h3
  simp only [exec_pure,pureExec,Except.ok.injEq] at hpure
  subst received
  have hte := wordCall_success callee ctx _ _ _ decoded ht
  refine ⟨of_decide_eq_true hpos,(burn ctx amount w).world,decoded,
    (staticWord quote ctx (stETHAddress ctx.self w) (pooledEthBySharesCalldata amount.val) w).attempts,
    (transferStage callee ctx converted (burn ctx amount w).world).attempts,hqe,hbe,?_,?_⟩
  · have finalw := hw0.trans (hw1.trans (hw2.trans hw3))
    change (tokenProgram quote callee ctx amount w).world = _ at finalw
    rw [finalw]
    exact hte
  · simp only [exec_bind,exec_pure] at ha0 ha1 ha2 ha3
    simpa only [tokenProgram,exec_bind,exec_pure,ha1,ha2,ha3,hap,hba,pureExec,List.nil_append,List.append_nil] using ha0

/-- Conversion is the first direct attempt and is STATICCALL. All later direct
attempts are the mutable transfer; nested child flags/order are preserved. -/
def nested (attempts : List Attempt) : List NestedAttempt :=
  (attempts.zipIdx).flatMap fun (a,i) =>
    ⟨a.request,i=0,a.accepted,a.returned,1⟩ :: a.nested.map fun child => {child with depth := child.depth+1}

def tokenReply (quote : StaticExternal) (callee : External) (ctx : Context) (amount : Word) (before : World) : Reply :=
  let r := run (tokenProgram quote callee ctx amount) before
  match r.outcome with
  | .ok received => .successWithTrace (encode 32 received.val) r.world (nested r.attempts)
  | .error fault => .rejectedWithTrace (ReplyABI.fault fault) (nested r.attempts)

/-- Real caller's canonical unwrap CALL is decoded here; other requests,
including its transferFrom, still use the explicit external implementation. -/
def calleeFor (wstETH : Address) (quote : StaticExternal) (callee otherCalls : External) : External := fun req before =>
  if req.target = wstETH ∧ req.payload.take 4 = encode 4 0xde0e9a3e then
    if req.value.val ≠ 0 ∨ req.payload.length < 36 then .rejected [] else
    tokenReply quote callee ⟨req.target,req.caller⟩
      (word (decode ((req.payload.drop 4).take 32))) before
  else otherCalls req before

theorem canonical_decode (amount : Word) :
    word (decode (encode 32 amount.val)) = amount := by
  have hb : amount.val < 256^32 := by have h := amount.isLt; norm_num at h ⊢; exact h
  rw [ABI.decode_encode_bounded 32 amount.val hb]
  apply Verity.Core.Uint256.ext
  exact Nat.mod_eq_of_lt amount.isLt

theorem canonical_call (wstETH : Address) (quote : StaticExternal) (callee otherCalls : External)
    (caller : Address) (amount : Word) (w : World) :
    calleeFor wstETH quote callee otherCalls
      ⟨caller,wstETH,0,AddressWrappedRequestCalls.unwrapCalldata amount⟩ w =
      tokenReply quote callee ⟨wstETH,caller⟩ amount w := by
  have hp : (encode 4 0xde0e9a3e ++ encode 32 amount.val).take 4 = encode 4 0xde0e9a3e := by
    simpa only [ABI.encode_length] using (List.take_left (l₁ := encode 4 0xde0e9a3e) (l₂ := encode 32 amount.val))
  have hd : (encode 4 0xde0e9a3e ++ encode 32 amount.val).drop 4 = encode 32 amount.val := by
    simpa only [ABI.encode_length] using (List.drop_left (l₁ := encode 4 0xde0e9a3e) (l₂ := encode 32 amount.val))
  have ht : (encode 32 amount.val).take 32 = encode 32 amount.val := by
    simpa only [ABI.encode_length] using (List.take_length (l := encode 32 amount.val))
  simp only [calleeFor,AddressWrappedRequestCalls.unwrapCalldata,hp,true_and,ite_true,
    Verity.Core.Uint256.val_zero,ne_eq,not_true_eq_false,List.length_append,ABI.encode_length,
    Nat.reduceAdd,Nat.lt_irrefl,or_self,if_false,hd,ht,canonical_decode]

theorem reply_not_plain (quote : StaticExternal) (callee : External) (ctx : Context)
    (amount : Word) (w after : World) (data : Bytes) :
    tokenReply quote callee ctx amount w ≠ .success data after := by
  unfold tokenReply
  dsimp only
  split <;> simp

theorem reply_success (quote : StaticExternal) (callee : External) (ctx : Context)
    (amount : Word) (w after : World) (data : Bytes) (trace : List NestedAttempt)
    (h : tokenReply quote callee ctx amount w = .successWithTrace data after trace) :
    ∃ received attempts,
      tokenProgram quote callee ctx amount w = ⟨.ok received,after,attempts⟩ ∧
      data = encode 32 received.val ∧ trace = nested attempts ∧
      TokenEffect quote callee ctx amount received w after attempts := by
  cases hr : tokenProgram quote callee ctx amount w with
  | mk outcome world attempts =>
    cases outcome with
    | «error» e => simp [tokenReply,run,hr] at h
    | ok received =>
      simp only [tokenReply,run,hr,Reply.successWithTrace.injEq] at h
      rcases h with ⟨hd,hw,ht⟩
      subst data
      subst after
      subst trace
      refine ⟨received,attempts,rfl,rfl,rfl,?_⟩
      have he := token_success quote callee ctx amount received w (by rw [hr])
      simpa only [hr] using he

/-- The previous caller effect is retained, and the additional token effect is
bound to the same transferred/unwrapped worlds, decoded amount, quote, enqueue
and journals. No final burn balance is asserted after arbitrary stETH callbacks. -/
def JoinedEffect (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (queueQuote : StaticExternal) (ctx : Context) (wstETH stETH : Address)
    (amount : Word) (owner : Address) (id : Nat) (before after : World)
    (attempts : List Attempt) : Prop :=
  let implementation := calleeFor wstETH conversion tokenTransfer otherCalls
  AddressWrappedRequestCalls.RequestEffect implementation queueQuote ctx wstETH stETH amount owner id before after attempts ∧
    ∃ transferred unwrapped received shares ta ua qa inner,
      AddressRequestCalls.TransferEffect implementation ctx wstETH amount.val before transferred ta ∧
      AddressWrappedRequestCalls.UnwrapEffect implementation ctx wstETH amount received transferred unwrapped ua ∧
      TokenEffect conversion tokenTransfer ⟨wstETH,ctx.self⟩ amount received
        (transfer transferred ctx.self wstETH 0) unwrapped inner ∧
      ua = [⟨⟨ctx.self,wstETH,0,AddressWrappedRequestCalls.unwrapCalldata amount⟩,true,
        encode 32 received.val,nested inner⟩] ∧
      100 ≤ received.val ∧ received.val ≤ 1000*10^18 ∧ received.val < 2^128 ∧
      AddressRequestCalls.QuoteEffect queueQuote ctx stETH received.val unwrapped shares qa ∧
      AddressRequestCalls.EnqueueEffect ctx (AddressRequestCalls.resolvedOwner ctx owner)
        received.val (shares.val % 2^128) id before.core.blockTimestamp unwrapped after ∧
      attempts = ta ++ ua ++ qa

def runRequest (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (queueQuote : StaticExternal) (ctx : Context) (wstETH stETH : Address)
    (amount : Word) (owner : Address) : Exec Nat :=
  AddressWrappedRequestCalls.runRequest (calleeFor wstETH conversion tokenTransfer otherCalls)
    queueQuote ctx wstETH stETH amount owner

theorem joined_success (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (queueQuote : StaticExternal) (ctx : Context) (wstETH stETH : Address)
    (amount : Word) (owner : Address) (id : Nat) (before : World)
    (h : (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).outcome = .ok id) :
    JoinedEffect conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner id before
      (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).world
      (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).attempts := by
  have old := AddressWrappedRequestCalls.run_success (calleeFor wstETH conversion tokenTransfer otherCalls)
    queueQuote ctx wstETH stETH amount owner id before h
  refine ⟨old,?_⟩
  obtain ⟨transferred,unwrapped,received,shares,ta,ua,qa,htransfer,hunwrap,hlo,hhi,hfit,hquote,henqueue,hjournal⟩ := old
  have saved := hunwrap
  obtain ⟨hcode,data,children,hlen,hreceived,hcallee,huajournal⟩ := hunwrap
  rw [canonical_call] at hcallee
  cases hcallee with
  | inl plain => exact False.elim (reply_not_plain _ _ _ _ _ _ _ plain.1)
  | inr successful =>
    obtain ⟨converted,inner,hprogram,hdata,hchildren,heffect⟩ := reply_success _ _ _ _ _ _ _ _ successful
    have hr : received = converted := by
      rw [hdata] at hreceived
      have ht : (encode 32 converted.val).take 32 = encode 32 converted.val := by
        simpa only [ABI.encode_length] using (List.take_length (l := encode 32 converted.val))
      simpa only [ht,canonical_decode] using hreceived
    rw [hr] at saved hlo hhi hfit hquote henqueue
    refine ⟨transferred,unwrapped,converted,shares,ta,ua,qa,inner,htransfer,saved,heffect,?_,hlo,hhi,hfit,hquote,henqueue,hjournal⟩
    simpa only [hdata,hchildren] using huajournal

theorem joined_failure_restores (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (queueQuote : StaticExternal) (ctx : Context) (wstETH stETH : Address)
    (amount : Word) (owner : Address) (before : World) (fault : Fault)
    (h : (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).outcome = .error fault) :
    (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).world = before :=
  AddressWrappedRequestCalls.run_failure_restores _ _ _ _ _ _ _ _ _ h

end LidoSRv3.Audit.Source.AddressWrappedTokenCalls
