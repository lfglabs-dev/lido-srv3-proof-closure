import LidoSRv3.Audit.Source.TrioAlloc2.MemoryComposition

namespace LidoSRv3.Tests.TrioIntegration
open LidoSRv3.Audit.Source
open TrioAlloc2

private def bytesFor (buckets capacities : List Word) (pre gap : TrioAlloc1.Bytes) : TrioAlloc1.Bytes :=
  pre ++ TrioAlloc1.encodeArray buckets ++ gap ++ TrioAlloc1.encodeArray capacities

private def equalResult (actual expected : Result StepOutput) : Bool :=
  match actual, expected with
  | .ok a, .ok b => decide (a = b)
  | .error a, .error b => decide (a = b)
  | _, _ => false

private def checkMemory (buckets capacities : List Word) (demand : Word)
    (pre gap : TrioAlloc1.Bytes) (expected : Result StepOutput) : IO Unit := do
  let bytes := bytesFor buckets capacities pre gap
  let memory := fun address => TrioAlloc1.decodeWord bytes address
  let result := allocateMemory memory pre.length
    (pre ++ TrioAlloc1.encodeArray buckets ++ gap).length demand
  unless equalResult result expected do
    throw (IO.userError s!"memory consumer mismatch: {repr result}")

-- Nonempty prees and gaps force reads through both actual array pointers.
#eval checkMemory [zero] [TrioAlloc1.word 5] (TrioAlloc1.word 3)
  [TrioAlloc1.byte 0xff] [TrioAlloc1.byte 0xab, TrioAlloc1.byte 0xcd]
  (.ok ⟨TrioAlloc1.word 3, [TrioAlloc1.word 3]⟩)
#eval checkMemory [TrioAlloc1.word 9998, TrioAlloc1.word 70, zero]
  [TrioAlloc1.word 10000, TrioAlloc1.word 101, TrioAlloc1.word 100]
  (TrioAlloc1.word 101) [] []
  (.ok ⟨TrioAlloc1.word 101, [TrioAlloc1.word 9998, TrioAlloc1.word 86, TrioAlloc1.word 85]⟩)
#eval checkMemory [] [] one [] [] (.ok ⟨zero, []⟩)
#eval checkMemory [one] [] zero [] [] (.ok ⟨zero, [one]⟩)
#eval checkMemory [zero] [] one [] [] (.error .arrayBounds)
#eval checkMemory [TrioAlloc1.word 9] [TrioAlloc1.word 8] one [] []
  (.ok ⟨zero, [TrioAlloc1.word 9]⟩)

/-- A wrong capacity pointer changes the observed execution. This negative
control would be ineffective if allocateMemory bypassed memory for ghost arrays. -/
private def checkWrongPointer : IO Unit := do
  let bytes := bytesFor [zero] [TrioAlloc1.word 5] [] []
  let memory := fun address => TrioAlloc1.decodeWord bytes address
  let correct := allocateMemory memory 0 64 one
  let wrong := allocateMemory memory 0 0 one
  unless equalResult correct (.ok ⟨one, [one]⟩) && equalResult wrong (.ok ⟨zero, [zero]⟩) do
    throw (IO.userError "capacity-pointer mutation was not detected")

#eval checkWrongPointer
end LidoSRv3.Tests.TrioIntegration
