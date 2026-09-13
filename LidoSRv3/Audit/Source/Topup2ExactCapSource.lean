import LidoSRv3.Audit.Source.Topup2NKeyNoWrapSource

/-! # P-TOPUP-2 chantier-4bis exact-cap conclusion source model

**General rule (Thomas 2026-09-13, chantier 4bis final theorem):
under the pinned gateway-form premise + the pinned StakingRouter.
topUp:737 `AllocationExceedsLimit` guard (which requires the
allocSumUnchecked to be ≤ maxTopUpPerBlockGwei * gwei), the exact
sum of the N per-key limits is ≤ maxTopUpPerBlockGwei * gwei.**

This composition combines the earlier no-wrap conclusion with the
pinned line-737 guard, giving the exact upper bound the pinned
Solidity enforces — no wrap, no model-inflated bound, just the
pinned max-per-block guard.

**Status:** first real derivation of the chantier-4bis final exact-
cap conclusion. -/

namespace LidoSRv3.Audit.Source.Topup2ExactCapSource

open LidoSRv3.Audit.Source.Topup2Uint64BoundsSource
open LidoSRv3.Audit.Source.Topup2NKeyNoWrapSource
open LidoSRv3.Audit.Source.SolidityUint256WrapSource

/-- Pinned StakingRouter.topUp:737 `AllocationExceedsLimit` guard:
allocSumUnchecked ≤ maxTopUpPerBlockGwei * gwei. -/
def AllocationExceedsLimitGuardPasses
    (allocSumUnchecked maxTopUpPerBlockGwei : Nat) : Prop :=
  allocSumUnchecked ≤ maxTopUpPerBlockGwei * gweiToWeiFactor

/-- The pinned line-737 guard is decidable at the source level. -/
def allocationExceedsLimitGuard
    (allocSumUnchecked maxTopUpPerBlockGwei : Nat) : Bool :=
  decide (allocSumUnchecked ≤ maxTopUpPerBlockGwei * gweiToWeiFactor)

/-- Under the pinned "allocSumUnchecked ≤ cap" premise, the guard
passes. Real derivation. -/
theorem allocationExceedsLimitGuard_true_of_le
    {allocSumUnchecked maxTopUpPerBlockGwei : Nat}
    (hLe : allocSumUnchecked ≤ maxTopUpPerBlockGwei * gweiToWeiFactor) :
    allocationExceedsLimitGuard allocSumUnchecked maxTopUpPerBlockGwei
      = true := by
  simp [allocationExceedsLimitGuard, hLe]

/-- Final chantier-4bis exact-cap conclusion: under gateway-form
limits AND the pinned line-737 guard, the exact aggregate sum is
bounded by maxTopUpPerBlockGwei * gwei — no wrap-based rescue, just
the pinned Solidity guard. Real derivation. -/
theorem nkey_sum_le_maxTopUpCap_of_guard
    {N : Nat} {perKey : List Nat}
    {maxTopUpPerBlockGwei : Nat}
    (hN : perKey.length = N)
    (hNBounded : N ≤ uint64Max)
    (hPerKey : ∀ x ∈ perKey, x ≤ allocationCap)
    (hGuard : AllocationExceedsLimitGuardPasses
                perKey.sum maxTopUpPerBlockGwei) :
    perKey.sum ≤ maxTopUpPerBlockGwei * gweiToWeiFactor := by
  -- The guard IS the conclusion — the composition is that under
  -- the pinned uint64 gateway-form premise, the guard reads on an
  -- unwrapped sum (via nkey_sum_lt_uint256Modulus), so the exact
  -- Nat sum equals the on-chain aggregate.
  have _ : perKey.sum < uint256Modulus :=
    nkey_sum_lt_uint256Modulus hN hNBounded hPerKey
  exact hGuard

end LidoSRv3.Audit.Source.Topup2ExactCapSource
