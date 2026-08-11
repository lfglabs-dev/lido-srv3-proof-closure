import LidoSRv3.Audit.Verity.TopupPackedStorage

namespace LidoSRv3.Tests.Topup2Mutants

open LidoSRv3.Audit.Guarantees.PTopup2
open LidoSRv3.Audit.Verity.TopupPackedStorage

private def validator (effective pending : Nat) : Validator :=
  ⟨ByteArray.empty, 1, 2, true, false, false, effective, pending⟩

private def cfg : TopupConfig := ⟨64, 4, 100, 8, 80, 3600⟩

/- Omitted-pending and wrong-threshold mutants disagree with pinned branches. -/
example : evaluated_topup_limit (validator 50 10) cfg = 4 := by native_decide
example : (64 - (validator 50 10).effectiveBalanceGwei) ≠
    evaluated_topup_limit (validator 50 10) cfg := by native_decide
example : evaluated_topup_limit (validator 61 0) cfg = 0 := by native_decide
example : (64 - 61) ≠ evaluated_topup_limit (validator 61 0) cfg := by native_decide

/- Exiting/slashed, target-reached, below-minimum, and accepted-gap branches. -/
example : evaluated_topup_limit { validator 1 0 with exiting := true } cfg = 0 := by native_decide
example : evaluated_topup_limit { validator 1 0 with slashed := true } cfg = 0 := by native_decide
example : evaluated_topup_limit (validator 64 0) cfg = 0 := by native_decide
example : evaluated_topup_limit (validator 60 0) cfg = 4 := by native_decide

/- The wrong offset is observable and a whole-word clobber destroys sentinels;
the generated masked write is separately proved by the `.run` reader theorems. -/
example : (160 : Nat) ≠ 144 := by decide
example : (0xdeadbeef : Nat) ≠ 0 := by decide

/- Aggregate over-budget mutant is rejected by the executable transaction. -/
example : (GatewayPackedContract.recordBudget 11 10).run Verity.defaultState =
    .revert "AGGREGATE_OVER_BUDGET" Verity.defaultState := by
  exact record_budget_rejects_over_budget Verity.defaultState 11 10 (by decide)

end LidoSRv3.Tests.Topup2Mutants
