import audit.trio.alloc2.runtime.ByteABI
import audit.trio.alloc2.composition.ProducerMemory

namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
open _root_.Compiler.CompilationModel
open _root_.LidoSRv3.Audit.Source.TrioAlloc1

/-- Actual successful interleaved producer execution establishes the copy/ABI
extent and the proportional result. The caller and callee have separate memory;
this theorem does not replace the compiler's decoder/allocation schedule. -/
theorem producer_copied_abi
    (layout : Layout) (storage : Storage) (oracle : StaticOracle) (input : CapacityInput)
    (before after : ProducerMemory.State) (produced : CapacityOutput)
    (executed : ProducerMemory.produceM layout storage oracle input before = (.ok produced, after))
    (callee caller : DenoteMemory.Memory) (argumentPointer returnPointer : Nat) :
    let args : LibraryABI.Arguments := ⟨produced.allocations, produced.capacities, input.depositsToAllocate⟩
    let argumentBytes := LibraryABI.encodeArguments args
    let entered := callee.copyFrom (DenoteMemory.listByte argumentBytes) argumentPointer 0 argumentBytes.length
    DenoteMemory.denoteMemoryOp (.calldatacopy argumentPointer 0 argumentBytes.length
      (DenoteMemory.listByte argumentBytes)) callee = .ok entered ∧
    ∃ result,
      LibraryABI.run (readBytes entered argumentPointer argumentBytes.length) = .ok (LibraryABI.encodeReturn result) ∧
      Spec.Distributes (decodedRows produced.allocations produced.capacities)
        input.depositsToAllocate.val result.amount.val (decodedRows result.buckets produced.capacities) ∧
      let resultBytes := LibraryABI.encodeReturn result
      let returned := caller.copyFrom (DenoteMemory.listByte resultBytes) returnPointer 0 resultBytes.length
      DenoteMemory.denoteMemoryOp (.returndatacopy returnPointer 0 resultBytes.length resultBytes) caller = .ok returned ∧
      LibraryABI.decodeReturn (readBytes returned returnPointer resultBytes.length) = .ok result := by
  have original := (ProducerMemory.success_establishes_premises layout storage oracle input before after produced executed).1
  obtain ⟨start, next, prefixRun⟩ := ProducerMemory.success_prefix layout storage oracle input before after produced executed
  have extent := producer_memory_establishes_byte_extent layout storage oracle input before.trace after.trace
    produced start next original prefixRun
  have copied := calldata_arguments callee ⟨produced.allocations, produced.capacities, input.depositsToAllocate⟩
    argumentPointer extent
  obtain ⟨result, allocated, distributes⟩ := producer_then_consumer_distributes layout storage oracle input
    before.trace after.trace produced original
  have resultLength := allocate_preserves_length _ _ _ _ allocated
  have bucketBound : result.buckets.length < 2^64 := by
    simp only [LibraryABI.encodeArguments, List.length_append, encodeWord_length, encodeArray_length] at extent
    omega
  refine ⟨copied.1, result, ?_, distributes, returndata_output caller result returnPointer bucketBound⟩
  rw [copied.2.2, allocated]
  rfl

#print axioms producer_copied_abi
end LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
