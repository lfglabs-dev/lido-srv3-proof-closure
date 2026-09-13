import LidoSRv3.Audit.Source.Topup2Uint64BoundsSource

/-! # P-TOPUP-2 pinned per-allocation guard source model

**General rule (Thomas 2026-09-13, real derivation of the pinned
StakingRouter.topUp:729 `AllocationExceedsLimit` per-allocation
guard.)**

Chantier 4 (per mandate): the pinned StakingRouter.topUp:729
guard checks each per-allocation limit at
`AllocationExceedsLimit(allocation, limit)` — allocation ≤ cap * 1
gwei, where cap = `_evaluateTopUpLimit(...)` from the gateway.

This composition names the per-allocation guard as a source-level
function of the allocation amount and the pinned per-key cap.
Downstream P-TOPUP-2 consumers can now enforce the per-allocation
line-729 check via a named source-level guard rather than a free
Bool.

**Status:** first real derivation of the pinned per-allocation
guard. -/

namespace LidoSRv3.Audit.Source.Topup2PerAllocGuardSource

open LidoSRv3.Audit.Source.Topup2Uint64BoundsSource

/-- Pinned per-allocation guard: `allocation ≤ perKeyCapGwei * 10^9`. -/
def perAllocationWithinCap
    (allocationWei perKeyCapGwei : Nat) : Bool :=
  decide (allocationWei ≤ perKeyCapGwei * gweiToWeiFactor)

/-- Under the pinned "allocation ≤ cap*gwei" premise, the guard
passes. Real derivation. -/
theorem perAllocationWithinCap_true_of_le
    {allocationWei perKeyCapGwei : Nat}
    (hLe : allocationWei ≤ perKeyCapGwei * gweiToWeiFactor) :
    perAllocationWithinCap allocationWei perKeyCapGwei = true := by
  simp [perAllocationWithinCap, hLe]

/-- Under the pinned "allocation > cap*gwei" premise, the guard
fails. -/
theorem perAllocationWithinCap_false_of_gt
    {allocationWei perKeyCapGwei : Nat}
    (hGt : perKeyCapGwei * gweiToWeiFactor < allocationWei) :
    perAllocationWithinCap allocationWei perKeyCapGwei = false := by
  simp [perAllocationWithinCap]
  omega

/-- Under the pinned gateway-form premise (`perKeyCapGwei ≤ uint64Max`),
the effective per-allocation cap is bounded by allocationCap. -/
theorem perAllocationWithinCap_implies_le_allocationCap
    {allocationWei perKeyCapGwei : Nat}
    (hGuard : allocationWei ≤ perKeyCapGwei * gweiToWeiFactor)
    (hCapBounded : perKeyCapGwei ≤ uint64Max) :
    allocationWei ≤ allocationCap := by
  unfold allocationCap
  have h1 : perKeyCapGwei * gweiToWeiFactor ≤ uint64Max * gweiToWeiFactor :=
    Nat.mul_le_mul_right gweiToWeiFactor hCapBounded
  omega

end LidoSRv3.Audit.Source.Topup2PerAllocGuardSource
