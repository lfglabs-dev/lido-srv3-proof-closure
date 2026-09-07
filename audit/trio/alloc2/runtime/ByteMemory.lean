import audit.trio.alloc2.composition.ByteIndexed
import Verity.Core.Model.DenoteMemory

/-! Bridge to the pinned Verity byte-memory denotation, including zero-filled
reads and actual writeWord operations. This is distinct from ContractState's
historical word map and from a whole lowered-Yul program refinement. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (encodeWord decodeWord)
open _root_.Compiler.CompilationModel

def view (memory : DenoteMemory.Memory) : ByteMemory.Memory := memory.readByte

def encode (value : Word) : DenoteMemory.Word := fun i =>
  (encodeWord value)[i.val]'(by simpa using i.isLt)

def decode (value : DenoteMemory.Word) : Word := decodeWord (List.ofFn value) 0

theorem expandedLength_ge (endOffset : Nat) : endOffset ≤ DenoteMemory.expandedLength endOffset := by
  unfold DenoteMemory.expandedLength
  split <;> omega

theorem view_writeWord (memory : DenoteMemory.Memory) (address : Nat) (value : Word) :
    view (memory.writeWord address (encode value)) = ByteMemory.store (view memory) address value := by
  have endBound : address+32 ≤ max memory.size (DenoteMemory.expandedLength (address+32)) :=
    Nat.le_trans (expandedLength_ge _) (Nat.le_max_right _ _)
  funext position
  by_cases inside : address ≤ position ∧ position < address+32
  · have inSize : position < max memory.size (DenoteMemory.expandedLength (address+32)) := by omega
    simp [view, DenoteMemory.Memory.readByte, DenoteMemory.Memory.writeWord, DenoteMemory.Memory.expand, inSize, inside,
      ByteMemory.store, encode]
  · by_cases inSize : position < max memory.size (DenoteMemory.expandedLength (address+32))
    · simp [view, DenoteMemory.Memory.readByte, DenoteMemory.Memory.writeWord, DenoteMemory.Memory.expand, inSize, inside,
        ByteMemory.store]
    · have oldOutside : ¬ position < memory.size := by
        have := Nat.le_max_left memory.size (DenoteMemory.expandedLength (address+32))
        omega
      simp [view, DenoteMemory.Memory.readByte, DenoteMemory.Memory.writeWord, DenoteMemory.Memory.expand, inSize, inside,
        ByteMemory.store, oldOutside]

theorem readWord_decode (memory : DenoteMemory.Memory) (address : Nat) :
    decode (memory.readWord address) = ByteMemory.load (view memory) address := rfl

/-- Exact memory-operation result, rather than a separately assumed store effect. -/
theorem mstore_result (memory : DenoteMemory.Memory) (address : Nat) (value : Word) :
    ∃ next, DenoteMemory.denoteMemoryOp (.mstore address (encode value)) memory = .ok next ∧
      view next = ByteMemory.store (view memory) address value ∧ memory.size ≤ next.size := by
  refine ⟨memory.writeWord address (encode value), rfl, view_writeWord _ _ _, ?_⟩
  exact Nat.le_max_left _ _

theorem mload_result (memory : DenoteMemory.Memory) (address : Nat) :
    DenoteMemory.denoteMemoryOp (.mload address) memory =
      .word (memory.readWord address) (memory.expand (address+32)) ∧
      decode (memory.readWord address) = ByteMemory.load (view memory) address :=
  ⟨rfl, rfl⟩

/-- A read inside an already allocated, word-aligned memory extent does not
change memory. This is the condition needed to replace mload by readWord. -/
theorem expand_eq_of_covered (memory : DenoteMemory.Memory) (address : Nat)
    (aligned : memory.size % 32 = 0) (covered : address+32 ≤ memory.size) :
    memory.expand (address+32) = memory := by
  have rounded : DenoteMemory.expandedLength (address+32) ≤ memory.size := by
    simp only [DenoteMemory.expandedLength, show address+32 ≠ 0 by omega, ↓reduceIte]
    omega
  simp [DenoteMemory.Memory.expand, Nat.max_eq_left rounded]

theorem mload_covered (memory : DenoteMemory.Memory) (address : Nat)
    (aligned : memory.size % 32 = 0) (covered : address+32 ≤ memory.size) :
    DenoteMemory.denoteMemoryOp (.mload address) memory = .word (memory.readWord address) memory := by
  rw [DenoteMemory.denoteMemoryOp_mload, expand_eq_of_covered memory address aligned covered]

#print axioms expand_eq_of_covered
#print axioms mload_covered
#print axioms view_writeWord
#print axioms readWord_decode
#print axioms mstore_result
#print axioms mload_result
end LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
