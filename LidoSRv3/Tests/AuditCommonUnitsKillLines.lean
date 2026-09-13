import LidoSRv3.Audit.Common.Units

/-! # Kill-lines for `Audit.Common.Amount` unit-aware Nat quantities

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Wave 0 unit-aware Amount type carrying a phantom unit tag on Nat. -/

namespace LidoSRv3.Tests.AuditCommonUnitsKillLines

open LidoSRv3.Audit.Common
open LidoSRv3.Audit.Common.Amount

/-- **Kill-line: `Amount.zero.value = 0` for any unit.** -/
theorem zero_value_wei : (zero : Wei).value = 0 := rfl
theorem zero_value_gwei : (zero : Gwei).value = 0 := rfl
theorem zero_value_validators : (zero : Validators).value = 0 := rfl
theorem zero_value_basisPoints : (zero : BasisPoints).value = 0 := rfl

/-- **Kill-line: `Amount.add` is addition on the underlying values.** -/
theorem add_zero_wei :
    (add (zero : Wei) zero).value = 0 := rfl

theorem add_composition (unit : Type) (a b : Amount unit) :
    (add a b).value = a.value + b.value := rfl

/-- **Kill-line: `Amount.add` is commutative on values (via Nat).** -/
theorem add_comm_values (unit : Type) (a b : Amount unit) :
    (add a b).value = (add b a).value := by
  simp [add, Nat.add_comm]

/-- **Kill-line: `Amount.add` is associative on values (via Nat).** -/
theorem add_assoc_values (unit : Type) (a b c : Amount unit) :
    (add (add a b) c).value = (add a (add b c)).value := by
  simp [add, Nat.add_assoc]

/-- **Kill-line: `Amount.add x zero` = value of x.** -/
theorem add_zero_right (unit : Type) (a : Amount unit) :
    (add a zero).value = a.value := by
  simp [add, zero]

/-- **Kill-line: `Amount.add zero x` = value of x.** -/
theorem add_zero_left (unit : Type) (a : Amount unit) :
    (add zero a).value = a.value := by
  simp [add, zero]

#print axioms zero_value_wei
#print axioms zero_value_gwei
#print axioms add_composition
#print axioms add_comm_values
#print axioms add_assoc_values
#print axioms add_zero_right
#print axioms add_zero_left

end LidoSRv3.Tests.AuditCommonUnitsKillLines
