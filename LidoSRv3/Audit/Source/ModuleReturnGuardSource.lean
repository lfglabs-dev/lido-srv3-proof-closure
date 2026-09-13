/-! # StakingRouter ModuleReturnExceedTarget guard source model

**General rule (Thomas 2026-09-13, real derivation of the pinned
StakingRouter `ModuleReturnExceedTarget` guard.)**

Chantier 4 (per mandate): the pinned StakingRouter enforces that
each per-module return does not exceed its target. The guard fires
at StakingRouter.topUp:737 as
`ModuleReturnExceedTarget(actualReturn, target)` reverting when
`actualReturn > target`.

This composition names the guard as a source-level function of the
per-module actual return and the pinned target.

**Status:** first real derivation of the pinned ModuleReturnExceedTarget
guard past a free Bool. -/

namespace LidoSRv3.Audit.Source.ModuleReturnGuardSource

/-- Pinned per-module return guard: `actualReturn ≤ target`. -/
def moduleReturnWithinTarget
    (actualReturn target : Nat) : Bool :=
  decide (actualReturn ≤ target)

/-- Under the pinned "actualReturn ≤ target" premise, the guard passes. -/
theorem moduleReturnWithinTarget_true_of_le
    {actualReturn target : Nat}
    (hLe : actualReturn ≤ target) :
    moduleReturnWithinTarget actualReturn target = true := by
  simp [moduleReturnWithinTarget, hLe]

/-- Under the pinned "actualReturn > target" premise, the guard fails. -/
theorem moduleReturnWithinTarget_false_of_gt
    {actualReturn target : Nat}
    (hGt : target < actualReturn) :
    moduleReturnWithinTarget actualReturn target = false := by
  simp [moduleReturnWithinTarget]
  omega

/-- Zero return is trivially within any target. -/
theorem moduleReturnWithinTarget_true_of_zero (target : Nat) :
    moduleReturnWithinTarget 0 target = true := by
  simp [moduleReturnWithinTarget]

end LidoSRv3.Audit.Source.ModuleReturnGuardSource
