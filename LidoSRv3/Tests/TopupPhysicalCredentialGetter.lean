import LidoSRv3.Audit.Guarantees.PTopupPhysicalCredentialGetter
import LidoSRv3.Tests.TopupCredentialCall
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupPhysicalCredentialGetter
open Audit.Source TrioReserve1 Live
open TopupBatchConsumerRegression TopupBatchRootCallsRegression
open TopupPhysicalCredentialGetter
deriving instance DecidableEq for StaticCall.Reply
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

def hash : TopupRouterCredentials.Keccak := fun data =>
  if data.drop 32 = encode 32 (TopupRouterCredentials.routerRoot+2) then word (1000+decode (data.take 32))
  else mapHash data

def baseRaw : Word := word (1*2^248+2^200+12345)
def before : World :=
  let core := env.before.core.writeContractSlot 2 1007 (word 1)
  let core := core.writeContractSlot 2 (TopupRouterCredentials.routerRoot+4) baseRaw
  {env.before with core}
def environment := {env with before := before}
def wc : Word := word (2*2^248+2^200+12345)
def batch (cursor buffer : Word) := TopupPhysicalCredentialGetter.run cursor buffer hash twoModule reject environment ctx
  (address 8) (word 7) [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1))

theorem physical_slots :
    DepositPhysicalAdmission.membershipSlot hash (asId (word 7)) = 1007 ∧
    TopupRouterCredentials.moduleSlot hash (word 7) = 90 ∧
    (selected hash (address 2) (word 7) before) = wc := by decide +kernel

theorem canonical_actual_dispatch : dispatch hash (TopupCredentialCall.request (address 3) (address 2) (word 7)) before =
    .success (encode 32 wc.val) := by decide +kernel

theorem trailing_calldata : dispatch hash
    {TopupCredentialCall.request (address 3) (address 2) (word 7) with payload :=
      (TopupCredentialCall.request (address 3) (address 2) (word 7)).payload ++ [0xff]} before =
    .success (encode 32 wc.val) := by decide +kernel

theorem unknown_module : dispatch hash (TopupCredentialCall.request (address 3) (address 2) (word 8)) before =
    .rejected unregistered := by decide +kernel

theorem target_qualifies_storage : dispatch hash (TopupCredentialCall.request (address 3) (address 4) (word 7)) before =
    .rejected unregistered := by decide +kernel

theorem arbitrary_caller_allowed : dispatch hash (TopupCredentialCall.request (address 999) (address 2) (word 7)) before =
    .success (encode 32 wc.val) := by decide +kernel

def altered (state typ position : Nat) : World :=
  let core := before.core.writeContractSlot 2 90 (word (40+state*2^224+typ*2^232))
  let core := core.writeContractSlot 2 1007 (word position)
  {before with core}

theorem no_active_or_enum_guard : body hash (address 2) (word 7) (altered 255 2 1) =
    .success (encode 32 wc.val) := by decide +kernel

theorem all_type_bytes_returned : body hash (address 2) (word 7) (altered 255 255 1) =
    .success (encode 32 (255*2^248+2^200+12345)) := by decide +kernel

theorem nonzero_position_only : body hash (address 2) (word 7) (altered 255 2 (2^256-1)) =
    .success (encode 32 wc.val) := by decide +kernel

theorem unregistered_before_config : body hash (address 2) (word 7) (altered 255 255 0) =
    .rejected unregistered := by decide +kernel

theorem short_head : dispatch hash ⟨address 3,address 2,word 0,
    encode 4 TopupCredentialCall.selector ++ List.replicate 31 0⟩ before = .rejected [] := by decide +kernel

theorem wrong_selector : dispatch hash ⟨address 3,address 2,word 0,
    encode 4 0 ++ encode 32 7⟩ before = .rejected [] := by decide +kernel

theorem full_success : (batch (word 128) (word 128)).outcome = .ok () := by decide +kernel

theorem full_trace : (batch (word 128) (word 128)).credentialAttempts =
    [⟨TopupCredentialCall.request (address 3) (address 2) (word 7),true,true,encode 32 wc.val,1⟩] ∧
    (batch (word 128) (word 128)).rootAttempts.length = 2 ∧
    (batch (word 128) (word 128)).moduleAttempts.length = 1 := by decide +kernel

theorem unregistered_bubbles_before_decoder :
    (TopupPhysicalCredentialGetter.run (word (2^64)) (word 128) hash twoModule reject
      {environment with before := altered 255 255 0} ctx (address 8) (word 7)
      [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1))).outcome =
      .error (.lookup (.bubbled unregistered)) := by decide +kernel

theorem type_not02_rejected_by_gateway :
    (TopupPhysicalCredentialGetter.run (word 128) (word 128) hash twoModule reject
      {environment with before := altered 255 1 1} ctx (address 8) (word 7)
      [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1))).outcome =
      .error .wrongWithdrawalCredentials := by decide +kernel

theorem late_failure : (batch (word 128) (word (2^64-160))).outcome =
    .error (.batch (.module (.reason "Panic(0x41)"))) ∧
    (batch (word 128) (word (2^64-160))).world = before ∧
    (batch (word 128) (word (2^64-160))).credentialAttempts.length = 1 ∧
    (batch (word 128) (word (2^64-160))).rootAttempts.length = 2 ∧
    ((batch (word 128) (word (2^64-160))).moduleAttempts.head?).map (fun a => a.accepted) = some true := by
  exact ⟨by decide +kernel,rfl,by decide +kernel,by decide +kernel,by decide +kernel⟩

def public_consumer := Audit.Guarantees.PTopupPhysicalCredentialGetter.actual_physical_credential_root_module_memory_effects
  (word 128) (word 128) hash twoModule reject environment ctx (address 8) (word 7)
  [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1)) full_success

#print axioms full_success
#print axioms late_failure
#print axioms public_consumer
end LidoSRv3.Tests.TopupPhysicalCredentialGetter
