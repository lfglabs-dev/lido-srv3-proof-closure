import LidoSRv3.Audit.Source.TrioAlloc1.Bytes

/-! Physical byte-memory primitives. Unlike the v0 word map, a store changes
32 consecutive bytes, so overlapping unaligned reads are allowed to change.
Allocation extent, expansion gas and compiler scheduling are separate. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteMemory
open _root_.LidoSRv3.Audit.Source.TrioAlloc1

abbrev Memory := Nat → Fin 256

def bytes (memory : Memory) (address : Nat) : Bytes :=
  List.ofFn fun i : Fin 32 => memory (address+i.val)

def load (memory : Memory) (address : Nat) : Word :=
  decodeWord (bytes memory address) 0

def store (memory : Memory) (address : Nat) (value : Word) : Memory := fun position =>
  if h : address ≤ position ∧ position < address+32 then
    (encodeWord value)[position-address]'(by rw [encodeWord_length]; omega)
  else memory position

theorem store_outside (memory : Memory) (address position : Nat) (value : Word)
    (outside : position < address ∨ address+32 ≤ position) :
    store memory address value position = memory position := by
  simp only [store]
  rw [dif_neg (by omega)]

theorem bytes_store (memory : Memory) (address : Nat) (value : Word) :
    bytes (store memory address value) address = encodeWord value := by
  apply List.ext_getElem
  · simp [bytes]
  · intro i left right
    have small : i < 32 := by simpa [bytes] using left
    simp only [bytes, List.getElem_ofFn]
    simp [store, Nat.add_sub_cancel_left, show address ≤ address+i ∧ address+i < address+32 by omega]

theorem load_store (memory : Memory) (address : Nat) (value : Word) :
    load (store memory address value) address = value := by
  rw [load, bytes_store, decodeWord_encodeWord]

theorem bytes_store_disjoint (memory : Memory) (written read : Nat) (value : Word)
    (disjoint : read+32 ≤ written ∨ written+32 ≤ read) :
    bytes (store memory written value) read = bytes memory read := by
  apply congrArg List.ofFn
  funext i
  apply store_outside
  have := i.isLt
  omega

theorem load_store_disjoint (memory : Memory) (written read : Nat) (value : Word)
    (disjoint : read+32 ≤ written ∨ written+32 ≤ read) :
    load (store memory written value) read = load memory read := by
  simp only [load, bytes_store_disjoint memory written read value disjoint]

theorem store_array (memory : Memory) (pointer : Nat) (values : List Word)
    (index : Fin values.length) (value : Word) (related : ArrayAt (load memory) pointer values) :
    ArrayAt (load (store memory (pointer+32*(index.val+1)) value)) pointer
      (values.set index.val value) := by
  constructor
  · rw [load_store_disjoint memory _ pointer value (Or.inl (by omega))]
    simpa only [List.length_set] using related.1
  · intro i
    have inside : i.val < values.length := by simpa using i.isLt
    by_cases same : i.val = index.val
    · simp [same, load_store]
    · rw [load_store_disjoint memory _ _ value (by omega)]
      simpa [same, Ne.symm same] using related.2 ⟨i.val, inside⟩

theorem store_other_array (memory : Memory) (written pointer : Nat) (value : Word)
    (values : List Word) (related : ArrayAt (load memory) pointer values)
    (disjoint : written+32 ≤ pointer ∨ pointer+32*(values.length+1) ≤ written) :
    ArrayAt (load (store memory written value)) pointer values := by
  constructor
  · rw [load_store_disjoint memory written pointer value (by omega)]
    exact related.1
  · intro i
    rw [load_store_disjoint memory written _ value (by have := i.isLt; omega)]
    exact related.2 i

/-- A store's last byte becomes the high byte of a read beginning there.
This rejects treating unaligned overlapping reads as independent word slots. -/
theorem overlapping_read_changes :
    load (store (fun _ => byte 0) 128 (word 1)) 159 ≠ load (fun _ => byte 0) 159 := by
  decide

#print axioms overlapping_read_changes
#print axioms store_array
#print axioms store_other_array
#print axioms bytes_store
#print axioms load_store
#print axioms store_outside
#print axioms load_store_disjoint
end LidoSRv3.Audit.Source.TrioAlloc2.ByteMemory
