import LidoSRv3.Audit.Model.AllocCapacity
import LidoSRv3.Audit.Source.SRAllocationConstantsSource

/-! # P-ALLOC-1 `total_addition` conjunct derived from pinned type bounds

Scope correction from pinned SRLib.sol:374-378 and 516-532: the module
summary returns uint256 values, and type-2 stake comes from another external
getter. The uint64 hypotheses below are additional assumptions, not consequences
of those ABI return types. These conditional arithmetic lemmas are retained from
PRs #652/#653; they do not establish reachable-router `CheckedBounds`.

**Chantier 3 (Piste A, Thomas 2026-09-13) real derivation of the
`total_addition` CheckedBounds conjunct.**

The registered abstract parent `checked_execute` consumes
`CheckedBounds` (five conjuncts).  Conjunct 3 (`total_addition`) is
`(depositsToAllocate : Nat) + (modules.map (MathView.allocationEntry cfg)).sum
≤ MAX_UINT256`.  The prior `PAlloc1RemainingBoundsScaffold.PinnedSRAllocationBoundsShape`
bundles this as a caller-supplied invariant (pass-through).  This
module derives it from real pinned bounds analog of
`PAlloc1TargetMultBounded.target_multiplication_under_pinned_type_bounds`
(PR #439/#557): `MAX_STAKING_MODULES_COUNT = 32`, uint64 `depositsToAllocate`,
and per-module uint64 `allocationEntry`.

Arithmetic bound: `deposits + Σ entries ≤ uint64Max + 32 * uint64Max
= 33 * (2^64 - 1) < 2^71 << 2^256`.  Closed by `decide` on the
constants and `Nat.add_le_add` + `List.sum_le_card_nsmul`. -/

namespace LidoSRv3.Audit.Guarantees.PAlloc1TotalAdditionBounded

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity
open LidoSRv3.Audit.Source.SRAllocationConstantsSource

/-- The uint64 upper bound, mirrored from `PAlloc1TargetMultBounded.uint64Max`. -/
def uint64Max : Nat := 2 ^ 64 - 1

/-- Pinned bounds premise on the `total_addition` conjunct: the module
count is bounded by `MAX_STAKING_MODULES_COUNT = 32`, `depositsToAllocate`
fits in uint64, and each module's `allocationEntry cfg m` fits in uint64. -/
structure PinnedAllocationEntryBounds
    (cfg : Config) (modules : List Module) (depositsToAllocate : Uint256) : Prop where
  modules_count : modules.length ≤ maxStakingModulesCount
  deposits_uint64 : (depositsToAllocate : Nat) ≤ uint64Max
  entries_uint64 : ∀ m ∈ modules, MathView.allocationEntry cfg m ≤ uint64Max

/-- The sum of `f x` over a list is bounded by the list length times the
per-element bound. -/
theorem sum_map_le_length_mul
    {α : Type} (f : α → Nat) (bound : Nat) (l : List α)
    (h : ∀ x ∈ l, f x ≤ bound) :
    (l.map f).sum ≤ l.length * bound := by
  induction l with
  | nil => simp
  | cons head tail ih =>
    have hHead : f head ≤ bound := h head List.mem_cons_self
    have hTail : ∀ x ∈ tail, f x ≤ bound := fun x hx =>
      h x (List.mem_cons_of_mem head hx)
    have hSumTail : (tail.map f).sum ≤ tail.length * bound := ih hTail
    have hAdd : f head + (tail.map f).sum ≤ bound + tail.length * bound :=
      Nat.add_le_add hHead hSumTail
    have hRewrite : bound + tail.length * bound = (tail.length + 1) * bound := by
      rw [Nat.add_mul, Nat.one_mul, Nat.add_comm]
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    rw [hRewrite] at hAdd
    exact hAdd

/-- Under the pinned bounds premise,
`depositsToAllocate + Σ allocationEntry ≤ (32 + 1) * uint64Max
= 33 * (2^64 - 1) ≈ 6 * 10^20 << MAX_UINT256 = 2^256 - 1`. This is the
`total_addition` conjunct of `CheckedBounds`. -/
theorem total_addition_under_pinned_bounds
    {cfg : Config} {modules : List Module} {depositsToAllocate : Uint256}
    (hPinned : PinnedAllocationEntryBounds cfg modules depositsToAllocate) :
    (depositsToAllocate : Nat) +
      (modules.map (MathView.allocationEntry cfg)).sum ≤ Verity.Core.MAX_UINT256 := by
  have hSum : (modules.map (MathView.allocationEntry cfg)).sum ≤
      modules.length * uint64Max :=
    sum_map_le_length_mul (MathView.allocationEntry cfg) uint64Max modules
      hPinned.entries_uint64
  have hModCount : modules.length * uint64Max ≤ maxStakingModulesCount * uint64Max :=
    Nat.mul_le_mul_right _ hPinned.modules_count
  have hSumBound : (modules.map (MathView.allocationEntry cfg)).sum ≤
      maxStakingModulesCount * uint64Max :=
    Nat.le_trans hSum hModCount
  have hTotal : (depositsToAllocate : Nat) +
        (modules.map (MathView.allocationEntry cfg)).sum ≤
      uint64Max + maxStakingModulesCount * uint64Max :=
    Nat.add_le_add hPinned.deposits_uint64 hSumBound
  have hSmall : uint64Max + maxStakingModulesCount * uint64Max ≤
      Verity.Core.MAX_UINT256 := by
    unfold uint64Max maxStakingModulesCount Verity.Core.MAX_UINT256
    decide
  exact Nat.le_trans hTotal hSmall

end LidoSRv3.Audit.Guarantees.PAlloc1TotalAdditionBounded
