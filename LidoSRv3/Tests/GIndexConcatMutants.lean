import LidoSRv3.Audit.Source.GIndexConcatCorrespondence

namespace LidoSRv3.Tests.GIndexConcatMutants

open LidoSRv3.Audit.Source.GIndexConcatCorrespondence

private def gindex (index pow : Nat) (hIndex : index ≤ maxUint248 := by decide)
    (hPow : pow < 2 ^ 8 := by decide) : GIndex :=
  ⟨index, pow, hIndex, hPow⟩

private def lhs2 := gindex 2 7
private def rhs3 := gindex 3 11

/-- Root/root is the smallest accepted boundary and copies `pow(rhs)`. -/
example : sourceConcat (gindex 1 255) (gindex 1 0) = .value 1 0 := by decide

/-- A concrete nontrivial append: binary `10 ++ 1 = 101`. -/
example : sourceConcat lhs2 rhs3 = .value 5 11 := by decide

/-- The exact maximum accepted depth is 248. -/
example : sourceConcat (gindex (2 ^ 247) 1) (gindex 1 2) =
    .value (2 ^ 247) 2 := by decide

/-- One additional right depth crosses the pinned guard. -/
example : sourceConcat (gindex (2 ^ 247) 1) (gindex 2 2) =
    .depthOverflow := by decide

/-- `fls(0) = 256` makes zero decoded indices source-unreachable through concat. -/
example : sourceConcat (gindex 0 0) (gindex 1 0) = .depthOverflow := by decide

private def wrongShiftMutant (lhs rhs : GIndex) : Nat :=
  (lhs.index <<< (fls rhs.index + 1)) |||
    (rhs.index ^^^ (1 <<< fls rhs.index))

private def wrongDepthMutant (lhs rhs : GIndex) : Bool :=
  fls lhs.index + fls rhs.index ≤ 248

private def wrongOrderMutant (lhs rhs : GIndex) : Nat :=
  (rhs.index <<< fls lhs.index) |||
    (lhs.index ^^^ (1 <<< fls lhs.index))

private def wrappingOverflowMutant (lhs rhs : GIndex) : Nat :=
  concatenatedIndex lhs rhs % (2 ^ 248)

/-- Wrong shift distance changes the nontrivial append. -/
example : wrongShiftMutant lhs2 rhs3 ≠ concatenatedIndex lhs2 rhs3 := by decide

/-- Dropping the guard's `+ 1` admits the first overflowing boundary. -/
example : wrongDepthMutant (gindex (2 ^ 247) 1) (gindex 2 2) = true ∧
    depthFits (gindex (2 ^ 247) 1) (gindex 2 2) = false := by decide

/-- Swapping operand roles is observable because concat is ordered. -/
example : wrongOrderMutant lhs2 rhs3 ≠ concatenatedIndex lhs2 rhs3 := by decide

/-- An unchecked/wrapping overflow mutant fabricates a value where source reverts. -/
example : wrappingOverflowMutant (gindex (2 ^ 247) 1) (gindex 2 2) = 0 ∧
    sourceConcat (gindex (2 ^ 247) 1) (gindex 2 2) = .depthOverflow := by decide

#print axioms source_concat_matches_spec
#print axioms source_concat_value_of_fits
#print axioms source_concat_depth_overflow

end LidoSRv3.Tests.GIndexConcatMutants
