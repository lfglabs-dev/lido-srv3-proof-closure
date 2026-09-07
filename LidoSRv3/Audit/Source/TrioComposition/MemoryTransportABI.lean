import LidoSRv3.Audit.Source.TrioComposition.MemoryTransportCopy

/-! Actual caller array reads feed canonical ABI encoding and independent
library execution. Successful return bytes are copied into a fresh caller array
without changing the original allocation array used by delta conversion.
Selector dispatch, deployment identity, byte-store refinement, and gas remain
external boundaries. Producer interleaved-store correctness is supplied by its
own induction, never by reconstructing memory from a completed ghost output. -/
namespace LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
open TrioAlloc1
open TrioAlloc2 (readMemoryArray allocateMemory)

def argumentsFromMemory (memory : MemoryWords) (ap cp : Nat) (demand : Word) :
    TrioAlloc2.LibraryABI.Arguments :=
  ⟨readMemoryArray memory ap, readMemoryArray memory cp, demand⟩

def libraryFromMemory (memory : MemoryWords) (ap cp : Nat) (demand : Word) :
    Except Bytes Bytes :=
  TrioAlloc2.LibraryABI.run
    (TrioAlloc2.LibraryABI.encodeArguments (argumentsFromMemory memory ap cp demand))

/-- The library receives decoded bytes made from actual caller mloads. Its
memory is a separate invocation; its internal writes cannot alias caller memory. -/
theorem libraryFromMemory_exact (memory : MemoryWords) (ap cp : Nat) (demand : Word)
    (bound : (TrioAlloc2.LibraryABI.encodeArguments
      (argumentsFromMemory memory ap cp demand)).length < 2^64) :
    libraryFromMemory memory ap cp demand =
      TrioAlloc2.LibraryABI.encodeOutcome (allocateMemory memory ap cp demand) :=
  TrioAlloc2.LibraryABI.run_encoded (argumentsFromMemory memory ap cp demand) bound

/-- Finite physical extent of the destination is an explicit condition. Both
arrays coexist after importing the separate library return array. -/
theorem library_return_transport (memory : MemoryWords) (ap cp rp : Nat) (demand : Word)
    (original : List Word) (result : TrioAlloc2.StepOutput)
    (originalAt : ArrayAt memory ap original)
    (argumentBound : (TrioAlloc2.LibraryABI.encodeArguments
      (argumentsFromMemory memory ap cp demand)).length < 2^64)
    (execution : allocateMemory memory ap cp demand = .ok result)
    (originalBound : ap+32*(original.length+1) ≤ 2^64)
    (returnBound : rp+32*(result.buckets.length+1) ≤ 2^64)
    (separate : Disjoint rp result.buckets.length ap original.length) :
    libraryFromMemory memory ap cp demand = .ok (TrioAlloc2.LibraryABI.encodeReturn result) ∧
    TrioAlloc2.LibraryABI.decodeReturn (TrioAlloc2.LibraryABI.encodeReturn result) = .ok result ∧
    ArrayAt (importReturn memory rp result) rp result.buckets ∧
    ArrayAt (importReturn memory rp result) ap original ∧
    readMemoryArray (importReturn memory rp result) ap = original ∧
    rp+32*(result.buckets.length+1) ≤ 2^256 ∧ ap+32*(original.length+1) ≤ 2^256 := by
  have lengthBound : result.buckets.length < 2^64 := by omega
  have wordBound : result.buckets.length < 2^256 := by omega
  have kept := importReturn_preserves memory rp ap result original wordBound separate originalAt
  refine ⟨?_, TrioAlloc2.LibraryABI.decodeReturn_encoded result lengthBound,
    importReturn_related memory rp result wordBound, kept,
    TrioAlloc2.readMemoryArray_eq _ ap original kept, by omega, by omega⟩
  rw [libraryFromMemory_exact memory ap cp demand argumentBound, execution]
  rfl

/-- A successful producer plus its proved memory relation is enough to establish
consumer success; no library-success premise is required here. -/
theorem producer_memory_library_distributes
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (executed : TrioAlloc1.produce layout storage oracle input before = (.ok output, after))
    (memory : MemoryWords) (ap cp : Nat)
    (related : MemoryArraysRelated memory ap cp output)
    (bound : (TrioAlloc2.LibraryABI.encodeArguments
      (argumentsFromMemory memory ap cp input.depositsToAllocate)).length < 2^64) :
    ∃ result,
      libraryFromMemory memory ap cp input.depositsToAllocate =
        .ok (TrioAlloc2.LibraryABI.encodeReturn result) ∧
      TrioAlloc2.Spec.Distributes (TrioAlloc2.decodedRows output.allocations output.capacities)
        input.depositsToAllocate.val result.amount.val
        (TrioAlloc2.decodedRows result.buckets output.capacities) := by
  obtain ⟨result, execution, distributes⟩ := TrioAlloc2.producer_then_memory_consumer_distributes
    layout storage oracle input before after output executed memory ap cp related
  refine ⟨result, ?_, distributes⟩
  rw [libraryFromMemory_exact memory ap cp input.depositsToAllocate bound, execution]
  rfl

#print axioms libraryFromMemory_exact
#print axioms library_return_transport
#print axioms producer_memory_library_distributes
end LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
