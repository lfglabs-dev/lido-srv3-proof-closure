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

/-- Kill-line: raw `valueWei` on the five-gwei witness is `5 * 10^9 ≠ 5`.
The honest conversion is `valueWei / GWEI = 5`. -/
theorem raw_valueWei_mutant_on_five_gwei_eq_five_billion_ne_five :
    mutantBudgetRawWei alignedFiveGweiBatch = 5 * 10 ^ 9 ∧
      mutantBudgetRawWei alignedFiveGweiBatch ≠ 5 ∧
      transitionBudget alignedFiveGweiBatch alignedFiveGweiCfg = 5 := by
  refine ⟨?eqWei, ?neFive, aligned_five_gwei_budget⟩
  · simp [mutantBudgetRawWei, alignedFiveGweiBatch, GWEI]
  · simp [mutantBudgetRawWei, alignedFiveGweiBatch, GWEI]

/-- Honest aligned conversion still holds on that witness. -/
example : transitionBudget alignedFiveGweiBatch alignedFiveGweiCfg = 5 :=
  aligned_five_gwei_budget

end LidoSRv3.Tests.PackW2Topup2WeiMutants
