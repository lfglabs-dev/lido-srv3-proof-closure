import LidoSRv3.Audit.Guarantees.PConsolidationEth1PhysicalQuota
import Compiler.Proofs.MappingSlot

/-! Typed physical modifier prefix, core17005714 Gateway185:
onlyRole → preservesEthBalance entry subtraction → whenResumed.
Outer ABI/payable credit and the intervening DSM/locator/witness prefix remain
outside. The entire quota settlement is retained on the same original World;
its pure balance/count replay does not execute those omitted preconditions. -/
set_option autoImplicit false
namespace audit.trio.consolidation.PhysicalEntrySettlement
open LidoSRv3.Audit.Source.TrioReserve1 LidoSRv3.Audit.Source.TrioReserve1.Live

def role : Nat := 0x2893ea78cf4b35bcb6ca1f49c79c387fe7f3d8fd18fe56f2424c792c6a8207d2
def resumeSlot : Nat := 0xe8b012900cb200ee5dfc3b895a32791b67d12891b09f117814f167a237783a02

/-- Non-upgradeable AccessControl has _roles at base0. Pure Keccak is used
both in the kernel definition and the runtime evaluator, without FFI override. -/
def mappingSlot (base key : Nat) : Nat := EvmYul.fromByteArrayBigEndian
  (KeccakEngine.keccak256 ((EvmYul.UInt256.ofNat key).toByteArray ++ (EvmYul.UInt256.ofNat base).toByteArray))
def roleSlot (caller : Address) : Nat := mappingSlot (mappingSlot 0 role) caller.val
theorem roleSlot_bytes (caller : Address) : roleSlot caller =
    EvmYul.fromByteArrayBigEndian (KeccakEngine.keccak256
      ((EvmYul.UInt256.ofNat caller.val).toByteArray ++
       (EvmYul.UInt256.ofNat (EvmYul.fromByteArrayBigEndian (KeccakEngine.keccak256
         ((EvmYul.UInt256.ofNat role).toByteArray ++ (EvmYul.UInt256.ofNat 0).toByteArray)))).toByteArray)) := rfl

def roleByte (ctx : Context) (before : World) : Nat :=
  (before.core.readContractSlot ctx.self.val (roleSlot ctx.sender)).val%256
def unauthorized (caller : Address) : Bytes := encode 4 0xe2517d3f ++ encode 32 caller.val ++ encode 32 role
def Admitted (ctx : Context) (msgValue : Word) (before : World) : Prop :=
  roleByte ctx before ≠ 0 ∧ msgValue.val ≤ before.balances ctx.self ∧
  (before.core.readContractSlot ctx.self.val resumeSlot).val ≤ before.core.blockTimestamp.val
def gates (ctx : Context) (msgValue : Word) (before : World) : Except Fault Unit :=
  if roleByte ctx before = 0 then .error (.bubbled (unauthorized ctx.sender)) else
  if before.balances ctx.self < msgValue.val then .error PhysicalQuotaSettlement.arithmetic else
  if before.core.blockTimestamp.val < (before.core.readContractSlot ctx.self.val resumeSlot).val then
    .error (.bubbled (encode 4 0x14378398)) else .ok ()

theorem gates_success (ctx : Context) (msgValue : Word) (before : World)
    (h : gates ctx msgValue before = .ok ()) : Admitted ctx msgValue before := by
  unfold gates at h
  split at h
  · contradiction
  · rename_i hr
    split at h
    · contradiction
    · rename_i hb
      split at h
      · contradiction
      · rename_i hp
        exact ⟨hr,by omega,by omega⟩

structure Result where
  outcome : Except Fault Unit
  world : World
  trace : List NestedAttempt
  suffix : Option PhysicalQuotaSettlement.Result
def ofPrior (r : PhysicalQuotaSettlement.Result) : Result := ⟨r.outcome,r.world,r.trace,some r⟩
def execute (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) : Result :=
  match gates ctx msgValue before with
  | .error f => ⟨.error f,before,[],none⟩
  | .ok () => ofPrior (PhysicalQuotaSettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before)

theorem execute_success (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World)
    (h : (execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).outcome = .ok ()) :
    Admitted ctx msgValue before ∧
    (PhysicalQuotaSettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).outcome = .ok () ∧
    execute callee sexternal ctx vault gateway inbox recipient msgValue groups before =
      ofPrior (PhysicalQuotaSettlement.execute callee sexternal ctx vault gateway inbox recipient msgValue groups before) := by
  unfold execute at h ⊢
  cases hg : gates ctx msgValue before with
  | «error» f => simp [hg] at h
  | ok u =>
    cases u
    simp only [hg] at h ⊢
    exact ⟨gates_success _ _ _ hg,h,by trivial⟩

theorem failure_restores (callee : External) (sexternal : StaticCall.External) (ctx : Context)
    (vault gateway inbox recipient : Address) (msgValue : Word)
    (groups : List WitnessGroupBytes) (before : World) (f : Fault)
    (h : (execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).outcome = .error f) :
    (execute callee sexternal ctx vault gateway inbox recipient msgValue groups before).world = before := by
  unfold execute at h ⊢
  cases hg : gates ctx msgValue before with
  | «error» fault => rfl
  | ok u =>
    cases u
    simp only [hg,ofPrior] at h ⊢
    exact PhysicalQuotaSettlement.failure_restores _ _ _ _ _ _ _ _ _ _ _ h

#print axioms roleSlot_bytes
#print axioms gates_success
#print axioms execute_success
#print axioms failure_restores
end audit.trio.consolidation.PhysicalEntrySettlement
