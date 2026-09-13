import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence

namespace LidoSRv3.Tests.MinFirstFoldlMinWordKillLines

open LidoSRv3.Audit.MinFirstAllocation
open Verity.Core Verity.Stdlib.Math

/-- Pin `foldl_minWord_some`: the `Option`-lifted min-scan is a `some`
of the pure min-scan. This is the shape reduction the pinned source
`allocationSizeUpperBound` (MinFirstAllocation.sol lines 93-100)
consumes to expose its `Uint256` fold. -/
theorem foldl_minWord_some_restated (l : List Source.Word) (m : Source.Word) :
    l.foldl (fun found value => some ((found.map (Source.minWord value)).getD value))
        (some m) =
      some (l.foldl (fun acc value => Source.minWord value acc) m) :=
  foldl_minWord_some l m

/-- Pin `val_foldl_minWord`: the fold's word value is the `Nat.min` fold
over the same list — the atomic step that lifts the pinned source's
Uint256 fold into the model's `Nat.min?`. -/
theorem val_foldl_minWord_restated (l : List Source.Word) (m : Source.Word) :
    (l.foldl (fun acc value => Source.minWord value acc) m).val =
      (l.map Uint256.val).foldl min m.val :=
  val_foldl_minWord l m

/-- Pin `foldl_minWord_eq_min?`: the option-lifted min-scan equals
`List.min?` on the value-mapped list, discharging the entire
`allocationSizeUpperBound` correspondence in one step. -/
theorem foldl_minWord_eq_min?_restated (l : List Source.Word) :
    Option.map Uint256.val
        (l.foldl (fun found value => some ((found.map (Source.minWord value)).getD value))
          none) =
      (l.map Uint256.val).min? :=
  foldl_minWord_eq_min? l

end LidoSRv3.Tests.MinFirstFoldlMinWordKillLines
