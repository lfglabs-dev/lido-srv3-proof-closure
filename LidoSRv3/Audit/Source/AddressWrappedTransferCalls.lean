import LidoSRv3.Audit.Guarantees.PAddress1WrappedTokenCalls

/-! Actual pinned OZ3.4.0 WstETH transferFrom consumed by the already joined
WithdrawalQueue→unwrap execution. Qualified token storage, source-ordered fresh
reads and checked arithmetic; no alias/frame/allowance/stage premise. -/
namespace LidoSRv3.Audit.Source.AddressWrappedTransferCalls
set_option autoImplicit false
open _root_.Verity (zeroAddress)
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal stETHTransferFromCalldata)
open AddressWrappedTokenCalls (balanceSlot)

@[simp] private theorem exec_bind {α β : Type} (x : Exec α) (f : α → Exec β) :
    (x >>= f) = bindExec x f := rfl

def allowanceSlot (owner spender : Address) : Nat :=
  Compiler.Proofs.nestedMappingSlotLocation 1 owner.val spender.val 0

/-- _transfer: both zero guards precede storage. Recipient balance is read
AFTER the sender debit, including sender=recipient or any physical slot alias. -/
def move (self fromAddr recipient : Address) (amount : Word) : Exec Unit := fun before =>
  if fromAddr = zeroAddress then fail (.reason "ERC20: transfer from the zero address") before else
  if recipient = zeroAddress then fail (.reason "ERC20: transfer to the zero address") before else
  let balance := before.core.readContractSlot self.val (balanceSlot fromAddr)
  if amount.val > balance.val then fail (.reason "ERC20: transfer amount exceeds balance") before else
  let debited := {before with core := before.core.writeContractSlot self.val (balanceSlot fromAddr) (word (balance.val-amount.val))}
  let fresh := debited.core.readContractSlot self.val (balanceSlot recipient)
  if fresh.val + amount.val ≥ 2^256 then fail (.reason "SafeMath: addition overflow") debited else
  ⟨.ok (), {debited with core := debited.core.writeContractSlot self.val (balanceSlot recipient) (word (fresh.val+amount.val)), logs := debited.logs ++ [⟨self,"Transfer",[word fromAddr.val,word recipient.val,amount]⟩]}, []⟩

def MoveEffect (self fromAddr recipient : Address) (amount : Word) (before after : World) : Prop :=
  fromAddr ≠ zeroAddress ∧ recipient ≠ zeroAddress ∧
  let balance := before.core.readContractSlot self.val (balanceSlot fromAddr)
  amount.val ≤ balance.val ∧
  let debited := {before with core := before.core.writeContractSlot self.val (balanceSlot fromAddr) (word (balance.val-amount.val))}
  let fresh := debited.core.readContractSlot self.val (balanceSlot recipient)
  fresh.val + amount.val < 2^256 ∧
  after = {debited with core := debited.core.writeContractSlot self.val (balanceSlot recipient) (word (fresh.val+amount.val)), logs := debited.logs ++ [⟨self,"Transfer",[word fromAddr.val,word recipient.val,amount]⟩]}

theorem move_success (self fromAddr recipient : Address) (amount : Word) (w : World)
    (h : (move self fromAddr recipient amount w).outcome = .ok ()) :
    MoveEffect self fromAddr recipient amount w (move self fromAddr recipient amount w).world ∧
      (move self fromAddr recipient amount w).attempts = [] := by
  unfold move at h ⊢
  dsimp only at h ⊢
  split at h
  · contradiction
  · rename_i hf
    simp only [if_neg hf]
    split at h
    · contradiction
    · rename_i ht
      simp only [if_neg ht]
      split at h
      · contradiction
      · rename_i hb
        simp only [if_neg hb]
        split at h
        · contradiction
        · rename_i ha
          simp only [if_neg ha]
          exact ⟨⟨hf,ht,Nat.le_of_not_gt hb,Nat.lt_of_not_ge ha,rfl⟩,trivial⟩

/-- The allowance expression is evaluated before _approve's own zero guards.
Its read occurs on the post-_transfer world, not a cached entry allowance. -/
def spend (ctx : Context) (fromAddr : Address) (amount : Word) : Exec Unit := fun before =>
  let allowance := before.core.readContractSlot ctx.self.val (allowanceSlot fromAddr ctx.sender)
  if amount.val > allowance.val then fail (.reason "ERC20: transfer amount exceeds allowance") before else
  if fromAddr = zeroAddress then fail (.reason "ERC20: approve from the zero address") before else
  if ctx.sender = zeroAddress then fail (.reason "ERC20: approve to the zero address") before else
  let remaining := word (allowance.val-amount.val)
  ⟨.ok (), {before with core := before.core.writeContractSlot ctx.self.val (allowanceSlot fromAddr ctx.sender) remaining, logs := before.logs ++ [⟨ctx.self,"Approval",[word fromAddr.val,word ctx.sender.val,remaining]⟩]}, []⟩

