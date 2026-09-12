import LidoSRv3.Audit.Guarantees.PTopupRouterAdmissionCall
import LidoSRv3.Tests.TopupRouterLocatorCall
set_option autoImplicit false
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000
namespace LidoSRv3.Tests.TopupRouterAdmissionCallRegression
open Audit.Source TrioReserve1 Live TopupGatewayWitnessBatch
open TopupBatchConsumerRegression
open TopupRouterAdmissionCallGates

def fixtureWorld : World :=
  let old := TopupPhysicalCredentialGetter.before
  let core := {old.core with blockTimestamp := word 1}
  let core := {core with storageWords := fun key => match key with
    | .contractSlot 3 _ => word 1
    | _ => old.core.storageWords key}
  {old with core := core}
def environment : TopupGatewayRootCalls.Environment :=
  {TopupPhysicalCredentialGetter.environment with before := fixtureWorld}

def auth (raw : Bytes) : StaticCall.External := fun req _ =>
  if req = request (address 2) (address 19) authSelector then .success raw else .rejected [0xba]
def permission (raw : Bytes) : StaticCall.External := fun req _ =>
  if req = request (address 2) (address 1) canDepositSelector then .success raw else .rejected [0xcb]
def g : Environment := ⟨address 19,auth (encode 32 3),permission (encode 32 1),word 128,word 160⟩
def denied : StaticCall.External := fun _ _ => .rejected [0xde,0xad]
def forbidden : StaticCall.External := fun _ _ => .forbiddenStateChange

def input (target : Nat) : TopupModuleCall.Input :=
  ⟨word 7,word target,[List.replicate 48 0],[word 42],[word 3],[word 0]⟩
def callee (target amount : Nat) : External := fun req _ =>
  if req.caller = address 2 ∧ req.target = address 40 ∧ req.value = word 0 ∧ req.payload = TopupModuleCall.payload (input target)
  then .success (TopupModuleCall.encodeReturn [word amount]) TopupTimingHistory.post
  else .rejected [0xba]
def args (target amount : Nat) : TopupRouterAdmissionCall.Input :=
  ⟨address 11,TopupRouterLocatorCall.good,address 9,word 128,word 128,
    TopupPhysicalCredentialGetter.hash,callee target amount,reject,environment,
    TopupRouterLocatorCall.supplied,address 8,word 7,[word 42],[word 3],[row],word target⟩
def batch (target amount : Nat := 0) := TopupRouterAdmissionCall.run g (args target amount)

theorem exact_static_requests :
    request (address 2) (address 19) authSelector = ⟨address 2,address 19,word 0,[0x64,0x48,0x62,0xde]⟩ ∧
    request (address 2) (address 1) canDepositSelector = ⟨address 2,address 1,word 0,[0xe7,0x8a,0x58,0x75]⟩ := by decide +kernel

theorem bool_true_false : decodeBool (word 128) (encode 32 0) = .ok (false,word 160) ∧
    decodeBool (word 128) (encode 32 1) = .ok (true,word 160) := by decide +kernel
theorem bool_noncanonical : decodeBool (word 128) (encode 32 2) = .error .empty := by decide +kernel
theorem bool_short : decodeBool (word 128) (List.replicate 31 0) = .error .empty := by decide +kernel
theorem bool_trailing : decodeBool (word 128) (encode 32 1 ++ [2,3]) = .ok (true,word 160) := by decide +kernel
theorem bool_allocation_first : decodeBool (word (2^64-32)) (encode 32 2) = .error (.reason "Panic(0x41)") := by decide +kernel

theorem auth_bubble_before_inputs :
    (TopupRouterAdmissionCallGates.run {g with locatorCall := denied} TopupPhysicalCredentialGetter.hash
      (address 3) ctx {input 0 with keyIndices := []} fixtureWorld).outcome = .error (.bubbled [0xde,0xad]) := by decide +kernel
theorem auth_forbidden : (authLookup {g with locatorCall := forbidden} (address 2) fixtureWorld).outcome = .error (.bubbled []) := by decide +kernel
theorem auth_noncanonical : (authLookup {g with locatorCall := auth (encode 32 (2^160+3))} (address 2) fixtureWorld).outcome = .error .empty := by decide +kernel
theorem auth_wrong_caller :
    (TopupRouterAdmissionCallGates.run g TopupPhysicalCredentialGetter.hash (address 4) ctx (input 0) fixtureWorld).outcome = .error (.bubbled (encode 4 0xea8e4eb5)) := by decide +kernel

