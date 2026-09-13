import LidoSRv3.Audit.Source.TrioAlloc1.Memory

/-!
Kill-lines pinning `TrioAlloc1.Memory` word-memory bridge:
`arrayWords_related` and `arraysMemory_related` witness theorems.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1MemoryKillLines

open LidoSRv3.Audit.Source.TrioAlloc1

/-! ## `arrayWords_related` — length-prefixed word array is
    ArrayAt-related to its bytes. -/

theorem arrayWords_related_restated
    (pointer : Nat) (values : List Word)
    (bound : values.length < 2^256) :
    ArrayAt (arrayWords pointer values) pointer values :=
  arrayWords_related pointer values bound

/-! ## `arraysMemory_related` — two separated regions retain both
    array shapes. -/

theorem arraysMemory_related_restated
    (output : CapacityOutput) (ap cp : Nat)
    (separated : ap + 32*(output.allocations.length+1) ≤ cp)
    (endBound : cp + 32*(output.capacities.length+1) ≤ 2^256) :
    MemoryArraysRelated (arraysMemory output ap cp) ap cp output :=
  arraysMemory_related output ap cp separated endBound

/-! ## `arraysMemory` on address < cp reads from allocations region. -/

theorem arraysMemory_low
    (output : CapacityOutput) (ap cp address : Nat)
    (h : address < cp) :
    arraysMemory output ap cp address =
      arrayWords ap output.allocations address := by
  simp [arraysMemory, h]

/-! ## `arraysMemory` on address ≥ cp reads from capacities region. -/

theorem arraysMemory_high
    (output : CapacityOutput) (ap cp address : Nat)
    (h : ¬ address < cp) :
    arraysMemory output ap cp address =
      arrayWords cp output.capacities address := by
  simp [arraysMemory, h]

end LidoSRv3.Tests.SourceTrioAlloc1MemoryKillLines
