import LidoSRv3.Audit.Guarantees.PAddress1RequestBatches

/-! WQ permit CALL before the accepted typed batch's physical pause admission.
The permit body/signature/domain/nonces are explicit external implementations.
No outer ABI, memory, gas or compiled-array allocation equivalence is claimed. -/
namespace LidoSRv3.Audit.Source.AddressPermitRequestCalls
set_option autoImplicit false
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Source.AddressRequestBatches
open LidoSRv3.Audit.Source.AddressRequestCalls (resolvedOwner)
open LidoSRv3.Audit.Verity.AddressRecipientCallBridge (StaticExternal callWithCalldata)

structure PermitInput where
  value : Word
  deadline : Word
  v : UInt8
  r : Word
  s : Word

/-- Seven canonical ABI words, including the requesting owner and queue spender.
UInt8 supplies the actual v domain; no fit premise is needed. -/
def calldata (ctx : Context) (p : PermitInput) : Bytes :=
  encode 4 0xd505accf ++ encode 32 ctx.sender.val ++ encode 32 ctx.self.val ++
    encode 32 p.value.val ++ encode 32 p.deadline.val ++ encode 32 p.v.toNat ++
    encode 32 p.r.val ++ encode 32 p.s.val

theorem calldata_length (ctx : Context) (p : PermitInput) : (calldata ctx p).length = 228 := by
  simp only [calldata, List.length_append, LidoSRv3.Audit.Source.TrioReserve1.ABI.encode_length]

def permitCall (permit : External) (ctx : Context) (target : Address) (p : PermitInput) : Exec Bytes :=
  callWithCalldata permit ctx target (calldata ctx p) 0

/-- Successful void permit ignores all returndata, even empty/short/noncanonical.
Only actual transport failure prevents the batch; its pause check is downstream. -/
def program (permit : External) (ctx : Context) (target : Address) (p : PermitInput)
    (batch : Exec (List Nat)) : Exec (List Nat) := fun before =>
  let called := permitCall permit ctx target p before
  match called.outcome with
  | .error e => ⟨.error e, called.world, called.attempts⟩
  | .ok _ =>
    let result := batch called.world
    ⟨result.outcome, result.world, called.attempts ++ result.attempts⟩

def runPermit (permit : External) (ctx : Context) (target : Address) (p : PermitInput)
    (batch : Exec (List Nat)) : Exec (List Nat) := fun before => run (program permit ctx target p batch) before

/-- Actual generated request and actual returned world; arbitrary success bytes
and nested attempts are observed without an invented void-return decoder. -/
def PermitEffect (permit : External) (ctx : Context) (target : Address) (p : PermitInput)
    (before after : World) (attempts : List Attempt) : Prop :=
  (before.core.codeSize target.val).val ≠ 0 ∧
    ∃ data nested,
      ((permit ⟨ctx.self,target,0,calldata ctx p⟩ (transfer before ctx.self target 0) =
          .success data after ∧ nested = []) ∨
       permit ⟨ctx.self,target,0,calldata ctx p⟩ (transfer before ctx.self target 0) =
          .successWithTrace data after nested) ∧
      attempts = [⟨⟨ctx.self,target,0,calldata ctx p⟩,true,data,nested⟩]

theorem call_success (permit : External) (ctx : Context) (target : Address) (p : PermitInput)
    (before : World) (data : Bytes)
    (h : (permitCall permit ctx target p before).outcome = .ok data) :
    PermitEffect permit ctx target p before (permitCall permit ctx target p before).world
      (permitCall permit ctx target p before).attempts := by
  by_cases hc : (before.core.codeSize target.val).val = 0
  · simp [permitCall,callWithCalldata,hc] at h
  cases hr : permit ⟨ctx.self,target,0,calldata ctx p⟩ (transfer before ctx.self target 0) with
  | rejected bytes => simp [permitCall,callWithCalldata,hc,hr] at h
  | rejectedWithTrace bytes nested => simp [permitCall,callWithCalldata,hc,hr] at h
  | success bytes after =>
    refine ⟨hc,bytes,[],?_,?_⟩ <;> simp [permitCall,callWithCalldata,hc,hr]
  | successWithTrace bytes after nested =>
    refine ⟨hc,bytes,nested,?_,?_⟩ <;> simp [permitCall,callWithCalldata,hc,hr]

/-- Complete batch effect on the permit-returned world, with the permit attempt
prepended to that same batch's journal. No permit-success premise is supplied. -/
def JoinedEffect (permit : External) (ctx : Context) (target : Address) (p : PermitInput)
    (batchEffect : List Nat → World → World → List Attempt → Prop)
    (ids : List Nat) (before after : World) (attempts : List Attempt) : Prop :=
  ∃ permitted pa ba, PermitEffect permit ctx target p before permitted pa ∧
    batchEffect ids permitted after ba ∧ attempts = pa ++ ba

theorem joined_success (permit : External) (ctx : Context) (target : Address) (p : PermitInput)
    (batch : Exec (List Nat)) (effect : List Nat → World → World → List Attempt → Prop)
    (batch_success : ∀ w ids, (batch w).outcome = .ok ids → effect ids w (batch w).world (batch w).attempts)
    (before : World) (ids : List Nat)
    (h : (runPermit permit ctx target p batch before).outcome = .ok ids) :
    JoinedEffect permit ctx target p effect ids before
      (runPermit permit ctx target p batch before).world (runPermit permit ctx target p batch before).attempts := by
  have hp : (program permit ctx target p batch before).outcome = .ok ids := by
    unfold runPermit run at h
    cases he : (program permit ctx target p batch before).outcome <;> simp_all
  cases hc : (permitCall permit ctx target p before).outcome with
  | «error» e => simp only [program,hc] at hp; contradiction
  | ok data =>
    have hb : (batch (permitCall permit ctx target p before).world).outcome = .ok ids := by
      simpa only [program,hc] using hp
    refine ⟨_,_,(batch (permitCall permit ctx target p before).world).attempts,call_success _ _ _ _ _ _ hc,?_,?_⟩
    · simpa only [runPermit,run,program,hc,hb] using batch_success _ ids hb
    · simp only [runPermit,run,program,hc,hb]

theorem failure_restores (permit : External) (ctx : Context) (target : Address) (p : PermitInput)
    (batch : Exec (List Nat)) (before : World) (fault : Fault)
    (h : (runPermit permit ctx target p batch before).outcome = .error fault) :
    (runPermit permit ctx target p batch before).world = before := by
  unfold runPermit run at h ⊢
  cases he : (program permit ctx target p batch before).outcome <;> simp_all

/-- Precisely the ENTIRE public batch conclusion, including output length. -/
def StETHEffect (callee : External) (quote : StaticExternal) (ctx : Context)
    (stETH owner : Address) (amounts : List Word) (ids : List Nat)
    (before after : World) (attempts : List Attempt) : Prop :=
  Resumed before ∧ Transcript (stETHEffect callee quote ctx stETH (resolvedOwner ctx owner))
    amounts ids before after attempts ∧ ids.length = amounts.length

def WrappedEffect (conversion : StaticExternal) (tokenTransfer otherCalls : External)
    (quote : StaticExternal) (ctx : Context) (wstETH stETH owner : Address)
    (amounts : List Word) (ids : List Nat) (before after : World) (attempts : List Attempt) : Prop :=
  Resumed before ∧ Transcript (wrappedEffect conversion tokenTransfer otherCalls quote ctx wstETH stETH
    (resolvedOwner ctx owner)) amounts ids before after attempts ∧ ids.length = amounts.length

end LidoSRv3.Audit.Source.AddressPermitRequestCalls
