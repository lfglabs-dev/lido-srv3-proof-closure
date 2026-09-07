import LidoSRv3.Audit.Source.TrioAlloc2.Conservation

namespace LidoSRv3.Tests.TrioAlloc2
open LidoSRv3.Audit.Source.TrioAlloc2

private def w (n : Nat) : Word := ⟨n % 2 ^ 256, Nat.mod_lt _ (by decide)⟩

/-- Actual second input uses the first output, not a separately supplied fixture.
Checks remain decoded Lean executions, not Solidity/Verity differential evidence. -/
private def checkSequential (buckets capacities₁ capacities₂ : List Word)
    (demand₁ demand₂ : Word) (expected₁ : StepOutput)
    (expected₂ : Result StepOutput) : IO Unit := do
  let first ← match allocate buckets capacities₁ demand₁ with
    | .error e => throw (IO.userError s!"first allocation failed: {repr e}")
    | .ok result => pure result
  unless first = expected₁ do throw (IO.userError s!"wrong first result: {repr first}")
  match allocate first.buckets capacities₂ demand₂, expected₂ with
  | .ok actual, .ok expected =>
    unless actual = expected do throw (IO.userError s!"wrong second result: {repr actual}")
  | .error actual, .error expected =>
    unless actual = expected do throw (IO.userError s!"wrong second error: {repr actual}")
  | actual, expected => throw (IO.userError s!"outcome mismatch: {repr actual}, {repr expected}")

#eval checkSequential [zero, zero] [w 3, w 3] [w 3, w 3] (w 3) (w 4)
  ⟨w 3, [w 2, w 1]⟩ (.ok ⟨w 3, [w 3, w 3]⟩)
-- Lowering capacities between calls preserves already overfull rows.
#eval checkSequential [zero, zero] [w 3, w 3] [one, w 3] (w 3) (w 4)
  ⟨w 3, [w 2, w 1]⟩ (.ok ⟨w 2, [w 2, w 3]⟩)
#eval checkSequential [zero] [maxWord] [maxWord] maxWord one
  ⟨maxWord, [maxWord]⟩ (.ok ⟨zero, [maxWord]⟩)
#eval checkSequential [zero] [w 3] [] one one
  ⟨one, [one]⟩ (.error .arrayBounds)
#eval checkSequential [zero] [w 3] [] one zero
  ⟨one, [one]⟩ (.ok ⟨zero, [one]⟩)

end LidoSRv3.Tests.TrioAlloc2
