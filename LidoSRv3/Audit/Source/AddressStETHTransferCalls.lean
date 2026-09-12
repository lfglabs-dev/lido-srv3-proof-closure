import LidoSRv3.Audit.Guarantees.PAddress1StETHConversionCalls

/-! Actual pinned full-Lido StETH.transfer specialization, consumed by the
postburn WstETH CALL. Physical mapping slot0 is checked against full Lido's
legacy assembly, not inferred from standalone StETH. No alias/frame premise. -/
namespace LidoSRv3.Audit.Source.AddressStETHTransferCalls
set_option autoImplicit false
open LidoSRv3.Audit.Source.TrioReserve1
open Live
open AddressStETHQuoteCalls (QuoteFormula)
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (erc20TransferCalldata)

def activeSlot : Nat := 0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece

def balanceSlot (owner : Address) : Nat := Compiler.Proofs.mappingSlotLocation 0 owner.val 0

/-- Exact two MSTORE words (cleaned address, zero base), then 64-byte Keccak.
No collision-resistance lemma is used by the physical reads or writes. -/
theorem balanceSlot_keccak (owner : Address) : balanceSlot owner =
    EvmYul.fromByteArrayBigEndian (KeccakEngine.keccak256
      ((EvmYul.UInt256.ofNat owner.val).toByteArray ++ (EvmYul.UInt256.ofNat 0).toByteArray)) := by
  simp only [balanceSlot,Compiler.Proofs.mappingSlotLocation_zero,
    Compiler.Proofs.solidityMappingSlot,Compiler.Proofs.abiEncodeMappingSlot]

def events (ctx : Context) (recipient : Address) (amount shares : Word) : List Log :=
  [⟨ctx.self,"Transfer",[word ctx.sender.val,word recipient.val,amount]⟩,
   ⟨ctx.self,"TransferShares",[word ctx.sender.val,word recipient.val,shares]⟩]

/-- The active flag is the entire SLOAD word tested for nonzero. Recipient is
read after debit; every possible address/mapping/fixed-slot alias is retained. -/
def move (ctx : Context) (recipient : Address) (amount shares : Word) : Exec Unit := fun before =>
  if ctx.sender = 0 then fail (.bubbled (ReplyABI.reason "TRANSFER_FROM_ZERO_ADDR")) before else
  if recipient = 0 then fail (.bubbled (ReplyABI.reason "TRANSFER_TO_ZERO_ADDR")) before else
  if recipient = ctx.self then fail (.bubbled (ReplyABI.reason "TRANSFER_TO_STETH_CONTRACT")) before else
  if (before.core.readContractSlot ctx.self.val activeSlot).val = 0 then
    fail (.bubbled (ReplyABI.reason "CONTRACT_IS_STOPPED")) before else
  let balance := before.core.readContractSlot ctx.self.val (balanceSlot ctx.sender)
  if shares.val > balance.val then fail (.bubbled (ReplyABI.reason "BALANCE_EXCEEDED")) before else
  let debited := {before with core := before.core.writeContractSlot ctx.self.val (balanceSlot ctx.sender) (word (balance.val-shares.val))}
  let fresh := debited.core.readContractSlot ctx.self.val (balanceSlot recipient)
  if fresh.val + shares.val ≥ 2^256 then fail (.bubbled (ReplyABI.reason "MATH_ADD_OVERFLOW")) debited else
  ⟨.ok (), {debited with core := debited.core.writeContractSlot ctx.self.val (balanceSlot recipient) (word (fresh.val+shares.val)), logs := debited.logs ++ events ctx recipient amount shares}, []⟩

