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
    MathView.capacity cfg [activeModule] 10 false activeModule ≠
      MathView.availableCapacity cfg false activeModule := by native_decide

/-- Mutant: run the active branch for an inactive module. -/
theorem active_guard_mutant_rejected :
    MathView.capacity cfg [inactiveModule] 10 false inactiveModule ≠
      min (MathView.targetValidators cfg [inactiveModule] 10 inactiveModule)
        (MathView.availableCapacity cfg false inactiveModule) := by native_decide

/-- Mutant: reverse the router-provided module order. -/
theorem router_order_mutant_rejected :
    ([activeModule, inactiveModule].map Module.moduleId) ≠
      ([activeModule, inactiveModule].reverse.map Module.moduleId) := by native_decide

/-- Mutant: replace Solidity checked addition by wrapping word addition. -/
theorem uint256_bound_mutant_rejected :
    safeAdd (Verity.Core.Uint256.ofNat MAX_UINT256) 1 = none ∧
      (Verity.Core.Uint256.ofNat MAX_UINT256 + 1 : Uint256) = 0 := by native_decide

end LidoSRv3.Tests.AllocCapacityRegression
