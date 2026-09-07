import LidoSRv3.Audit.Source.TrioAlloc2.LoopBounds

namespace LidoSRv3.Tests.TrioAlloc2
open LidoSRv3.Audit.Source.TrioAlloc2

private def w (n : Nat) : Word := ⟨n % 2 ^ 256, Nat.mod_lt _ (by decide)⟩

/-- Executed vectors, not proof axioms. A mismatch fails elaboration with an IO
exception. Universal bounds and length claims are in the imported proof module. -/
private def checkLoop (buckets capacities : List Word) (demand : Word)
    (expected : Result StepOutput) : IO Unit := do
  match allocate buckets capacities demand, expected with
  | .ok actual, .ok expected =>
    if actual = expected then pure () else throw (IO.userError s!"unexpected success: {repr actual}")
  | .error actual, .error expected =>
    if actual = expected then pure () else throw (IO.userError s!"unexpected panic: {repr actual}")
  | .ok actual, .error _ => throw (IO.userError s!"expected failure; got {repr actual}")
  | .error actual, .ok _ => throw (IO.userError s!"expected success; got {repr actual}")

example : allocate [w 7] [] zero = .ok ⟨zero, [w 7]⟩ :=
  allocate_zero_demand _ _

#eval checkLoop [w 7] [] zero (.ok ⟨zero, [w 7]⟩)
#eval checkLoop [] [] (w 5) (.ok ⟨zero, []⟩)
#eval checkLoop [zero] [] one (.error .arrayBounds)
#eval checkLoop [zero] [w 5, zero] (w 3) (.ok ⟨w 3, [w 3]⟩)
#eval checkLoop [w 9] [w 8] (w 3) (.ok ⟨zero, [w 9]⟩)
#eval checkLoop [w 9998, w 70, zero] [w 10000, w 101, w 100] (w 101)
  (.ok ⟨w 101, [w 9998, w 86, w 85]⟩)
#eval checkLoop [zero] [maxWord] maxWord (.ok ⟨maxWord, [maxWord]⟩)

end LidoSRv3.Tests.TrioAlloc2
