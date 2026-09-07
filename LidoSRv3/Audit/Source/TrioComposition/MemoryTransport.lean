import LidoSRv3.Audit.Source.TrioAlloc2.MemoryComposition
import LidoSRv3.Audit.Source.TrioAlloc2.LibraryABI

/-! Executable source word-memory primitives. Addresses are byte addresses, but
stores update aligned word observations rather than overlapping byte windows.
The finite bounds and disjointness below are explicit compiler-refinement
obligations. These lemmas do not equate a completed ghost producer output with
the producer's actual interleaved write schedule.

Pinned SRLib.ir.yul:2391 allocates/zeros allocations; 2537 stores each first-pass
allocation; 2542 allocates capacities; 2556 reads allocations; 2595 stores
capacities; 2630ff encodes library inputs; 2670ff copies the separate return array.
-/
namespace LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
open TrioAlloc1

def store (memory : MemoryWords) (address : Nat) (value : Word) : MemoryWords :=
  fun query => if query = address then value else memory query

/-- Half-open byte extent. No modular address arithmetic is hidden here. -/
def InRegion (pointer count address : Nat) : Prop :=
  pointer ≤ address ∧ address < pointer + 32 * (count + 1)

def Disjoint (p n q k : Nat) : Prop :=
  p + 32 * (n+1) ≤ q ∨ q + 32 * (k+1) ≤ p

def OutsideUnchanged (before after : MemoryWords) (pointer count : Nat) : Prop :=
  ∀ address, ¬ InRegion pointer count address → after address = before address

/-- Forward sequential stores, preserving all other word observations. -/
def storeWords (memory : MemoryWords) (pointer : Nat) : List Word → MemoryWords
  | [] => memory
  | value :: rest => storeWords (store memory pointer value) (pointer+32) rest

