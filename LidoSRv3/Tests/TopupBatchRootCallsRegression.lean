import LidoSRv3.Audit.Guarantees.PTopup2RootCalls
import LidoSRv3.Tests.TopupBatchConsumerRegression

namespace LidoSRv3.Tests.TopupBatchRootCallsRegression
open Audit.Source TrioReserve1 Live SszValidatorLeaf SszVerifierEntry SszWrapperIndex
open TopupGatewayWitnessBatch

set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

/-- Deliberately partial SHA interpreter: no total-success/width assumption. -/
def partialSha : Precompile := fun bytes =>
  if bytes.length = 64 then ⟨true,32,0⟩ else ⟨false,0,17⟩

def roots : StaticCall.External := fun req _ =>
  if req = SszRootCall.request (TopupBatchConsumerRegression.address 3) TopupBatchConsumerRegression.beacon.childBlockTimestamp then
    .success (List.replicate 32 0)
  else .rejected [0xba]

def env : TopupGatewayRootCalls.Environment :=
  ⟨partialSha,roots,(fun _ => 0),TopupBatchConsumerRegression.gi,
    TopupGatewayConfigWords.readConfig (TopupBatchConsumerRegression.address 3) TopupBatchConsumerRegression.before,
    TopupBatchConsumerRegression.beacon,⟨32,by decide⟩,0,TopupBatchConsumerRegression.address 3,TopupBatchConsumerRegression.before⟩

def runWith (allocation : Word) := TopupBatchRootCalls.run TopupBatchConsumerRegression.mapHash (TopupBatchConsumerRegression.moduleWith allocation)
  TopupBatchConsumerRegression.reject env TopupBatchConsumerRegression.ctx (TopupBatchConsumerRegression.address 8) (word 7) [word 42] [word 3] [TopupBatchConsumerRegression.row] (word (2^256-1))

theorem actual_batch_succeeds : (runWith (word 0)).outcome = .ok () := by decide +kernel

theorem actual_batch_has_joint_guarantee :
    TopupBatchRootCalls.Success TopupBatchConsumerRegression.mapHash (TopupBatchConsumerRegression.moduleWith (word 0)) TopupBatchConsumerRegression.reject env TopupBatchConsumerRegression.ctx
      (TopupBatchConsumerRegression.address 8) (word 7) [word 42] [word 3] [TopupBatchConsumerRegression.row] (word (2^256-1)) (runWith (word 0)) :=
  Audit.Guarantees.PTopup2.actual_root_module_batch_bound TopupBatchConsumerRegression.mapHash (TopupBatchConsumerRegression.moduleWith (word 0))
    TopupBatchConsumerRegression.reject env TopupBatchConsumerRegression.ctx (TopupBatchConsumerRegression.address 8) (word 7) [word 42] [word 3] [TopupBatchConsumerRegression.row]
    (word (2^256-1)) actual_batch_succeeds

theorem actual_requests_and_effects :
    (runWith (word 0)).rootAttempts.map (fun a => (a.request.caller,a.request.target,a.accepted)) =
      [(TopupBatchConsumerRegression.address 3,SszRootCall.target,true)] ∧
    (runWith (word 0)).moduleAttempts.map (fun a => (a.request.caller,a.request.target,a.accepted)) =
      [(TopupBatchConsumerRegression.address 2,TopupBatchConsumerRegression.address 40,true)] ∧
    (runWith (word 0)).world.balances (TopupBatchConsumerRegression.address 2) = 12 ∧
    (runWith (word 0)).world.logs.map (·.name) = ["ActualModuleEffect","StakingRouterETHTopUp"] ∧
    (partialSha []).success = false := by decide +kernel

theorem above_cap_rolls_back_keeps_both_attempts :
    (runWith (word 21000000000)).outcome = .error (.module (.reason "ModuleReturnExceedTarget")) ∧
    (runWith (word 21000000000)).world.balances (TopupBatchConsumerRegression.address 2) = 7 ∧
    (runWith (word 21000000000)).world.logs = [] ∧
    (runWith (word 21000000000)).rootAttempts.length = 1 ∧
    (runWith (word 21000000000)).moduleAttempts.length = 1 := by decide +kernel

def loopRows (e : TopupGatewayRootCalls.Environment) (rows : List Row) :=
  TopupGatewayRootCalls.loop e none 0 rows

theorem duplicate_retains_first_root :
    (loopRows env [TopupBatchConsumerRegression.row,TopupBatchConsumerRegression.row]).outcome = .error .invalidSortOrder ∧
    (loopRows env [TopupBatchConsumerRegression.row,TopupBatchConsumerRegression.row]).attempts.length = 1 := by decide +kernel

