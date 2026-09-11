import LidoSRv3.Audit.Guarantees.PDeposit1PhysicalAdmission
import audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest

namespace LidoSRv3.Tests.DepositPhysicalAdmission
set_option autoImplicit false
set_option maxRecDepth 16384
open LidoSRv3.Audit.Source
open TrioReserve1
open audit.trio.deposit
open LidoSRv3.Audit.Guarantees.PDeposit1
open audit.trio.deposit.Tests.Verity

-- Deliberately colliding test hash, never presented as Keccak correctness.
-- Membership and module config both read slot90 here; production theorem has
-- no injectivity premise. The real-hash layout is checked by the Solidity suite.
def before : Live.World :=
  {ModulePhysicalMetadataTest.before with core := ((ModulePhysicalMetadataTest.before.core.writeContractSlot 2 90 (Live.word 40)).writeContractSlot
    2 (TopupRouterCredentials.routerRoot+4) (Live.word 99))}
def supplied : RouterDeposit.Context := {ModulePhysicalMetadataTest.ctx with moduleActive := false,withdrawalCredentials := none}
def run (w : Live.World := before) := _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.execute ModulePhysicalMetadataTest.hash (ModulePhysicalMetadataTest.answer (ModuleCall.encodeReturn [] []))
  ModulePhysicalMetadataTest.reject supplied ModulePhysicalMetadataTest.liveCtx ModulePhysicalMetadataTest.input w

theorem context_derived : _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.derivedContext ModulePhysicalMetadataTest.hash supplied ModulePhysicalMetadataTest.liveCtx.sender ModulePhysicalMetadataTest.input.moduleId before = ModulePhysicalMetadataTest.ctx := by
  decide +kernel

example : _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.membership ModulePhysicalMetadataTest.hash ModulePhysicalMetadataTest.liveCtx.sender ModulePhysicalMetadataTest.input.moduleId before = 40 := by decide +kernel
example : _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.status (_root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.config ModulePhysicalMetadataTest.hash ModulePhysicalMetadataTest.liveCtx.sender ModulePhysicalMetadataTest.input.moduleId before) = 0 := by decide +kernel
example : (_root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.selected ModulePhysicalMetadataTest.hash ModulePhysicalMetadataTest.liveCtx.sender ModulePhysicalMetadataTest.input.moduleId before).val = 99 := by decide +kernel
example : (run before).outcome = .ok () := by decide +kernel
example : (run before).attempts.length = 1 := by decide +kernel
example : (run before).world.logs.map (·.name) = ["ModuleEffect","StakingRouterETHDeposited"] := by decide +kernel

def configWorld (status kind position : Nat) : Live.World :=
  -- A separated test hash is used for rejection order/status sweep below.
  {before with core := ((before.core.writeContractSlot 2 80 (Live.word position)).writeContractSlot
      2 90 (Live.word (40+status*2^224+kind*2^232)))}
def separatedHash : _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.Keccak := fun data =>
  if data = Live.encode 32 ModulePhysicalMetadataTest.input.moduleId.val ++ Live.encode 32 (TopupRouterCredentials.routerRoot+2)
  then Live.word 80 else Live.word 90

def rejected (status kind position : Nat) (ctx : RouterDeposit.Context := supplied) :=
  _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.execute separatedHash ModulePhysicalMetadataTest.reject ModulePhysicalMetadataTest.reject ctx ModulePhysicalMetadataTest.liveCtx ModulePhysicalMetadataTest.input (configWorld status kind position)

example : (rejected 255 2 0 {supplied with caller := ⟨8,by decide⟩}).outcome =
    .error (.reason "NotAuthorized") := by decide +kernel
example : (rejected 255 2 0 supplied).outcome = .error (.reason "StakingModuleUnregistered") := by decide +kernel
example : (rejected 3 2 1 supplied).outcome = .error (.reason "Panic(0x21)") := by decide +kernel
example : (rejected 255 2 1 supplied).outcome = .error (.reason "Panic(0x21)") := by decide +kernel
example : (rejected 1 255 1 supplied).outcome = .error (.reason "StakingModuleNotActive") := by decide +kernel
example : (rejected 2 255 1 supplied).outcome = .error (.reason "StakingModuleNotActive") := by decide +kernel
example : (rejected 0 255 1 supplied).outcome = .error (.bubbled [0xde,0xad]) := by decide +kernel
example : (_root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.selectedOctets separatedHash ModulePhysicalMetadataTest.liveCtx.sender ModulePhysicalMetadataTest.input.moduleId (configWorld 0 255 1)).head? = some 255 := by decide +kernel
example : (_root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.selected separatedHash ModulePhysicalMetadataTest.liveCtx.sender ModulePhysicalMetadataTest.input.moduleId (configWorld 0 255 1)).val % 2^248 = 99 := by decide +kernel
example : (_root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.execute ModulePhysicalMetadataTest.hash ModulePhysicalMetadataTest.reject ModulePhysicalMetadataTest.reject supplied ModulePhysicalMetadataTest.liveCtx {ModulePhysicalMetadataTest.input with maxEB := ModulePhysicalMetadataTest.sw 0} before).outcome =
    .error (.reason "Panic(0x12)") := by decide +kernel

