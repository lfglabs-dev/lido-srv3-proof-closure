import LidoSRv3.Audit.Guarantees.PTopup2

/-!
# Wave 2 W2-TOPUP2-WEI: abstract `valueWei / GWEI` child

Unregistered child of `PTopup2.transitionBudget`. It records that the
leftover-budget walk already consumes wei divided by `GWEI`, and that an
aligned five-gwei call with large module/block caps budgets to 5.

This is the abstract Nat conversion already in `transitionBudget`. It does
not connect SSZ, `allocateDeposits`, or a live gateway. No new guarantee
ID. `A-TOPUP-BEACON-ADDRESS` stays OPEN.
-/

namespace LidoSRv3.Audit.Spec.Topup2WeiConversionChild

open LidoSRv3.Audit.Guarantees
open PTopup2

/-- Aligned wei is recovered by dividing by `GWEI`. -/
theorem valueWei_div_gwei_of_aligned (gwei : Nat) :
    (gwei * GWEI) / GWEI = gwei :=
  Nat.mul_div_cancel gwei (by decide : GWEI ≠ 0)

/-- `transitionBudget` is exactly `min (valueWei / GWEI) (min module block)`.
This is the definition; the `/ GWEI` is load-bearing, not a comment. -/
theorem transitionBudget_uses_wei_div_gwei (b : TopupBatch) (cfg : TopupConfig) :
    transitionBudget b cfg =
      min (b.valueWei / GWEI) (min cfg.moduleAllocationLimitGwei cfg.maxTopUpPerBlockGwei) :=
  rfl

/-- Concrete: `valueWei = 5 * GWEI`, module and block caps large → budget = 5. -/
theorem aligned_five_gwei_budget :
    let b : TopupBatch := { validators := [], requestedGwei := [], allocations := [],
      valueWei := 5 * GWEI, beaconRootTimestamp := 0, currentTimestamp := 0 }
    let cfg : TopupConfig := { targetBalanceGwei := 0, minTopUpGwei := 0,
      maxTopUpPerBlockGwei := 100, maxValidatorsPerCall := 1,
      moduleAllocationLimitGwei := 100, maxRootAge := 0 }
    transitionBudget b cfg = 5 := by
  simp [transitionBudget]
  rw [valueWei_div_gwei_of_aligned]
  decide

end LidoSRv3.Audit.Spec.Topup2WeiConversionChild
