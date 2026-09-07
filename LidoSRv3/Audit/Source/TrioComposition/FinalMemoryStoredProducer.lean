import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryProducer
import LidoSRv3.Audit.Source.TrioComposition.ProducerStores
import audit.trio.alloc2.composition.AllocationMemoryBridge

/-! One producer call tree threads allocation guards and actual per-row array
writes. Each module call executes once. Successful memory is the memory produced
by those writes; it is never reconstructed from a completed CapacityOutput.

This is a projected word-memory model: allocation/capacity headers and cells
are observable, while cache structs, configuration buffers, slot-hash buffers,
and static-return buffers are abstract values with allocation guards. Their
physical stores require a compiler byte-memory primitive/frame relation. The
proved pointer separation below discharges overlap between the two observable
arrays; this file does not prove the omitted scratch/cache writes themselves. -/
namespace LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredProducer
open TrioAlloc1
open MemoryTransport

structure Output where
  produced : CapacityOutput
  pointer : Word
  allocationPointer : Word
  capacityPointer : Word
  memory : MemoryWords

/-- Allocation zeroing occurs before cache allocation guards. Cache payload
stores are outside the projected two-array word memory. -/
def reservePrefix (pointer count : Word) (memory : MemoryWords) :
    Except Failure (Word × MemoryWords) := do
  let allocationsEnd ← AllocationMemory.allocateArray pointer count
  let initial := zeroArray memory pointer.val count.val
  let cacheEnd ← AllocationMemory.allocateArray allocationsEnd count
  let next ← TrioAlloc2.MemoryPrefix.producerCacheRows count.val cacheEnd
  pure (next,initial)

theorem prefix_exact (pointer count : Word) (memory : MemoryWords) :
    reservePrefix pointer count memory =
      (TrioAlloc2.MemoryPrefix.producerPrefix pointer count).map
        (fun next => (next,zeroArray memory pointer.val count.val)) := by
  unfold reservePrefix TrioAlloc2.MemoryPrefix.producerPrefix
  cases first : AllocationMemory.allocateArray pointer count with
  | error reason => rfl
  | ok firstEnd =>
    simp only [bind,Except.bind]
    cases second : AllocationMemory.allocateArray firstEnd count with
    | error reason => rfl
    | ok cacheEnd =>
      cases TrioAlloc2.MemoryPrefix.producerCacheRows count.val cacheEnd <;> rfl

theorem prefix_safe (pointer count : Word) (memory : MemoryWords)
    (space : pointer.val+224*count.val+64 ≤ 2^32) :
    reservePrefix pointer count memory =
      .ok (word (pointer.val+224*count.val+64),zeroArray memory pointer.val count.val) := by
  have bound : pointer.val+224*count.val+64 < 2^64 := by omega
  rw [prefix_exact,TrioAlloc2.MemoryPrefix.prefix_eq_producer]
  change ((TrioAlloc2.MemoryPrefix.execute pointer count).mapError
    (fun _ => Failure.panic (word 0x41))).map _ = _
  rw [← MemoryGuard.check_eq]
  simp [MemoryGuard.check,MemoryGuard.run,bound,Except.mapError,Except.map]

