import LidoSRv3.Audit.Verity.TopupMultiCallBlockCap

/-! P-TOPUP-2 same-block n-call vectors. -/

namespace LidoSRv3.Tests.TopupUnboundedMultiCallMutants

open LidoSRv3.Audit.Guarantees.PTopup2
open LidoSRv3.Audit.Verity.TopupMultiCallBlockCap

/-- Setter `TopUpGateway.sol:361-365` refuses `minBlockDistance = 0`. -/
example : ¬ minBlockDistanceAdmitted 0 := setter_refuses_zero

example : minBlockDistanceAdmitted 1 := by decide

/-- After a nonzero-block write, same-block distance fails when
`minBlockDistance ≥ 1`. -/
example :
    ¬ BlockDistancePassed
      (setLastTopUpData killState 1 1) 1 :=
  distance_fails_after_set killState 1 1 (by decide) (by decide)

/-- Honest n=2 same block: sum equals the cap. -/
example :
    (runMany killCfg 1 1 killState [killBatch, killBatch]).1 = [10, 0] ∧
      (runMany killCfg 1 1 killState [killBatch, killBatch]).1.sum = 10 := by
  decide

/-- A first zero-limit call does not write `lastTopUpBlock`; the second
call may allocate, and the sum is still ≤ cap. -/
private def zeroLimitValidator : Validator :=
  { pubkey := ⟨#[1]⟩, index := 0, wc := 2, activated := true
    slashed := false, exiting := false
    effectiveBalanceGwei := 32, pendingBalanceGwei := 0 }

private def zeroLimitBatch : TopupBatch :=
  { validators := [zeroLimitValidator], requestedGwei := [10], allocations := []
    valueWei := 100 * GWEI, beaconRootTimestamp := 0, currentTimestamp := 0 }

example : totalLimits zeroLimitBatch killCfg = 0 := by decide

example : (transition zeroLimitBatch killCfg).sum = 0 :=
  totalLimits_zero_implies_transition_zero zeroLimitBatch killCfg (by decide)

example :
    (runMany killCfg 1 1 killState [zeroLimitBatch, killBatch]).1 = [0, 10] ∧
      (runMany killCfg 1 1 killState [zeroLimitBatch, killBatch]).1.sum ≤
        killCfg.maxTopUpPerBlockGwei := by
  decide

/-- Three same-block calls: only the first positive one commits. -/
example :
    (runMany killCfg 1 1 killState [killBatch, killBatch, killBatch]).1.sum = 10 := by
  decide

/-- Mutant without `_setLastTopUpData`: two calls exceed the cap. -/
example :
    (runManyNoLock killCfg 1 1 killState [killBatch, killBatch]).1 = [10, 10] ∧
      (runManyNoLock killCfg 1 1 killState [killBatch, killBatch]).1.sum = 20 := by
  decide

/-- Router-only (fresh budget, no gateway lock): same exceedance.  Not a
published finding — `StakingRouter.sol:686` auth-gates the caller to the
gateway, which refuses the second positive same-block call. -/
example :
    routerOnlyMany killCfg [killBatch, killBatch] = [10, 10] := by
  decide

#print axioms setter_refuses_zero
#print axioms totalLimits_zero_implies_transition_zero
#print axioms distance_fails_after_set
#print axioms same_block_sum_le_cap
#print axioms honest_two_call_sum_eq_cap
#print axioms honest_two_call_respects_parent
#print axioms no_lock_two_call_exceeds_cap
#print axioms router_only_two_call_exceeds_cap
#print axioms no_lock_kill_line_refutes_unconditional_sum

end LidoSRv3.Tests.TopupUnboundedMultiCallMutants
