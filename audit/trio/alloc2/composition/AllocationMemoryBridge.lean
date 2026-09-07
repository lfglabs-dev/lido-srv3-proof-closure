import LidoSRv3.Audit.Source.TrioAlloc1.AllocationMemory
import LidoSRv3.Audit.Source.TrioAlloc2.MemoryPrefix

/-! Exact word-operation bridge to the producer's pinned allocation primitives.
This removes an independently assumed rounding/alignment model at this boundary.
It does not certify the full compiler schedule, memory stores or gas behavior. -/
namespace LidoSRv3.Audit.Source.TrioAlloc2.MemoryPrefix
open _root_.LidoSRv3.Audit.Source.TrioAlloc1 (word)

def toProducer (result : AllocResult) : Except TrioAlloc1.Failure Word :=
  result.mapError fun _ => .panic (word 0x41)

theorem rounded_aligned (size : Word) (small : size.val < 2^128) (aligned : size.val % 32 = 0) :
    TrioAlloc1.AllocationMemory.roundedSize size = size.val := by
  have bound : size.val+31 < 2^256 := by omega
  simp only [TrioAlloc1.AllocationMemory.roundedSize, Nat.mod_eq_of_lt bound]
  omega

theorem finalize_eq_reserve (pointer size : Word) (small : size.val < 2^128)
    (aligned : size.val % 32 = 0) :
    TrioAlloc1.AllocationMemory.finalize pointer size = toProducer (reserve pointer size.val) := by
  have rounded := rounded_aligned size small aligned
  have guard : ((pointer.val+size.val)%2^256 > TrioAlloc1.AllocationMemory.limit ∨
      (pointer.val+size.val)%2^256 < pointer.val) ↔
      ((pointer.val+size.val)%2^256 ≥ 2^64 ∨ (pointer.val+size.val)%2^256 < pointer.val) := by
    unfold TrioAlloc1.AllocationMemory.limit
    omega
  simp only [TrioAlloc1.AllocationMemory.finalize, rounded, word, reserve, toProducer]
  simp only [guard]
  split <;> rfl

theorem array_eq_producer (pointer count : Word) :
    TrioAlloc1.AllocationMemory.allocateArray pointer count = toProducer (array pointer count) := by
  by_cases large : count.val ≥ 2^64
  · have producerLarge : count.val > TrioAlloc1.AllocationMemory.limit := by
      unfold TrioAlloc1.AllocationMemory.limit; omega
    simp [TrioAlloc1.AllocationMemory.allocateArray, TrioAlloc1.AllocationMemory.arraySize,
      producerLarge, array, large, toProducer, bind, Except.bind, Except.mapError]
  · have producerSmall : ¬ count.val > TrioAlloc1.AllocationMemory.limit := by
      unfold TrioAlloc1.AllocationMemory.limit; omega
    have sizeBound : 32*count.val+32 < 2^256 := by omega
    have small : (word (32*count.val+32)).val < 2^128 := by
      simp only [word, Nat.mod_eq_of_lt sizeBound]; omega
    have aligned : (word (32*count.val+32)).val % 32 = 0 := by
      simp only [word, Nat.mod_eq_of_lt sizeBound]; omega
    simp only [TrioAlloc1.AllocationMemory.allocateArray, TrioAlloc1.AllocationMemory.arraySize,
      producerSmall, ↓reduceIte, bind, Except.bind, array, large]
    rw [finalize_eq_reserve pointer _ small aligned]
    simp only [word, Nat.mod_eq_of_lt sizeBound, Nat.mul_add, Nat.mul_one]

def producerCacheRows : Nat → Word → Except TrioAlloc1.Failure Word
  | 0, pointer => .ok pointer
  | n+1, pointer => do
    let next ← TrioAlloc1.AllocationMemory.finalize pointer (word 160)
    producerCacheRows n next

def producerPrefix (pointer count : Word) : Except TrioAlloc1.Failure Word := do
  let allocations ← TrioAlloc1.AllocationMemory.allocateArray pointer count
  let cache ← TrioAlloc1.AllocationMemory.allocateArray allocations count
  producerCacheRows count.val cache

theorem cacheRows_eq_producer (n : Nat) (pointer : Word) :
    producerCacheRows n pointer = toProducer (cacheRows n pointer) := by
  induction n generalizing pointer with
  | zero => rfl
  | succ n ih =>
    simp only [producerCacheRows, cacheRows]
    rw [finalize_eq_reserve pointer (word 160) (by decide) (by decide)]
    change (do let next ← toProducer (reserve pointer 160); producerCacheRows n next) = _
    cases hr : reserve pointer 160 with
    | error reason => simp [hr, toProducer, bind, Except.bind, Except.mapError]
    | ok next => simpa [hr, toProducer, bind, Except.bind, Except.mapError] using ih next

theorem prefix_eq_producer (pointer count : Word) :
    producerPrefix pointer count = toProducer (execute pointer count) := by
  simp only [producerPrefix, execute, array_eq_producer]
  cases ha : array pointer count with
  | error reason => simp [ha, toProducer, bind, Except.bind, Except.mapError]
  | ok allocations =>
    cases hc : array allocations count with
    | error reason => simp [ha, hc, toProducer, bind, Except.bind, Except.mapError]
    | ok cache => simpa [ha, hc, toProducer, bind, Except.bind, Except.mapError] using
        cacheRows_eq_producer count.val cache

/-- Successful execution of the exact producer primitives entails the extent
bound; this premise refers to executable word operations, not a size predicate. -/
theorem producerPrefix_extent (pointer count out : Word)
    (executed : producerPrefix pointer count = .ok out) :
    out.val = pointer.val+224*count.val+64 ∧ out.val < 2^64 ∧ 160+64*count.val < 2^64 := by
  rw [prefix_eq_producer] at executed
  cases h : execute pointer count with
  | error reason => simp [h, toProducer, Except.mapError] at executed
  | ok next =>
    simp only [h, toProducer, Except.mapError, Except.ok.injEq] at executed
    subst out
    exact execute_extent _ _ _ h

#print axioms prefix_eq_producer
#print axioms producerPrefix_extent

#print axioms rounded_aligned
#print axioms finalize_eq_reserve
#print axioms array_eq_producer
end LidoSRv3.Audit.Source.TrioAlloc2.MemoryPrefix
