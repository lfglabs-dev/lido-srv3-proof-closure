import LidoSRv3.Audit.Guarantees.PTopup1RootCalls
import LidoSRv3.Tests.TopupBatchRootCallsRegression
import LidoSRv3.Tests.TopupModuleCallMutants

namespace LidoSRv3.Tests.TopupRootCallEffectsRegression
open Audit.Source TrioReserve1 Live TopupGatewayWitnessBatch

set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

/-- Existing two-row actual-root fixture, whose module accepts only the exact
produced arrays, instantiates the new joint physical-effects consumer. -/
theorem zero_batch_effects :
    TopupRootCallEffects.Effects TopupBatchConsumerRegression.mapHash
      TopupBatchRootCallsRegression.twoModule TopupBatchConsumerRegression.reject
      TopupBatchRootCallsRegression.env TopupBatchConsumerRegression.ctx
      (TopupBatchConsumerRegression.address 8) (word 7) [word 42,word 43] [word 3,word 4]
      [TopupBatchConsumerRegression.row,TopupBatchRootCallsRegression.secondRow] (word (2^256-1))
      TopupBatchRootCallsRegression.twoBatch :=
  Audit.Guarantees.PTopup1.actual_root_module_batch_effects _ _ _ _ _ _ _ _ _ _ _
    TopupBatchRootCallsRegression.two_rows_consume_ordered_limits.1

/-- Zero allocations retain the module's own changed world; only the router
zero-amount event is appended, with no withdrawal/helper attempt. -/
theorem zero_keeps_actual_module_effects :
    TopupBatchRootCallsRegression.twoBatch.world.core = TopupBatchConsumerRegression.changed.core ∧
    TopupBatchRootCallsRegression.twoBatch.world.balances = TopupBatchConsumerRegression.changed.balances ∧
    TopupBatchRootCallsRegression.twoBatch.world.logs = TopupBatchConsumerRegression.changed.logs ++
      [TopupRouterContinuation.topUpEvent TopupBatchConsumerRegression.ctx.sender
        (TopupModuleCall.continuationInput TopupBatchRootCallsRegression.twoInput [word 0,word 0]) 0] ∧
    TopupBatchRootCallsRegression.twoBatch.moduleAttempts.length = 1 := by
  exact ⟨rfl,rfl,rfl,by decide +kernel⟩

def start : World :=
  let w := TopupRouterContinuationMutants.before
  let core := w.core.writeContractSlot 2 90 (word (40+2*2^232))
  let core := core.writeContractSlot 3 TopupGatewayConfigWords.gatewayRoot (word (3+2000000000*2^160))
  let core := core.writeContractSlot 3 (TopupGatewayConfigWords.gatewayRoot+1) (word 1)
  let core := core.writeContractSlot 2 (TopupRouterCredentials.routerRoot+5) (word (3000000000*2^24))
  {w with core}
def environment := {TopupBatchRootCallsRegression.env with before := start}
def mkRow (index : Nat) (keyByte : UInt8) : Row :=
  {TopupBatchConsumerRegression.row with
    index := ⟨index % (2^256),Nat.mod_lt _ (by decide)⟩
    witness := {TopupBatchConsumerRegression.witness with
      effectiveBalance := 0
      pubkey := SszRootCall.fromBytes (TopupRouterContinuationMutants.key keyByte)}}
def rows := [mkRow 0 1,mkRow 1 9,mkRow 2 2]
def expected : TopupModuleCall.Input := TopupModuleCallMutants.positiveInput
def module (amounts : List Word) : External := fun req _ =>
  if req.caller = TopupBatchConsumerRegression.address 2 ∧
      req.target = TopupBatchConsumerRegression.address 40 ∧ req.value = word 0 ∧
      req.payload = TopupModuleCall.payload expected then
    .success (TopupModuleCall.encodeReturn amounts) TopupRouterContinuationMutants.before
  else .rejected [0xba]
def runWith (amounts : List Word) := TopupBatchRootCalls.run TopupBatchConsumerRegression.mapHash
  (module amounts) TopupRouterContinuationMutants.callee environment TopupBatchConsumerRegression.ctx
  (TopupBatchConsumerRegression.address 8) (word 7) [word 1,word 2,word 3] [word 4,word 5,word 6]
  rows (word (2^256-1))
def positive := runWith [word (10^18),word 0,word (2*10^18)]

def checkedOutput : Output :=
  ⟨rows.map (fun r => r.witness.pubkey),[2*10^18,2*10^18,2*10^18],6*10^18⟩
