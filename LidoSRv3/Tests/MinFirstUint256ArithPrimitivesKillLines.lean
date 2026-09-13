import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence

namespace LidoSRv3.Tests.MinFirstUint256ArithPrimitivesKillLines

open LidoSRv3.Audit.MinFirstAllocation
open Verity.Core Verity.Stdlib.Math

/-- Pin `safeSub_isSome_of_le`: the pinned-source `safeSub` returns
`some (a - b)` exactly when the subtraction does not underflow. Any drift
in the `safeSub` short-circuit shape breaks this before it can silently
change the discharge of the underflow-guard obligation. -/
theorem safeSub_isSome_of_le_restated {a b : Uint256} (h : b.val ≤ a.val) :
    safeSub a b = some (a - b) :=
  safeSub_isSome_of_le h

/-- Pin `val_of_safeSub`: whenever `safeSub` succeeds, the extracted word
carries the underlying `Nat` subtraction (with the underflow ruled out
definitionally). -/
theorem val_of_safeSub_restated {a b w : Uint256} (h : safeSub a b = some w) :
    w.val = a.val - b.val :=
  val_of_safeSub h

/-- Pin `val_div`: the pinned-source `Uint256` division agrees with the
`Nat` division when the divisor is non-zero — this is the concrete surface
consumed by `ceilDiv` refinement. -/
theorem val_div_restated {a b : Uint256} (hb : b.val ≠ 0) :
    (a / b).val = a.val / b.val :=
  val_div hb

/-- Pin `val_add_of_lt`: the pinned-source `Uint256` addition agrees with
the `Nat` addition when the sum is strictly below the modulus. This is
the no-wrap primitive used across the audit's arithmetic refinements. -/
theorem val_add_of_lt_restated {a b : Uint256}
    (h : a.val + b.val < Uint256.modulus) :
    (a + b).val = a.val + b.val :=
  val_add_of_lt h

/-- Pin `val_ofNat_of_lt`: `Uint256.ofNat d` carries `d` verbatim whenever
`d` fits in the word. This is the base case for every literal-embedding
lemma in the min-first correspondence proof. -/
theorem val_ofNat_of_lt_restated {d : Nat} (h : d < Uint256.modulus) :
    (Uint256.ofNat d).val = d :=
  val_ofNat_of_lt h

/-- Pin `val_ceilDiv`: the pinned-source `Verity.Stdlib.Math.ceilDiv` word
matches `Model.ceilDiv` on `Nat` whenever the divisor is a non-zero
in-range count — this is the single-step arithmetic bridge exposed by
`allocateToBestCandidate` (Lido core `17005714`, MinFirstAllocation lines
88-106). -/
theorem val_ceilDiv_restated {a : Uint256} {d : Nat}
    (hd : 0 < d) (hdlt : d < Uint256.modulus) :
    (Verity.Stdlib.Math.ceilDiv a (Uint256.ofNat d)).val = Model.ceilDiv a.val d :=
  val_ceilDiv hd hdlt

end LidoSRv3.Tests.MinFirstUint256ArithPrimitivesKillLines
