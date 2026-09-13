import LidoSRv3.Audit.Source.StakingModuleRegistrySource

/-! # Kill-lines for `StakingModuleRegistrySource`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned SR registry state invariants.**

`StakingModuleRegistrySource` defines:
- `moduleCountFromRegistry` = `state.moduleCount` projection.
- `moduleCount_bounded_of_registry_state`: `moduleCount ≤ 32` by
  construction.
- `moduleFields_bounded_by_uint64`: four-field uint64 bounds.
- `SRMonotonicityInvariant`: `max(summary, accounting) ≤ deposited`.

These kill-lines pin each invariant and demonstrate boundary cases. -/

namespace LidoSRv3.Tests.StakingModuleRegistryKillLines

open LidoSRv3.Audit.Source.StakingModuleRegistrySource

/-- **Kill-line: registry with exactly 32 modules is admitted.** -/
theorem registry_at_max :
    moduleCountFromRegistry ⟨32, by decide⟩ = 32 := rfl

/-- **Kill-line: empty registry is admitted.** -/
theorem registry_at_zero :
    moduleCountFromRegistry ⟨0, by decide⟩ = 0 := rfl

/-- **Kill-line: uint64Max is exactly 2^64 - 1.** -/
theorem uint64Max_pinned :
    uint64Max = 2 ^ 64 - 1 := rfl

/-- **Kill-line: monotonicity invariant at boundary.**

At `deposited = 100, summary = 100, accounting = 50`, the invariant
holds: `max(100, 50) = 100 ≤ 100`. -/
theorem monotonicity_at_boundary :
    SRMonotonicityInvariant
      { depositedCount := 100
        depositableCount := 0
        summaryExitedCount := 100
        accountingExitedCount := 50
        depositedBounded := by unfold uint64Max; decide
        depositableBounded := by decide
        summaryExitedBounded := by unfold uint64Max; decide
        accountingExitedBounded := by decide } := by
  unfold SRMonotonicityInvariant
  decide

/-- **Kill-line: monotonicity is decidable at concrete witness.**

Boundary : exit counts equal deposited count. -/
theorem monotonicity_at_zero :
    SRMonotonicityInvariant
      { depositedCount := 0
        depositableCount := 0
        summaryExitedCount := 0
        accountingExitedCount := 0
        depositedBounded := by decide
        depositableBounded := by decide
        summaryExitedBounded := by decide
        accountingExitedBounded := by decide } := by
  unfold SRMonotonicityInvariant
  decide

#print axioms registry_at_max
#print axioms registry_at_zero
#print axioms uint64Max_pinned
#print axioms monotonicity_at_boundary
#print axioms monotonicity_at_zero

end LidoSRv3.Tests.StakingModuleRegistryKillLines
