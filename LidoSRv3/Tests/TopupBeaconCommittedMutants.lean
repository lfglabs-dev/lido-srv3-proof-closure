import LidoSRv3.Audit.Source.TopupBeaconCommitted
import LidoSRv3.Tests.TopupRouterContinuationMutants

namespace LidoSRv3.Tests.TopupBeaconCommittedMutants
open LidoSRv3.Audit.Source TrioReserve1 Live TopupBeaconBatch TopupBeaconCallee
open TopupBeaconCommitted LidoSRv3.Audit.Verity.TopupTx
open LidoSRv3.Audit.Verity TopupRouterContinuation
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Tests.TopupRouterContinuationMutants (mapHash context beacon single changedWithdrawal changedInput ether before)

/-- Nonzero source-callee execution is constructed using the established
physical fixture. The new theorem receives its actual helper result, without
an admission/frame/funding predicate or a returned digest hypothesis. -/
theorem positive_helper : ∃ after : World,
    helper mapHash (TopupBeaconFundedTx.routerContext context) beacon single changedWithdrawal.world =
      ⟨.ok (),after,[⟨⟨context.sender,beacon,word ether,TopupBeaconEffects.sourcePayload changedInput⟩,true,[],[]⟩]⟩ ∧
    CallSpec.Balances changedWithdrawal.world.balances after.balances context.sender beacon ether ∧
    (after.core.readContractSlot beacon.val countSlot).val = 4 := by
  obtain ⟨after,hpush,_,_,_,_⟩ := TopupBeaconEffects.source_push_success
    changedInput (TopupBeaconFundedTx.routerContext context) beacon (word ether) changedWithdrawal.world
    (by decide +kernel) (by decide +kernel) (by decide +kernel) (by decide +kernel)
    (by decide +kernel) (by decide +kernel) (by rfl)
    (by decide +kernel) (by decide +kernel) (by decide +kernel)
  have hh : helper mapHash (TopupBeaconFundedTx.routerContext context) beacon single changedWithdrawal.world =
      ⟨.ok (),after,[⟨⟨context.sender,beacon,word ether,TopupBeaconEffects.sourcePayload changedInput⟩,true,[],[]⟩]⟩ := by
    change TopupBeaconBatch.loop _ _ [changedInput] [ether] _ = _
    simp only [TopupBeaconBatch.loop,show changedInput.publicKey.length = 48 from by decide +kernel,
      show ether ≠ 0 from by decide +kernel,show 10^18 ≤ ether from by decide +kernel,
      show ether/10^9 ≤ 2^64-1 from by decide +kernel,decide_true,require,if_true,if_false,
      bind,pure,bindExec,pureExec,hpush,List.append_nil,List.nil_append]
    rfl
  refine ⟨after,hh,?_⟩
  have hb := helper_success_balances mapHash (TopupBeaconFundedTx.routerContext context)
    beacon single changedWithdrawal.world after _ hh
  change CallSpec.Balances _ _ _ _ ether at hb
  have hc := helper_success_count mapHash (TopupBeaconFundedTx.routerContext context)
    beacon single changedWithdrawal.world after _ hh
  refine ⟨hb,?_⟩
  have he := hc.1
  have hz : (changedWithdrawal.world.core.readContractSlot beacon.val countSlot).val = 3 := by decide +kernel
  have hn : (if single.pubkeys = [] then 0 else nonzeroCount (values single.allocations)) = 1 := by decide +kernel
  simpa only [hz,hn,Nat.zero_add] using he

example : (2^64)*10^9-1 < uint256Modulus :=
  guarded_amount_fits _ (by decide +kernel)
example : ¬ (2^64)*10^9 / 10^9 ≤ 2^64-1 := by decide +kernel

/-- Empty-key early return must not be silently strengthened to full allocation
accounting. The outer input guard remains necessary to compose the router. -/
example : helper mapHash (TopupBeaconFundedTx.routerContext context) beacon
    {single with pubkeys := []} before = ⟨.ok (),before,[]⟩ := rfl
example : ¬ CallSpec.Balances before.balances before.balances context.sender beacon ether := by
  intro h
  have hb := h beacon
  change 11 + 0 = 11 + ether at hb
  norm_num [ether] at hb

/-- Key-width validation precedes the zero-allocation skip. -/
example : TopupBeaconBatch.loop (TopupBeaconFundedTx.routerContext context) beacon
    [{changedInput with publicKey := [], publicKeyBounded := by simp}] [0] before =
      ⟨.error (.reason "InvalidPublicKeysBatchLength"),before,[]⟩ := rfl
example : TopupBeaconBatch.loop (TopupBeaconFundedTx.routerContext context) beacon
    [] [0] before = ⟨.error (.reason "SourceDepositLengthMismatch"),before,[]⟩ := rfl

/-- An empty execution cannot manufacture a bound on an arbitrary initial
slot. This distinguishes a derived transition invariant from an admission axiom. -/
example : TopupBeaconBatch.loop (TopupBeaconFundedTx.routerContext context) beacon [] []
    {before with core := before.core.writeContractSlot beacon.val countSlot (Live.word (maxCount+7))} =
    ⟨.ok (),{before with core := before.core.writeContractSlot beacon.val countSlot (Live.word (maxCount+7))},[]⟩ := rfl

#print axioms positive_helper
#print axioms loop_success_balances
#print axioms helper_success_balances
#print axioms committed_funding
#print axioms helper_success_count
end LidoSRv3.Tests.TopupBeaconCommittedMutants
