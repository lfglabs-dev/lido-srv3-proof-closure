import LidoSRv3.Audit.Guarantees.PAddress1StETHTransferCalls

/-! Full-Lido transferFrom: physical allowance FIRST, then the accepted
physical transfer implementation on the actual allowance-returned World.
Only canonical generated CALLs are claimed; no runtime-code identity premise. -/
namespace LidoSRv3.Audit.Source.AddressStETHTransferFromCalls
set_option autoImplicit false
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (stETHTransferFromCalldata)

def allowanceSlot (owner spender : Address) : Nat :=
  Compiler.Proofs.nestedMappingSlotLocation 1 owner.val spender.val 0

/-- Two exact 64-byte preimages: owner/base1, then spender/inner hash.
The range lemma is structural; no mapping-injectivity hypothesis is used. -/
theorem allowanceSlot_keccak (owner spender : Address) : allowanceSlot owner spender =
    EvmYul.fromByteArrayBigEndian (KeccakEngine.keccak256
      ((EvmYul.UInt256.ofNat spender.val).toByteArray ++
       (EvmYul.UInt256.ofNat (Compiler.Proofs.solidityMappingSlot 1 owner.val)).toByteArray)) := by
  unfold allowanceSlot Compiler.Proofs.nestedMappingSlotLocation
  rw [Nat.add_zero,Nat.mod_eq_of_lt (Compiler.Proofs.solidityMappingSlot_lt_evmModulus _ _)]
  rfl

def approval (ctx : Context) (owner : Address) (amount : Word) : Log :=
  ⟨ctx.self,"Approval",[word owner.val,word ctx.sender.val,amount]⟩

/-- Pinned StETH462: full Word infinity really skips both _approve guards,
write and log. Finite allowance check precedes owner/spender guards. -/
def spend (ctx : Context) (owner : Address) (amount : Word) : Exec Unit := fun before =>
  let current := before.core.readContractSlot ctx.self.val (allowanceSlot owner ctx.sender)
  if current.val = 2^256-1 then pureExec () before else
  if amount.val > current.val then fail (.bubbled (ReplyABI.reason "ALLOWANCE_EXCEEDED")) before else
  if owner = 0 then fail (.bubbled (ReplyABI.reason "APPROVE_FROM_ZERO_ADDR")) before else
  if ctx.sender = 0 then fail (.bubbled (ReplyABI.reason "APPROVE_TO_ZERO_ADDR")) before else
  let remaining := word (current.val-amount.val)
  ⟨.ok (),{before with core := before.core.writeContractSlot ctx.self.val (allowanceSlot owner ctx.sender) remaining, logs := before.logs ++ [approval ctx owner remaining]},[]⟩

def SpendEffect (ctx : Context) (owner : Address) (amount : Word) (before after : World) : Prop :=
  let current := before.core.readContractSlot ctx.self.val (allowanceSlot owner ctx.sender)
  (current.val = 2^256-1 ∧ after = before) ∨
  (current.val ≠ 2^256-1 ∧ amount.val ≤ current.val ∧ owner ≠ 0 ∧ ctx.sender ≠ 0 ∧
    after = {before with core := before.core.writeContractSlot ctx.self.val (allowanceSlot owner ctx.sender) (word (current.val-amount.val)),logs := before.logs ++ [approval ctx owner (word (current.val-amount.val))]})

theorem spend_success (ctx : Context) (owner : Address) (amount : Word) (w : World)
    (h : (spend ctx owner amount w).outcome = .ok ()) :
    SpendEffect ctx owner amount w (spend ctx owner amount w).world ∧ (spend ctx owner amount w).attempts = [] := by
  unfold spend at h ⊢
  dsimp only at h ⊢
  split at h
  · rename_i hi
    simp only [if_pos hi,pureExec]
    exact ⟨Or.inl ⟨hi,rfl⟩,trivial⟩
  · rename_i hi
    simp only [if_neg hi]
    split at h
    · contradiction
    · rename_i ha
      simp only [if_neg ha]
      split at h
      · contradiction
      · rename_i ho
        simp only [if_neg ho]
        split at h
        · contradiction
        · rename_i hs
          simp only [if_neg hs]
          exact ⟨Or.inr ⟨hi,Nat.le_of_not_gt ha,ho,hs,rfl⟩,trivial⟩

