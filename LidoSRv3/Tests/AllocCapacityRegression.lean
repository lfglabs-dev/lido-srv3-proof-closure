import LidoSRv3.Audit.Source.AllocCapacityCorrespondence
import LidoSRv3.Audit.Guarantees.PAlloc1AvailableArithmeticBounded

/-! Concrete negative mutants for the canonical P-ALLOC-1 semantics. Each
regression becomes false if the named source construct is replaced by its
mutant. -/

namespace LidoSRv3.Tests.AllocCapacityRegression

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.SolidityAllocCapacity

def cfg : Config := ⟨32, 64⟩

/-- Values from scripts/upgrade/upgrade-params-mainnet.toml at the Solidity pin.
These are wei amounts. The former uint64 bound excluded this configuration. -/
def mainnetConfig : Config := ⟨32000000000000000000, 2048000000000000000000⟩

theorem mainnet_effective_balance_bounds :
    mainnetConfig.maxEBType1 ≠ 0 ∧
    (mainnetConfig.maxEBType2 : Nat) >
      Audit.Guarantees.PAlloc1AvailableArithmeticBounded.uint64Max ∧
    (mainnetConfig.maxEBType2 : Nat) ≤
      Audit.Guarantees.PAlloc1AvailableArithmeticBounded.uint128Max := by decide

/-- A nonempty type-2 top-up input satisfies the revised arithmetic structure
with the actual configured balances. This is not a deployed-module invariant. -/
theorem mainnet_available_bounds_example :
    Audit.Guarantees.PAlloc1AvailableArithmeticBounded.PinnedAvailableArithmeticBounds
      mainnetConfig
      [{ moduleId := 1, shareLimit := 10000, isActive := true, isType2 := true,
         depositableCount := 1, depositedCount := 1, summaryExitedCount := 0,
         accountingExitedCount := 0, totalModuleStake := 32000000000000000000 }] true := by
  constructor <;> simp [mainnetConfig, MathView.activeCount, MathView.allocationEntry,
    Audit.Guarantees.PAlloc1AvailableArithmeticBounded.uint64Max,
    Audit.Guarantees.PAlloc1AvailableArithmeticBounded.uint128Max] <;> decide

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
    (LidoSRv3.Audit.SolidityAllocCapacity.execute cfg [activeModule] 10 false).map
      (fun rows => rows.map Row.capacity) = some [10] ∧
    (LidoSRv3.Audit.SolidityAllocCapacity.execute cfg [activeModule] 10 false).map
      (fun rows => rows.map Row.capacity) ≠ some [100] := by native_decide

/-- Mutant: run the active branch for an inactive module. -/
theorem active_guard_mutant_rejected :
    (LidoSRv3.Audit.SolidityAllocCapacity.execute cfg [inactiveModule] 10 false).map
      (fun rows => rows.map Row.capacity) = some [10] ∧
    (LidoSRv3.Audit.SolidityAllocCapacity.execute cfg [inactiveModule] 10 false).map
      (fun rows => rows.map Row.capacity) ≠ some [2] := by native_decide

/-- Mutant: reverse the router-provided module order. -/
theorem router_order_mutant_rejected :
    (LidoSRv3.Audit.SolidityAllocCapacity.execute cfg [activeModule, inactiveModule] 10 false).map
      (fun rows => rows.map Row.moduleId) = some [7, 8] ∧
    (LidoSRv3.Audit.SolidityAllocCapacity.execute cfg [activeModule, inactiveModule] 10 false).map
      (fun rows => rows.map Row.moduleId) ≠ some [8, 7] := by native_decide

/-- Mutant: replace Solidity checked addition by wrapping word addition. -/
theorem uint256_bound_mutant_rejected :
    LidoSRv3.Audit.SolidityAllocCapacity.execute cfg [activeModule]
      (Verity.Core.Uint256.ofNat MAX_UINT256) false = none ∧
    (Verity.Core.Uint256.ofNat MAX_UINT256 + 10 : Uint256) = 9 := by native_decide

end LidoSRv3.Tests.AllocCapacityRegression
