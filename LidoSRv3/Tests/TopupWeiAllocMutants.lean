import LidoSRv3.Audit.Source.TopupWeiAlloc

/-! P-TOPUP-2 live wei conversion and module-selected allocateDeposits vectors. -/

namespace LidoSRv3.Tests.TopupWeiAllocMutants

open LidoSRv3.Audit.Source.TopupWeiAlloc

/-- Happy conversion: 5 gwei ↔ 5 * 10^9 wei (`TopUpGateway.sol:226`). -/
example : mulGwei 5 = 5 * GWEI := rfl
example : divGwei (mulGwei 5) = 5 := mulGwei_divGwei 5
example : aligned (mulGwei 5) := mulGwei_aligned 5

/-- `StakingRouter.sol:706` floors dust. -/
example : floorGwei (mulGwei 3 + 7) = mulGwei 3 := by decide

example : aligned (floorGwei (mulGwei 3 + 7)) := floorGwei_aligned _

/-- Live rounded target: min(module, block*wei) then floor (`:696-706`). -/
example : liveRoundedTarget (mulGwei 50) 20 = mulGwei 20 := by decide

example : liveRoundedTarget (mulGwei 10 + 3) 20 = mulGwei 10 := by decide

/-- Gateway limits lifted to wei. -/
example : liveLimitsWei [1, 2] = [mulGwei 1, mulGwei 2] := rfl

/-- Happy module return: `[10e9, 10e9]` under limits `[20e9, 20e9]`, cap 20 gwei. -/
example : admittedAllocations (liveLimitsWei [20, 20]) (mulGwei 20)
    ⟨[mulGwei 10, mulGwei 10]⟩ = some [mulGwei 10, mulGwei 10] := by
  decide

/-- Zeros are allowed (`IStakingModuleV2.sol:17`). -/
example : admittedAllocations (liveLimitsWei [20, 20]) (mulGwei 20)
    ⟨[0, 0]⟩ = some [0, 0] := by
  decide

/-- `StakingRouter.sol:724` `AmountNotAlignedToGwei`. -/
example : admittedAllocations [mulGwei 1] (mulGwei 1) ⟨[1]⟩ = none :=
  misaligned_rejected (mulGwei 1) (mulGwei 1)

/-- `StakingRouter.sol:728` `AllocationExceedsLimit`. -/
example : admittedAllocations [mulGwei 1] (mulGwei 2) ⟨[mulGwei 2]⟩ = none :=
  over_limit_rejected

/-- `StakingRouter.sol:737` `ModuleReturnExceedTarget`. -/
example : admittedAllocations (liveLimitsWei [20, 20]) (mulGwei 10)
    ⟨[mulGwei 10, mulGwei 10]⟩ = none :=
  over_target_rejected

/-- Arity mismatch fails closed. -/
example : admittedAllocations [mulGwei 1] (mulGwei 1) ⟨[0, 0]⟩ = none := by
  decide

/-- Module `[0, 20e9]` is admitted; leftover `consumeBudget` is `[20, 0]`. -/
example : consumeLeft = [20, 0] := consumeLeft_eq

example : admittedAllocations (liveLimitsWei twoKeyLimitsGwei) (mulGwei 20)
    moduleRight = some [0, mulGwei 20] :=
  moduleRight_admitted

example : (moduleRight.allocations.map divGwei) ≠ consumeLeft :=
  (module_policy_not_consumeBudget).2.2

/-- Admitted sum stays under the live block-cap word. -/
example : ∀ allocs,
    admittedAllocations (liveLimitsWei [20, 20])
      (liveRoundedTarget (mulGwei 100) 20) ⟨[0, mulGwei 20]⟩ = some allocs →
    allocs.sum ≤ liveMaxTopUpPerBlockWei 20 :=
  fun _ h => admitted_sum_le_block_cap h

#print axioms LidoSRv3.Audit.Source.TopupWeiAlloc.admitted_sum_le_block_cap
#print axioms LidoSRv3.Audit.Source.TopupWeiAlloc.admitted_aligned
#print axioms LidoSRv3.Audit.Source.TopupWeiAlloc.mulGwei_divGwei
#print axioms LidoSRv3.Audit.Source.TopupWeiAlloc.module_policy_not_consumeBudget
#print axioms LidoSRv3.Audit.Source.TopupWeiAlloc.liveRoundedTarget_aligned

end LidoSRv3.Tests.TopupWeiAllocMutants
