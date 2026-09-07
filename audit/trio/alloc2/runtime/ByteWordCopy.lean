import audit.trio.alloc2.runtime.ByteABIFrame
import audit.trio.alloc2.runtime.ByteCoverage

/-! Word copy used by the emitted SRLib return decoder: increasing source and
 destination addresses, one mload followed by one mstore per word. The covered
 source premise justifies the exact mload memory result; the fresh destination
 premise prevents writes from changing later reads. Allocation/decoder guards
 must establish these premises before this loop is entered. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
open _root_.Compiler.CompilationModel
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (ArrayAt)

def copyWords (memory : DenoteMemory.Memory) (src dest : Nat) : Nat → DenoteMemory.Memory
  | 0 => memory
  | n+1 => copyWords (memory.writeWord dest (memory.readWord src)) (src+32) (dest+32) n

theorem raw_store_byte_frame (memory : DenoteMemory.Memory) (dest address : Nat)
    (value : DenoteMemory.Word) (outside : address < dest ∨ dest+32 ≤ address) :
    (memory.writeWord dest value).readByte address = memory.readByte address := by
  have absent : ¬ (dest ≤ address ∧ address < dest+32) := by omega
  by_cases covered : address < max memory.size (DenoteMemory.expandedLength (dest+32))
  · simp [DenoteMemory.Memory.readByte, DenoteMemory.Memory.writeWord,
      DenoteMemory.Memory.expand, covered, absent]
  · have oldAbsent : ¬ address < memory.size := by omega
    simp [DenoteMemory.Memory.readByte, DenoteMemory.Memory.writeWord,
      DenoteMemory.Memory.expand, covered, oldAbsent]

theorem raw_store_readWord (memory : DenoteMemory.Memory) (dest : Nat) (value : DenoteMemory.Word) :
    (memory.writeWord dest value).readWord dest = value := by
  funext i
  have bound : dest+i.val < max memory.size (DenoteMemory.expandedLength (dest+32)) :=
    Nat.lt_of_lt_of_le (by have := i.isLt; omega)
      (Nat.le_trans (expandedLength_ge _) (Nat.le_max_right _ _))
  change (if dest+i.val < max memory.size (DenoteMemory.expandedLength (dest+32)) then _ else _) = _
  rw [if_pos bound]
  exact DenoteMemory.Memory.writeWord_at memory dest value i

theorem raw_store_word_frame (memory : DenoteMemory.Memory) (dest address : Nat)
    (value : DenoteMemory.Word) (outside : address+32 ≤ dest ∨ dest+32 ≤ address) :
    (memory.writeWord dest value).readWord address = memory.readWord address := by
  funext i
  exact raw_store_byte_frame memory dest (address+i.val) value (by have := i.isLt; omega)

theorem copyWords_byte_frame (n : Nat) (memory : DenoteMemory.Memory) (src dest address : Nat)
    (outside : address < dest ∨ dest+32*n ≤ address) :
    (copyWords memory src dest n).readByte address = memory.readByte address := by
  induction n generalizing memory src dest with
  | zero => rfl
  | succ n ih =>
    rw [copyWords, ih _ _ _ (by omega)]
    exact raw_store_byte_frame _ _ _ _ (by omega)

theorem copyWords_word_frame (n : Nat) (memory : DenoteMemory.Memory) (src dest address : Nat)
    (outside : address+32 ≤ dest ∨ dest+32*n ≤ address) :
    (copyWords memory src dest n).readWord address = memory.readWord address := by
  funext i
  exact copyWords_byte_frame n memory src dest (address+i.val) (by have := i.isLt; omega)

/-- Each destination word is the original source word, including unaligned
addresses; freshness covers the complete source interval. -/
theorem copyWords_read (n : Nat) (memory : DenoteMemory.Memory) (src dest index : Nat)
    (inside : index < n) (fresh : src+32*n ≤ dest) :
    (copyWords memory src dest n).readWord (dest+32*index) = memory.readWord (src+32*index) := by
  induction n generalizing memory src dest index with
  | zero => omega
  | succ n ih =>
    cases index with
    | zero =>
      simp only [Nat.mul_zero, Nat.add_zero, copyWords]
      rw [copyWords_word_frame n _ (src+32) (dest+32) dest (Or.inl (Nat.le_refl _))]
      exact raw_store_readWord _ _ _
    | succ index =>
      have copied := ih (memory.writeWord dest (memory.readWord src)) (src+32) (dest+32) index
        (by omega) (by omega)
      have framed := raw_store_word_frame memory dest (src+32+32*index) (memory.readWord src)
        (Or.inl (by omega))
      simpa only [copyWords, Nat.mul_add, Nat.mul_one, Nat.add_assoc, Nat.add_left_comm,
        Nat.add_comm] using copied.trans framed

/-- The actual primitive-operation schedule, including mload's memory result. -/
inductive WordCopyTrace : DenoteMemory.Memory → Nat → Nat → Nat → DenoteMemory.Memory → Prop
  | done (memory : DenoteMemory.Memory) (src dest : Nat) : WordCopyTrace memory src dest 0 memory
  | step (memory next final : DenoteMemory.Memory) (src dest n : Nat)
      (loaded : DenoteMemory.denoteMemoryOp (.mload src) memory = .word (memory.readWord src) memory)
      (stored : DenoteMemory.denoteMemoryOp (.mstore dest (memory.readWord src)) memory = .ok next)
      (rest : WordCopyTrace next (src+32) (dest+32) n final) :
      WordCopyTrace memory src dest (n+1) final

theorem copyWords_trace (n : Nat) (memory : DenoteMemory.Memory) (src dest : Nat)
    (aligned : memory.size % 32 = 0) (covered : src+32*n ≤ memory.size) :
    WordCopyTrace memory src dest n (copyWords memory src dest n) := by
  induction n generalizing memory src dest with
  | zero => exact .done memory src dest
  | succ n ih =>
    apply WordCopyTrace.step memory (memory.writeWord dest (memory.readWord src)) _ src dest n
    · exact mload_covered memory src aligned (by omega)
    · rfl
    · apply ih
      · change max memory.size (DenoteMemory.expandedLength (dest+32)) % 32 = 0
        rcases Nat.le_total memory.size (DenoteMemory.expandedLength (dest+32)) with left | right
        · simpa only [Nat.max_eq_right left] using DenoteMemory.expandedLength_aligned (dest+32)
        · simpa only [Nat.max_eq_left right] using aligned
      · exact Nat.le_trans (by omega) (Nat.le_max_left _ _)

#print axioms copyWords_read
#print axioms copyWords_byte_frame
#print axioms copyWords_trace
end LidoSRv3.Audit.Source.TrioAlloc2.ByteRuntime
