import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredProducer

/-! Five cache-field word stores from SRLib.sol:513-525 (struct fields at
SRLib.sol:43-49). The stored producer allocates the pointer array and 160-byte
rows before module calls. The compiler artifact records offsets 64, 96, 128,
0, 32 in this source order. This leaf proves field reads and array preservation
for derived row addresses; it does not yet insert the stores around the calls
in the main producer, model configuration/return buffers, or prove byte-memory
compiler correspondence. Values here are the already decoded source fields. -/
namespace LidoSRv3.Audit.Source.TrioComposition.CacheStores
open TrioAlloc1 MemoryTransport FinalMemoryStoredProducer

structure Values where
  share : Word
  status : Word
  wcType : Word
  depositable : Word
  active : Word

def write (memory : MemoryWords) (p : Nat) (v : Values) : MemoryWords :=
  let a := store memory (p+64) v.share
  let b := store a (p+96) v.status
  let c := store b (p+128) v.wcType
  let d := store c p v.depositable
  store d (p+32) v.active

theorem fields (memory : MemoryWords) (p : Nat) (v : Values) :
    (write memory p v) (p+64) = v.share ∧
    (write memory p v) (p+96) = v.status ∧
    (write memory p v) (p+128) = v.wcType ∧
    (write memory p v) p = v.depositable ∧
    (write memory p v) (p+32) = v.active := by
  simp [write, store]

theorem outside (memory : MemoryWords) (p address : Nat) (v : Values)
    (h : address < p ∨ p+160 ≤ address) :
    write memory p v address = memory address := by
  have h0 : address ≠ p := by omega
  have h1 : address ≠ p+32 := by omega
  have h2 : address ≠ p+64 := by omega
  have h3 : address ≠ p+96 := by omega
  have h4 : address ≠ p+128 := by omega
  simp [write, store, h0, h1, h2, h3, h4]

def rowAddress (pointer : Word) (count index : Nat) : Nat :=
  (allocationPointer pointer).val + 64*(count+1) + 160*index

theorem row_bounds (pointer : Word) (l : Layout) (s : Storage) (i : Nat)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32)
    (hi : i < (s (countSlot l)).val) :
    (allocationPointer pointer).val+32*((s (countSlot l)).val+1) ≤
      rowAddress pointer (s (countSlot l)).val i ∧
    rowAddress pointer (s (countSlot l)).val i + 160 ≤ (capacityPointer pointer l s).val := by
  have b := bounds pointer l s space
  have monotone := rows_monotone l s (s (countSlot l)).val 0 (rowsStart pointer l s) b.rows_space
  change (rowsStart pointer l s).val ≤ (capacityPointer pointer l s).val at monotone
  have hc := b.cache_value
  have hr := b.rows_value
  simp only [rowAddress]
  omega

theorem preserves_arrays (memory : MemoryWords) (pointer : Word) (l : Layout)
    (s : Storage) (i : Nat) (v : Values) (out : CapacityOutput)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32)
    (hi : i < (s (countSlot l)).val)
    (alength : out.allocations.length = (s (countSlot l)).val)
    (related : MemoryArraysRelated memory (allocationPointer pointer).val
      (capacityPointer pointer l s).val out) :
    MemoryArraysRelated (write memory (rowAddress pointer (s (countSlot l)).val i) v)
      (allocationPointer pointer).val (capacityPointer pointer l s).val out := by
  have hb := row_bounds pointer l s i space hi
  unfold write
  apply scratch_store_frame _ pointer l s _ _ out alength (by omega) (by omega)
  apply scratch_store_frame _ pointer l s _ _ out alength (by omega) (by omega)
  apply scratch_store_frame _ pointer l s _ _ out alength (by omega) (by omega)
  apply scratch_store_frame _ pointer l s _ _ out alength (by omega) (by omega)
  exact scratch_store_frame _ pointer l s _ _ out alength (by omega) (by omega) related

/-- Values used by the first pass, including already decoded narrow fields. -/
def fromRow (row : CachedRow) : Values :=
  ⟨word row.stored.share.val, word row.stored.status.val, word row.stored.wcType.val,
    row.summary.depositable, row.active⟩

/-- Second-pass reads of the five fields in SRLib.sol:542-552. -/
def capacityFromMemory (input : CapacityInput) (total allocation : Word)
    (memory : MemoryWords) (p : Nat) : Except Failure Word := do
  if (memory (p+96)).val ≠ 0 then pure allocation
  else
    let available ← if input.isTopUp && (memory (p+128)).val == 2 then do
      let product ← checked ((memory (p+32)).val * input.config.maxEBType2.val)
      checkedDiv product input.config.maxEBType1
      else checked (allocation.val + (memory p).val)
    let product ← checked ((memory (p+64)).val * total.val)
    let target := product.val / 10000
    pure (word (min target available.val))

theorem capacity_after_write (input : CapacityInput) (total : Word)
    (row : CachedRow) (memory : MemoryWords) (p : Nat) :
    capacityFromMemory input total row.allocation (write memory p (fromRow row)) p =
      rowCapacity input total row := by
  obtain ⟨hs, ht, hw, hd, ha⟩ := fields memory p (fromRow row)
  have shareSmall : row.stored.share.val < 2^256 := by have h := row.stored.share.isLt; omega
  have statusSmall : row.stored.status.val < 2^256 := by have h := row.stored.status.isLt; omega
  have typeSmall : row.stored.wcType.val < 2^256 := by have h := row.stored.wcType.isLt; omega
  simp only [capacityFromMemory]
  simp only [hs, ht, hw, hd, ha]
  simp only [fromRow, word,
    Nat.mod_eq_of_lt shareSmall, Nat.mod_eq_of_lt statusSmall, Nat.mod_eq_of_lt typeSmall,
    rowCapacity]

#print axioms fields
#print axioms preserves_arrays
#print axioms capacity_after_write

end LidoSRv3.Audit.Source.TrioComposition.CacheStores
