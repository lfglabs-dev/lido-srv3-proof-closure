import LidoSRv3.Audit.Source.TopupRouterCommitted
import LidoSRv3.Tests.TopupModuleCallMutants

namespace LidoSRv3.Tests.TopupRouterCommittedMutants
open LidoSRv3.Audit.Source TrioReserve1 Live TopupRouterCommitted
open TopupModuleCallMutants

/-- The inherited module returns raw ABI bytes and a changed world. Its
complete existing executor actually reaches the real withdrawal/beacon path. -/
def committed := TopupModuleCall.execute mapHash positiveModule TopupRouterContinuationMutants.callee
  ctx (address 8) positiveInput before

theorem committed_success : committed.outcome = .ok () := by
  have h := positive_execution
  change (TopupModuleCall.program mapHash positiveModule TopupRouterContinuationMutants.callee
    ctx (address 8) positiveInput before).outcome = .ok () at h
  unfold committed TopupModuleCall.execute Live.run
  dsimp only
  rw [h]
  exact h

/-- Consume the NEW theorem with actual execution; no helper-frame/count or
per-call balance theorem is supplied by this regression. -/
theorem committed_reaches_helper : ∃ raw afterModule moduleTrace allocations total,
    TopupModuleCall.call mapHash positiveModule (LidoSRv3.Audit.Verity.TopupBeaconFundedTx.routerContext ctx)
      positiveInput before = ⟨.ok raw,afterModule,moduleTrace⟩ ∧
    TopupModuleCall.decodeReturn raw = .ok allocations ∧
    TopupRouterContinuation.guardSum (TopupRouterContinuation.values allocations)
      (TopupRouterContinuation.values positiveInput.limits) 0 = .ok total ∧
    total ≤ positiveInput.roundedTarget.val ∧
    let ci := TopupModuleCall.continuationInput positiveInput allocations
    let suffixResult := TopupRouterContinuation.program mapHash TopupRouterContinuationMutants.callee
      ctx (address 8) ci afterModule
    committed.world = suffixResult.world ∧
    committed.attempts = moduleTrace ++ suffixResult.attempts ∧
    ((total = 0 ∧ suffixResult =
      ⟨.ok (),{afterModule with logs := afterModule.logs ++ [TopupRouterContinuation.topUpEvent ctx.sender ci 0]},[]⟩) ∨
     PositiveEffects mapHash TopupRouterContinuationMutants.callee ctx (address 8) ci afterModule suffixResult total) :=
  module_execute_success _ _ _ _ _ _ _ committed_success

/-- The positive branch is non-vacuous: the actual guard computes 3 ETH,
so the new consumer theorem cannot discharge this fixture via the zero branch.
Only the inherited execution outcome is used, not its ledger postconditions. -/
theorem positive_suffix_effects : PositiveEffects TopupRouterContinuationMutants.mapHash
    TopupRouterContinuationMutants.callee TopupRouterContinuationMutants.context
    TopupRouterContinuationMutants.beacon TopupRouterContinuationMutants.input
    TopupRouterContinuationMutants.before
    (TopupRouterContinuation.program TopupRouterContinuationMutants.mapHash
      TopupRouterContinuationMutants.callee TopupRouterContinuationMutants.context
      TopupRouterContinuationMutants.beacon TopupRouterContinuationMutants.input
      TopupRouterContinuationMutants.before) (3*10^18) := by
  have hs := (execute_success_program TopupRouterContinuationMutants.mapHash
    TopupRouterContinuationMutants.callee TopupRouterContinuationMutants.context
    TopupRouterContinuationMutants.beacon TopupRouterContinuationMutants.input
    TopupRouterContinuationMutants.before TopupRouterContinuationMutants.positiveFacts.2.1).2
  obtain ⟨total,hguard,_,heffects⟩ := continuation_success _ _ _ _ _ _ hs
  have hg : TopupRouterContinuation.guardSum
      (TopupRouterContinuation.values TopupRouterContinuationMutants.input.allocations)
      (TopupRouterContinuation.values TopupRouterContinuationMutants.input.limits) 0 =
      .ok (3*10^18) := rfl
  rw [hg] at hguard
  cases hguard
  rcases heffects with ⟨hz,_⟩ | hp
  · exact False.elim ((by decide : 3*10^18 ≠ 0) hz)
  · exact hp

-- Genuine empty-key early return must not be counted as a deposit.
example : helperAmount {TopupRouterContinuationMutants.input with pubkeys := []} = 0 := rfl
example : helperCount {TopupRouterContinuationMutants.input with pubkeys := []} = 0 := rfl
example : helperAmount TopupRouterContinuationMutants.input = 3*10^18 := rfl
example : helperCount TopupRouterContinuationMutants.input = 2 := rfl

-- The actual module may change the starting ledger even with zero allocation.
-- No invariant connecting these arbitrary module effects to the pre-call
-- ledger is smuggled into the new suffix theorem.
set_option maxRecDepth 16384 in
example : zeroResult.world.balances (address 2) = 12 := rfl
example : before.balances (address 2) = 7 := rfl
example : malformed.world = before := TopupModuleCall.failure_restores _ _ _ _ _ _ _ _ (by rfl)

#print axioms committed_success
#print axioms positive_suffix_effects
#print axioms committed_reaches_helper
end LidoSRv3.Tests.TopupRouterCommittedMutants
