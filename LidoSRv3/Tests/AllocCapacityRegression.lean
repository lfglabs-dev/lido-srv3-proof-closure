import LidoSRv3.Audit.Model.AllocCapacity

/-! Concrete negative mutants for the canonical P-ALLOC-1 semantics. Each
regression becomes false if the named source construct is replaced by its
mutant. -/

namespace LidoSRv3.Tests.AllocCapacityRegression

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

def cfg : Config := ⟨32, 64⟩

def activeModule : Module := {
  moduleId := 7, shareLimit := 5000, isActive := true, isType2 := false
  depositableCount := 90, depositedCount := 10, summaryExitedCount := 0
  accountingExitedCount := 0, totalModuleStake := 0
}

def inactiveModule : Module := {
  activeModule with moduleId := 8, shareLimit := 1000, isActive := false
}

/-- Mutant: remove `Math.min` and retain the available-capacity operand. -/
theorem min_clamp_mutant_rejected :
    (execute cfg [activeModule] 10 false).map
      (fun rows => rows.map Row.capacity) = some [10] ∧
    (execute cfg [activeModule] 10 false).map
      (fun rows => rows.map Row.capacity) ≠ some [100] := by native_decide

/-- Mutant: run the active branch for an inactive module. -/
theorem active_guard_mutant_rejected :
    (execute cfg [inactiveModule] 10 false).map
      (fun rows => rows.map Row.capacity) = some [10] ∧
    (execute cfg [inactiveModule] 10 false).map
      (fun rows => rows.map Row.capacity) ≠ some [2] := by native_decide

/-- Mutant: reverse the router-provided module order. -/
theorem router_order_mutant_rejected :
    (execute cfg [activeModule, inactiveModule] 10 false).map
      (fun rows => rows.map Row.moduleId) = some [7, 8] ∧
    (execute cfg [activeModule, inactiveModule] 10 false).map
      (fun rows => rows.map Row.moduleId) ≠ some [8, 7] := by native_decide

/-- Mutant: replace Solidity checked addition by wrapping word addition. -/
theorem uint256_bound_mutant_rejected :
    execute cfg [activeModule]
      (Verity.Core.Uint256.ofNat MAX_UINT256) false = none ∧
    (Verity.Core.Uint256.ofNat MAX_UINT256 + 10 : Uint256) = 9 := by native_decide

end LidoSRv3.Tests.AllocCapacityRegression
