import LidoSRv3.Audit.Source.TrioComposition.RowMemory
import LidoSRv3.Audit.Source.TrioComposition.MemoryGuard

/-! Producer allocation guards in compiler order: allocation/cache prefix,
scratch configuration, interleaved first-pass buffers, capacity array and
second-pass arithmetic. Physical stores/copies and gas remain separate. -/
namespace LidoSRv3.Audit.Source.TrioComposition.MemoryProducer
open TrioAlloc1

def afterPrefix (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput) :
    CallTree.Program (CapacityOutput × Word) := do
  let firstPointer ← CallTree.check (AllocationMemory.finalize pointer (word 224))
  let ((rows,total),rowsEnd) ← RowMemory.firstLoop l s input (s (countSlot l)).val
    0 input.depositsToAllocate firstPointer
  let capacityEnd ← CallTree.check (AllocationMemory.allocateArray rowsEnd (s (countSlot l)))
  let buckets ← CallTree.check (secondLoop input total rows)
  pure (outputOfBuckets buckets,capacityEnd)

def producer (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput) :
    CallTree.Program (CapacityOutput × Word) := do
  let next ← CallTree.check (MemoryGuard.check pointer (s (countSlot l)))
  afterPrefix next l s input

def finalPointer (pointer : Word) (l : Layout) (s : Storage) : Word :=
  word ((RowMemory.endPointer l s (s (countSlot l)).val 0 (word (pointer.val+224))).val+
    32*(s (countSlot l)).val+32)

set_option maxRecDepth 4096 in
/-- Scratch, every first-pass allocation and the capacity array are discharged
from one numeric budget and the physical count bound. All source failure
alternatives survive; successful producer or callee replies are not assumed. -/
theorem afterPrefix_exact (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (countBound : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+384*(s (countSlot l)).val+256 ≤ 2^32) :
    afterPrefix pointer l s input =
      (do let result ← CallTree.producer l s input; pure (result,finalPointer pointer l s)) := by
  have small : pointer.val ≤ 2^32 := by omega
  have scratchBound : pointer.val+224 < 2^256 := by omega
  have scratchVal : (word (pointer.val+224)).val = pointer.val+224 := Nat.mod_eq_of_lt scratchBound
  have rowSpace : (word (pointer.val+224)).val+352*(s (countSlot l)).val ≤ 2^32 := by
    rw [scratchVal]
    omega
  have rowsBound := RowMemory.endPointer_bound l s (s (countSlot l)).val 0 (word (pointer.val+224))
  have rowsSmall : (RowMemory.endPointer l s (s (countSlot l)).val 0 (word (pointer.val+224))).val ≤ 2^32 := by omega
  have capacity := AllocationMemory.bounded_array_allocates
    (RowMemory.endPointer l s (s (countSlot l)).val 0 (word (pointer.val+224)))
    (s (countSlot l)) rowsSmall countBound
  simp only [afterPrefix, RowMemory.config_allocation pointer small, RowMemory.check_ok_bind,
    RowMemory.firstLoop_exact l s input _ 0 input.depositsToAllocate _ rowSpace,
    RowMemory.bind_assoc, RowMemory.pure_bind, capacity, CallTree.producer, finalPointer]

set_option maxRecDepth 4096 in
/-- Complete producer guard sequence, including the previously proved array
and cache prefix. The final pointer budget includes worst-case stake buffers. -/
theorem producer_exact (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (countBound : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+608*(s (countSlot l)).val+320 ≤ 2^32) :
    producer pointer l s input =
      (do let result ← CallTree.producer l s input
          pure (result,finalPointer (word (pointer.val+224*(s (countSlot l)).val+64)) l s)) := by
  have prefixBound : pointer.val+224*(s (countSlot l)).val+64 < 2^64 := by omega
  have prefixWordBound : pointer.val+224*(s (countSlot l)).val+64 < 2^256 := by omega
  have guardOk : MemoryGuard.check pointer (s (countSlot l)) =
      .ok (word (pointer.val+224*(s (countSlot l)).val+64)) := by
    simp [MemoryGuard.check, MemoryGuard.run, prefixBound, Except.mapError]
  have remaining : (word (pointer.val+224*(s (countSlot l)).val+64)).val+
      384*(s (countSlot l)).val+256 ≤ 2^32 := by
    change (pointer.val+224*(s (countSlot l)).val+64)%2^256+384*(s (countSlot l)).val+256 ≤ 2^32
    rw [Nat.mod_eq_of_lt prefixWordBound]
    omega
  simp only [producer, guardOk, RowMemory.check_ok_bind,
    afterPrefix_exact _ l s input countBound remaining]

theorem prefix_failure (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (reason : Failure) (failed : MemoryGuard.check pointer (s (countSlot l)) = .error reason) :
    producer pointer l s input = .done (.error reason) := by
  simp [producer, failed, CallTree.check, bind, CallTree.bind]

#print axioms afterPrefix_exact
#print axioms producer_exact
#print axioms prefix_failure
end LidoSRv3.Audit.Source.TrioComposition.MemoryProducer
