import LidoSRv3.Audit.Model.AllocCapacity

/-! # P-ALLOC-1 `target_multiplication` conjunct derived from pinned type bounds

**General rule (Thomas 2026-09-12), applied to ALLOC-1 CheckedBounds
target_multiplication conjunct.**

The registered abstract parent of P-ALLOC-1
(`checked_execute` in `LidoSRv3.Audit.Guarantees.PAlloc1`) consumes
`CheckedBounds cfg modules depositsToAllocate isTopUp` as a caller
hypothesis. Its four conjuncts are:

1. `maxEBType1_nonzero : cfg.maxEBType1 ≠ 0`
2. `active_subtraction : ...` (per-module exited ≤ deposited)
3. `total_addition : ...` (∑ allocationEntry ≤ MAX_UINT256)
4. `available_arithmetic : ...` (per-module capacity ≤ MAX_UINT256)
5. `target_multiplication : shareLimit * totalValidators ≤ MAX_UINT256`

Per Thomas 2026-09-12: `stakeShareLimit ≤ 10000` (uint16 in the pinned
`StakingModule` struct, and additionally bounded by the total basis
points constant 10000) and `totalValidators` is bounded by uint64,
so `stakeShareLimit * totalValidators ≤ 65535 * (2^64 - 1) < 2^80`,
FAR below `MAX_UINT256 = 2^256 - 1`.

The composition below derives the `target_multiplication` conjunct of
`CheckedBounds` from an explicit `PinnedStakingModuleTypeBounds`
premise. The other three conjuncts have per-module dynamic dependencies
that require additional invariants beyond type bounds; they remain as
follow-up work per the general rule.

Residual (in `fidelity.missing`): the premise assumes the pinned
`StakingModule` struct layout (`shareLimit : uint16` and
`totalValidators : uint64` per SRLib.sol). The other three CheckedBounds
conjuncts (active_subtraction, total_addition, available_arithmetic)
require additional invariants and are separately follow-ups. -/

namespace LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

/-- The pinned `StakingModule` struct declares `stakeShareLimit :
uint16` (SRLib.sol Module definition), so `shareLimit ≤ 2^16 - 1 =
65535`. Additionally the router uses `TOTAL_BASIS_POINTS = 10000`
as the divisor at SRLib.sol:552, so admissible share limits are
`shareLimit ≤ 10000` in practice. -/
def uint16Max : Nat := 2 ^ 16 - 1

/-- The pinned `totalValidators` accumulator (SRLib.sol:506, 532)
sums `depositsToAllocate + Σ validatorsCount` where each contributes
count is uint64-bounded (validator index domain). -/
def uint64Max : Nat := 2 ^ 64 - 1

/-- Pinned type-bound premise on `StakingModule.shareLimit` and the
`totalValidators` accumulator: `shareLimit ≤ 2^16 - 1` and
`totalValidators cfg modules deposits ≤ 2^64 - 1`. -/
structure PinnedStakingModuleTypeBounds
    (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256) : Prop where
  shareLimit_uint16 : ∀ m ∈ modules, (m.shareLimit : Nat) ≤ uint16Max
  totalValidators_uint64 :
    MathView.totalValidators cfg modules depositsToAllocate ≤ uint64Max

/-- Under the pinned type-bound premise,
`shareLimit * totalValidators ≤ uint16Max * uint64Max
≈ 1.2 * 10^24 << MAX_UINT256 = 2^256 - 1`. This is the
`target_multiplication` conjunct of `CheckedBounds`. -/
theorem target_multiplication_under_pinned_type_bounds
    {cfg : Config} {modules : List Module} {depositsToAllocate : Uint256}
    (hPinned : PinnedStakingModuleTypeBounds cfg modules depositsToAllocate) :
    ∀ m ∈ modules, m.isActive = true →
      (m.shareLimit : Nat) * MathView.totalValidators cfg modules depositsToAllocate
        ≤ Verity.Core.MAX_UINT256 := by
  intro m hMem _hActive
  have hShare : (m.shareLimit : Nat) ≤ uint16Max :=
    hPinned.shareLimit_uint16 m hMem
  have hTotal : MathView.totalValidators cfg modules depositsToAllocate ≤ uint64Max :=
    hPinned.totalValidators_uint64
  have hProduct : (m.shareLimit : Nat)
        * MathView.totalValidators cfg modules depositsToAllocate ≤
      uint16Max * uint64Max :=
    Nat.mul_le_mul hShare hTotal
  have hSmall : uint16Max * uint64Max ≤ Verity.Core.MAX_UINT256 := by
    unfold uint16Max uint64Max Verity.Core.MAX_UINT256
    decide
  exact Nat.le_trans hProduct hSmall

end LidoSRv3.Audit.Guarantees.PAlloc1TargetMultBounded
