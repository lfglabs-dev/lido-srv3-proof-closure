import LidoSRv3.Audit.Source.Alloc1CompositeBoundsSource

/-! # Kill-lines for `Alloc1CompositeBoundsSource`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the composite P-ALLOC-1 CheckedBounds premise (SR allocation
constants + type-width bounds).** -/

namespace LidoSRv3.Tests.Alloc1CompositeBoundsKillLines

open LidoSRv3.Audit.Source.Alloc1CompositeBoundsSource
open LidoSRv3.Audit.Source.SRAllocationConstantsSource

/-- **Kill-line: `PinnedAllocConstantsPremise` is inhabited.**

A mutant that dropped one of the three conjuncts would fail this
by-construction proof. -/
theorem pinnedAllocConstantsPremise_inhabited_kill :
    PinnedAllocConstantsPremise :=
  PinnedAllocConstantsPremise_inhabited

/-- **Kill-line: the pinned MAX_STAKING_MODULES_COUNT constant is 32.**

Read from the premise's `maxModulesConstant` field. -/
theorem pinned_maxModules_constant :
    PinnedAllocConstantsPremise_inhabited.maxModulesConstant.symm.trans rfl =
      (rfl : maxStakingModulesCount = 32) :=
  rfl

/-- **Kill-line: the pinned STAKE_SHARE_LIMIT_MAX_BP constant is 10000.**

Read from the premise's `stakeShareLimitConstant` field. -/
theorem pinned_stakeShareLimit_constant :
    PinnedAllocConstantsPremise_inhabited.stakeShareLimitConstant.symm.trans rfl =
      (rfl : stakeShareLimitMaxBp = 10000) :=
  rfl

/-- **Kill-line: any validated stakeShareLimit ≤ 10000 fits uint16.**

A mutant that changed the uint16 bound would refute this. -/
theorem pinned_stakeShareLimit_fits_uint16
    {ssl : Nat} (h : ssl ≤ stakeShareLimitMaxBp) :
    ssl ≤ uint16Max :=
  stakeShareLimit_le_uint16Max_of_premise
    PinnedAllocConstantsPremise_inhabited h

/-- **Kill-line: stakeShareLimit = 10000 (the max) fits uint16.** -/
theorem stakeShareLimit_max_fits_uint16 :
    stakeShareLimitMaxBp ≤ uint16Max :=
  pinned_stakeShareLimit_fits_uint16 (Nat.le_refl _)

#print axioms pinnedAllocConstantsPremise_inhabited_kill
#print axioms pinned_maxModules_constant
#print axioms pinned_stakeShareLimit_constant
#print axioms pinned_stakeShareLimit_fits_uint16
#print axioms stakeShareLimit_max_fits_uint16

end LidoSRv3.Tests.Alloc1CompositeBoundsKillLines
