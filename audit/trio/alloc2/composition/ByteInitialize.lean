import audit.trio.alloc2.composition.ByteIndexed

/-! Constructive physical-array initialization by 32-byte stores, starting from
arbitrary existing memory. This is a store-sequence lemma for the later producer
bridge, not a claim about the producer/compiler's complete write schedule. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.ByteMemory
open _root_.LidoSRv3.Audit.Source.TrioAlloc1

def writeWords (memory : Memory) (start : Nat) : List Word → Memory
  | [] => memory
  | value :: rest => writeWords (store memory start value) (start+32) rest

theorem writeWords_outside (values : List Word) (memory : Memory) (start address : Nat)
    (h : address < start ∨ start+32*values.length ≤ address) :
    writeWords memory start values address = memory address := by
  induction values generalizing memory start with
  | nil => rfl
  | cons value rest ih =>
    simp only [List.length_cons] at h
    rw [writeWords, ih _ _ (by omega)]
    exact store_outside memory start address value (by omega)

theorem writeWords_load_outside (values : List Word) (memory : Memory) (start address : Nat)
    (h : address+32 ≤ start ∨ start+32*values.length ≤ address) :
    load (writeWords memory start values) address = load memory address := by
  induction values generalizing memory start with
  | nil => rfl
  | cons value rest ih =>
    simp only [List.length_cons] at h
    rw [writeWords, ih _ _ (by omega)]
    exact load_store_disjoint memory start address value (by omega)

theorem writeWords_element (values : List Word) (memory : Memory) (start : Nat)
    (i : Fin values.length) :
    load (writeWords memory start values) (start+32*i.val) = values[i] := by
  induction values generalizing memory start with
  | nil => exact Fin.elim0 i
  | cons value rest ih =>
    rcases i with ⟨i, bound⟩
    cases i with
    | zero =>
      simp only [writeWords, Nat.mul_zero, Nat.add_zero]
      rw [writeWords_load_outside rest _ (start+32) start (Or.inl (by omega))]
      exact load_store memory start value
    | succ i =>
      have inside : i < rest.length := by simpa using Nat.lt_of_succ_lt_succ bound
      have addr : start+32*(i+1) = (start+32)+32*i := by omega
      change load (writeWords (store memory start value) (start+32) rest) (start+32*(i+1)) = rest[i]
      rw [addr]
      exact ih (store memory start value) (start+32) ⟨i, inside⟩

/-- Writes the length header as well as every element. -/
def writeArray (memory : Memory) (pointer : Nat) (values : List Word) : Memory :=
  writeWords memory pointer (word values.length :: values)

theorem writeArray_related (memory : Memory) (pointer : Nat) (values : List Word)
    (bound : values.length < 2^256) :
    ArrayAt (load (writeArray memory pointer values)) pointer values := by
  constructor
  · have header := writeWords_element (word values.length :: values) memory pointer ⟨0, by simp⟩
    simpa [writeArray, word, Nat.mod_eq_of_lt bound] using congrArg Fin.val header
  · intro i
    exact writeWords_element (word values.length :: values) memory pointer ⟨i.val+1, by simpa using Nat.succ_lt_succ i.isLt⟩

theorem writeArray_preserves_other (memory : Memory) (written pointer : Nat)
    (new old : List Word) (related : ArrayAt (load memory) pointer old)
    (separated : pointer+32*(old.length+1) ≤ written ∨ written+32*(new.length+1) ≤ pointer) :
    ArrayAt (load (writeArray memory written new)) pointer old := by
  constructor
  · rw [writeArray, writeWords_load_outside _ memory written pointer (by simp; omega)]
    exact related.1
  · intro i
    rw [writeArray, writeWords_load_outside _ memory written _ (by have := i.isLt; simp; omega)]
    exact related.2 i

def constructArrays (memory : Memory) (ap cp : Nat) (buckets capacities : List Word) : Memory :=
  writeArray (writeArray memory ap buckets) cp capacities

theorem constructArrays_related (memory : Memory) (ap cp : Nat) (buckets capacities : List Word)
    (bucketBound : buckets.length < 2^256) (capacityBound : capacities.length < 2^256)
    (separated : ap+32*(buckets.length+1) ≤ cp ∨ cp+32*(capacities.length+1) ≤ ap) :
    ByteIndexed.ArraysAt (constructArrays memory ap cp buckets capacities) ap cp buckets capacities := by
  exact ⟨writeArray_preserves_other (writeArray memory ap buckets) cp ap capacities buckets
    (writeArray_related memory ap buckets bucketBound) separated,
    writeArray_related (writeArray memory ap buckets) cp capacities capacityBound, separated⟩

#print axioms writeWords_outside
#print axioms writeWords_load_outside
#print axioms writeWords_element
#print axioms writeArray_related
#print axioms constructArrays_related
end LidoSRv3.Audit.Source.TrioAlloc2.ByteMemory
