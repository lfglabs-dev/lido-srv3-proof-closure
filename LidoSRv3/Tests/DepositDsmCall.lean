import LidoSRv3.Audit.Guarantees.PDeposit1DsmCall
import LidoSRv3.Tests.DepositPhysicalAdmission
namespace LidoSRv3.Tests.DepositDsmCall
set_option autoImplicit false
set_option maxRecDepth 16384
open LidoSRv3.Audit.Source TrioReserve1 audit.trio.deposit
open LidoSRv3.Audit.Guarantees.PDeposit1
open audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest
abbrev D := LidoSRv3.Audit.Source.DepositDsmCall.LookupResult

def before := LidoSRv3.Tests.DepositPhysicalAdmission.before
-- Deliberately wrong supplied DSM, plus false/none physical admission fields.
def supplied := {LidoSRv3.Tests.DepositPhysicalAdmission.supplied with depositSecurityModule := (⟨999,by decide⟩ : TrioAlloc1.Address)}
def locator := addr 3
def cursor := Live.word 128

def answer (raw : Live.Bytes) : StaticCall.External := fun req _ =>
  if req = LidoSRv3.Audit.Source.DepositDsmCall.request liveCtx.sender locator
  then .success raw else .rejected [0xff]
def query := answer (Live.encode 32 7)
def rejectQuery : StaticCall.External := fun _ _ => .rejected [0xde,0xad]
def forbidden : StaticCall.External := fun _ _ => .forbiddenStateChange

def run (q : StaticCall.External := query) (b : Live.World := before) :=
  LidoSRv3.Audit.Source.DepositDsmCall.execute q locator cursor hash
    (audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest.answer (ModuleCall.encodeReturn [] []))
    reject supplied liveCtx input b

example : LidoSRv3.Audit.Source.DepositDsmCall.selector = 0x472c1776 := by decide +kernel
example : (run).outcome = .ok () := by decide +kernel
example : (run).locatorAttempts = [⟨LidoSRv3.Audit.Source.DepositDsmCall.request liveCtx.sender locator,true,true,Live.encode 32 7,1⟩] := by decide +kernel
example : (run).attempts.length = 1 := by decide +kernel
example : (run).world.logs.map (·.name) = ["ModuleEffect","StakingRouterETHDeposited"] := by decide +kernel
example : (run rejectQuery).outcome = .error (.bubbled [0xde,0xad]) := by decide +kernel
example : (run rejectQuery).attempts = [] := by decide +kernel
example : (run forbidden).outcome = .error (.bubbled []) := by decide +kernel
example : (run (answer (Live.encode 32 999))).outcome = .error (.reason "NotAuthorized") := by decide +kernel
example : (run (answer (Live.encode 32 0))).outcome = .error (.reason "NotAuthorized") := by decide +kernel
example : (run (answer (Live.encode 32 (2^160+7)))).outcome = .error .empty := by decide +kernel
example : (run (answer (List.replicate 31 0))).outcome = .error .empty := by decide +kernel
example : (run (answer (Live.encode 32 7 ++ [255,1,2]))).outcome = .ok () := by decide +kernel
example : LidoSRv3.Audit.Source.DepositDsmCall.decodeAddress cursor (Live.encode 32 0) = .ok ⟨0,by decide⟩ := by decide +kernel
example : LidoSRv3.Audit.Source.DepositDsmCall.decodeAddress (Live.word (2^64-32)) [0] = .error (.reason "Panic(0x41)") := by decide +kernel
example : LidoSRv3.Audit.Source.DepositDsmCall.decodeAddress (Live.word (2^64-33)) (Live.encode 32 7) = .ok ⟨7,by decide⟩ := by decide +kernel

def noCode := {before with core := {before.core with codeSize := fun _ => Live.word 0}}
example : (run query noCode).outcome = .error .empty := by decide +kernel
example : (run query noCode).locatorAttempts = [⟨LidoSRv3.Audit.Source.DepositDsmCall.request liveCtx.sender locator,true,true,[],1⟩] := by decide +kernel

def positive := LidoSRv3.Audit.Source.DepositDsmCall.execute query locator cursor hash
  positiveModule withdrawalExternal supplied liveCtx input before

theorem positive_transport : positive =
    let r := LidoSRv3.Tests.DepositPhysicalAdmission.positive
    LidoSRv3.Audit.Source.DepositDsmCall.Result.mk r.outcome r.world r.attempts
      [⟨LidoSRv3.Audit.Source.DepositDsmCall.request liveCtx.sender locator,true,true,Live.encode 32 7,1⟩] := by
  unfold positive
  exact LidoSRv3.Audit.Source.DepositDsmCall.execute_of_lookup query locator cursor hash positiveModule withdrawalExternal
    supplied liveCtx input before ⟨7,by decide⟩ _ (by decide +kernel)

theorem positive_execution : positive.outcome = .ok () := by
  rw [positive_transport]
  exact LidoSRv3.Tests.DepositPhysicalAdmission.positive_execution

theorem public_positive : LidoSRv3.Audit.Source.DepositDsmCall.Effects query locator cursor hash
    positiveModule withdrawalExternal supplied liveCtx input before positive.world positive.attempts positive.locatorAttempts := by
  have h : positive = ⟨.ok (),positive.world,positive.attempts,positive.locatorAttempts⟩ := by
    have ho := positive_execution
    cases he : positive with
    | mk outcome world attempts staticTrace => simp only [he] at ho; subst outcome; rfl
  exact actual_dsm_call_registered_module_suffix _ _ _ _ _ _ _ _ _ _ _ _ _ h

theorem public_rejection_restores : (run rejectQuery).world = before := by
  apply actual_dsm_call_failure_restores rejectQuery locator cursor hash
    (audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest.answer (ModuleCall.encodeReturn [] [])) reject supplied liveCtx input
    before _ _ _ (.bubbled [0xde,0xad])
  rfl

def lateRaw := LidoSRv3.Audit.Source.DepositDsmCall.program query locator cursor hash
  positiveModule reject supplied liveCtx input before
def late := LidoSRv3.Audit.Source.DepositDsmCall.execute query locator cursor hash
  positiveModule reject supplied liveCtx input before

example : lateRaw.world.logs.map (·.name) = ["ModuleEffect","StakingRouterETHDeposited"] := by decide +kernel
example : late.locatorAttempts.length = 1 ∧ late.attempts.length = 2 := by decide +kernel

theorem late_outcome : late.outcome = .error (.bubbled [0xde,0xad]) := by decide +kernel

theorem public_late_restores : late.world = before := by
  have h : late = ⟨.error (.bubbled [0xde,0xad]),late.world,late.attempts,late.locatorAttempts⟩ := by
    have ho := late_outcome
    cases he : late with
    | mk outcome world attempts staticTrace => simp only [he] at ho; subst outcome; rfl
  exact actual_dsm_call_failure_restores _ _ _ _ _ _ _ _ _ _ _ _ _ _ h

#print axioms LidoSRv3.Audit.Source.DepositDsmCall.lookup_origin
#print axioms actual_dsm_call_registered_module_suffix
#print axioms actual_dsm_call_failure_restores
#print axioms public_positive
#print axioms public_rejection_restores
#print axioms public_late_restores
end LidoSRv3.Tests.DepositDsmCall