def SpendEffect (ctx : Context) (fromAddr : Address) (amount : Word) (before after : World) : Prop :=
  let allowance := before.core.readContractSlot ctx.self.val (allowanceSlot fromAddr ctx.sender)
  amount.val ≤ allowance.val ∧ fromAddr ≠ zeroAddress ∧ ctx.sender ≠ zeroAddress ∧
  let remaining := word (allowance.val-amount.val)
  after = {before with core := before.core.writeContractSlot ctx.self.val (allowanceSlot fromAddr ctx.sender) remaining, logs := before.logs ++ [⟨ctx.self,"Approval",[word fromAddr.val,word ctx.sender.val,remaining]⟩]}

theorem spend_success (ctx : Context) (fromAddr : Address) (amount : Word) (w : World)
    (h : (spend ctx fromAddr amount w).outcome = .ok ()) :
    SpendEffect ctx fromAddr amount w (spend ctx fromAddr amount w).world ∧
      (spend ctx fromAddr amount w).attempts = [] := by
  unfold spend at h ⊢
  dsimp only at h ⊢
  split at h
  · contradiction
  · rename_i ha
    simp only [if_neg ha]
    split at h
    · contradiction
    · rename_i hf
      simp only [if_neg hf]
      split at h
      · contradiction
      · rename_i hs
        simp only [if_neg hs]
        exact ⟨⟨Nat.le_of_not_gt ha,hf,hs,rfl⟩,trivial⟩

def transferFrom (ctx : Context) (fromAddr recipient : Address) (amount : Word) : Exec Unit := do
  move ctx.self fromAddr recipient amount
  spend ctx fromAddr amount

/-- Ordered physical writes and both events. No final token balance equation
is asserted after the subsequent unwrap and arbitrary stETH callback. -/
def TransferFromEffect (ctx : Context) (fromAddr recipient : Address) (amount : Word)
    (before after : World) : Prop :=
  ∃ moved, MoveEffect ctx.self fromAddr recipient amount before moved ∧
    SpendEffect ctx fromAddr amount moved after

theorem transferFrom_success (ctx : Context) (fromAddr recipient : Address) (amount : Word) (w : World)
    (h : (transferFrom ctx fromAddr recipient amount w).outcome = .ok ()) :
    TransferFromEffect ctx fromAddr recipient amount w (transferFrom ctx fromAddr recipient amount w).world ∧
      (transferFrom ctx fromAddr recipient amount w).attempts = [] := by
  cases hm : (move ctx.self fromAddr recipient amount w).outcome with
  | «error» e => simp [transferFrom,bindExec,hm] at h
  | ok u =>
    cases u
    have he := move_success _ _ _ _ _ hm
    have hs : (spend ctx fromAddr amount (move ctx.self fromAddr recipient amount w).world).outcome = .ok () := by
      simpa only [transferFrom,exec_bind,bindExec,hm] using h
    have se := spend_success _ _ _ _ hs
    simp only [transferFrom,exec_bind,bindExec,hm]
    exact ⟨⟨_,he.1,se.1⟩,by simp only [he.2,se.2,List.nil_append]⟩

def transferReply (ctx : Context) (fromAddr recipient : Address) (amount : Word) (before : World) : Reply :=
  let r := run (transferFrom ctx fromAddr recipient amount) before
  match r.outcome with
  | .ok () => .success (encode 32 1) r.world
  | .error fault => .rejected (ReplyABI.fault fault)

/-- Canonical caller ABI dispatcher. Addresses use the actual uint160 cleanup;
only the generated canonical call is claimed equivalent to compiler decoding. -/
def calleeFor (wstETH : Address) (otherCalls : External) : External := fun req before =>
  if req.target = wstETH ∧ req.payload.take 4 = encode 4 0x23b872dd then
    if req.value.val ≠ 0 ∨ req.payload.length < 100 then .rejected [] else
    transferReply ⟨req.target,req.caller⟩
      (.ofNat (decode ((req.payload.drop 4).take 32)))
      (.ofNat (decode ((req.payload.drop 36).take 32)))
      (word (decode ((req.payload.drop 68).take 32))) before
  else otherCalls req before

