import LidoSRv3.Audit.Guarantees.PDeposit1AdmissionErrors
import LidoSRv3.Tests.DepositDsmCall
namespace LidoSRv3.Tests.DepositAdmissionErrorsRegression
set_option autoImplicit false
set_option maxRecDepth 16384
set_option maxHeartbeats 8000000
open LidoSRv3.Audit.Source TrioReserve1 audit.trio.deposit
open audit.trio.deposit.Tests.Verity.ModulePhysicalMetadataTest
open LidoSRv3.Audit.Guarantees.PDeposit1
open LidoSRv3.Audit.Source.DepositAdmissionErrors
def run (status kind position : Nat) (q : StaticCall.External := DepositDsmCall.query) :=
  LidoSRv3.Audit.Source.DepositAdmissionErrors.execute q DepositDsmCall.locator DepositDsmCall.cursor
    DepositPhysicalAdmission.separatedHash reject reject DepositDsmCall.supplied liveCtx input
    (DepositPhysicalAdmission.configWorld status kind position)
theorem dsm_before_all_guards : (run 255 255 0 DepositDsmCall.rejectQuery).result.outcome = .error (.bubbled [0xde,0xad]) ∧
    (run 255 255 0 DepositDsmCall.rejectQuery).localFailure = none := by decide +kernel
theorem authorization_before_membership_and_enum :
    (run 255 255 0 (DepositDsmCall.answer (Live.encode 32 999))).result.outcome = .error (.bubbled [0xea,0x8e,0x4e,0xb5]) := by decide +kernel
theorem membership_before_enum : (run 255 255 0).result.outcome = .error (.bubbled [0xd4,0x1d,0x62,0x82]) := by decide +kernel
theorem enum_before_inactive : (run 3 255 1).result.outcome = .error (.bubbled (Live.encode 4 0x4e487b71 ++ Live.encode 32 0x21)) := by decide +kernel
theorem inactive_exact : (run 2 255 1).result.outcome = .error (.bubbled [0x64,0x5c,0xc9,0xf6]) := by decide +kernel
theorem active_allows_type255 : (run 0 255 1).result.outcome = .error (.bubbled [0xde,0xad]) ∧ (run 0 255 1).localFailure = none := by decide +kernel
theorem all_status_bytes : (List.range 256).all (fun status =>
    (run status 255 1).result.outcome ==
      if status = 0 then .error (.bubbled [0xde,0xad])
      else if status < 3 then .error (.bubbled (errorBytes .inactive))
      else .error (.bubbled (errorBytes .invalidEnum))) = true := by decide +kernel
theorem short_dsm_before_auth : (run 255 255 0 (DepositDsmCall.answer (List.replicate 31 0))).result.outcome = .error .empty := by decide +kernel
theorem local_no_module_attempt : (run 255 255 0).result.attempts = [] ∧ (run 255 255 0).result.locatorAttempts.length = 1 := by decide +kernel
theorem lengths : (errorBytes .unauthorized).length = 4 ∧ (errorBytes .unregistered).length = 4 ∧
    (errorBytes .invalidEnum).length = 36 ∧ (errorBytes .inactive).length = 4 := by decide +kernel

theorem downstream_arithmetic_not_remapped :
    (LidoSRv3.Audit.Source.DepositAdmissionErrors.execute DepositDsmCall.query DepositDsmCall.locator DepositDsmCall.cursor hash
      reject reject DepositDsmCall.supplied liveCtx {input with maxEB := sw 0} DepositDsmCall.before).result.outcome =
      .error (.reason "Panic(0x12)") := by decide +kernel

def positive := LidoSRv3.Audit.Source.DepositAdmissionErrors.execute DepositDsmCall.query DepositDsmCall.locator DepositDsmCall.cursor hash
  positiveModule withdrawalExternal DepositDsmCall.supplied liveCtx input DepositDsmCall.before
theorem positive_transport : positive = ⟨DepositDsmCall.positive,none⟩ :=
  execute_of_admitted_lookup _ _ _ _ _ _ _ _ _ _ ⟨7,by decide⟩ [⟨LidoSRv3.Audit.Source.DepositDsmCall.request liveCtx.sender DepositDsmCall.locator,true,true,Live.encode 32 7,1⟩] (by decide +kernel) (by decide +kernel)
theorem positive_execution : positive.result.outcome = .ok () := by
  rw [positive_transport]; exact DepositDsmCall.positive_execution
theorem public_nonempty : LidoSRv3.Audit.Source.DepositDsmCall.Effects DepositDsmCall.query DepositDsmCall.locator DepositDsmCall.cursor hash
    positiveModule withdrawalExternal DepositDsmCall.supplied liveCtx input DepositDsmCall.before
    positive.result.world positive.result.attempts positive.result.locatorAttempts :=
  ((actual_dsm_call_admission_bytes_suffix _ _ _ _ _ _ _ _ _ _).1 positive_execution).2.2

def late := LidoSRv3.Audit.Source.DepositAdmissionErrors.execute DepositDsmCall.query DepositDsmCall.locator DepositDsmCall.cursor hash
  positiveModule reject DepositDsmCall.supplied liveCtx input DepositDsmCall.before
theorem late_transport : late = ⟨DepositDsmCall.late,none⟩ :=
  execute_of_admitted_lookup _ _ _ _ _ _ _ _ _ _ ⟨7,by decide⟩ [⟨LidoSRv3.Audit.Source.DepositDsmCall.request liveCtx.sender DepositDsmCall.locator,true,true,Live.encode 32 7,1⟩] (by decide +kernel) (by decide +kernel)
theorem late_outcome : late.result.outcome = .error (.bubbled [0xde,0xad]) := by
  rw [late_transport]; exact DepositDsmCall.late_outcome
theorem public_late_original : late.result.world = DepositDsmCall.before :=
  (actual_dsm_call_admission_bytes_suffix _ _ _ _ _ _ _ _ _ _).2.2 _ late_outcome

theorem public_local_origin : LocalRejection DepositDsmCall.query DepositDsmCall.locator DepositDsmCall.cursor
    DepositPhysicalAdmission.separatedHash DepositDsmCall.supplied liveCtx input
    (DepositPhysicalAdmission.configWorld 255 255 0) (run 255 255 0) ⟨7,by decide⟩ .unregistered :=
  (actual_dsm_call_admission_bytes_suffix _ _ _ _ _ _ _ _ _ _).2.1 _ _ (by decide +kernel)

#print axioms public_nonempty
#print axioms public_late_original
#print axioms public_local_origin
end LidoSRv3.Tests.DepositAdmissionErrorsRegression
