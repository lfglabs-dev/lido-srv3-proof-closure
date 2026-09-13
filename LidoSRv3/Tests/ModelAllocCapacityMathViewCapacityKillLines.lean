import LidoSRv3.Audit.Model.AllocCapacity

/-! # Kill-lines for `Model.AllocCapacity.MathView.capacity` and `capacities`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-ALLOC-1 MathView capacity semantics: active module picks
min(target, available), inactive module falls back to allocationEntry. -/

namespace LidoSRv3.Tests.ModelAllocCapacityMathViewCapacityKillLines

open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.AllocCapacity.MathView

/-- Sample WC01 active module. -/
def activeModule : Module :=
  { moduleId := 1, shareLimit := 5000, isActive := true, isType2 := false,
    depositableCount := 100, depositedCount := 200,
    summaryExitedCount := 10, accountingExitedCount := 20,
    totalModuleStake := 0 }

/-- Sample WC01 *inactive* module. -/
def inactiveModule : Module := { activeModule with isActive := false }

/-- **Kill-line: `capacity` on active module = min(target, available).**

A mutant that swapped min for max, or dropped the active check,
would refute. -/
theorem capacity_active_composition (cfg : Config)
    (modules : List Module) (deposits : Verity.Uint256) (isTopUp : Bool)
    (m : Module) (h : m.isActive = true) :
    capacity cfg modules deposits isTopUp m =
      min (targetValidators cfg modules deposits m)
          (availableCapacity cfg isTopUp m) := by
  unfold capacity
  simp [h]

/-- **Kill-line: `capacity` on inactive module = allocationEntry.**

Inactive modules preserve their current allocation without any
new target/available min. -/
theorem capacity_inactive_composition (cfg : Config)
    (modules : List Module) (deposits : Verity.Uint256) (isTopUp : Bool)
    (m : Module) (h : m.isActive = false) :
    capacity cfg modules deposits isTopUp m = allocationEntry cfg m := by
  unfold capacity
  simp [h]

/-- **Kill-line: `capacities` on empty module list is empty.** -/
theorem capacities_empty (cfg : Config) (deposits : Verity.Uint256) (isTopUp : Bool) :
    capacities cfg [] deposits isTopUp = [] := rfl

/-- **Kill-line: `capacities` length equals input module count.** -/
theorem capacities_length (cfg : Config) (modules : List Module)
    (deposits : Verity.Uint256) (isTopUp : Bool) :
    (capacities cfg modules deposits isTopUp).length = modules.length := by
  simp [capacities]

/-- **Kill-line: `capacities` on singleton active WC01 module.**

The MathView calculation: targetValidators = 5000 * (0 + 180) / 10000
= 90. availableCapacity = 180 + 100 = 280. capacity = min(90, 280)
= 90. -/
theorem capacities_singleton_active_wc01 :
    capacities { maxEBType1 := 32, maxEBType2 := 2048 }
      [activeModule] 0 false = [90] := by decide

/-- **Kill-line: `capacities` on singleton inactive module falls back.** -/
theorem capacities_singleton_inactive :
    capacities { maxEBType1 := 32, maxEBType2 := 2048 }
      [inactiveModule] 0 false = [allocationEntry
        { maxEBType1 := 32, maxEBType2 := 2048 } inactiveModule] := by
  unfold capacities
  simp [capacity_inactive_composition _ _ _ _ inactiveModule rfl]

#print axioms capacity_active_composition
#print axioms capacity_inactive_composition
#print axioms capacities_empty
#print axioms capacities_length
#print axioms capacities_singleton_active_wc01
#print axioms capacities_singleton_inactive

end LidoSRv3.Tests.ModelAllocCapacityMathViewCapacityKillLines