theorem short_slot_proof_makes_no_root_attempt :
    (loopRows env [{TopupBatchConsumerRegression.row with proof := []}]).attempts = [] := by decide +kernel

theorem activation_precedes_root :
    (loopRows {env with divisor := ⟨0,by decide⟩} [TopupBatchConsumerRegression.row]).outcome = .error .divisionByZero ∧
    (loopRows {env with divisor := ⟨0,by decide⟩} [TopupBatchConsumerRegression.row]).attempts = [] := by decide +kernel

theorem rejected_root_retains_attempt :
    (loopRows {env with rootExternal := fun _ _ => .rejected [0xde]} [TopupBatchConsumerRegression.row]).outcome =
      .error (.verifier .rootNotFound) ∧
    (loopRows {env with rootExternal := fun _ _ => .rejected [0xde]} [TopupBatchConsumerRegression.row]).attempts.map (·.accepted) =
      [false] := by decide +kernel

theorem wrong_caller_rejected :
    (loopRows {env with gateway := TopupBatchConsumerRegression.address 2} [TopupBatchConsumerRegression.row]).outcome = .error (.verifier .rootNotFound) := by
  decide +kernel

theorem pending_overflow_retains_verified_root :
    (loopRows env [{TopupBatchConsumerRegression.row with pending := ⟨2^256-1,by decide⟩}]).outcome = .error .pendingOverflow ∧
    (loopRows env [{TopupBatchConsumerRegression.row with pending := ⟨2^256-1,by decide⟩}]).attempts.map (·.accepted) = [true] := by
  decide +kernel


def secondRow : Row :=
  {TopupBatchConsumerRegression.row with
    index := ⟨1,by decide⟩
    witness := {TopupBatchConsumerRegression.witness with effectiveBalance := 33}}
def twoInput : TopupModuleCall.Input :=
  ⟨word 7,word 20000000000,[List.replicate 48 0,List.replicate 48 0],
    [word 42,word 43],[word 3,word 4],[word 32000000000,word 31000000000]⟩
def twoModule : External := fun req _ =>
  if req.caller = TopupBatchConsumerRegression.address 2 ∧
      req.target = TopupBatchConsumerRegression.address 40 ∧ req.value = word 0 ∧
      req.payload = TopupModuleCall.payload twoInput then
    .success (TopupModuleCall.encodeReturn [word 0,word 0]) TopupBatchConsumerRegression.changed
  else .rejected [0xba]
def twoBatch := TopupBatchRootCalls.run TopupBatchConsumerRegression.mapHash twoModule
  TopupBatchConsumerRegression.reject env TopupBatchConsumerRegression.ctx
  (TopupBatchConsumerRegression.address 8) (word 7) [word 42,word 43] [word 3,word 4]
  [TopupBatchConsumerRegression.row,secondRow] (word (2^256-1))

/-- Distinct ordered indices and effective balances must produce the exact
32/31 Gwei limits accepted by the actual module, after two actual root calls. -/
theorem two_rows_consume_ordered_limits :
    twoBatch.outcome = .ok () ∧
    twoBatch.rootAttempts.length = 2 ∧ twoBatch.moduleAttempts.length = 1 ∧
    twoBatch.attempts.map (fun a => match a with | .inl _ => true | .inr _ => false) =
      [true,true,false] := by decide +kernel

def failedBatch := TopupBatchRootCalls.run TopupBatchConsumerRegression.mapHash twoModule
  TopupBatchConsumerRegression.reject {env with rootExternal := fun _ _ => .forbiddenStateChange}
  TopupBatchConsumerRegression.ctx (TopupBatchConsumerRegression.address 8)
  (word 7) [word 42] [word 3] [TopupBatchConsumerRegression.row] (word 0)

theorem forbidden_root_skips_module :
    failedBatch.outcome = .error (.gateway (.verifier .rootNotFound)) ∧
    failedBatch.rootAttempts.map (·.accepted) = [false] ∧
    failedBatch.moduleAttempts = [] := by decide +kernel

#print axioms two_rows_consume_ordered_limits
#print axioms forbidden_root_skips_module

#print axioms actual_batch_succeeds
#print axioms actual_batch_has_joint_guarantee
#print axioms actual_requests_and_effects
#print axioms above_cap_rolls_back_keeps_both_attempts
#print axioms duplicate_retains_first_root
#print axioms short_slot_proof_makes_no_root_attempt
#print axioms activation_precedes_root
#print axioms rejected_root_retains_attempt
#print axioms wrong_caller_rejected
#print axioms pending_overflow_retains_verified_root
end LidoSRv3.Tests.TopupBatchRootCallsRegression