private theorem take_encoded (n x : Nat) (xs : Bytes) :
    (encode n x ++ xs).take n = encode n x := by
  simpa only [ABI.encode_length] using (List.take_left (l₁ := encode n x) (l₂ := xs))
private theorem drop_encoded (n x : Nat) (xs : Bytes) :
    (encode n x ++ xs).drop n = xs := by
  simpa only [ABI.encode_length] using (List.drop_left (l₁ := encode n x) (l₂ := xs))

private theorem canonical_address (a : Address) : _root_.Verity.Core.Address.ofNat (decode (encode 32 a.val)) = a := by
  have ha : a.val < 256^32 := by have h := a.isLt; norm_num [Verity.Core.ADDRESS_MODULUS] at h ⊢; omega
  rw [ABI.decode_encode_bounded 32 a.val ha]
  apply _root_.Verity.Core.Address.ext
  exact Nat.mod_eq_of_lt a.isLt

-- Canonical argument decoding is consumed below by the joined public theorem.
theorem canonical_call (wstETH : Address) (otherCalls : External) (caller fromAddr recipient : Address)
    (amount : Word) (w : World) :
    calleeFor wstETH otherCalls ⟨caller,wstETH,0,stETHTransferFromCalldata fromAddr recipient amount.val⟩ w =
      transferReply ⟨wstETH,caller⟩ fromAddr recipient amount w := by
  simp only [calleeFor,stETHTransferFromCalldata,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.transferFromSelector,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.abiAddress,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.abiWord,List.append_assoc,take_encoded,
    true_and,ite_true,Verity.Core.Uint256.val_zero,ne_eq,not_true_eq_false,
    List.length_append,ABI.encode_length,Nat.reduceAdd,Nat.lt_irrefl,or_self,if_false,
    drop_encoded]
  have h36 : 36 = 4+32 := rfl
  have h68 : 68 = 4+32+32 := rfl
  simp only [h36,h68,← List.drop_drop,drop_encoded,take_encoded,
    (show (encode 32 amount.val).take 32 = encode 32 amount.val from by simpa only [ABI.encode_length] using (List.take_length (l := encode 32 amount.val))),
    Verity.Core.Address.toNat,canonical_address,AddressWrappedTokenCalls.canonical_decode]

/-- The old unwrap dispatcher passes transferFrom to the new executed callee. -/
theorem canonical_outer_call (wstETH : Address) (conversion : StaticExternal)
    (tokenTransfer otherCalls : External) (ctx : Context) (amount : Word) (w : World) :
    AddressWrappedTokenCalls.calleeFor wstETH conversion tokenTransfer (calleeFor wstETH otherCalls)
      ⟨ctx.self,wstETH,0,stETHTransferFromCalldata ctx.sender ctx.self amount.val⟩ w =
      transferReply ⟨wstETH,ctx.self⟩ ctx.sender ctx.self amount w := by
  have hp : (stETHTransferFromCalldata ctx.sender ctx.self amount.val).take 4 = encode 4 0x23b872dd := by
    simp only [stETHTransferFromCalldata,
      LidoSRv3.Audit.Verity.AddressRecipientCallBridge.transferFromSelector,
      List.append_assoc,take_encoded]
  have hn : encode 4 0x23b872dd ≠ encode 4 0xde0e9a3e := by decide +kernel
  simp only [AddressWrappedTokenCalls.calleeFor,hp,hn,and_false,if_false]
  exact canonical_call _ _ _ _ _ _ _

theorem reply_success (ctx : Context) (fromAddr recipient : Address) (amount : Word)
    (before after : World) (data : Bytes)
    (h : transferReply ctx fromAddr recipient amount before = .success data after) :
    data = encode 32 1 ∧ TransferFromEffect ctx fromAddr recipient amount before after := by
  cases hr : transferFrom ctx fromAddr recipient amount before with
  | mk outcome world attempts =>
    cases outcome with
    | «error» e => simp [transferReply,run,hr] at h
    | ok u =>
      cases u
      simp only [transferReply,run,hr,Reply.success.injEq] at h
      rcases h with ⟨hd,hw⟩
      subst data
      subst after
      exact ⟨rfl,by simpa only [hr] using (transferFrom_success ctx fromAddr recipient amount before (by rw [hr])).1⟩

