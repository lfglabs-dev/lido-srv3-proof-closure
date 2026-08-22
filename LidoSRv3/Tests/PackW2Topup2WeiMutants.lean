import LidoSRv3.Audit.Guarantees.PTopup2
import LidoSRv3.Audit.Spec.Topup2WeiConversionChild

/-!
# Pack W2-TOPUP2-WEI fail-closed vectors

A mutant budget that uses raw `valueWei` (no `/ GWEI`) on the five-gwei
witness equals `5 * 10^9`, which is not 5. The honest
`transitionBudget` divides by `GWEI` and equals 5.

Does not connect SSZ, `allocateDeposits`, or a live gateway.
`A-TOPUP-BEACON-ADDRESS` stays OPEN.
-/

namespace LidoSRv3.Tests.PackW2Topup2WeiMutants

open LidoSRv3.Audit.Guarantees
open PTopup2
open LidoSRv3.Audit.Spec.Topup2WeiConversionChild

/-- Mutant budget: treat `valueWei` as already-gwei. No `/ GWEI`. -/
def mutantBudgetRawWei (b : TopupBatch) : Nat :=
  b.valueWei

/-- The five-gwei witness from `aligned_five_gwei_budget`. -/
def fiveGweiBatch : TopupBatch :=
  { validators := [], requestedGwei := [], allocations := [],
    valueWei := 5 * GWEI, beaconRootTimestamp := 0, currentTimestamp := 0 }

def fiveGweiCfg : TopupConfig :=
  { targetBalanceGwei := 0, minTopUpGwei := 0,
    maxTopUpPerBlockGwei := 100, maxValidatorsPerCall := 1,
    moduleAllocationLimitGwei := 100, maxRootAge := 0 }

/-- Kill-line: raw `valueWei` on the five-gwei witness is `5 * 10^9 ≠ 5`.
The honest conversion is `valueWei / GWEI = 5`. -/
theorem raw_valueWei_mutant_on_five_gwei_eq_five_billion_ne_five :
    mutantBudgetRawWei fiveGweiBatch = 5 * 10 ^ 9 ∧
      mutantBudgetRawWei fiveGweiBatch ≠ 5 ∧
      transitionBudget fiveGweiBatch fiveGweiCfg = 5 := by
  refine ⟨?eqWei, ?neFive, aligned_five_gwei_budget⟩
  · simp [mutantBudgetRawWei, fiveGweiBatch, GWEI]
  · simp [mutantBudgetRawWei, fiveGweiBatch, GWEI]

/-- Honest aligned conversion still holds on that witness. -/
example : transitionBudget fiveGweiBatch fiveGweiCfg = 5 :=
  aligned_five_gwei_budget

end LidoSRv3.Tests.PackW2Topup2WeiMutants
