import LidoSRv3.Audit.Source.TopupBeaconSumBound
import LidoSRv3.Tests.TopupBeaconCommittedMutants
import LidoSRv3.Tests.TopupRouterCommittedMutants

namespace LidoSRv3.Tests.TopupBeaconSumBoundMutants
open LidoSRv3.Audit.Source TrioReserve1 Live TopupBeaconBatch TopupBeaconCallee
open TopupBeaconSumBound LidoSRv3.Audit.Verity.TopupTx
open LidoSRv3.Audit.Verity TopupRouterContinuation
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Tests.TopupRouterContinuationMutants (mapHash context beacon single changedWithdrawal changedInput ether before)

/-- The necessary sum theorem consumes an actual positive helper execution;
the count/ledger postconditions of the inherited fixture are not its premises. -/
theorem positive_exact_sum : ∃ after : World,
    helper mapHash (TopupBeaconFundedTx.routerContext context) beacon single changedWithdrawal.world =
      ⟨.ok (),after,[⟨⟨context.sender,beacon,word ether,TopupBeaconEffects.sourcePayload changedInput⟩,true,[],[]⟩]⟩ ∧
    ether = allocSum (values single.allocations) ∧
    allocSum (values single.allocations) < uint256Modulus := by
  obtain ⟨after,hh,_,_⟩ := TopupBeaconCommittedMutants.positive_helper
  have hg : guardSum (values single.allocations) (values single.limits) 0 = .ok ether := by
    decide +kernel
  have he := helper_success_guard_exact mapHash (TopupBeaconFundedTx.routerContext context)
    beacon single changedWithdrawal.world after _ ether hg hh
  have hf := helper_success_sum_fits mapHash (TopupBeaconFundedTx.routerContext context)
    beacon single changedWithdrawal.world after _ hh
  have hn : single.pubkeys ≠ [] := by decide +kernel
  rw [if_neg hn] at hf
  rcases he with hempty | he
  · exact False.elim (hn hempty)
  · exact ⟨after,hh,he,hf⟩

/-- The actual positive suffix result supplies the sum proof. No precomputed
ledger, capacity or sum-range fact is passed to the new theorem. -/
theorem positive_suffix_sum :
    3*10^18 = allocSum (values TopupRouterContinuationMutants.input.allocations) ∧
    allocSum (values TopupRouterContinuationMutants.input.allocations) < uint256Modulus := by
  have h := positive_effects_sum mapHash TopupRouterContinuationMutants.callee context beacon
    TopupRouterContinuationMutants.input before _ (3*10^18) (by rfl)
    TopupRouterCommittedMutants.positive_suffix_effects
  exact h.resolve_left (by decide +kernel)

/-- The refined theorem is applied to the complete existing module executor,
retaining its actual raw reply, decoded allocations and post-module world. -/
theorem module_exact_sum_chain : ∃ raw afterModule moduleTrace allocations total,
    TopupModuleCall.call TopupModuleCallMutants.mapHash TopupModuleCallMutants.positiveModule
      (TopupBeaconFundedTx.routerContext TopupModuleCallMutants.ctx)
      TopupModuleCallMutants.positiveInput TopupModuleCallMutants.before =
        ⟨.ok raw,afterModule,moduleTrace⟩ ∧
    TopupModuleCall.decodeReturn raw = .ok allocations ∧
    guardSum (values allocations) (values TopupModuleCallMutants.positiveInput.limits) 0 = .ok total ∧
    total ≤ TopupModuleCallMutants.positiveInput.roundedTarget.val ∧
    let ci := TopupModuleCall.continuationInput TopupModuleCallMutants.positiveInput allocations
    let suffixResult := TopupRouterContinuation.program TopupModuleCallMutants.mapHash
      TopupRouterContinuationMutants.callee TopupModuleCallMutants.ctx (TopupModuleCallMutants.address 8) ci afterModule
    TopupRouterCommittedMutants.committed.world = suffixResult.world ∧
    TopupRouterCommittedMutants.committed.attempts = moduleTrace ++ suffixResult.attempts ∧
    ((total = 0 ∧ suffixResult =
      ⟨.ok (),{afterModule with logs := afterModule.logs ++
        [topUpEvent TopupModuleCallMutants.ctx.sender ci 0]},[]⟩) ∨
     (TopupRouterCommitted.PositiveEffects TopupModuleCallMutants.mapHash
       TopupRouterContinuationMutants.callee TopupModuleCallMutants.ctx (TopupModuleCallMutants.address 8) ci afterModule suffixResult total ∧
      (TopupModuleCallMutants.positiveInput.pubkeys = [] ∨
        (total = allocSum (values allocations) ∧ allocSum (values allocations) < uint256Modulus)))) :=
  module_execute_success_sum _ _ _ _ _ _ _ TopupRouterCommittedMutants.committed_success

-- The numeric capacity theorem bounds even the loose uint64-gwei ceiling;
-- removing either the per-call bound or physical-count argument is not justified.
example : maxCount * (2^64 * 10^9 - 1) < uint256Modulus := by decide +kernel
example : (2^64 * 10^9 - 1) / 10^9 = 2^64-1 := by decide +kernel
example : ¬ (2^64 * 10^9) / 10^9 ≤ 2^64-1 := by decide +kernel
example : nonzeroCount [0,10^18,0,2*10^18] = 2 := by decide +kernel
example : allocSum [0,10^18,0,2*10^18] = 3*10^18 := by decide +kernel

private def emptyHuge : Input :=
  {single with pubkeys := [], allocations := [word (2^256-1),word (2^256-1)]}

-- Empty keys return before inspecting these allocations. No false bound on
-- their mathematical sum is inferred from the helper's successful zero effect.
example : helper mapHash (TopupBeaconFundedTx.routerContext context) beacon emptyHuge before =
    ⟨.ok (),before,[]⟩ := rfl
example : uint256Modulus ≤ allocSum (values emptyHuge.allocations) := by decide +kernel
example : (if emptyHuge.pubkeys = [] then 0 else allocSum (values emptyHuge.allocations)) = 0 := rfl

-- No caller-supplied initial count bound is needed on a zero-deposit execution.
example : TopupBeaconBatch.loop (TopupBeaconFundedTx.routerContext context) beacon [] []
    {before with core := before.core.writeContractSlot beacon.val countSlot (word (maxCount+7))} =
      ⟨.ok (),{before with core := before.core.writeContractSlot beacon.val countSlot (word (maxCount+7))},[]⟩ := rfl

#print axioms positive_suffix_sum
#print axioms module_exact_sum_chain
#print axioms positive_exact_sum
#print axioms helper_success_guard_exact
#print axioms loop_success_sum_fits
end LidoSRv3.Tests.TopupBeaconSumBoundMutants
