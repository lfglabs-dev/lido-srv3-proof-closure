import LidoSRv3.Audit.Model.AllocCapacity

/-! # Conditional bounds for allocation-capacity arithmetic

The summary replies and type-2 stake are uint256 values in pinned SRLib.sol.
The bounds below are explicit premises, not consequences of their ABI types.
Counts and allocation entries are bounded by uint64; maxEBType2 is a wei
amount bounded by uint128. This admits the pinned mainnet value of 2048 ether.
The top-up product is below 2^192 and the other branch's sum below 2^65,
so both fit uint256. Module and writer invariants remain assumed.
-/

namespace LidoSRv3.Audit.Guarantees.PAlloc1AvailableArithmeticBounded

open Verity
open Verity.Stdlib.Math
open LidoSRv3.Audit.AllocCapacity

/-- The uint64 upper bound. -/
def uint64Max : Nat := 2 ^ 64 - 1

/-- Bound on the wei-denominated effective balance, not a validator count. -/
def uint128Max : Nat := 2 ^ 128 - 1

/-- Conditional bounds: uint64 counts and allocation entries, uint128 wei
per type-2 validator. None of the external uint256 replies supplies these bounds. -/
structure PinnedAvailableArithmeticBounds
    (cfg : Config) (modules : List Module) (isTopUp : Bool) : Prop where
  activeCount_uint64 : ∀ m ∈ modules, MathView.activeCount m ≤ uint64Max
  maxEBType2_uint128 : (cfg.maxEBType2 : Nat) ≤ uint128Max
  allocationEntry_uint64 : ∀ m ∈ modules, MathView.allocationEntry cfg m ≤ uint64Max
  depositableCount_uint64 : ∀ m ∈ modules, (m.depositableCount : Nat) ≤ uint64Max

/-- Under the pinned bounds premise, the `available_arithmetic`
conjunct of `CheckedBounds` holds by real arithmetic on both branches:
the type-2 topup branch is bounded by `uint64Max * uint128Max`, the
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
    have hMaxEB : (cfg.maxEBType2 : Nat) ≤ uint128Max := hPinned.maxEBType2_uint128
    have hProduct : MathView.activeCount m * (cfg.maxEBType2 : Nat) ≤
        uint64Max * uint128Max :=
      Nat.mul_le_mul hActive hMaxEB
    have hSmall : uint64Max * uint128Max ≤ Verity.Core.MAX_UINT256 := by
      unfold uint64Max uint128Max Verity.Core.MAX_UINT256
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
