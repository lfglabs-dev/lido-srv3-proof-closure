import LidoSRv3.Audit.Source.TrioComposition.MemoryTransport

/-! Five-word first-pass cache representation used by the second pass. These
are executable stores and loads; the concrete pointer-table placement and
interleaved frame relation remain local compiler-representation obligations. -/
namespace LidoSRv3.Audit.Source.TrioComposition.CacheRepresentation
open TrioAlloc1 MemoryTransport

def fields (row : CachedRow) : List Word :=
  [row.summary.depositable,row.active,word row.stored.share.val,word row.stored.status.val,word row.stored.wcType.val]

def write (memory : MemoryWords) (pointer : Nat) (row : CachedRow) : MemoryWords :=
  storeWords memory pointer (fields row)

def CacheAt (memory : MemoryWords) (pointer : Nat) (row : CachedRow) : Prop :=
  memory pointer = row.summary.depositable ∧
  memory (pointer+32) = row.active ∧
  memory (pointer+64) = word row.stored.share.val ∧
  memory (pointer+96) = word row.stored.status.val ∧
  memory (pointer+128) = word row.stored.wcType.val

theorem write_related (memory : MemoryWords) (pointer : Nat) (row : CachedRow) :
    CacheAt (write memory pointer row) pointer row := by
  have a := storeWords_read memory pointer (fields row) ⟨0,by simp [fields]⟩
  have b := storeWords_read memory pointer (fields row) ⟨1,by simp [fields]⟩
  have c := storeWords_read memory pointer (fields row) ⟨2,by simp [fields]⟩
  have d := storeWords_read memory pointer (fields row) ⟨3,by simp [fields]⟩
  have e := storeWords_read memory pointer (fields row) ⟨4,by simp [fields]⟩
  exact ⟨a,b,c,d,e⟩

/-- Actual second-pass cache reads, with allocation loaded from its separate
array by the caller. It does not receive a CachedRow as executable input. -/
def capacity (input : CapacityInput) (total allocation : Word)
    (memory : MemoryWords) (pointer : Nat) : Except Failure Word := do
  if (memory (pointer+96)).val ≠ 0 then pure allocation
  else
    let available ← if input.isTopUp && (memory (pointer+128)).val == 2 then do
      let product ← checked ((memory (pointer+32)).val * input.config.maxEBType2.val)
      checkedDiv product input.config.maxEBType1
      else checked (allocation.val + (memory pointer).val)
    let product ← checked ((memory (pointer+64)).val * total.val)
    pure (word (min (product.val / 10000) available.val))

theorem capacity_correspondence (input : CapacityInput) (total : Word)
    (memory : MemoryWords) (pointer : Nat) (row : CachedRow)
    (related : CacheAt memory pointer row) :
    capacity input total row.allocation memory pointer = rowCapacity input total row := by
  rcases related with ⟨a,b,c,d,e⟩
  have share : row.stored.share.val < 2^256 := Nat.lt_trans row.stored.share.isLt (by decide)
  have status : row.stored.status.val < 2^256 := Nat.lt_trans row.stored.status.isLt (by decide)
  have wc : row.stored.wcType.val < 2^256 := Nat.lt_trans row.stored.wcType.isLt (by decide)
  simp only [capacity,rowCapacity,a,b,c,d,e,word,Nat.mod_eq_of_lt share,
    Nat.mod_eq_of_lt status,Nat.mod_eq_of_lt wc]

/-- The read correspondence is derived from executed cache stores, with every
capacity arithmetic failure preserved. -/
theorem write_then_capacity (input : CapacityInput) (total : Word)
    (memory : MemoryWords) (pointer : Nat) (row : CachedRow) :
    capacity input total row.allocation (write memory pointer row) pointer =
      rowCapacity input total row :=
  capacity_correspondence input total _ pointer row (write_related memory pointer row)

theorem outside (memory : MemoryWords) (pointer : Nat) (row : CachedRow)
    (address : Nat) (separate : address < pointer ∨ pointer+160 ≤ address) :
    write memory pointer row address = memory address :=
  storeWords_outside memory pointer (fields row) address separate

/-- The five cache stores preserve an already-live output array whenever their
allocated span is disjoint. This is a local frame lemma for insertion into the
full monotone allocation schedule, not a global hash-disjointness assumption. -/
theorem preserves_array (memory : MemoryWords) (pointer : Nat) (row : CachedRow)
    (ap : Nat) (values : List Word) (related : ArrayAt memory ap values)
    (separate : ap+32*(values.length+1) ≤ pointer ∨ pointer+160 ≤ ap) :
    ArrayAt (write memory pointer row) ap values := by
  constructor
  · rw [outside memory pointer row ap (by omega)]
    exact related.1
  · intro i
    rw [outside memory pointer row (ap+32*(i.val+1)) (by have hi := i.isLt; omega)]
    exact related.2 i

#print axioms preserves_array

#print axioms write_related
#print axioms write_then_capacity
#print axioms outside
end LidoSRv3.Audit.Source.TrioComposition.CacheRepresentation
