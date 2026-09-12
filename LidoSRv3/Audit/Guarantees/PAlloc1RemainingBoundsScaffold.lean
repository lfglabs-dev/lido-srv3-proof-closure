import LidoSRv3.Audit.Model.AllocCapacity

/-! # P-ALLOC-1 remaining CheckedBounds conjuncts naming scaffold

**General rule (Thomas 2026-09-12), applied to ALLOC-1 CheckedBounds
three remaining conjuncts.**

The registered abstract parent `checked_execute` consumes
`CheckedBounds` (five conjuncts). Conjunct 5
(`target_multiplication`) is already derived from pinned uint16/
uint64 type bounds by `PAlloc1TargetMultBounded` (PR #439). This
module names the pinned invariants for the three remaining
conjuncts:

- `active_subtraction` — SRStorage `addValidators` /
  `_updateExitedCounters` monotonicity invariant.
- `total_addition` — `MAX_STAKING_MODULES_COUNT = 32` + per-module
  uint64 `allocationEntry` bound.
- `available_arithmetic` — uint64 bounds on `activeCount` and
  `depositableCount`.

**Status: naming scaffold, not a full composition.** The three
derivation theorems are trivial projections; live SRStorage
invariants and pinned StakingModule type-bound source models are the
follow-up. -/

namespace LidoSRv3.Audit.Guarantees.PAlloc1RemainingBoundsScaffold

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

/-- Pinned SRStorage / registry premise on the three remaining
`CheckedBounds` conjuncts. -/
structure PinnedSRAllocationBoundsShape
    (cfg : Config) (modules : List Module)
    (depositsToAllocate : Uint256) (isTopUp : Bool) : Prop where
  activeSubtractionInvariant : ∀ m ∈ modules,
    (wordMax m.summaryExitedCount m.accountingExitedCount : Nat)
      ≤ (m.depositedCount : Nat)
  totalAdditionInvariant : (depositsToAllocate : Nat) +
    (modules.map (MathView.allocationEntry cfg)).sum ≤ MAX_UINT256
  availableArithmeticInvariant : ∀ m ∈ modules, m.isActive = true →
    (if isTopUp && m.isType2 then
      MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤ MAX_UINT256
    else
      MathView.allocationEntry cfg m + (m.depositableCount : Nat) ≤ MAX_UINT256)

theorem active_subtraction_under_pinned_sr_shape
    {cfg : Config} {modules : List Module}
    {depositsToAllocate : Uint256} {isTopUp : Bool}
    (hPinned : PinnedSRAllocationBoundsShape cfg modules depositsToAllocate isTopUp) :
    ∀ m ∈ modules,
      (wordMax m.summaryExitedCount m.accountingExitedCount : Nat)
        ≤ (m.depositedCount : Nat) :=
  hPinned.activeSubtractionInvariant

theorem total_addition_under_pinned_sr_shape
    {cfg : Config} {modules : List Module}
    {depositsToAllocate : Uint256} {isTopUp : Bool}
    (hPinned : PinnedSRAllocationBoundsShape cfg modules depositsToAllocate isTopUp) :
    (depositsToAllocate : Nat) +
      (modules.map (MathView.allocationEntry cfg)).sum ≤ MAX_UINT256 :=
  hPinned.totalAdditionInvariant

theorem available_arithmetic_under_pinned_sr_shape
    {cfg : Config} {modules : List Module}
    {depositsToAllocate : Uint256} {isTopUp : Bool}
    (hPinned : PinnedSRAllocationBoundsShape cfg modules depositsToAllocate isTopUp) :
    ∀ m ∈ modules, m.isActive = true →
      (if isTopUp && m.isType2 then
        MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤ MAX_UINT256
      else
        MathView.allocationEntry cfg m + (m.depositableCount : Nat) ≤ MAX_UINT256) :=
  hPinned.availableArithmeticInvariant

end LidoSRv3.Audit.Guarantees.PAlloc1RemainingBoundsScaffold
