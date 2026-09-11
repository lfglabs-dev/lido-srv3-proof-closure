import LidoSRv3.Audit.Guarantees.PTopupCredentialCalls
import LidoSRv3.Tests.TopupModuleMemoryRegression
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupCredentialCall
open Audit.Source TrioReserve1 Live TopupCredentialCall
open TopupBatchConsumerRegression TopupBatchRootCallsRegression
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

def credentials : Word := word (2*2^248+12345)
def raw : Bytes := encode 32 credentials.val
/-- Only the exact gateway/router/moduleId request is admitted. -/
def getter : StaticCall.External := fun req _ =>
  if req = request (address 3) (address 2) (word 7) then .success raw else .rejected [0xba]

def batchWith (get : StaticCall.External) (cursor buffer : Word) :=
  TopupCredentialCall.run get cursor buffer mapHash twoModule reject env ctx
    (address 8) (word 7) [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1))
def batch := batchWith getter (word 128) (word 128)

theorem request_bytes : (request (address 3) (address 2) (word 7)).payload =
    [0xf8,0x5c,0x6c,0xeb] ++ List.replicate 31 0 ++ [7] := by decide +kernel

theorem decoded_first_word : decodeCredentials (word 128) raw = .ok (credentials,word 160) := by decide +kernel

theorem trailing_ignored : decodeCredentials (word 129) (raw ++ [0xff,0x77]) = .ok (credentials,word 161) := by decide +kernel

theorem short_rejected : decodeCredentials (word 128) (List.replicate 31 0) = .error .empty := by decide +kernel

theorem allocation_before_short : decodeCredentials (word (2^64)) [] = .error (.reason "Panic(0x41)") := by decide +kernel

theorem allocation_boundary : decodeCredentials (word (2^64-32)) raw = .error (.reason "Panic(0x41)") := by decide +kernel

theorem exact_getter : lookup getter (address 3) (address 2) (word 7) (word 128) env.before =
    ⟨.ok (credentials,word 160),[⟨request (address 3) (address 2) (word 7),true,true,raw,1⟩]⟩ := by decide +kernel

theorem wrong_id : (lookup getter (address 3) (address 2) (word 8) (word 128) env.before).outcome =
    .error (.bubbled [0xba]) := by decide +kernel

theorem wrong_caller : (lookup getter (address 4) (address 2) (word 7) (word 128) env.before).outcome =
    .error (.bubbled [0xba]) := by decide +kernel

def noCode : World := {env.before with core := {env.before.core with codeSize := fun _ => word 0}}
theorem ordinary_no_code_attempt : lookup getter (address 3) (address 2) (word 7) (word 128) noCode =
    ⟨.error .empty,[⟨request (address 3) (address 2) (word 7),true,true,[],1⟩]⟩ := by decide +kernel

theorem full_batch_success : batch.outcome = .ok () := by decide +kernel

theorem actual_word_overwrites_supplied : env.credentials = 0 ∧ credentials.val ≠ 0 ∧
    (resolved env credentials).credentials = BitVec.ofNat 256 (2*2^248+12345) := by decide +kernel

theorem full_batch_ordered_observations :
    batch.observations.map (fun o => match o with | .inl a => (a.request.caller,a.request.target,true) | .inr a => (a.request.caller,a.request.target,false)) =
      [(address 3,address 2,true),(address 3,SszRootCall.target,true),(address 3,SszRootCall.target,true),(address 2,address 40,false)] := by decide +kernel

theorem wrong_prefix_before_loop :
    (batchWith (fun _ _ => .success (encode 32 (1*2^248))) (word 128) (word 128)).outcome = .error .wrongWithdrawalCredentials ∧
    (batchWith (fun _ _ => .success (encode 32 (1*2^248))) (word 128) (word 128)).rootAttempts = [] ∧
    (batchWith (fun _ _ => .success (encode 32 (1*2^248))) (word 128) (word 128)).moduleAttempts = [] := by
  exact ⟨by decide +kernel,rfl,rfl⟩

theorem lookup_failure_before_loop :
    (batchWith (fun _ _ => .rejected [0xfa]) (word (2^64)) (word 128)).outcome = .error (.lookup (.bubbled [0xfa])) ∧
    (batchWith (fun _ _ => .rejected [0xfa]) (word (2^64)) (word 128)).rootAttempts = [] := by
  exact ⟨by decide +kernel,rfl⟩

theorem lengths_before_lookup :
    (TopupCredentialCall.run getter (word (2^64)) (word 128) mapHash twoModule reject env ctx
      (address 8) (word 7) [] [] [] (word 0)).outcome = .error (.lengths .wrongArrayLength) ∧
    (TopupCredentialCall.run getter (word (2^64)) (word 128) mapHash twoModule reject env ctx
      (address 8) (word 7) [] [] [] (word 0)).credentialAttempts = [] := by
  exact ⟨by decide +kernel,rfl⟩

theorem late_failure_keeps_calls_restores :
    (batchWith getter (word 128) (word (2^64-160))).outcome = .error (.batch (.module (.reason "Panic(0x41)"))) ∧
    (batchWith getter (word 128) (word (2^64-160))).world = env.before ∧
    (batchWith getter (word 128) (word (2^64-160))).credentialAttempts.length = 1 ∧
    (batchWith getter (word 128) (word (2^64-160))).rootAttempts.length = 2 ∧
    ((batchWith getter (word 128) (word (2^64-160))).moduleAttempts.head?).map (fun a => a.accepted) = some true := by
  exact ⟨by decide +kernel,rfl,by decide +kernel,by decide +kernel,by decide +kernel⟩

def public_consumer := Audit.Guarantees.PTopupCredentialCalls.actual_credential_root_module_memory_effects
  getter (word 128) (word 128) mapHash twoModule reject env ctx (address 8) (word 7)
  [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1)) full_batch_success

#print axioms full_batch_success
#print axioms late_failure_keeps_calls_restores
#print axioms public_consumer
end LidoSRv3.Tests.TopupCredentialCall