/-- Uses the actual post-allowance World for conversion and every movement read.
A hypothetical allowance/rate/balance alias is therefore not discarded. -/
def program (ctx : Context) (owner recipient : Address) (amount : Word) : Exec Unit :=
  bindExec (spend ctx owner amount) (fun _ => AddressStETHTransferCalls.program ⟨ctx.self,owner⟩ recipient amount)

def ProgramEffect (ctx : Context) (owner recipient : Address) (amount : Word) (before after : World) : Prop :=
  ∃ allowed,
    spend ctx owner amount before = ⟨.ok (),allowed,[]⟩ ∧
    SpendEffect ctx owner amount before allowed ∧
    AddressStETHTransferCalls.ProgramEffect ⟨ctx.self,owner⟩ recipient amount allowed after

theorem program_success (ctx : Context) (owner recipient : Address) (amount : Word) (w : World)
    (h : (program ctx owner recipient amount w).outcome = .ok ()) :
    ProgramEffect ctx owner recipient amount w (program ctx owner recipient amount w).world ∧
    (program ctx owner recipient amount w).attempts = [] := by
  cases hs : (spend ctx owner amount w).outcome with
  | «error» fault => simp [program,bindExec,hs] at h
  | ok u =>
    cases u
    have se := spend_success ctx owner amount w hs
    have hm : (AddressStETHTransferCalls.program ⟨ctx.self,owner⟩ recipient amount (spend ctx owner amount w).world).outcome = .ok () := by
      simpa only [program,bindExec,hs] using h
    have he := AddressStETHTransferCalls.program_success _ _ _ _ hm
    have eqs : spend ctx owner amount w = ⟨.ok (),(spend ctx owner amount w).world,[]⟩ := by
      cases hx : spend ctx owner amount w
      simp_all
    simp only [program,bindExec,hs]
    exact ⟨⟨_,eqs,se.1,he.1⟩,by simp only [se.2,he.2,List.nil_append]⟩

def reply (ctx : Context) (owner recipient : Address) (amount : Word) (before : World) : Reply :=
  let r := run (program ctx owner recipient amount) before
  match r.outcome with
  | .ok () => .success (encode 32 1) r.world
  | .error fault => .rejected (ReplyABI.fault fault)

def callee : External := fun req before =>
  if req.payload.take 4 = encode 4 0x23b872dd then
    if req.value.val ≠ 0 ∨ req.payload.length < 100 then .rejected [] else
    reply ⟨req.target,req.caller⟩ (.ofNat (decode ((req.payload.drop 4).take 32)))
      (.ofNat (decode ((req.payload.drop 36).take 32))) (word (decode ((req.payload.drop 68).take 32))) before
  else .rejected []

private theorem take_encoded (n x : Nat) (xs : Bytes) : (encode n x ++ xs).take n = encode n x := by
  simpa only [ABI.encode_length] using List.take_left (l₁ := encode n x) (l₂ := xs)
private theorem drop_encoded (n x : Nat) (xs : Bytes) : (encode n x ++ xs).drop n = xs := by
  simpa only [ABI.encode_length] using List.drop_left (l₁ := encode n x) (l₂ := xs)
private theorem canonical_address (a : Address) : _root_.Verity.Core.Address.ofNat (decode (encode 32 a.val)) = a := by
  have ha : a.val < 256^32 := by have h := a.isLt; norm_num [Verity.Core.ADDRESS_MODULUS] at h ⊢; omega
  rw [ABI.decode_encode_bounded 32 a.val ha]
  apply _root_.Verity.Core.Address.ext
  exact Nat.mod_eq_of_lt a.isLt

theorem canonical_call (target caller owner recipient : Address) (amount : Word) (w : World) :
    callee ⟨caller,target,0,stETHTransferFromCalldata owner recipient amount.val⟩ w =
      reply ⟨target,caller⟩ owner recipient amount w := by
  simp only [callee,stETHTransferFromCalldata,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.transferFromSelector,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.abiAddress,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.abiWord,List.append_assoc,take_encoded,
    ite_true,Verity.Core.Uint256.val_zero,ne_eq,not_true_eq_false,
    List.length_append,ABI.encode_length,Nat.reduceAdd,Nat.lt_irrefl,or_self,if_false,drop_encoded]
  have h36 : 36 = 4+32 := rfl
  have h68 : 68 = 4+32+32 := rfl
  simp only [h36,h68,← List.drop_drop,drop_encoded,take_encoded,
    (show (encode 32 amount.val).take 32 = encode 32 amount.val from by simpa only [ABI.encode_length] using List.take_length (l := encode 32 amount.val)),
    Verity.Core.Address.toNat,canonical_address,AddressWrappedTokenCalls.canonical_decode]

