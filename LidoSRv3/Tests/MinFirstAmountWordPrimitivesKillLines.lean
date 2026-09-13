import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence

namespace LidoSRv3.Tests.MinFirstAmountWordPrimitivesKillLines

open LidoSRv3.Audit.MinFirstAllocation
open Verity.Core Verity.Stdlib.Math

/-- Pin `val_sub_of_le` so the `Uint256` subtraction underflow-guard bridge
into `Nat` remains attached to the pinned source: any drift in
`Uint256.sub`/`Uint256.ofNat` would break this before it can rot the
`MinFirstAmountCorrespondence` proof. -/
theorem val_sub_of_le_restated {a b : Uint256} (h : b ≤ a) :
    (a - b).val = a.val - b.val :=
  val_sub_of_le h

/-- Pin `val_minWord`: the `Source.minWord` lift returns exactly the
`Nat.min` of the two word values. -/
theorem val_minWord_restated (a b : Source.Word) :
    (Source.minWord a b).val = min a.val b.val :=
  val_minWord a b

/-- Pin `min_sub_distrib`: the shape difference between the pinned source
(`min` first, subtract once) and `checkedAmount` (subtract per-branch)
requires both branches to dominate `c`. -/
theorem min_sub_distrib_restated {x y c : Nat} (hx : c ≤ x) (hy : c ≤ y) :
    min x y - c = min (x - c) (y - c) :=
  min_sub_distrib hx hy

end LidoSRv3.Tests.MinFirstAmountWordPrimitivesKillLines
