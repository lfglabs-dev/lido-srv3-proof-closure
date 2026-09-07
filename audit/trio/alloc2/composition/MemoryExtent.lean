import audit.trio.alloc2.composition.AllocationMemoryBridge
import LidoSRv3.Audit.Source.TrioAlloc1.Memory
import audit.trio.alloc2.composition.LibraryABI

namespace LidoSRv3.Audit.Source.TrioAlloc2

/-- Actual producer lengths plus successful execution of the emitted pre-call
allocation guards establish the byte extent needed by the ABI theorem. The
allocation-prefix-to-compiler relation remains an explicit separate obligation. -/
theorem producer_memory_establishes_byte_extent
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (input : TrioAlloc1.CapacityInput) (before after : TrioAlloc1.Transcript)
    (produced : TrioAlloc1.CapacityOutput) (pointer next : Word)
    (producer : TrioAlloc1.produce layout storage oracle input before = (.ok produced, after))
    (memory : MemoryPrefix.producerPrefix pointer (storage (TrioAlloc1.countSlot layout)) = .ok next) :
    (LibraryABI.encodeArguments ⟨produced.allocations, produced.capacities, input.depositsToAllocate⟩).length < 2^64 := by
  have lengths := TrioAlloc1.producer_length_from_storage layout storage oracle input before after produced producer
  have bound := (MemoryPrefix.producerPrefix_extent _ _ _ memory).2.2
  simp only [LibraryABI.encodeArguments, List.length_append, TrioAlloc1.encodeWord_length,
    TrioAlloc1.encodeArray_length]
  omega

/-- Canonical bytes from the actual producer execute the decoded consumer;
there is no assumed byte-length bound at this composed boundary. -/
theorem producer_memory_byte_execution
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (input : TrioAlloc1.CapacityInput) (before after : TrioAlloc1.Transcript)
    (produced : TrioAlloc1.CapacityOutput) (pointer next : Word)
    (producer : TrioAlloc1.produce layout storage oracle input before = (.ok produced, after))
    (memory : MemoryPrefix.producerPrefix pointer (storage (TrioAlloc1.countSlot layout)) = .ok next) :
    LibraryABI.run (LibraryABI.encodeArguments ⟨produced.allocations, produced.capacities, input.depositsToAllocate⟩) =
      LibraryABI.encodeOutcome (allocate produced.allocations produced.capacities input.depositsToAllocate) :=
  LibraryABI.run_encoded _ (producer_memory_establishes_byte_extent _ _ _ _ _ _ _ _ _ producer memory)

#print axioms producer_memory_establishes_byte_extent
#print axioms producer_memory_byte_execution
end LidoSRv3.Audit.Source.TrioAlloc2
