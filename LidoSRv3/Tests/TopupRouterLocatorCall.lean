import LidoSRv3.Audit.Guarantees.PTopupRouterLocatorCall
import LidoSRv3.Tests.TopupTimingHistory
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupRouterLocatorCall
open Audit.Source TrioReserve1 Live TopupGatewayWitnessBatch
open TopupBatchConsumerRegression TopupBatchRootCallsRegression
open TopupRouterLocatorCall
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

/-- Deliberately wrong prior router: successful execution must consume the reply. -/
def supplied : Context := {ctx with sender := address 999}
def locator := address 9

def getter (raw : Bytes) : StaticCall.External := fun req _ =>
  if req.caller = address 3 ∧ req.target = locator ∧ req.value = word 0 ∧ req.payload = encode 4 0xef6c064c then
    .success raw else .rejected [0xba]
def good := getter (encode 32 2)
def rejected : StaticCall.External := fun _ _ => .rejected [0xde,0xad]
def forbidden : StaticCall.External := fun _ _ => .forbiddenStateChange

def batch (e : TopupGatewayRootCalls.Environment := TopupTimingHistory.base)
    (l : StaticCall.External := good) (cursor buffer : Word := word 128)
    (zeroLimits : Bool := false) (amount : Word := word 0) :=
  TopupRouterLocatorCall.run l locator cursor buffer TopupPhysicalCredentialGetter.hash
    (TopupTimingHistory.module zeroLimits amount) reject e supplied (address 8) (word 7)
    [word 42,word 43] [word 3,word 4]
    (if zeroLimits then TopupTimingHistory.zeroRows else [row,secondRow]) (word (2^256-1))

theorem request_exact : request (address 3) locator =
    ⟨address 3,address 9,word 0,[0xef,0x6c,0x06,0x4c]⟩ := by decide +kernel

theorem canonical_zero_and_max :
    decodeRouter (word 128) (encode 32 0) = .ok (address 0,word 160) ∧
    decodeRouter (word 128) (encode 32 (2^160-1)) = .ok (address (2^160-1),word 160) := by decide +kernel

theorem canonical_high_rejected : decodeRouter (word 128) (encode 32 (2^160+2)) = .error .empty := by decide +kernel

theorem short_rejected : decodeRouter (word 128) (List.replicate 31 0) = .error .empty := by decide +kernel

theorem trailing_ignored : decodeRouter (word 128) (encode 32 2 ++ [0xff,0x99]) = .ok (address 2,word 160) := by decide +kernel

theorem allocation_before_head_and_canonical :
    decodeRouter (word (2^64-32)) (List.replicate 31 0) = .error (.reason "Panic(0x41)") ∧
    decodeRouter (word (2^64-32)) (encode 32 (2^160)) = .error (.reason "Panic(0x41)") := by decide +kernel

theorem lengths_before_timing_lookup :
    (TopupRouterLocatorCall.run rejected locator (word 128) (word 128) TopupPhysicalCredentialGetter.hash
      reject reject (TopupTimingHistory.timed 9 0 0 1 8 0 (2^64-1)) supplied (address 8) (word 7) [] [] [] (word 0)).outcome =
      .error (.lengths .wrongArrayLength) := by decide +kernel

theorem count_before_timing_lookup :
    (TopupRouterLocatorCall.run rejected locator (word 128) (word 128) TopupPhysicalCredentialGetter.hash
      reject reject (TopupTimingHistory.timed 9 0 0 1 8 0 (2^64-1)) supplied (address 8) (word 7)
      [word 1,word 2,word 3] [word 1,word 2,word 3] [row,row,row] (word 0)).outcome =
      .error (.lengths .maxValidatorsExceeded) := by decide +kernel

theorem timing_before_locator :
    (batch (TopupTimingHistory.timed 9 0 2 0 10 0 1) rejected).outcome = .error (.timing .minBlockDistanceNotMet) ∧
    (batch (TopupTimingHistory.timed 9 0 2 0 10 0 1) rejected).observations = [] := by decide +kernel

theorem lookup_bubbles_before_allocation :
    (batch TopupTimingHistory.base rejected (word (2^64))).outcome = .error (.lookup (.bubbled [0xde,0xad])) ∧
    (batch TopupTimingHistory.base rejected (word (2^64))).locatorAttempts.length = 1 ∧
    (batch TopupTimingHistory.base rejected (word (2^64))).suffix.isNone = true := by decide +kernel

theorem forbidden_static_state_change :
    (batch TopupTimingHistory.base forbidden).outcome = .error (.lookup (.bubbled [])) := by decide +kernel

