import LidoSRv3.Audit.Source.TrioAlloc2.LibraryABI
import LidoSRv3.Audit.Source.TrioAlloc2.Composition

/-! Integrated producer-to-library byte boundary. The extent premise remains
explicit until derived from the executed compiler allocation schedule. This
does not identify the byte codec with arbitrary deployed DELEGATECALL behavior. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2

def producerArguments (output : TrioAlloc1.CapacityOutput) (demand : Word) :
    LibraryABI.Arguments := ⟨output.allocations, output.capacities, demand⟩

/-- Actual producer outputs flow through argument decoding, proportional
execution, return encoding and return decoding. Consumer success is derived,
not assumed. The original allocations remain available to the parent's delta
conversion because only the decoded return array is passed back. -/
theorem producer_then_abi_distributes
    (layout : TrioAlloc1.Layout) (storage : TrioAlloc1.Storage) (oracle : TrioAlloc1.StaticOracle)
    (input : TrioAlloc1.CapacityInput) (before after : TrioAlloc1.Transcript)
    (output : TrioAlloc1.CapacityOutput)
    (executed : TrioAlloc1.produce layout storage oracle input before = (.ok output, after))
    (extent : (LibraryABI.encodeArguments
      (producerArguments output input.depositsToAllocate)).length < 2^64) :
    ∃ result,
      LibraryABI.run (LibraryABI.encodeArguments
        (producerArguments output input.depositsToAllocate)) =
        .ok (LibraryABI.encodeReturn result) ∧
      LibraryABI.decodeReturn (LibraryABI.encodeReturn result) = .ok result ∧
      Spec.Distributes (decodedRows output.allocations output.capacities)
        input.depositsToAllocate.val result.amount.val
        (decodedRows result.buckets output.capacities) := by
  obtain ⟨result, ran, distributed⟩ := producer_then_consumer_distributes
    layout storage oracle input before after output executed
  have size := extent
  simp only [producerArguments, LibraryABI.encodeArguments, List.length_append,
    TrioAlloc1.encodeWord_length, TrioAlloc1.encodeArray_length] at size
  have resultBound : result.buckets.length < 2^64 := by
    rw [allocate_preserves_length _ _ _ _ ran]
    omega
  refine ⟨result, ?_, LibraryABI.decodeReturn_encoded result resultBound, distributed⟩
  rw [LibraryABI.run_encoded _ extent]
  change LibraryABI.encodeOutcome
    (allocate output.allocations output.capacities input.depositsToAllocate) = _
  rw [ran]
  rfl

#print axioms producer_then_abi_distributes
end LidoSRv3.Audit.Source.TrioAlloc2
