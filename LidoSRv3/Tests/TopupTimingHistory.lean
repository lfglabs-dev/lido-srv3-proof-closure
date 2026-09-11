import LidoSRv3.Audit.Guarantees.PTopupTimingHistory
import LidoSRv3.Tests.TopupPhysicalCredentialGetter
set_option autoImplicit false
namespace LidoSRv3.Tests.TopupTimingHistory
open Audit.Source TrioReserve1 Live TopupGatewayWitnessBatch
open TopupBatchConsumerRegression TopupBatchRootCallsRegression
open TopupTimingHistory
set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

def base := TopupPhysicalCredentialGetter.environment

def timed (lb lt distance age bn ts child : Nat) : TopupGatewayRootCalls.Environment :=
  let core := {base.before.core with blockNumber := word bn, blockTimestamp := word ts}
  let core := core.writeContractSlot 3 TopupGatewayConfigWords.gatewayRoot
    (word (2+lt*2^64+lb*2^96+distance*2^128+age*2^144+64*2^160))
  {base with before := {base.before with core := core}, beacon := {base.beacon with childBlockTimestamp := BitVec.ofNat 64 child}}

def post : World :=
  let core := {changed.core with blockNumber := word (2^32+9), blockTimestamp := word (2^32+7)}
  let core := core.writeContractSlot 3 TopupGatewayConfigWords.gatewayRoot
    (word (77+88*2^64+99*2^96+12345*2^128+2^255))
  {changed with core := core}

def module (zeroLimits : Bool) (amount : Word) : External := fun req _ =>
  let input := if zeroLimits then {twoInput with limits := [word 0,word 0]} else twoInput
  if req.caller = address 2 ∧ req.target = address 40 ∧ req.value = word 0 ∧ req.payload = TopupModuleCall.payload input then
    .success (TopupModuleCall.encodeReturn [amount,word 0]) post
  else .rejected [0xba]

def zeroRows : List Row := [row,secondRow].map (fun r => {r with witness := {r.witness with slashed := true}})

def batch (e : TopupGatewayRootCalls.Environment) (zeroLimits : Bool := false) (amount : Word := word 0) :=
  TopupTimingHistory.run (word 128) (word 128) TopupPhysicalCredentialGetter.hash
    (module zeroLimits amount) reject e ctx (address 8) (word 7) [word 42,word 43] [word 3,word 4]
    (if zeroLimits then zeroRows else [row,secondRow]) (word (2^256-1))

theorem last_block_zero_shortcircuits : gates (timed 0 0 65535 0 0 1 1) = .ok () := by decide +kernel

theorem checked_subtraction_before_age : gates (timed 9 0 0 1 8 (2^256-1) (2^64-1)) = .error .arithmetic := by decide +kernel

theorem distance_before_root_age : gates (timed 9 0 2 1 10 (2^256-1) (2^64-1)) = .error .minBlockDistanceNotMet := by decide +kernel

theorem distance_equality_passes : gates (timed 9 0 2 0 11 1 1) = .ok () := by decide +kernel

theorem uint64_age_overflow : gates (timed 0 0 0 1 0 0 (2^64-1)) = .error .arithmetic := by decide +kernel

theorem uint64_max_age_succeeds : gates (timed 0 0 0 1 0 (2^64-1) (2^64-2)) = .ok () := by decide +kernel

theorem age_before_last_timestamp : gates (timed 0 1 0 0 0 2 1) = .error .rootIsTooOld := by decide +kernel

theorem timestamp_equality_rejected : gates (timed 0 1 0 0 0 1 1) = .error .rootPrecedesLastTopUp := by decide +kernel

theorem future_root_not_rejected : gates (timed 0 0 0 0 0 1 99) = .ok () := by decide +kernel

theorem lengths_before_timing :
    (TopupTimingHistory.run (word 128) (word 128) TopupPhysicalCredentialGetter.hash
      reject reject (timed 9 0 0 1 8 0 (2^64-1)) ctx (address 8) (word 7) [] [] [] (word 0)).outcome =
      .error (.lengths .wrongArrayLength) := by decide +kernel

