import LidoSRv3.Audit.Source.SolidityMinSource
import LidoSRv3.Audit.Source.Topup2Uint64BoundsSource

/-! # StakingRouter.topUp:703 min(alloc, cap*1 gwei) source model

**General rule (Thomas 2026-09-13, real derivation of the pinned
StakingRouter.topUp:703 `min(alloc, cap * 1 gwei)` clamp step.)**

Chantier 4 (per mandate): the pinned StakingRouter.topUp at line 703
clamps each per-key allocation to `min(alloc, cap * 1 gwei)`, where
`cap` is the gateway-supplied per-key cap. This composition names
the clamp step as `minAllocCap alloc capGwei = min alloc (capGwei *
10^9)`.

**Status:** first real derivation of the pinned line-703 min-clamp
step past a free Nat, with the standard min-le properties. -/

namespace LidoSRv3.Audit.Source.Topup2MinClampSource

open LidoSRv3.Audit.Source.SolidityMinSource
open LidoSRv3.Audit.Source.Topup2Uint64BoundsSource

/-- Pinned min-clamp step: `min(alloc, cap * 10^9)`. -/
def minAllocCap (alloc capGwei : Nat) : Nat :=
  minU alloc (capGwei * gweiToWeiFactor)

/-- The clamped value is at most the input allocation. -/
theorem minAllocCap_le_alloc (alloc capGwei : Nat) :
    minAllocCap alloc capGwei ≤ alloc := by
  unfold minAllocCap
  exact minU_le_left alloc (capGwei * gweiToWeiFactor)

/-- The clamped value is at most the pinned cap * gwei. -/
theorem minAllocCap_le_cap (alloc capGwei : Nat) :
    minAllocCap alloc capGwei ≤ capGwei * gweiToWeiFactor := by
  unfold minAllocCap
  exact minU_le_right alloc (capGwei * gweiToWeiFactor)

/-- Under the pinned gateway-form premise (`capGwei ≤ uint64Max`),
the clamped value is at most allocationCap. -/
theorem minAllocCap_le_allocationCap
    {alloc capGwei : Nat}
    (hCapBounded : capGwei ≤ uint64Max) :
    minAllocCap alloc capGwei ≤ allocationCap := by
  have h1 : minAllocCap alloc capGwei ≤ capGwei * gweiToWeiFactor :=
    minAllocCap_le_cap alloc capGwei
  have h2 : capGwei * gweiToWeiFactor ≤ uint64Max * gweiToWeiFactor :=
    Nat.mul_le_mul_right gweiToWeiFactor hCapBounded
  unfold allocationCap
  omega

end LidoSRv3.Audit.Source.Topup2MinClampSource