theorem prefix_computes_expected :
    (TopupGatewayRootCalls.loop (TopupBatchRootCalls.environment environment) none 0 rows).outcome =
      .ok checkedOutput := by decide +kernel
theorem actual_input_is_expected :
    TopupBatchConsumer.moduleInput checkedOutput (word 7) [word 1,word 2,word 3]
      [word 4,word 5,word 6] TopupBatchConsumerRegression.ctx.sender (word (2^256-1)) start = expected := by rfl

/-- The actual root-produced arrays select the same already verified physical
continuation, including the exact returned module world. -/
theorem module_program_matches_physical_fixture :
    TopupModuleCall.program TopupBatchConsumerRegression.mapHash
      (module [word (10^18),word 0,word (2*10^18)]) TopupRouterContinuationMutants.callee
      TopupBatchConsumerRegression.ctx (TopupBatchConsumerRegression.address 8) expected start =
        TopupModuleCallMutants.positiveProgram := by
  have hcall : TopupModuleCall.call TopupBatchConsumerRegression.mapHash
      (module [word (10^18),word 0,word (2*10^18)]) TopupModuleCallMutants.routerCtx expected start =
      ⟨.ok (TopupModuleCall.encodeReturn TopupRouterContinuationMutants.input.allocations),
       TopupRouterContinuationMutants.before,
       [⟨⟨TopupBatchConsumerRegression.address 2,TopupBatchConsumerRegression.address 40,word 0,
         TopupModuleCall.payload expected⟩,true,
         TopupModuleCall.encodeReturn TopupRouterContinuationMutants.input.allocations,[]⟩]⟩ := by rfl
  have he := TopupModuleCall.program_encoded TopupBatchConsumerRegression.mapHash
    (module [word (10^18),word 0,word (2*10^18)]) TopupRouterContinuationMutants.callee
    TopupBatchConsumerRegression.ctx (TopupBatchConsumerRegression.address 8) expected start
    TopupRouterContinuationMutants.before TopupRouterContinuationMutants.input.allocations [] _ (by decide) hcall
  have he2 := TopupModuleCall.program_encoded TopupModuleCallMutants.mapHash
    TopupModuleCallMutants.positiveModule TopupRouterContinuationMutants.callee
    TopupModuleCallMutants.ctx (TopupModuleCallMutants.address 8) TopupModuleCallMutants.positiveInput
    TopupModuleCallMutants.before TopupRouterContinuationMutants.before
    TopupRouterContinuationMutants.input.allocations [] _ (by decide) (by rfl)
  have heq := he.trans he2.symm
  change TopupModuleCall.program _ _ _ _ _ _ _ = TopupModuleCallMutants.positiveProgram at heq
  exact heq

/-- The prefix computes actual arrays and runs the actual module before the
unchanged physical positive fixture. Exact program transport reuses its
retained kernel proof without evaluating opaque beacon hash primitives. -/
theorem positive_program_projection :
    positive.outcome = TopupModuleCallMutants.positiveProgram.outcome.mapError TopupBatchRootCalls.Error.module := by
  have hp := TopupModuleCallMutants.positive_execution
  unfold positive runWith TopupBatchRootCalls.run
  rw [show checkLengths (TopupBatchRootCalls.environment environment).cfg rows.length
    [word 1,word 2,word 3].length [word 4,word 5,word 6].length rows.length rows.length = .ok () from by decide]
  unfold TopupBatchRootCalls.finish
  rw [prefix_computes_expected]
  change (TopupModuleCall.execute TopupBatchConsumerRegression.mapHash
    (module [word (10^18),word 0,word (2*10^18)]) TopupRouterContinuationMutants.callee
    TopupBatchConsumerRegression.ctx (TopupBatchConsumerRegression.address 8) expected start).outcome.mapError
      TopupBatchRootCalls.Error.module = _
  have heq := module_program_matches_physical_fixture
  unfold TopupModuleCall.execute Live.run
  rw [heq]
  dsimp only
  rw [hp]
  simp only [hp]

theorem positive_batch_succeeds : positive.outcome = .ok () := by
  rw [positive_program_projection,TopupModuleCallMutants.positive_execution]
  rfl

theorem positive_batch_joint_consumer :
    TopupRootCallEffects.Effects TopupBatchConsumerRegression.mapHash
      (module [word (10^18),word 0,word (2*10^18)]) TopupRouterContinuationMutants.callee
      environment TopupBatchConsumerRegression.ctx (TopupBatchConsumerRegression.address 8)
      (word 7) [word 1,word 2,word 3] [word 4,word 5,word 6] rows (word (2^256-1)) positive :=
  Audit.Guarantees.PTopup1.actual_root_module_batch_effects _ _ _ _ _ _ _ _ _ _ _
    positive_batch_succeeds


