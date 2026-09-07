import audit.trio.alloc2.runtime.ByteMemory
import audit.trio.alloc2.composition.LibraryABI

namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
open _root_.Compiler.CompilationModel
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (Bytes)

/-- Observe an actual contiguous byte interval after an executed copy. -/
def readBytes (memory : DenoteMemory.Memory) (pointer size : Nat) : Bytes :=
  List.ofFn fun i : Fin size => memory.readByte (pointer+i.val)

theorem copyFrom_readByte (memory : DenoteMemory.Memory) (source : Nat → DenoteMemory.Byte)
    (dest offset size index : Nat) (inside : index < size) :
    (memory.copyFrom source dest offset size).readByte (dest+index) = source (offset+index) := by
  have bound : dest+index < max memory.size (DenoteMemory.expandedLength (dest+size)) :=
    Nat.lt_of_lt_of_le (by omega) (Nat.le_trans (expandedLength_ge _) (Nat.le_max_right _ _))
  change (if dest+index < max memory.size (DenoteMemory.expandedLength (dest+size)) then _ else _) = _
  rw [if_pos bound]
  exact DenoteMemory.Memory.copyFrom_at memory source dest offset size ⟨index, inside⟩

theorem copyFrom_frame (memory : DenoteMemory.Memory) (source : Nat → DenoteMemory.Byte)
    (dest offset size address : Nat) (outside : address < dest ∨ dest+size ≤ address) :
    (memory.copyFrom source dest offset size).readByte address = memory.readByte address := by
  have absent : ¬ (dest ≤ address ∧ address < dest+size) := by omega
  by_cases covered : address < max memory.size (DenoteMemory.expandedLength (dest+size))
  · simp [DenoteMemory.Memory.readByte, DenoteMemory.Memory.copyFrom,
      DenoteMemory.Memory.expand, covered, absent]
  · have oldAbsent : ¬ address < memory.size := by omega
    simp [DenoteMemory.Memory.readByte, DenoteMemory.Memory.copyFrom,
      DenoteMemory.Memory.expand, covered, oldAbsent]

/-- Full byte equality, not merely equality of selected decoded words. -/
theorem copied_bytes (memory : DenoteMemory.Memory) (bytes : Bytes) (dest : Nat) :
    readBytes (memory.copyFrom (DenoteMemory.listByte bytes) dest 0 bytes.length) dest bytes.length = bytes := by
  apply List.ext_getElem (by simp [readBytes])
  intro i hi hj
  simp only [readBytes, List.getElem_ofFn]
  rw [copyFrom_readByte _ _ _ _ _ _ hj]
  simp [DenoteMemory.listByte, List.getElem?_eq_getElem hj]

theorem calldata_arguments (memory : DenoteMemory.Memory) (a : LibraryABI.Arguments) (dest : Nat)
    (bound : (LibraryABI.encodeArguments a).length < 2^64) :
    let bytes := LibraryABI.encodeArguments a
    let next := memory.copyFrom (DenoteMemory.listByte bytes) dest 0 bytes.length
    DenoteMemory.denoteMemoryOp (.calldatacopy dest 0 bytes.length (DenoteMemory.listByte bytes)) memory = .ok next ∧
    LibraryABI.decodeArguments (readBytes next dest bytes.length) = .ok a ∧
    LibraryABI.run (readBytes next dest bytes.length) =
      LibraryABI.encodeOutcome (allocate a.buckets a.capacities a.demand) := by
  dsimp only
  rw [copied_bytes]
  exact ⟨rfl, LibraryABI.decodeArguments_encoded a bound, LibraryABI.run_encoded a bound⟩

theorem returndata_output (memory : DenoteMemory.Memory) (out : StepOutput) (dest : Nat)
    (bound : out.buckets.length < 2^64) :
    let bytes := LibraryABI.encodeReturn out
    let next := memory.copyFrom (DenoteMemory.listByte bytes) dest 0 bytes.length
    DenoteMemory.denoteMemoryOp (.returndatacopy dest 0 bytes.length bytes) memory = .ok next ∧
    LibraryABI.decodeReturn (readBytes next dest bytes.length) = .ok out := by
  dsimp only
  rw [copied_bytes]
  constructor
  · simp [DenoteMemory.denoteMemoryOp]
  · exact LibraryABI.decodeReturn_encoded out bound

#print axioms copyFrom_readByte
#print axioms copyFrom_frame
#print axioms copied_bytes
#print axioms calldata_arguments
#print axioms returndata_output
end LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