theorem reply_not_trace (ctx : Context) (fromAddr recipient : Address) (amount : Word)
    (before after : World) (data : Bytes) (trace : List NestedAttempt) :
    transferReply ctx fromAddr recipient amount before ≠ .successWithTrace data after trace := by
  unfold transferReply
  dsimp only
  split <;> simp

/-- Entire previous JoinedEffect plus the physical transferFrom at its exact
first CALL pre/postworld, canonical arguments and returned bool true. -/
def JoinedEffect (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (queueQuote : StaticExternal) (ctx : Context) (wstETH stETH : Address)
    (amount : Word) (owner : Address) (id : Nat) (before after : World)
    (attempts : List Attempt) : Prop :=
  AddressWrappedTokenCalls.JoinedEffect conversion tokenTransfer (calleeFor wstETH otherCalls)
    queueQuote ctx wstETH stETH amount owner id before after attempts ∧
  ∃ transferred unwrapped received shares ta ua qa inner,
    TransferFromEffect ⟨wstETH,ctx.self⟩ ctx.sender ctx.self amount
      (transfer before ctx.self wstETH 0) transferred ∧
    ta = [⟨⟨ctx.self,wstETH,0,stETHTransferFromCalldata ctx.sender ctx.self amount.val⟩,true,encode 32 1,[]⟩] ∧
    AddressWrappedRequestCalls.UnwrapEffect
      (AddressWrappedTokenCalls.calleeFor wstETH conversion tokenTransfer (calleeFor wstETH otherCalls))
      ctx wstETH amount received transferred unwrapped ua ∧
    AddressWrappedTokenCalls.TokenEffect conversion tokenTransfer ⟨wstETH,ctx.self⟩ amount received
      (transfer transferred ctx.self wstETH 0) unwrapped inner ∧
    100 ≤ received.val ∧ received.val ≤ 1000*10^18 ∧ received.val < 2^128 ∧
    AddressRequestCalls.QuoteEffect queueQuote ctx stETH received.val unwrapped shares qa ∧
    AddressRequestCalls.EnqueueEffect ctx (AddressRequestCalls.resolvedOwner ctx owner)
      received.val (shares.val % 2^128) id before.core.blockTimestamp unwrapped after ∧
    attempts = ta ++ ua ++ qa

def runRequest (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (queueQuote : StaticExternal) (ctx : Context) (wstETH stETH : Address) (amount : Word) (owner : Address) : Exec Nat :=
  AddressWrappedTokenCalls.runRequest conversion tokenTransfer (calleeFor wstETH otherCalls)
    queueQuote ctx wstETH stETH amount owner

theorem joined_success (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (queueQuote : StaticExternal) (ctx : Context) (wstETH stETH : Address)
    (amount : Word) (owner : Address) (id : Nat) (before : World)
    (h : (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).outcome = .ok id) :
    JoinedEffect conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner id before
      (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).world
      (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).attempts := by
  have old := AddressWrappedTokenCalls.joined_success conversion tokenTransfer (calleeFor wstETH otherCalls)
    queueQuote ctx wstETH stETH amount owner id before h
  refine ⟨old,?_⟩
  obtain ⟨transferred,unwrapped,received,shares,ta,ua,qa,inner,ht,hu,he,huaj,hl,hh,hfit,hq,hen,hj⟩ := old.2
  obtain ⟨hc,data,children,hlen,hbool,hreply,hta⟩ := ht
  rw [canonical_outer_call] at hreply
  cases hreply with
  | inr trace => exact False.elim (reply_not_trace _ _ _ _ _ _ _ _ trace)
  | inl plain =>
    obtain ⟨hd,hphysical⟩ := reply_success _ _ _ _ _ _ _ plain.1
    refine ⟨transferred,unwrapped,received,shares,ta,ua,qa,inner,hphysical,?_,hu,he,hl,hh,hfit,hq,hen,hj⟩
    simpa only [hd,plain.2] using hta

theorem joined_failure_restores (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (queueQuote : StaticExternal) (ctx : Context) (wstETH stETH : Address)
    (amount : Word) (owner : Address) (before : World) (fault : Fault)
    (h : (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).outcome = .error fault) :
    (runRequest conversion tokenTransfer otherCalls queueQuote ctx wstETH stETH amount owner before).world = before :=
  AddressWrappedTokenCalls.joined_failure_restores _ _ _ _ _ _ _ _ _ _ _ h

end LidoSRv3.Audit.Source.AddressWrappedTransferCalls