theorem inputs_empty_first : validateInputs {input 0 with keyIndices := []} = .error (.bubbled (encode 4 0xc4d88632)) := by decide +kernel
theorem inputs_lengths : validateInputs {input 0 with operatorIds := []} = .error (.bubbled (encode 4 0xfc235960)) := by decide +kernel
theorem inputs_pubkey : validateInputs {input 0 with pubkeys := [List.replicate 47 0]} = .error (.bubbled (encode 4 0x500585ad)) := by decide +kernel

theorem registration_before_enum : physical TopupPhysicalCredentialGetter.hash (address 2) (word 7)
    (TopupPhysicalCredentialGetter.altered 255 1 0) = .error (.bubbled (encode 4 0xd41d6282)) := by decide +kernel
theorem enum_before_active_type : physical TopupPhysicalCredentialGetter.hash (address 2) (word 7)
    (TopupPhysicalCredentialGetter.altered 255 1 1) = .error (.bubbled (encode 4 0x4e487b71 ++ encode 32 0x21)) := by decide +kernel
theorem active_before_type : physical TopupPhysicalCredentialGetter.hash (address 2) (word 7)
    (TopupPhysicalCredentialGetter.altered 1 1 1) = .error (.bubbled (encode 4 0x645cc9f6)) := by decide +kernel
theorem wrong_type : physical TopupPhysicalCredentialGetter.hash (address 2) (word 7)
    (TopupPhysicalCredentialGetter.altered 0 1 1) = .error (.bubbled (encode 4 0x2e5c948c)) := by decide +kernel

theorem positive_target_skips_canDeposit :
    (TopupRouterAdmissionCallGates.run {g with canDepositCall := denied} TopupPhysicalCredentialGetter.hash (address 3) ctx (input 1) fixtureWorld).outcome = .ok () ∧
    (TopupRouterAdmissionCallGates.run {g with canDepositCall := denied} TopupPhysicalCredentialGetter.hash (address 3) ctx (input 1) fixtureWorld).attempts.length = 1 := by decide +kernel
theorem zero_target_denied :
    (TopupRouterAdmissionCallGates.run {g with canDepositCall := permission (encode 32 0)} TopupPhysicalCredentialGetter.hash (address 3) ctx (input 0) fixtureWorld).outcome = .error (.bubbled (encode 4 0x5609c247)) := by decide +kernel
theorem zero_target_forbidden :
    (TopupRouterAdmissionCallGates.run {g with canDepositCall := forbidden} TopupPhysicalCredentialGetter.hash (address 3) ctx (input 0) fixtureWorld).outcome = .error (.bubbled []) := by decide +kernel

theorem complete_nonempty_success : (batch).outcome = .ok () := by decide +kernel
theorem complete_world_and_journal :
    (batch).admissionAttempts.length = 2 ∧
    (batch).world.logs.map (·.name) = ["ActualModuleEffect","StakingRouterETHTopUp"] ∧
    (batch).projection.bind (fun r => r.suffix.bind (fun s => s.suffix.map (fun t => (t.rootAttempts.length,t.moduleAttempts.length)))) = some (1,1) := by decide +kernel

theorem complete_positive_target : (batch 20000000000 0).outcome = .ok () ∧
    (batch 20000000000 0).admissionAttempts.length = 1 := by decide +kernel

theorem complete_zero_rejection_before_module :
    let r := TopupRouterAdmissionCall.run {g with canDepositCall := permission (encode 32 0)} (args 0 0)
    r.outcome = .error (.admission (.bubbled (encode 4 0x5609c247))) ∧
    r.ready.map (·.rootAttempts.length) = some 1 ∧ r.projection.isNone = true ∧
    r.admissionAttempts.length = 2 ∧ r.world.logs = [] := by decide +kernel


def public_consumer := Audit.Guarantees.PTopupRouterAdmissionCall.actual_router_admission_complete_prior g (args 0 0) complete_nonempty_success

theorem complete_late_failure : (batch 0 1000000000).outcome =
    .error (.prior (.phase (.phase (.phase (.batch (.module (.reason "AllocationExceedsLimit"))))))) ∧
    (batch 0 1000000000).admissionAttempts.length = 2 ∧
    (batch 0 1000000000).world.logs = [] := by decide +kernel

theorem public_rollback : (batch 0 1000000000).world = fixtureWorld :=
  Audit.Guarantees.PTopupRouterAdmissionCall.actual_gateway_entry_failure_restores g (args 0 1000000000) _ complete_late_failure.1

#print axioms public_consumer
#print axioms public_rollback
end LidoSRv3.Tests.TopupRouterAdmissionCallRegression