theorem storeWords_outside (memory : MemoryWords) (pointer : Nat) (values : List Word)
    (address : Nat) (outside : address < pointer ∨ pointer + 32*values.length ≤ address) :
    storeWords memory pointer values address = memory address := by
  induction values generalizing memory pointer with
  | nil => rfl
  | cons value rest ih =>
    have outside' : address < pointer+32 ∨ pointer+32+32*rest.length ≤ address := by
      simp only [List.length_cons] at outside
      omega
    rw [storeWords, ih _ _ outside']
    have ne : address ≠ pointer := by simp only [List.length_cons] at outside; omega
    simp [store, ne]

theorem storeWords_read (memory : MemoryWords) (pointer : Nat) (values : List Word)
    (i : Fin values.length) :
    storeWords memory pointer values (pointer+32*i.val) = values[i] := by
  induction values generalizing memory pointer with
  | nil => exact Fin.elim0 i
  | cons value rest ih =>
    cases i with
    | mk i hi =>
      cases i with
      | zero =>
        simp only [Nat.mul_zero, Nat.add_zero, storeWords]
        rw [storeWords_outside _ _ _ pointer (Or.inl (by omega))]
        simp [store]
      | succ i =>
        have bound : i < rest.length := by simpa using hi
        have addr : pointer+32*(i+1) = pointer+32+32*i := by omega
        simpa only [storeWords, addr, Fin.getElem_fin, List.getElem_cons_succ] using
          ih (store memory pointer value) (pointer+32) ⟨i,bound⟩

/-- Header, then consecutive element stores, as in allocated array decoding. -/
def storeArray (memory : MemoryWords) (pointer : Nat) (values : List Word) : MemoryWords :=
  storeWords memory pointer (word values.length :: values)

theorem storeArray_related (memory : MemoryWords) (pointer : Nat) (values : List Word)
    (bound : values.length < 2^256) :
    ArrayAt (storeArray memory pointer values) pointer values := by
  constructor
  · have header := storeWords_read memory pointer (word values.length :: values) ⟨0,by simp⟩
    change storeWords memory pointer (word values.length :: values) pointer = word values.length at header
    change (storeWords memory pointer (word values.length :: values) pointer).val = values.length
    rw [header]
    exact Nat.mod_eq_of_lt bound
  · intro i
    exact storeWords_read memory pointer (word values.length :: values)
      ⟨i.val+1,by simp⟩

theorem storeArray_outside (memory : MemoryWords) (pointer : Nat) (values : List Word) :
    OutsideUnchanged memory (storeArray memory pointer values) pointer values.length := by
  intro address outside
  apply storeWords_outside
  simp only [InRegion] at outside
  simp only [List.length_cons]
  omega

theorem frame_array (before after : MemoryWords) (p n q : Nat) (values : List Word)
    (frame : OutsideUnchanged before after p n)
    (separate : Disjoint p n q values.length) (related : ArrayAt before q values) :
    ArrayAt after q values := by
  have untouched : ∀ address, InRegion q values.length address → after address = before address := by
    intro address inside
    apply frame
    simp only [InRegion, Disjoint] at *
    omega
  constructor
  · rw [untouched q (by constructor <;> omega)]
    exact related.1
  · intro i
    rw [untouched (q+32*(i.val+1)) (by have hi := i.isLt; constructor <;> omega)]
    exact related.2 i

/-- Fresh zero initialization is executable, and is separate from row writes. -/
def zeroArray (memory : MemoryWords) (pointer count : Nat) : MemoryWords :=
  storeArray memory pointer (List.replicate count (word 0))

theorem zeroArray_related (memory : MemoryWords) (pointer count : Nat)
    (bound : count < 2^256) :
    ArrayAt (zeroArray memory pointer count) pointer (List.replicate count (word 0)) :=
  storeArray_related memory pointer _ (by simpa using bound)

def storeElement (memory : MemoryWords) (pointer index : Nat) (value : Word) : MemoryWords :=
  store memory (pointer+32*(index+1)) value

/-- The row-loop induction can advance one actual mstore at a time. -/
theorem storeElement_related (memory : MemoryWords) (pointer : Nat) (values : List Word)
    (index : Fin values.length) (value : Word) (related : ArrayAt memory pointer values) :
    ArrayAt (storeElement memory pointer index.val value) pointer (values.set index.val value) := by
  constructor
  · have ne : pointer ≠ pointer+32*(index.val+1) := by omega
    simpa [storeElement, store, ne] using related.1
  · intro i
    have hi : i.val < values.length := by simpa using i.isLt
    have old := related.2 ⟨i.val,hi⟩
    by_cases eq : index.val = i.val
    · simp [storeElement, store, eq]
    · have addr : pointer+32*(i.val+1) ≠ pointer+32*(index.val+1) := by omega
      simp only [storeElement, store, if_neg addr]
      simpa only [Fin.getElem_fin, List.getElem_set, if_neg eq] using old

theorem storeElement_outside (memory : MemoryWords) (pointer count : Nat)
    (index : Fin count) (value : Word) :
    OutsideUnchanged memory (storeElement memory pointer index.val value) pointer count := by
  intro address outside
  have hi := index.isLt
  have ne : address ≠ pointer+32*(index.val+1) := by
    simp only [InRegion] at outside
    omega
  simp [storeElement, store, ne]

theorem outside_trans (first middle last : MemoryWords) (p n : Nat)
    (left : OutsideUnchanged first middle p n)
    (right : OutsideUnchanged middle last p n) : OutsideUnchanged first last p n := by
  intro address outside
  exact (right address outside).trans (left address outside)

theorem storeElement_frame (memory : MemoryWords) (p n q : Nat) (values : List Word)
    (index : Fin n) (value : Word) (separate : Disjoint p n q values.length)
    (related : ArrayAt memory q values) :
    ArrayAt (storeElement memory p index.val value) q values :=
  frame_array _ _ p n q values (storeElement_outside memory p n index value) separate related

theorem storeArray_frame (memory : MemoryWords) (p q : Nat) (written preserved : List Word)
    (separate : Disjoint p written.length q preserved.length)
    (related : ArrayAt memory q preserved) :
    ArrayAt (storeArray memory p written) q preserved :=
  frame_array _ _ p written.length q preserved (storeArray_outside memory p written) separate related

theorem storeArray_read (memory : MemoryWords) (pointer : Nat) (values : List Word)
    (bound : values.length < 2^256) :
    TrioAlloc2.readMemoryArray (storeArray memory pointer values) pointer = values :=
  TrioAlloc2.readMemoryArray_eq _ _ _ (storeArray_related memory pointer values bound)

#print axioms storeArray_related
#print axioms storeElement_related
#print axioms storeArray_frame
#print axioms storeElement_frame

end LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
