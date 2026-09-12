import LidoSRv3.Audit.Verity.TopupUnboundedCount
import LidoSRv3.Audit.Verity.Topup2DistributionTx

/-! P-TOPUP-2 unbounded-count consumer vectors. -/

namespace LidoSRv3.Tests.TopupUnboundedCountMutants

open Verity
open LidoSRv3.Audit.Guarantees.PTopup2
open LidoSRv3.Audit.Verity.Topup2DistributionTx
open LidoSRv3.Audit.Verity.TopupUnboundedCount

private def word (n : Nat) : Word := Verity.Core.Uint256.ofNat n

private def words (xs : List Nat) : List Word := xs.map word

private def runAny (effective pending requested topUpLimits : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) : View :=
  let before := stateFor effective pending requested topUpLimits defaultState
  observe (List.replicate requested.length 0) remainingCap
    ((allocateAnyCount requested.length target minTopUp remainingCap moduleLimit
      valueGwei).run before)

private def runFrozen (effective pending requested topUpLimits : List Word)
    (target minTopUp remainingCap moduleLimit valueGwei : Word) : View :=
  let before := stateFor effective pending requested topUpLimits defaultState
  observe (List.replicate requested.length 0) remainingCap
    ((allocate requested.length target minTopUp remainingCap moduleLimit
      valueGwei).run before)

/-- Leftover walk on a 40-key list (above the frozen 32) still respects the
budget.  StakingRouter / IStakingModuleV2 have no `count ≤ 32`. -/
example :
    (consumeBudget 10 (List.replicate 40 1)).sum = 10 ∧
      (consumeBudget 10 (List.replicate 40 1)).sum ≤ 10 := by
  decide

/-- Registered abstract parent is the unbounded leftover-walk instance. -/
example (b : TopupBatch) (cfg : TopupConfig) :
    (transition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei :=
  parent_block_cap_is_unbounded_instance b cfg

/-- Frozen-32 `allocate` and unbounded `allocateAnyCount` agree on a
2-key batch (`count ≤ 32`). -/
example :
    runFrozen (words [32, 40]) (words [0, 0]) (words [6, 8]) (words [32, 24])
      (word 64) (word 1) (word 10) (word 100) (word 100) =
    runAny (words [32, 40]) (words [0, 0]) (words [6, 8]) (words [32, 24])
      (word 64) (word 1) (word 10) (word 100) (word 100) := by
  decide

/-- Unbounded lockstep on 2 keys: same observables as the independent
source view. -/
example :
    runAny (words [32, 40]) (words [0, 0]) (words [6, 8]) (words [32, 24])
      (word 64) (word 1) (word 10) (word 100) (word 100) =
      ⟨.committed, words [6, 4], word 0, word 10⟩ := by
  decide

/-- Count 33: the frozen-32 parent transaction reverts.  The unbounded
consumer (and StakingRouter) does not. -/
private def over33 : Nat := 33

private def overEff : List Word := List.replicate over33 (word 32)
private def overPend : List Word := List.replicate over33 (word 0)
private def overReq : List Word := List.replicate over33 (word 1)
private def overLim : List Word := List.replicate over33 (word 32)

example : over33 > maxValidatorsPerTopUp := by decide

example :
    runFrozen overEff overPend overReq overLim
      (word 64) (word 1) (word 100) (word 100) (word 100) =
      ⟨.reverted, List.replicate over33 (word 0), word 100, word 0⟩ := by
  decide

example :
    runAny overEff overPend overReq overLim
      (word 64) (word 1) (word 100) (word 100) (word 100) =
      ⟨.committed, List.replicate over33 (word 1), word 67, word 33⟩ := by
  decide

/-- Kill-line: a “drop the literal-32 guard” mutant is **not** refused by
the leftover walk / StakingRouter.  The contract guard is the stored
`uint64`, not this 32. -/
theorem frozen_32_is_model_not_router :
    (allocate over33 (word 64) (word 1) (word 100) (word 100) (word 100)).run
        (stateFor overEff overPend overReq overLim defaultState) =
      .revert "MaxValidatorsPerTopUpExceeded"
        (stateFor overEff overPend overReq overLim defaultState) ∧
    ¬ ((allocateAnyCount over33 (word 64) (word 1) (word 100) (word 100)
          (word 100)).run
        (stateFor overEff overPend overReq overLim defaultState) =
      .revert "MaxValidatorsPerTopUpExceeded"
        (stateFor overEff overPend overReq overLim defaultState)) := by
  constructor
  · rfl
  · intro h
    have hsucc :
        (allocateAnyCount over33 (word 64) (word 1) (word 100) (word 100)
          (word 100)).run
          (stateFor overEff overPend overReq overLim defaultState) =
          .success ⟨List.replicate over33 (word 1), word 67, word 33⟩
            ((persistAllocs (List.replicate over33 (word 1))
              (stateFor overEff overPend overReq overLim defaultState)).writeSlot
              remainingSlot (word 67) |>.writeSlot allocatedSlot (word 33)) := rfl
    rw [hsucc] at h
    cases h

#print axioms leftover_walk_sum_le_budget
#print axioms parent_block_cap_is_unbounded_instance
#print axioms sourceRun_any_count
#print axioms allocate_eq_any_of_le
#print axioms verity_tx_simulates_pinned_source_any_count
#print axioms parent_verity_is_unbounded_instance
#print axioms frozen_32_is_model_not_router

end LidoSRv3.Tests.TopupUnboundedCountMutants