-- Reuse the accepted positive module and actual withdrawal/beacon execution;
-- the new prefix replaces deliberately false/absent supplied config values.
def positive := _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.execute ModulePhysicalMetadataTest.hash ModulePhysicalMetadataTest.positiveModule ModulePhysicalMetadataTest.withdrawalExternal supplied ModulePhysicalMetadataTest.liveCtx ModulePhysicalMetadataTest.input before

open ModulePhysicalMetadataTest in
theorem positive_program_transport :
    _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.program hash positiveModule withdrawalExternal supplied liveCtx input before =
    ModulePhysicalMetadata.program hash positiveModule withdrawalExternal ctx liveCtx input ModulePhysicalMetadataTest.before := by
  have ha : (supplied.caller != supplied.depositSecurityModule) = false := by decide +kernel
  have hm : _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.membership hash liveCtx.sender input.moduleId before ≠ 0 := by decide +kernel
  have hs : _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.status (_root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.config hash liveCtx.sender input.moduleId before) = 0 := by decide +kernel
  simp only [_root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.program,ha,Bool.false_eq_true,if_false,hm,hs,context_derived]
  have pn := ModulePhysicalMetadata.program_of_call hash positiveModule withdrawalExternal ctx liveCtx input before funded
    (sw 99) rawPositive [⟨⟨addr 2,addr 40,Live.word 0,ModuleCall.payload 2 input.depositCalldata⟩,true,rawPositive,nested⟩]
    rfl rfl rfl (by decide) (by decide) (by rfl)
  have po := ModulePhysicalMetadata.program_of_call hash positiveModule withdrawalExternal ctx liveCtx input ModulePhysicalMetadataTest.before funded
    (sw 99) rawPositive [⟨⟨addr 2,addr 40,Live.word 0,ModuleCall.payload 2 input.depositCalldata⟩,true,rawPositive,nested⟩]
    rfl rfl rfl (by decide) (by decide) (by rfl)
  have hn : ModuleCall.target hash liveCtx.sender input before = 2 := by decide +kernel
  have ho : ModuleCall.target hash liveCtx.sender input ModulePhysicalMetadataTest.before = 2 := by decide +kernel
  rw [hn] at pn
  rw [ho] at po
  exact pn.trans po.symm

private theorem run_outcome (p : Live.Exec Unit) (w : Live.World) :
    (Live.run p w).outcome = (p w).outcome := by
  unfold Live.run
  dsimp only
  split <;> simp_all

theorem positive_execution : positive.outcome = .ok () := by
  have h := ModulePhysicalMetadataTest.positive_execution
  dsimp only [ModulePhysicalMetadataTest.positive,ModulePhysicalMetadata.execute] at h
  rw [run_outcome] at h
  dsimp only [positive,_root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.execute]
  rw [run_outcome,positive_program_transport]
  exact h

theorem public_positive : _root_.LidoSRv3.Audit.Source.DepositPhysicalAdmission.Effects ModulePhysicalMetadataTest.hash ModulePhysicalMetadataTest.positiveModule ModulePhysicalMetadataTest.withdrawalExternal supplied ModulePhysicalMetadataTest.liveCtx ModulePhysicalMetadataTest.input
    before positive.world positive.attempts := by
  have heq : positive = ⟨.ok (),positive.world,positive.attempts⟩ := by
    have h := positive_execution
    cases he : positive with
    | mk outcome world attempts => simp only [he] at h; subst outcome; rfl
  exact actual_registered_module_call_metadata_suffix _ _ _ _ _ _ _ _ _ heq

theorem public_rejection_restores :
    (rejected 255 1 0 supplied).world = configWorld 255 1 0 := by
  apply actual_registered_module_failure_restores separatedHash ModulePhysicalMetadataTest.reject ModulePhysicalMetadataTest.reject supplied
    ModulePhysicalMetadataTest.liveCtx ModulePhysicalMetadataTest.input (configWorld 255 1 0) _ _ (.reason "StakingModuleUnregistered")
  rfl

#print axioms LidoSRv3.Audit.Source.DepositPhysicalAdmission.selected_fields
#print axioms LidoSRv3.Audit.Source.DepositPhysicalAdmission.selectedOctets_head
#print axioms actual_registered_module_call_metadata_suffix
#print axioms actual_registered_module_failure_restores
#print axioms public_positive
#print axioms public_rejection_restores
end LidoSRv3.Tests.DepositPhysicalAdmission