def MoveEffect (ctx : Context) (recipient : Address) (amount shares : Word) (before after : World) : Prop :=
  ctx.sender ≠ 0 ∧ recipient ≠ 0 ∧ recipient ≠ ctx.self ∧
  (before.core.readContractSlot ctx.self.val activeSlot).val ≠ 0 ∧
  let balance := before.core.readContractSlot ctx.self.val (balanceSlot ctx.sender)
  shares.val ≤ balance.val ∧
  let debited := {before with core := before.core.writeContractSlot ctx.self.val (balanceSlot ctx.sender) (word (balance.val-shares.val))}
  let fresh := debited.core.readContractSlot ctx.self.val (balanceSlot recipient)
  fresh.val + shares.val < 2^256 ∧
  after = {debited with core := debited.core.writeContractSlot ctx.self.val (balanceSlot recipient) (word (fresh.val+shares.val)), logs := debited.logs ++ events ctx recipient amount shares}

theorem move_success (ctx : Context) (recipient : Address) (amount shares : Word) (w : World)
    (h : (move ctx recipient amount shares w).outcome = .ok ()) :
    MoveEffect ctx recipient amount shares w (move ctx recipient amount shares w).world ∧
    (move ctx recipient amount shares w).attempts = [] := by
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
      · rename_i hs
        simp only [if_neg hs]
        split at h
        · contradiction
        · rename_i hp
          simp only [if_neg hp]
          split at h
          · contradiction
          · rename_i hb
            simp only [if_neg hb]
            split at h
            · contradiction
            · rename_i ha
              simp only [if_neg ha]
              exact ⟨⟨hf,ht,hs,hp,Nat.le_of_not_gt hb,Nat.lt_of_not_ge ha,rfl⟩,trivial⟩

/-- Internal getSharesByPooledEth executes before all _transferShares guards.
Its strict width, raw arithmetic and zero-divisor failure are unchanged. -/
def program (ctx : Context) (recipient : Address) (amount : Word) : Exec Unit := fun before =>
  match AddressStETHQuoteCalls.body ctx.self amount before with
  | .error fault => fail fault before
  | .ok shares => move ctx recipient amount shares before

def ProgramEffect (ctx : Context) (recipient : Address) (amount : Word) (before after : World) : Prop :=
  ∃ shares, AddressStETHQuoteCalls.body ctx.self amount before = .ok shares ∧
    QuoteFormula ctx.self amount.val shares before ∧ MoveEffect ctx recipient amount shares before after

theorem program_success (ctx : Context) (recipient : Address) (amount : Word) (w : World)
    (h : (program ctx recipient amount w).outcome = .ok ()) :
    ProgramEffect ctx recipient amount w (program ctx recipient amount w).world ∧
    (program ctx recipient amount w).attempts = [] := by
  cases hq : AddressStETHQuoteCalls.body ctx.self amount w with
  | «error» fault => simp [program,hq,fail] at h
  | ok shares =>
    simp only [program,hq] at h ⊢
    obtain ⟨he,ha⟩ := move_success ctx recipient amount shares w h
    exact ⟨⟨shares,hq,AddressStETHQuoteCalls.body_success ctx.self amount shares w hq,he⟩,ha⟩

def reply (ctx : Context) (recipient : Address) (amount : Word) (before : World) : Reply :=
  let r := run (program ctx recipient amount) before
  match r.outcome with
  | .ok () => .success (encode 32 1) r.world
  | .error fault => .rejected (ReplyABI.fault fault)

/-- Canonical generated CALL dispatcher; dynamically qualified by req.target.
No claim to recognize deployed bytecode or arbitrary malformed ABI dispatch. -/
def callee : External := fun req before =>
  if req.value.val = 0 ∧ req.payload.take 4 = encode 4 0xa9059cbb ∧ 68 ≤ req.payload.length then
    reply ⟨req.target,req.caller⟩ (.ofNat (decode ((req.payload.drop 4).take 32)))
      (word (decode ((req.payload.drop 36).take 32))) before
  else .rejected []

private theorem canonical_address (a : Address) : _root_.Verity.Core.Address.ofNat (decode (encode 32 a.val)) = a := by
  have ha : a.val < 256^32 := by have h := a.isLt; norm_num [Verity.Core.ADDRESS_MODULUS] at h ⊢; omega
  rw [ABI.decode_encode_bounded 32 a.val ha]
  apply _root_.Verity.Core.Address.ext
  exact Nat.mod_eq_of_lt a.isLt