/-- Each guarded row is followed immediately by its allocation element store. -/
def firstLoop (l : Layout) (s : Storage) (input : CapacityInput) (ap : Nat) :
    Nat → Nat → Word → Word → MemoryWords →
      CallTree.Program (((List CachedRow × Word) × MemoryWords) × Word)
  | 0, _, total, pointer, memory => pure ((([],total),memory),pointer)
  | n+1, i, total, pointer, memory => do
    let ((row,total'),next) ← FinalMemoryRows.firstRow pointer l s input i total
    let written := storeElement memory ap i row.allocation
    let (((rows,last),finalMemory),endPointer) ← firstLoop l s input ap n (i+1) total' next written
    pure (((row::rows,last),finalMemory),endPointer)

set_option maxRecDepth 4096 in
theorem firstLoop_exact (l : Layout) (s : Storage) (input : CapacityInput) (ap n i : Nat)
    (total pointer : Word) (memory : MemoryWords) (space : pointer.val+864*n ≤ 2^32) :
    firstLoop l s input ap n i total pointer memory =
      (do let result ← ProducerStores.firstLoop l s input ap n i total memory
          pure (result,FinalMemoryRows.endPointer l s n i pointer)) := by
  induction n generalizing i total pointer memory with
  | zero => rfl
  | succ n ih =>
    have rowSpace : pointer.val+864 ≤ 2^32 := by clear ih; omega
    have advanceBound := FinalMemoryRows.advance_bound pointer l s i
    have remaining : (FinalMemoryRows.advance pointer l s i).val+864*n ≤ 2^32 := by omega
    have row := FinalMemoryRows.firstRow_exact pointer l s input i total rowSpace
    change FinalMemoryRows.firstRow pointer l s input i total =
      (do let value ← CallTree.firstRow l s input i total
          pure (value,FinalMemoryRows.advance pointer l s i)) at row
    simp only [firstLoop,row,ProducerStores.firstLoop,RowMemory.bind_assoc,RowMemory.pure_bind,
      ih (i+1) _ (FinalMemoryRows.advance pointer l s i) _ remaining,FinalMemoryRows.endPointer]

/-- Lower as well as upper pointer bounds are needed to separate actual arrays. -/
theorem rows_monotone (l : Layout) (s : Storage) (n i : Nat) (pointer : Word)
    (space : pointer.val+864*n ≤ 2^32) :
    pointer.val ≤ (FinalMemoryRows.endPointer l s n i pointer).val := by
  induction n generalizing i pointer with
  | zero => exact Nat.le_refl _
  | succ n ih =>
    have increment : (if (readModule l s i).wcType.val = 2 then 160 else 0) ≤ 160 := by split <;> omega
    have small : pointer.val+704+(if (readModule l s i).wcType.val = 2 then 160 else 0) ≤ 2^32 := by omega
    have advanceVal := FinalMemoryRows.word_small _ small
    have advanceBound := FinalMemoryRows.advance_bound pointer l s i
    have remaining : (FinalMemoryRows.advance pointer l s i).val+864*n ≤ 2^32 := by omega
    have tail := ih (i+1) (FinalMemoryRows.advance pointer l s i) remaining
    simp only [FinalMemoryRows.endPointer,FinalMemoryRows.advance]
    simp only [FinalMemoryRows.advance] at tail
    rw [advanceVal] at tail
    omega

def allocationPointer (pointer : Word) : Word := word (pointer.val+128)
def cacheEnd (pointer : Word) (l : Layout) (s : Storage) : Word :=
  word ((allocationPointer pointer).val+224*(s (countSlot l)).val+64)
def rowsStart (pointer : Word) (l : Layout) (s : Storage) : Word :=
  word ((cacheEnd pointer l s).val+224)
def capacityPointer (pointer : Word) (l : Layout) (s : Storage) : Word :=
  FinalMemoryRows.endPointer l s (s (countSlot l)).val 0 (rowsStart pointer l s)
def finalPointer (pointer : Word) (l : Layout) (s : Storage) : Word :=
  word ((capacityPointer pointer l s).val+32*(s (countSlot l)).val+32)

structure Bounds (pointer : Word) (l : Layout) (s : Storage) : Prop where
  ap_value : (allocationPointer pointer).val = pointer.val+128
  cache_value : (cacheEnd pointer l s).val = (allocationPointer pointer).val+224*(s (countSlot l)).val+64
  rows_value : (rowsStart pointer l s).val = (cacheEnd pointer l s).val+224
  rows_space : (rowsStart pointer l s).val+864*(s (countSlot l)).val ≤ 2^32
  separate : (allocationPointer pointer).val+32*((s (countSlot l)).val+1) ≤ (capacityPointer pointer l s).val
  capacity_end : (capacityPointer pointer l s).val+32*((s (countSlot l)).val+1) ≤ 2^32

theorem bounds (pointer : Word) (l : Layout) (s : Storage)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32) : Bounds pointer l s := by
  have apValue : (allocationPointer pointer).val = pointer.val+128 :=
    FinalMemoryRows.word_small _ (by omega)
  have cacheValue : (cacheEnd pointer l s).val =
      (allocationPointer pointer).val+224*(s (countSlot l)).val+64 := by
    apply FinalMemoryRows.word_small; rw [apValue]; omega
  have rowsValue : (rowsStart pointer l s).val = (cacheEnd pointer l s).val+224 := by
    apply FinalMemoryRows.word_small; rw [cacheValue,apValue]; omega
  have rowSpace : (rowsStart pointer l s).val+864*(s (countSlot l)).val ≤ 2^32 := by
    rw [rowsValue,cacheValue,apValue]; omega
  have lower := rows_monotone l s (s (countSlot l)).val 0 (rowsStart pointer l s) rowSpace
  have upper := FinalMemoryRows.endPointer_bound l s (s (countSlot l)).val 0 (rowsStart pointer l s)
  change (rowsStart pointer l s).val ≤ (capacityPointer pointer l s).val at lower
  change (capacityPointer pointer l s).val ≤ (rowsStart pointer l s).val+864*(s (countSlot l)).val at upper
  refine ⟨apValue,cacheValue,rowsValue,rowSpace,?_,?_⟩
  · rw [rowsValue,cacheValue] at lower
    omega
  · rw [rowsValue,cacheValue,apValue] at upper
    omega

/-- The fused program uses exactly the final pointer of the guard-only producer. -/
theorem finalPointer_eq (pointer : Word) (l : Layout) (s : Storage)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32) :
    finalPointer pointer l s = FinalMemoryProducer.endPointer pointer l s := by
  have apValue := (bounds pointer l s space).ap_value
  have cacheEq : cacheEnd pointer l s = word (pointer.val+224*(s (countSlot l)).val+192) := by
    unfold cacheEnd
    rw [apValue]
    congr 1 <;> omega
  simp only [finalPointer,capacityPointer,rowsStart,cacheEq,
    FinalMemoryProducer.endPointer,FinalMemoryProducer.finalPointer]

