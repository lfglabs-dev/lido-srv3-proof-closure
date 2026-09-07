import LidoSRv3.Audit.Source.TrioAlloc1.Memory
import LidoSRv3.Audit.Source.TrioAlloc2.Composition

/-!
The consumer reads both length-prefixed arrays from the supplied memory, instead
of receiving the producer's ghost output arrays as arguments. The memory relation
remains explicit: compiler allocation, wraparound failure and parent execution
are not established by this bridge.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc2

/-- Read the stored length, then every element at its byte address. -/
def readMemoryArray (memory : TrioAlloc1.MemoryWords) (pointer : Nat) : List Word :=
  List.ofFn fun i : Fin (memory pointer).val => memory (pointer + 32 * (i.val + 1))

theorem readMemoryArray_eq (memory : TrioAlloc1.MemoryWords) (pointer : Nat)
    (values : List Word) (related : TrioAlloc1.ArrayAt memory pointer values) :
    readMemoryArray memory pointer = values := by
  obtain ⟨length, elements⟩ := related
  apply List.ext_getElem
  · simp [readMemoryArray, length]
  · intro i left right
    simp only [readMemoryArray, List.getElem_ofFn]
    exact elements ⟨i, right⟩

/-- Decoded proportional execution whose inputs are actual memory reads. -/
def allocateMemory (memory : TrioAlloc1.MemoryWords) (allocationPtr capacityPtr : Nat)
    (demand : Word) : Result StepOutput :=
  allocate (readMemoryArray memory allocationPtr) (readMemoryArray memory capacityPtr) demand

theorem allocateMemory_eq (memory : TrioAlloc1.MemoryWords) (ap cp : Nat)
    (output : TrioAlloc1.CapacityOutput) (demand : Word)
    (related : TrioAlloc1.MemoryArraysRelated memory ap cp output) :
    allocateMemory memory ap cp demand = allocate output.allocations output.capacities demand := by
  unfold allocateMemory
  rw [readMemoryArray_eq memory ap output.allocations related.1,
    readMemoryArray_eq memory cp output.capacities related.2.1]

/-- Producer success and a concrete memory relation establish consumer success
and the independent distribution relation. No consumer success is assumed. -/
theorem producer_then_memory_consumer_distributes
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (input : TrioAlloc1.CapacityInput) (before after : TrioAlloc1.Transcript)
    (output : TrioAlloc1.CapacityOutput)
    (executed : TrioAlloc1.produce layout storage oracle input before = (.ok output, after))
    (memory : TrioAlloc1.MemoryWords) (ap cp : Nat)
    (related : TrioAlloc1.MemoryArraysRelated memory ap cp output) :
    ∃ result, allocateMemory memory ap cp input.depositsToAllocate = .ok result ∧
      Spec.Distributes (decodedRows output.allocations output.capacities)
        input.depositsToAllocate.val result.amount.val (decodedRows result.buckets output.capacities) := by
  rw [allocateMemory_eq memory ap cp output input.depositsToAllocate related]
  exact producer_then_consumer_distributes layout storage oracle input before after output executed

/-- For encoded producer arrays, the memory relation is derived from bytes.
The nonwrapping memory extent is still an explicit obligation of the allocator. -/
theorem producer_then_byte_consumer_distributes
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (input : TrioAlloc1.CapacityInput) (before after : TrioAlloc1.Transcript)
    (output : TrioAlloc1.CapacityOutput)
    (executed : TrioAlloc1.produce layout storage oracle input before = (.ok output, after))
    (pre gap : TrioAlloc1.Bytes)
    (bounded : (TrioAlloc1.outputBytes output pre gap).length ≤ 2 ^ 256) :
    ∃ result, allocateMemory (fun address => TrioAlloc1.decodeWord
        (TrioAlloc1.outputBytes output pre gap) address) pre.length
        (pre ++ TrioAlloc1.encodeArray output.allocations ++ gap).length input.depositsToAllocate = .ok result ∧
      Spec.Distributes (decodedRows output.allocations output.capacities)
        input.depositsToAllocate.val result.amount.val (decodedRows result.buckets output.capacities) := by
  exact producer_then_memory_consumer_distributes layout storage oracle input before after output executed
    _ _ _ (TrioAlloc1.outputBytes_related output pre gap bounded)

#print axioms producer_then_memory_consumer_distributes
#print axioms producer_then_byte_consumer_distributes
end LidoSRv3.Audit.Source.TrioAlloc2