private theorem take_encoded (n x : Nat) (xs : Bytes) : (encode n x ++ xs).take n = encode n x := by
  simpa only [ABI.encode_length] using (List.take_left (l₁ := encode n x) (l₂ := xs))
private theorem drop_encoded (n x : Nat) (xs : Bytes) : (encode n x ++ xs).drop n = xs := by
  simpa only [ABI.encode_length] using (List.drop_left (l₁ := encode n x) (l₂ := xs))

theorem canonical_call (ctx : Context) (target recipient : Address) (amount : Word) (w : World) :
    callee ⟨ctx.self,target,0,erc20TransferCalldata recipient amount.val⟩ w =
      reply ⟨target,ctx.self⟩ recipient amount w := by
  simp only [callee,erc20TransferCalldata,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.erc20TransferSelector,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.abiAddress,
    LidoSRv3.Audit.Verity.AddressRecipientCallBridge.abiWord,List.append_assoc,take_encoded,
    Verity.Core.Uint256.val_zero,le_refl,List.length_append,ABI.encode_length,Nat.reduceAdd,and_self,if_true]
  have h36 : 36 = 4+32 := rfl
  simp only [h36,← List.drop_drop,drop_encoded,take_encoded,
    (show (encode 32 amount.val).take 32 = encode 32 amount.val from by simpa only [ABI.encode_length] using List.take_length (l := encode 32 amount.val)),
    Verity.Core.Address.toNat,canonical_address,AddressWrappedTokenCalls.canonical_decode]

theorem reply_success (ctx : Context) (recipient : Address) (amount : Word) (w after : World) (data : Bytes)
    (h : reply ctx recipient amount w = .success data after) :
    data = encode 32 1 ∧ ProgramEffect ctx recipient amount w after := by
  cases hr : program ctx recipient amount w with
  | mk outcome world attempts =>
    cases outcome with
    | «error» e => simp [reply,run,hr] at h
    | ok u =>
      cases u
      simp only [reply,run,hr,Reply.success.injEq] at h
      obtain ⟨hd,hw⟩ := h
      subst data
      subst after
      exact ⟨rfl,by simpa only [hr] using (program_success ctx recipient amount w (by rw [hr])).1⟩

theorem reply_not_trace (ctx : Context) (recipient : Address) (amount : Word) (w after : World)
    (data : Bytes) (trace : List NestedAttempt) : reply ctx recipient amount w ≠ .successWithTrace data after trace := by
  unfold reply
  dsimp only
  split <;> simp

/-- Same actual mutable CALL, returned World and decoded true used by WstETH. -/
theorem call_effect (ctx : Context) (target recipient : Address) (amount decoded : Word)
    (before after : World) (attempts : List Attempt)
    (h : AddressWrappedTokenCalls.CallEffect callee ctx target (erc20TransferCalldata recipient amount.val) before after decoded attempts) :
    decoded = word 1 ∧ ProgramEffect ⟨target,ctx.self⟩ recipient amount (transfer before ctx.self target 0) after := by
  obtain ⟨hc,data,nested,hl,hd,hr,hj⟩ := h
  rw [canonical_call] at hr
  rcases hr with plain | traced
  · obtain ⟨hb,he⟩ := reply_success _ _ _ _ _ _ plain.1
    rw [hb] at hd
    have ht : (encode 32 1).take 32 = encode 32 1 := by simpa only [ABI.encode_length] using List.take_length (l := encode 32 1)
    exact ⟨by simpa only [ht,show word (decode (encode 32 1)) = word 1 from by decide +kernel] using hd,he⟩
  · exact False.elim (reply_not_trace _ _ _ _ _ _ _ traced)

