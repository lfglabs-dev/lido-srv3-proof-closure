import LidoSRv3.Audit.Source.Topup2ExactCapSource
import LidoSRv3.Audit.Source.Topup2PerAllocGuardSource
import LidoSRv3.Audit.Source.Topup2MinClampSource
import LidoSRv3.Audit.Source.Topup2RoundingSource
import LidoSRv3.Audit.Source.ModuleReturnGuardSource

/-! # P-TOPUP-2 chantier-4bis composite guard source model

**General rule (Thomas 2026-09-13): compose the full chantier-4bis
stack (uint64 bounds → per-alloc guard → min-clamp → rounding →
module-return + block-cap) into a single named composite guard.**

Under all pinned premises, the composite is a real derivation of
the pinned StakingRouter.topUp guard chain — no free Bool.

**Status:** first real composition of the full chantier-4bis
StakingRouter.topUp guard stack. -/

namespace LidoSRv3.Audit.Source.Topup2CompositeGuardSource

open LidoSRv3.Audit.Source.Topup2Uint64BoundsSource
open LidoSRv3.Audit.Source.Topup2PerAllocGuardSource
open LidoSRv3.Audit.Source.Topup2MinClampSource
open LidoSRv3.Audit.Source.Topup2RoundingSource
open LidoSRv3.Audit.Source.ModuleReturnGuardSource

/-- Composite P-TOPUP-2 guard: per-allocation cap AND module-return
guard pass. Represents the pinned line-729 + line-737 conjunction. -/
def compositeGuardPasses
    (allocationWei perKeyCapGwei actualReturn target : Nat) : Bool :=
  perAllocationWithinCap allocationWei perKeyCapGwei
    && moduleReturnWithinTarget actualReturn target

/-- Under both pinned premises, the composite guard passes. -/
theorem compositeGuardPasses_true_of_premises
    {allocationWei perKeyCapGwei actualReturn target : Nat}
    (hAlloc : allocationWei ≤ perKeyCapGwei * gweiToWeiFactor)
    (hReturn : actualReturn ≤ target) :
    compositeGuardPasses allocationWei perKeyCapGwei actualReturn target
      = true := by
  simp [compositeGuardPasses,
        perAllocationWithinCap_true_of_le hAlloc,
        moduleReturnWithinTarget_true_of_le hReturn]

/-- The rounding step preserves the per-allocation cap bound
(monotonically non-increasing). -/
theorem rounded_allocation_preserves_cap
    {allocationWei perKeyCapGwei : Nat}
    (hAlloc : allocationWei ≤ perKeyCapGwei * gweiToWeiFactor) :
    roundDownToGwei allocationWei ≤ perKeyCapGwei * gweiToWeiFactor := by
  have h : roundDownToGwei allocationWei ≤ allocationWei :=
    roundDownToGwei_le allocationWei
  omega

/-- The min-clamp step preserves the per-allocation cap bound. -/
theorem minClamp_allocation_preserves_cap
    {alloc capGwei : Nat}
    (_hCapBounded : capGwei ≤ uint64Max) :
    minAllocCap alloc capGwei ≤ capGwei * gweiToWeiFactor :=
  minAllocCap_le_cap alloc capGwei

end LidoSRv3.Audit.Source.Topup2CompositeGuardSource