def noCode : TopupGatewayRootCalls.Environment :=
  let e := TopupTimingHistory.base
  {e with before := {e.before with core := {e.before.core with codeSize := fun a => if a = 9 then word 0 else e.before.core.codeSize a}}}

theorem ordinary_nocode_empty_then_decoder :
    (batch noCode).outcome = .error (.lookup .empty) ∧
    (batch noCode).locatorAttempts = [⟨request (address 3) locator,true,true,[],1⟩] := by decide +kernel

theorem zero_router_reaches_physical_registration :
    (batch TopupTimingHistory.base (getter (encode 32 0))).outcome =
      .error (.phase (.phase (.lookup (.bubbled TopupPhysicalCredentialGetter.unregistered)))) ∧
    (batch TopupTimingHistory.base (getter (encode 32 0))).suffix.map (·.credentialAttempts.length) = some 1 := by decide +kernel

theorem full_success_overwrites_wrong_router : (batch).outcome = .ok () := by decide +kernel

theorem full_transcript_and_cursor :
    (batch).locatorAttempts = [⟨request (address 3) locator,true,true,encode 32 2,1⟩] ∧
    (batch).suffix.map (·.credentialAttempts) = some [⟨TopupCredentialCall.request (address 3) (address 2) (word 7),true,true,encode 32 TopupPhysicalCredentialGetter.wc.val,1⟩] ∧
    (batch).suffix.map (·.rootAttempts.length) = some 2 ∧
    (batch).suffix.map (·.moduleAttempts.length) = some 1 ∧
    (batch).observations.length = 5 ∧
    TopupCredentialCall.decodeCredentials (word 160) (encode 32 TopupPhysicalCredentialGetter.wc.val) = .ok (TopupPhysicalCredentialGetter.wc,word 192) := by decide +kernel

theorem second_allocation_consumes_next :
    (batch TopupTimingHistory.base good (word (2^64-64))).outcome =
      .error (.phase (.phase (.lookup (.reason "Panic(0x41)")))) ∧
    (batch TopupTimingHistory.base good (word (2^64-64))).locatorAttempts.length = 1 ∧
    (batch TopupTimingHistory.base good (word (2^64-64))).suffix.map (·.credentialAttempts.length) = some 1 := by decide +kernel

theorem positive_limits_zero_allocations_history :
    (batch).suffix.bind (fun s => s.stage.map (fun t => t.produced.map (fun p => p.2.total))) = some (some 63000000000) ∧
    (batch).world.logs.map (·.name) = ["ActualModuleEffect","StakingRouterETHTopUp","LastTopUpChanged"] ∧
    TopupTimingHistory.lastTimestamp (address 3) (batch).world = 7 ∧
    (TopupTimingHistory.stored (address 3) (batch).world).val / 2^128 = 12345+2^127 := by decide +kernel

theorem nonempty_zero_limits_no_history :
    (batch TopupTimingHistory.base good (word 128) (word 128) true).outcome = .ok () ∧
    (batch TopupTimingHistory.base good (word 128) (word 128) true).world.logs.map (·.name) =
      ["ActualModuleEffect","StakingRouterETHTopUp"] := by decide +kernel

theorem late_failure_journal :
    (batch TopupTimingHistory.base good (word 128) (word 128) false (word 21000000000)).outcome =
      .error (.phase (.phase (.batch (.module (.reason "ModuleReturnExceedTarget"))))) ∧
    (batch TopupTimingHistory.base good (word 128) (word 128) false (word 21000000000)).observations.length = 5 ∧
    (batch TopupTimingHistory.base good (word 128) (word 128) false (word 21000000000)).world.logs = [] := by decide +kernel

def public_consumer := Audit.Guarantees.PTopupRouterLocatorCall.actual_locator_timing_credential_root_module_memory_history
  good locator (word 128) (word 128) TopupPhysicalCredentialGetter.hash (TopupTimingHistory.module false (word 0)) reject
  TopupTimingHistory.base supplied (address 8) (word 7) [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1)) full_success_overwrites_wrong_router

theorem public_rollback :
    (batch TopupTimingHistory.base good (word 128) (word 128) false (word 21000000000)).world = TopupTimingHistory.base.before :=
  Audit.Guarantees.PTopupRouterLocatorCall.actual_locator_timing_credential_root_module_failure_restores
    good locator (word 128) (word 128) TopupPhysicalCredentialGetter.hash (TopupTimingHistory.module false (word 21000000000)) reject
    TopupTimingHistory.base supplied (address 8) (word 7) [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1)) _ late_failure_journal.1

#print axioms public_consumer
#print axioms public_rollback
end LidoSRv3.Tests.TopupRouterLocatorCall
