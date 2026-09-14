import LidoSRv3.Audit.Model.AllocCapacity

/-! # P-ALLOC-1 `available_arithmetic` conjunct derived from pinned type bounds

Scope correction from pinned SRLib.sol:374-378 and 516-532: the module
summary returns uint256 values, and type-2 stake comes from another external
getter. The uint64 hypotheses below are additional assumptions, not consequences
of those ABI return types. These conditional arithmetic lemmas are retained from
PRs #652/#653; they do not establish reachable-router `CheckedBounds`.

**Chantier 3 (Piste A, Thomas 2026-09-13) real derivation of the
`available_arithmetic` CheckedBounds conjunct.**

The registered abstract parent `checked_execute` consumes
`CheckedBounds` (five conjuncts).  Conjunct 4 (`available_arithmetic`)
is per-module case-split:

- topup && type2: `activeCount m * (cfg.maxEBType2 : Nat) ≤ MAX_UINT256`.
- else: `allocationEntry cfg m + (m.depositableCount : Nat) ≤ MAX_UINT256`.

Analog of `PAlloc1TargetMultBounded.target_multiplication_under_pinned_type_bounds`
(PR #439/#557) and `PAlloc1TotalAdditionBounded.total_addition_under_pinned_bounds`
(chantier 3 follow-up 2026-09-13): both bound alternatives reduce to
`x + y` or `x * y` where each operand fits in uint64.

Arithmetic bounds:
- `activeCount * maxEBType2 ≤ (2^64 - 1) * (2^64 - 1) = (2^64 - 1)^2
  ≈ 3.4·10^38 < 2^128 << MAX_UINT256 = 2^256 - 1`.
- `allocationEntry + depositableCount ≤ 2 * (2^64 - 1) ≈ 3.7·10^19
  << MAX_UINT256`.

Both closed by `decide` on the operand product/sum after case-splitting. -/

namespace LidoSRv3.Audit.Guarantees.PAlloc1AvailableArithmeticBounded

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

/-- The uint64 upper bound. -/
def uint64Max : Nat := 2 ^ 64 - 1

/-- Pinned per-module bounds premise for the `available_arithmetic`
conjunct.  Each of the four operands appearing in the two branches
(activeCount, maxEBType2, allocationEntry, depositableCount) is bounded
by uint64. -/
structure PinnedAvailableArithmeticBounds
    (cfg : Config) (modules : List Module) (isTopUp : Bool) : Prop where
  activeCount_uint64 : ∀ m ∈ modules, MathView.activeCount m ≤ uint64Max
  maxEBType2_uint64 : (cfg.maxEBType2 : Nat) ≤ uint64Max
  allocationEntry_uint64 : ∀ m ∈ modules, MathView.allocationEntry cfg m ≤ uint64Max
  depositableCount_uint64 : ∀ m ∈ modules, (m.depositableCount : Nat) ≤ uint64Max

/-- Under the pinned bounds premise, the `available_arithmetic`
conjunct of `CheckedBounds` holds by real arithmetic on both branches:
the type-2 topup branch is bounded by `uint64Max * uint64Max`, the
else branch by `2 * uint64Max`, each ≤ MAX_UINT256 by `decide`. -/
theorem available_arithmetic_under_pinned_bounds
    {cfg : Config} {modules : List Module} {isTopUp : Bool}
    (hPinned : PinnedAvailableArithmeticBounds cfg modules isTopUp) :
    ∀ m ∈ modules, m.isActive = true →
      (if isTopUp && m.isType2 then
        MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤ Verity.Core.MAX_UINT256
      else
        MathView.allocationEntry cfg m + (m.depositableCount : Nat) ≤
          Verity.Core.MAX_UINT256) := by
  intro m hMem _hActive
  by_cases hBranch : isTopUp && m.isType2
  · rw [if_pos hBranch]
    have hActive : MathView.activeCount m ≤ uint64Max :=
      hPinned.activeCount_uint64 m hMem
    have hMaxEB : (cfg.maxEBType2 : Nat) ≤ uint64Max := hPinned.maxEBType2_uint64
    have hProduct : MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤
        uint64Max * uint64Max :=
      Nat.mul_le_mul hActive hMaxEB
    have hSmall : uint64Max * uint64Max ≤ Verity.Core.MAX_UINT256 := by
      unfold uint64Max Verity.Core.MAX_UINT256
      decide
    exact Nat.le_trans hProduct hSmall
  · rw [if_neg hBranch]
    have hAlloc : MathView.allocationEntry cfg m ≤ uint64Max :=
      hPinned.allocationEntry_uint64 m hMem
    have hDep : (m.depositableCount : Nat) ≤ uint64Max :=
      hPinned.depositableCount_uint64 m hMem
    have hSum : MathView.allocationEntry cfg m + (m.depositableCount : Nat) ≤
        uint64Max + uint64Max :=
      Nat.add_le_add hAlloc hDep
    have hSmall : uint64Max + uint64Max ≤ Verity.Core.MAX_UINT256 := by
      unfold uint64Max Verity.Core.MAX_UINT256
      decide
    exact Nat.le_trans hSum hSmall

end LidoSRv3.Audit.Guarantees.PAlloc1AvailableArithmeticBounded