/-- Full107e token effect retained; the fresh postburn slot7 target is bound
explicitly to the physical transfer and its actual true return. -/
def TokenEffect (ctx : Context) (amount received : Word) (before after : World) (attempts : List Attempt) : Prop :=
  AddressStETHConversionCalls.TokenEffect callee ctx amount received before after attempts ∧
  ∃ burned transferReturn qa ta,
    AddressWrappedTokenCalls.StaticEffect AddressStETHConversionCalls.conversion ctx
      (AddressWrappedTokenCalls.stETHAddress ctx.self before)
      (LidoSRv3.Audit.Verity.AddressRecipientCallBridge.pooledEthBySharesCalldata amount.val) before received qa ∧
    AddressWrappedTokenCalls.BurnEffect ctx amount before burned ∧
    AddressWrappedTokenCalls.CallEffect callee ctx (AddressWrappedTokenCalls.stETHAddress ctx.self burned)
      (erc20TransferCalldata ctx.sender received.val) burned after transferReturn ta ∧
    transferReturn = word 1 ∧
    ProgramEffect ⟨AddressWrappedTokenCalls.stETHAddress ctx.self burned,ctx.self⟩ ctx.sender received
      (transfer burned ctx.self (AddressWrappedTokenCalls.stETHAddress ctx.self burned) 0) after ∧ attempts = qa ++ ta

theorem token_effect (ctx : Context) (amount received : Word) (before after : World) (attempts : List Attempt)
    (h : AddressStETHConversionCalls.TokenEffect callee ctx amount received before after attempts) :
    TokenEffect ctx amount received before after attempts := by
  refine ⟨h,?_⟩
  obtain ⟨hp,burned,ret,qa,ta,hq,hb,ht,hj⟩ := h.1
  obtain ⟨htrue,he⟩ := call_effect ctx _ ctx.sender received ret burned after ta ht
  exact ⟨burned,ret,qa,ta,hq,hb,ht,htrue,he,hj⟩

/-- Entire107e item plus the actual token/transfer effect on the same worlds. -/
def Item (otherCalls : External) (ctx : Context) (wstETH target owner : Address)
    (amount : Word) (id : Nat) (before after : World) (attempts : List Attempt) : Prop :=
  AddressStETHConversionCalls.Item callee otherCalls ctx wstETH target owner amount id before after attempts ∧
  ∃ transferred unwrapped received shares ta ua qa inner,
    AddressWrappedTransferCalls.TransferFromEffect ⟨wstETH,ctx.self⟩ ctx.sender ctx.self amount
      (transfer before ctx.self wstETH 0) transferred ∧
    AddressWrappedRequestCalls.UnwrapEffect
      (AddressWrappedTokenCalls.calleeFor wstETH AddressStETHConversionCalls.conversion callee (AddressWrappedTransferCalls.calleeFor wstETH otherCalls))
      ctx wstETH amount received transferred unwrapped ua ∧
    TokenEffect ⟨wstETH,ctx.self⟩ amount received (transfer transferred ctx.self wstETH 0) unwrapped inner ∧
    100 ≤ received.val ∧ received.val ≤ 1000*10^18 ∧ received.val < 2^128 ∧
    QuoteFormula target received.val shares unwrapped ∧
    AddressRequestCalls.QuoteEffect (AddressStETHQuoteCalls.quote target) ctx target received.val unwrapped shares qa ∧
    AddressRequestCalls.EnqueueEffect ctx (AddressRequestCalls.resolvedOwner ctx owner)
      received.val (shares.val % 2^128) id before.core.blockTimestamp unwrapped after ∧ attempts = ta ++ ua ++ qa

theorem item_effect (otherCalls : External) (ctx : Context) (wstETH target owner : Address)
    (amount : Word) (id : Nat) (before after : World) (attempts : List Attempt)
    (h : AddressStETHConversionCalls.Item callee otherCalls ctx wstETH target owner amount id before after attempts) :
    Item otherCalls ctx wstETH target owner amount id before after attempts := by
  refine ⟨h,?_⟩
  obtain ⟨transferred,unwrapped,received,shares,ta,ua,qa,inner,ht,hu,he,hl,hh,hfit,hq,hqe,hen,hj⟩ := h.2
  exact ⟨transferred,unwrapped,received,shares,ta,ua,qa,inner,ht,hu,token_effect _ _ _ _ _ _ he,hl,hh,hfit,hq,hqe,hen,hj⟩
end LidoSRv3.Audit.Source.AddressStETHTransferCalls