theorem reply_success (ctx : Context) (owner recipient : Address) (amount : Word) (w after : World) (data : Bytes)
    (h : reply ctx owner recipient amount w = .success data after) :
    data = encode 32 1 ∧ ProgramEffect ctx owner recipient amount w after := by
  cases hr : program ctx owner recipient amount w with
  | mk outcome world attempts =>
    cases outcome with
    | «error» e => simp [reply,run,hr] at h
    | ok u =>
      cases u
      simp only [reply,run,hr,Reply.success.injEq] at h
      obtain ⟨hd,hw⟩ := h
      subst data
      subst after
      exact ⟨rfl,by simpa only [hr] using (program_success ctx owner recipient amount w (by rw [hr])).1⟩

theorem reply_not_trace (ctx : Context) (owner recipient : Address) (amount : Word) (w after : World)
    (data : Bytes) (trace : List NestedAttempt) : reply ctx owner recipient amount w ≠ .successWithTrace data after trace := by
  unfold reply
  dsimp only
  split <;> simp

/-- Actual first request CALL, actual true reply decoded by the old bool decoder,
and physical effect on the same returned world; no supplied stage premise. -/
theorem transfer_effect (ctx : Context) (target : Address) (amount : Word) (before after : World) (attempts : List Attempt)
    (h : AddressRequestCalls.TransferEffect callee ctx target amount.val before after attempts) :
    ProgramEffect ⟨target,ctx.self⟩ ctx.sender ctx.self amount (transfer before ctx.self target 0) after ∧
    attempts = [⟨⟨ctx.self,target,0,stETHTransferFromCalldata ctx.sender ctx.self amount.val⟩,true,encode 32 1,[]⟩] := by
  obtain ⟨hc,data,nested,hl,hd,hr,hj⟩ := h
  rw [canonical_call] at hr
  rcases hr with plain | traced
  · obtain ⟨hb,he⟩ := reply_success _ _ _ _ _ _ _ plain.1
    exact ⟨he,by simpa only [hb,plain.2] using hj⟩
  · exact False.elim (reply_not_trace _ _ _ _ _ _ _ _ traced)

def Item (ctx : Context) (target owner : Address) (amount : Word) (id : Nat)
    (before after : World) (attempts : List Attempt) : Prop :=
  AddressStETHQuoteCalls.StItem callee ctx target owner amount id before after attempts ∧
  ∃ called shares ta qa,
    AddressRequestCalls.TransferEffect callee ctx target amount.val before called ta ∧
    ProgramEffect ⟨target,ctx.self⟩ ctx.sender ctx.self amount (transfer before ctx.self target 0) called ∧
    ta = [⟨⟨ctx.self,target,0,stETHTransferFromCalldata ctx.sender ctx.self amount.val⟩,true,encode 32 1,[]⟩] ∧
    AddressStETHQuoteCalls.QuoteFormula target amount.val shares called ∧
    AddressRequestCalls.QuoteEffect (AddressStETHQuoteCalls.quote target) ctx target amount.val called shares qa ∧
    AddressRequestCalls.EnqueueEffect ctx (AddressRequestCalls.resolvedOwner ctx owner)
      amount.val (shares.val % 2^128) id before.core.blockTimestamp called after ∧ attempts = ta ++ qa

theorem item_effect (ctx : Context) (target owner : Address) (amount : Word) (id : Nat)
    (before after : World) (attempts : List Attempt)
    (h : AddressStETHQuoteCalls.StItem callee ctx target owner amount id before after attempts) :
    Item ctx target owner amount id before after attempts := by
  refine ⟨h,?_⟩
  obtain ⟨called,shares,ta,qa,ht,hf,hq,hen,hj⟩ := h.2
  obtain ⟨he,ha⟩ := transfer_effect ctx target amount before called ta ht
  exact ⟨called,shares,ta,qa,ht,he,ha,hf,hq,hen,hj⟩
end LidoSRv3.Audit.Source.AddressStETHTransferFromCalls