theorem finalPointer_bound (pointer : Word) (l : Layout) (s : Storage)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32) :
    (finalPointer pointer l s).val ≤ pointer.val+1120*(s (countSlot l)).val+448 := by
  rw [finalPointer_eq pointer l s space]
  exact FinalMemoryProducer.endPointer_bound pointer l s

/-- A word store in the excluded cache/scratch band cannot alter either
observable array. This is the local frame primitive available for compiler
store refinement; actual byte-store addresses and aliasing remain its boundary. -/
theorem scratch_store_frame (memory : MemoryWords) (pointer : Word) (l : Layout) (s : Storage)
    (address : Nat) (value : Word) (out : CapacityOutput)
    (alength : out.allocations.length = (s (countSlot l)).val)
    (lower : (allocationPointer pointer).val+32*((s (countSlot l)).val+1) ≤ address)
    (upper : address < (capacityPointer pointer l s).val)
    (related : MemoryArraysRelated memory (allocationPointer pointer).val
      (capacityPointer pointer l s).val out) :
    MemoryArraysRelated (store memory address value) (allocationPointer pointer).val
      (capacityPointer pointer l s).val out := by
  refine ⟨?_,?_,related.2.2⟩
  · constructor
    · have ne : (allocationPointer pointer).val ≠ address := by omega
      simpa only [store,if_neg ne] using related.1.1
    · intro i
      have hi := i.isLt
      have ne : (allocationPointer pointer).val+32*(i.val+1) ≠ address := by omega
      simpa only [store,if_neg ne] using related.1.2 i
  · constructor
    · have ne : (capacityPointer pointer l s).val ≠ address := by omega
      simpa only [store,if_neg ne] using related.2.1.1
    · intro i
      have ne : (capacityPointer pointer l s).val+32*(i.val+1) ≠ address := by omega
      simpa only [store,if_neg ne] using related.2.1.2 i