theorem positive_world_matches_physical_fixture :
    positive.world = TopupRouterContinuationMutants.result.world := by
  unfold positive runWith TopupBatchRootCalls.run
  rw [show checkLengths (TopupBatchRootCalls.environment environment).cfg rows.length
    [word 1,word 2,word 3].length [word 4,word 5,word 6].length rows.length rows.length = .ok () from by decide]
  unfold TopupBatchRootCalls.finish
  rw [prefix_computes_expected]
  change (TopupModuleCall.execute TopupBatchConsumerRegression.mapHash
    (module [word (10^18),word 0,word (2*10^18)]) TopupRouterContinuationMutants.callee
    TopupBatchConsumerRegression.ctx (TopupBatchConsumerRegression.address 8) expected start).world = _
  unfold TopupModuleCall.execute Live.run
  rw [module_program_matches_physical_fixture]
  dsimp only
  rw [TopupModuleCallMutants.positive_execution]
  dsimp only
  have hp := TopupModuleCall.program_encoded TopupModuleCallMutants.mapHash
    TopupModuleCallMutants.positiveModule TopupRouterContinuationMutants.callee
    TopupModuleCallMutants.ctx (TopupModuleCallMutants.address 8) TopupModuleCallMutants.positiveInput
    TopupModuleCallMutants.before TopupRouterContinuationMutants.before
    TopupRouterContinuationMutants.input.allocations [] _ (by decide) (by rfl)
  change TopupModuleCallMutants.positiveProgram = _ at hp
  rw [hp]
  have he := TopupRouterCommitted.execute_success_program TopupRouterContinuationMutants.mapHash
    TopupRouterContinuationMutants.callee TopupRouterContinuationMutants.context
    TopupRouterContinuationMutants.beacon TopupRouterContinuationMutants.input
    TopupRouterContinuationMutants.before TopupRouterContinuationMutants.positiveFacts.2.1
  exact congrArg (fun r => r.world) he.1.symm

/-- This reads the actual deposit-contract count slot, not a synthetic counter. -/
theorem positive_physical_balances_and_count :
    positive.world.balances (TopupBatchConsumerRegression.address 2) = 7 ∧
    positive.world.balances (TopupBatchConsumerRegression.address 1) = 97*10^18 ∧
    positive.world.balances (TopupBatchConsumerRegression.address 8) = 11+3*10^18 ∧
    (positive.world.core.readContractSlot 8 32).val = 5 := by
  rw [positive_world_matches_physical_fixture]
  refine ⟨TopupRouterContinuationMutants.positiveFacts.2.2.2.1,?_,
    TopupRouterContinuationMutants.positiveFacts.2.2.2.2.2.1,
    TopupRouterContinuationMutants.positiveFacts.2.2.2.2.2.2.1⟩
  have h := TopupRouterContinuationMutants.positiveFacts.2.2.2.2.1
  change TopupRouterContinuationMutants.result.world.balances
    (TopupBatchConsumerRegression.address 1) + 3*10^18 = 100*10^18 at h
  have arithmetic : ∀ n : Nat, n + 3*10^18 = 100*10^18 → n = 97*10^18 := by
    intro n hn
    omega
  exact arithmetic _ h

def overCap := runWith [word (2*10^18),word (2*10^18),word 0]
theorem actual_reply_above_cap_rejected :
    overCap.outcome = .error (.module (.reason "ModuleReturnExceedTarget")) ∧
    overCap.rootAttempts.length = 3 ∧ overCap.moduleAttempts.length = 1 := by decide +kernel

theorem actual_reply_above_cap_restores : overCap.world = start :=
  TopupBatchRootCalls.failure_restores _ _ _ _ _ _ _ _ _ _ _ _
    actual_reply_above_cap_rejected.1

#print axioms module_program_matches_physical_fixture
#print axioms positive_world_matches_physical_fixture
#print axioms positive_physical_balances_and_count
#print axioms actual_reply_above_cap_rejected
#print axioms actual_reply_above_cap_restores

#print axioms zero_keeps_actual_module_effects
#print axioms prefix_computes_expected
#print axioms actual_input_is_expected
#print axioms zero_batch_effects
#print axioms positive_program_projection
#print axioms positive_batch_succeeds
#print axioms positive_batch_joint_consumer

end LidoSRv3.Tests.TopupRootCallEffectsRegression