theorem config_before_timing :
    (TopupTimingHistory.run (word 128) (word 128) TopupPhysicalCredentialGetter.hash
      reject reject (timed 9 0 0 1 8 0 (2^64-1)) ctx (address 8) (word 7)
      [word 1,word 2,word 3] [word 1,word 2,word 3] [row,row,row] (word 0)).outcome =
      .error (.lengths .maxValidatorsExceeded) := by decide +kernel

theorem timing_before_lookup :
    (batch (timed 9 0 2 0 10 0 1)).outcome = .error (.timing .minBlockDistanceNotMet) ∧
    (batch (timed 9 0 2 0 10 0 1)).credentialAttempts = [] ∧
    (batch (timed 9 0 2 0 10 0 1)).rootAttempts = [] ∧
    (batch (timed 9 0 2 0 10 0 1)).moduleAttempts = [] := by decide +kernel

theorem full_success : (batch base).outcome = .ok () := by decide +kernel

theorem positive_limits_zero_allocations_write :
    (batch base).stage.map (fun s => s.produced.map (fun p => p.2.total)) = some (some 63000000000) ∧
    (batch base).world.logs.map (·.name) = ["ActualModuleEffect","StakingRouterETHTopUp","LastTopUpChanged"] ∧
    (batch base).world.logs.getLast?.map (·.values) = some [word (2^32+7)] ∧
    lastTimestamp (address 3) (batch base).world = 7 ∧
    lastBlock (address 3) (batch base).world = 9 ∧
    (stored (address 3) (batch base).world).val % 2^64 = 77 ∧
    (stored (address 3) (batch base).world).val / 2^128 = 12345+2^127 := by decide +kernel

theorem nonempty_zero_limits_skip_history :
    (batch base true).outcome = .ok () ∧
    (batch base true).stage.map (fun s => s.produced.map (fun p => p.2.total)) = some (some 0) ∧
    (batch base true).rootAttempts.length = 2 ∧
    (batch base true).moduleAttempts.length = 1 ∧
    (batch base true).world.logs.map (·.name) = ["ActualModuleEffect","StakingRouterETHTopUp"] ∧
    lastTimestamp (address 3) (batch base true).world = 88 ∧
    lastBlock (address 3) (batch base true).world = 99 := by decide +kernel

theorem late_failure_keeps_attempts_restores_history :
    (batch base false (word 21000000000)).outcome = .error (.phase (.batch (.module (.reason "ModuleReturnExceedTarget")))) ∧
    (batch base false (word 21000000000)).credentialAttempts.length = 1 ∧
    (batch base false (word 21000000000)).rootAttempts.length = 2 ∧
    (batch base false (word 21000000000)).moduleAttempts.length = 1 ∧
    (batch base false (word 21000000000)).world.logs = [] ∧
    (stored (address 3) (batch base false (word 21000000000)).world) = stored (address 3) base.before := by decide +kernel

def public_consumer := Audit.Guarantees.PTopupTimingHistory.actual_timing_credential_root_module_memory_history
  (word 128) (word 128) TopupPhysicalCredentialGetter.hash (module false (word 0)) reject base ctx (address 8) (word 7)
  [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1)) full_success

theorem public_rollback :
    (batch base false (word 21000000000)).world = base.before :=
  Audit.Guarantees.PTopupTimingHistory.actual_timing_credential_root_module_failure_restores
    (word 128) (word 128) TopupPhysicalCredentialGetter.hash (module false (word 21000000000)) reject base ctx (address 8) (word 7)
    [word 42,word 43] [word 3,word 4] [row,secondRow] (word (2^256-1)) _ late_failure_keeps_attempts_restores_history.1

#print axioms full_success
#print axioms public_consumer
#print axioms public_rollback
end LidoSRv3.Tests.TopupTimingHistory