/-- The executable has a single source first pass and a single capacity pass.
It allocates each observable array at the then-current free pointer. -/
def producer (memory : MemoryWords) (pointer : Word) (l : Layout) (s : Storage)
    (input : CapacityInput) : CallTree.Program Output := do
  let ap ← CallTree.check (FinalMemoryRows.slot pointer)
  let (prefixEnd,initial) ← CallTree.check (reservePrefix ap (s (countSlot l)) memory)
  let start ← CallTree.check (AllocationMemory.finalize prefixEnd (word 224))
  let (((rows,total),allocated),cp) ← firstLoop l s input ap.val (s (countSlot l)).val 0
    input.depositsToAllocate start initial
  let endPointer ← CallTree.check (AllocationMemory.allocateArray cp (s (countSlot l)))
  let capacities := zeroArray allocated cp.val (s (countSlot l)).val
  let (buckets,after) ← CallTree.check (ProducerStores.secondLoop input total cp.val rows 0 capacities)
  pure ⟨outputOfBuckets buckets,endPointer,ap,cp,after⟩

set_option maxRecDepth 4096 in
/-- Tree equality includes failures and every adversarial response continuation.
The right side is a theorem-level factorization, not an additional producer run. -/
theorem producer_exact (memory : MemoryWords) (pointer : Word) (l : Layout) (s : Storage)
    (input : CapacityInput) (hc : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32) :
    producer memory pointer l s input =
      (do let (produced,after) ← ProducerStores.producer memory (allocationPointer pointer).val
            (capacityPointer pointer l s).val l s input
          pure ⟨produced,finalPointer pointer l s,allocationPointer pointer,capacityPointer pointer l s,after⟩) := by
  have geometry := bounds pointer l s space
  have slotSpace : pointer.val+128 ≤ 2^32 := by omega
  have prefixSpace : (allocationPointer pointer).val+224*(s (countSlot l)).val+64 ≤ 2^32 := by
    rw [geometry.ap_value]; omega
  have cacheSmall : (cacheEnd pointer l s).val ≤ 2^32 := by rw [geometry.cache_value]; exact prefixSpace
  have cpSmall : (capacityPointer pointer l s).val ≤ 2^32 := by have := geometry.capacity_end; omega
  have slotEq := FinalMemoryRows.slot_exact pointer slotSpace
  change FinalMemoryRows.slot pointer = .ok (allocationPointer pointer) at slotEq
  have prefEq := prefix_safe (allocationPointer pointer) (s (countSlot l)) memory prefixSpace
  change reservePrefix (allocationPointer pointer) (s (countSlot l)) memory =
    .ok (cacheEnd pointer l s,zeroArray memory (allocationPointer pointer).val (s (countSlot l)).val) at prefEq
  have scratch := RowMemory.config_allocation (cacheEnd pointer l s) cacheSmall
  change AllocationMemory.finalize (cacheEnd pointer l s) (word 224) = .ok (rowsStart pointer l s) at scratch
  have loop := firstLoop_exact l s input (allocationPointer pointer).val (s (countSlot l)).val 0
    input.depositsToAllocate (rowsStart pointer l s)
    (zeroArray memory (allocationPointer pointer).val (s (countSlot l)).val) geometry.rows_space
  change firstLoop l s input (allocationPointer pointer).val (s (countSlot l)).val 0
      input.depositsToAllocate (rowsStart pointer l s)
      (zeroArray memory (allocationPointer pointer).val (s (countSlot l)).val) =
    (do let result ← ProducerStores.firstLoop l s input (allocationPointer pointer).val
          (s (countSlot l)).val 0 input.depositsToAllocate
          (zeroArray memory (allocationPointer pointer).val (s (countSlot l)).val)
        pure (result,capacityPointer pointer l s)) at loop
  have cap := AllocationMemory.bounded_array_allocates (capacityPointer pointer l s) (s (countSlot l)) cpSmall hc
  change AllocationMemory.allocateArray (capacityPointer pointer l s) (s (countSlot l)) =
      .ok (finalPointer pointer l s) at cap
  simp only [producer,slotEq,prefEq,scratch,loop,cap,RowMemory.check_ok_bind,
    RowMemory.bind_assoc,RowMemory.pure_bind,ProducerStores.producer]

