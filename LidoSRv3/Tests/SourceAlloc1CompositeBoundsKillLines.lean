import LidoSRv3.Audit.Source.Alloc1CompositeBoundsSource

/-!
Kill-lines pinning `Source.Alloc1CompositeBoundsSource` composite
CheckedBounds premise structure — pinned SR allocation-constant
bounds plus the derived uint16 fit.
-/

namespace LidoSRv3.Tests.SourceAlloc1CompositeBoundsKillLines

open LidoSRv3.Audit.Source.Alloc1CompositeBoundsSource
open LidoSRv3.Audit.Source.SRAllocationConstantsSource

/-! ## Pinned SR allocation constants. -/

theorem maxStakingModulesCount_val : maxStakingModulesCount = 32 := rfl

theorem stakeShareLimitMaxBp_val : stakeShareLimitMaxBp = 10000 := rfl

/-! ## Composite premise passthrough — one field per pinned constant. -/

theorem premise_maxModulesConstant
    (premise : PinnedAllocConstantsPremise) :
    maxStakingModulesCount = 32 :=
  premise.maxModulesConstant

theorem premise_stakeShareLimitConstant
    (premise : PinnedAllocConstantsPremise) :
    stakeShareLimitMaxBp = 10000 :=
  premise.stakeShareLimitConstant

/-! ## Inhabitation of the composite premise. -/

theorem premise_inhabited_restated :
    PinnedAllocConstantsPremise :=
  PinnedAllocConstantsPremise_inhabited

/-! ## Under the premise, any validated stakeShareLimit fits uint16. -/

theorem stakeShareLimit_le_uint16Max_of_premise_restated
    (premise : PinnedAllocConstantsPremise)
    {ssl : Nat} (hValidated : ssl ≤ stakeShareLimitMaxBp) :
    ssl ≤ uint16Max :=
  stakeShareLimit_le_uint16Max_of_premise premise hValidated

/-! ## Concrete stakeShareLimit witnesses. -/

theorem stakeShareLimit_zero_fits_uint16 :
    (0 : Nat) ≤ uint16Max := by decide

theorem stakeShareLimit_max_fits_uint16 :
    (10000 : Nat) ≤ uint16Max := by decide

theorem stakeShareLimit_between_fits_uint16 :
    (5000 : Nat) ≤ uint16Max := by decide

end LidoSRv3.Tests.SourceAlloc1CompositeBoundsKillLines
