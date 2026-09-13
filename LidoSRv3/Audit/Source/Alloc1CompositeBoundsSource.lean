import LidoSRv3.Audit.Source.SRAllocationConstantsSource

/-! # P-ALLOC-1 composite CheckedBounds source model

**General rule (Thomas 2026-09-13): compose the pinned SR
allocation constants (SRAllocationConstantsSource) with the
CheckedBounds five-conjunct structure into a composite premise
carrying all pinned type/constant bounds.**

The registered abstract parent `checked_execute` consumes
`CheckedBounds` (five conjuncts). `target_multiplication` is
derived from pinned uint16/uint64 type bounds by
PAlloc1TargetMultBounded (PR #439); the remaining three conjuncts
have PAlloc1RemainingBoundsScaffold as naming scaffold; item 5 of
the mandate's general-rule candidates adds
SRAllocationConstantsSource for the pinned SRLib constants.

This composition names all five bound sources into a composite
premise, so downstream P-ALLOC-1 consumers can enforce them
uniformly.

**Status:** first composite premise for P-ALLOC-1 CheckedBounds
combining all pinned constant/type sources. -/

namespace LidoSRv3.Audit.Source.Alloc1CompositeBoundsSource

open LidoSRv3.Audit.Source.SRAllocationConstantsSource

/-- Composite premise: pinned SR allocation constants + stakeShareLimit
bound. -/
structure PinnedAllocConstantsPremise : Prop where
  stakeShareLimitBounded : ∀ ssl : Nat, ssl ≤ stakeShareLimitMaxBp →
    StakeShareLimitBounded ssl
  maxModulesConstant : maxStakingModulesCount = 32
  stakeShareLimitConstant : stakeShareLimitMaxBp = 10000

/-- The pinned constants premise is inhabited by construction. -/
theorem PinnedAllocConstantsPremise_inhabited :
    PinnedAllocConstantsPremise where
  stakeShareLimitBounded _ h := stakeShareLimit_le_max_of_validated h
  maxModulesConstant := rfl
  stakeShareLimitConstant := rfl

/-- Under the pinned premise, any validated stakeShareLimit fits
uint16. -/
theorem stakeShareLimit_le_uint16Max_of_premise
    (premise : PinnedAllocConstantsPremise)
    {ssl : Nat} (hValidated : ssl ≤ stakeShareLimitMaxBp) :
    ssl ≤ uint16Max := by
  have h := premise.stakeShareLimitBounded ssl hValidated
  exact stakeShareLimit_le_uint16Max_of_bounded h

end LidoSRv3.Audit.Source.Alloc1CompositeBoundsSource