/-- Erasing the internal memory and pointers preserves all original outcomes. -/
theorem projection (memory : MemoryWords) (pointer : Word) (l : Layout) (s : Storage)
    (input : CapacityInput) (hc : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32) :
    (do let result ← producer memory pointer l s input; pure result.produced) = CallTree.producer l s input := by
  rw [producer_exact memory pointer l s input hc space]
  simp only [RowMemory.bind_assoc,RowMemory.pure_bind]
  exact ProducerStores.projection _ _ _ _ _ _

/-- Erasing only memory and array locations retains the existing allocated
producer, including its exact final free pointer on every success. -/
theorem guard_projection (memory : MemoryWords) (pointer : Word) (l : Layout) (s : Storage)
    (input : CapacityInput) (hc : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32) :
    (do let out ← producer memory pointer l s input; pure (out.produced,out.pointer)) =
      FinalMemoryProducer.producer pointer l s input := by
  rw [producer_exact memory pointer l s input hc space,
    FinalMemoryProducer.producer_exact pointer l s input hc space]
  rw [← ProducerStores.projection memory (allocationPointer pointer).val
    (capacityPointer pointer l s).val l s input]
  simp only [RowMemory.bind_assoc,RowMemory.pure_bind,finalPointer_eq pointer l s space]

/-- A successful actual execution supplies the original execution and physical
array pointer relation, with separation and finite extents derived here. -/
theorem success (memory : MemoryWords) (pointer : Word) (l : Layout) (s : Storage)
    (oracle : StaticOracle) (input : CapacityInput) (before after : Transcript) (out : Output)
    (executed : CallTree.evaluate oracle (producer memory pointer l s input) before = (.ok out,after))
    (hc : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32) :
    produce l s oracle input before = (.ok out.produced,after) ∧
    MemoryArraysRelated out.memory out.allocationPointer.val out.capacityPointer.val out.produced ∧
    out.allocationPointer = allocationPointer pointer ∧
    out.capacityPointer = capacityPointer pointer l s ∧ out.pointer = finalPointer pointer l s := by
  rw [producer_exact memory pointer l s input hc space] at executed
  simp only [CallTree.evaluate_monad_bind,CallTree.evaluate_pure] at executed
  obtain ⟨⟨produced,final⟩,middle,stored,result⟩ := bindExec_success _ _ _ _ _ executed
  change (Except.ok ⟨produced,finalPointer pointer l s,allocationPointer pointer,capacityPointer pointer l s,final⟩,middle) =
    (.ok out,after) at result
  simp only [Prod.mk.injEq,Except.ok.injEq] at result
  obtain ⟨rfl,rfl⟩ := result
  have geometry := bounds pointer l s space
  have separate : Disjoint (allocationPointer pointer).val (s (countSlot l)).val
      (capacityPointer pointer l s).val (s (countSlot l)).val := Or.inl geometry.separate
  have aend : (allocationPointer pointer).val+32*((s (countSlot l)).val+1) ≤ 2^256 := by
    have a := geometry.separate; have b := geometry.capacity_end; omega
  have cend : (capacityPointer pointer l s).val+32*((s (countSlot l)).val+1) ≤ 2^256 := by
    have b := geometry.capacity_end; omega
  have established := ProducerStores.success memory (allocationPointer pointer).val
    (capacityPointer pointer l s).val l s oracle input before middle produced final stored separate aend cend
  exact ⟨established.1,established.2,rfl,rfl,rfl⟩

#print axioms producer_exact
#print axioms projection
#print axioms success
#print axioms bounds
#print axioms guard_projection
#print axioms scratch_store_frame
end LidoSRv3.Audit.Source.TrioComposition.FinalMemoryStoredProducer
