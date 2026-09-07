import LidoSRv3.Audit.Source.TrioComposition.FinalMemoryRows
import LidoSRv3.Audit.Source.TrioComposition.MemoryGuard

/-! Producer allocation guards in compiler order: runtime count-slot buffers,
allocation/cache prefix,
scratch configuration, interleaved first-pass buffers, capacity array and
second-pass arithmetic. Physical stores/copies and gas remain separate. -/
namespace LidoSRv3.Audit.Source.TrioComposition.FinalMemoryProducer
open TrioAlloc1

def afterPrefix (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput) :
    CallTree.Program (CapacityOutput × Word) := do
  let firstPointer ← CallTree.check (AllocationMemory.finalize pointer (word 224))
  let ((rows,total),rowsEnd) ← FinalMemoryRows.firstLoop l s input (s (countSlot l)).val
    0 input.depositsToAllocate firstPointer
  let capacityEnd ← CallTree.check (AllocationMemory.allocateArray rowsEnd (s (countSlot l)))
  let buckets ← CallTree.check (secondLoop input total rows)
  pure (outputOfBuckets buckets,capacityEnd)

def guardedProducer (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput) :
    CallTree.Program (CapacityOutput × Word) := do
  let next ← CallTree.check (MemoryGuard.check pointer (s (countSlot l)))
  afterPrefix next l s input

def finalPointer (pointer : Word) (l : Layout) (s : Storage) : Word :=
  word ((FinalMemoryRows.endPointer l s (s (countSlot l)).val 0 (word (pointer.val+224))).val+
    32*(s (countSlot l)).val+32)

set_option maxRecDepth 4096 in
/-- Scratch, every first-pass allocation and the capacity array are discharged
from one numeric budget and the physical count bound. All source failure
alternatives survive; successful producer or callee replies are not assumed. -/
theorem afterPrefix_exact (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (countBound : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+896*(s (countSlot l)).val+256 ≤ 2^32) :
    afterPrefix pointer l s input =
      (do let result ← CallTree.producer l s input; pure (result,finalPointer pointer l s)) := by
  have small : pointer.val ≤ 2^32 := by omega
  have scratchBound : pointer.val+224 < 2^256 := by omega
  have scratchVal : (word (pointer.val+224)).val = pointer.val+224 := Nat.mod_eq_of_lt scratchBound
  have rowSpace : (word (pointer.val+224)).val+864*(s (countSlot l)).val ≤ 2^32 := by
    rw [scratchVal]
    omega
  have rowsBound := FinalMemoryRows.endPointer_bound l s (s (countSlot l)).val 0 (word (pointer.val+224))
  have rowsSmall : (FinalMemoryRows.endPointer l s (s (countSlot l)).val 0 (word (pointer.val+224))).val ≤ 2^32 := by omega
  have capacity := AllocationMemory.bounded_array_allocates
    (FinalMemoryRows.endPointer l s (s (countSlot l)).val 0 (word (pointer.val+224)))
    (s (countSlot l)) rowsSmall countBound
  simp only [afterPrefix, RowMemory.config_allocation pointer small, RowMemory.check_ok_bind,
    FinalMemoryRows.firstLoop_exact l s input _ 0 input.depositsToAllocate _ rowSpace,
    RowMemory.bind_assoc, RowMemory.pure_bind, capacity, CallTree.producer, finalPointer]

set_option maxRecDepth 4096 in
/-- Guard sequence after the runtime count-slot buffers, including the array
and cache prefix. The final pointer budget includes worst-case stake buffers. -/
theorem guardedProducer_exact (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (countBound : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+1120*(s (countSlot l)).val+320 ≤ 2^32) :
    guardedProducer pointer l s input =
      (do let result ← CallTree.producer l s input
          pure (result,finalPointer (word (pointer.val+224*(s (countSlot l)).val+64)) l s)) := by
  have prefixBound : pointer.val+224*(s (countSlot l)).val+64 < 2^64 := by omega
  have prefixWordBound : pointer.val+224*(s (countSlot l)).val+64 < 2^256 := by omega
  have guardOk : MemoryGuard.check pointer (s (countSlot l)) =
      .ok (word (pointer.val+224*(s (countSlot l)).val+64)) := by
    simp [MemoryGuard.check, MemoryGuard.run, prefixBound, Except.mapError]
  have remaining : (word (pointer.val+224*(s (countSlot l)).val+64)).val+
      896*(s (countSlot l)).val+256 ≤ 2^32 := by
    change (pointer.val+224*(s (countSlot l)).val+64)%2^256+896*(s (countSlot l)).val+256 ≤ 2^32
    rw [Nat.mod_eq_of_lt prefixWordBound]
    omega
  simp only [guardedProducer, guardOk, RowMemory.check_ok_bind,
    afterPrefix_exact _ l s input countBound remaining]


/-- The second runtime count read occurs after the outer division, and performs
its own two 64-byte slot allocations before the producer array/cache prefix. -/
def producer (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput) :
    CallTree.Program (CapacityOutput × Word) := do
  let countPointer ← CallTree.check (FinalMemoryRows.slot pointer)
  guardedProducer countPointer l s input

def endPointer (pointer : Word) (l : Layout) (s : Storage) : Word :=
  finalPointer (word (pointer.val+224*(s (countSlot l)).val+192)) l s

theorem producer_exact (pointer : Word) (l : Layout) (s : Storage) (input : CapacityInput)
    (countBound : (s (countSlot l)).val ≤ 32)
    (space : pointer.val+1120*(s (countSlot l)).val+448 ≤ 2^32) :
    producer pointer l s input =
      (do let result ← CallTree.producer l s input
          pure (result,endPointer pointer l s)) := by
  have slotSpace : pointer.val+128 ≤ 2^32 := by omega
  have slotVal := FinalMemoryRows.word_small (pointer.val+128) slotSpace
  have remaining : (word (pointer.val+128)).val+1120*(s (countSlot l)).val+320 ≤ 2^32 := by
    rw [slotVal]; omega
  simp only [producer, FinalMemoryRows.slot_exact pointer slotSpace, RowMemory.check_ok_bind,
    guardedProducer_exact _ l s input countBound remaining, slotVal, endPointer]
  have offset : pointer.val+128+224*(s (countSlot l)).val+64 =
      pointer.val+224*(s (countSlot l)).val+192 := by omega
  rw [offset]

/-- This unconditional upper bound is also valid when word arithmetic wraps;
bounded callers use it to discharge the next branch's allocations. -/
theorem endPointer_bound (pointer : Word) (l : Layout) (s : Storage) :
    (endPointer pointer l s).val ≤ pointer.val+1120*(s (countSlot l)).val+448 := by
  have prefixMod := Nat.mod_le (pointer.val+224*(s (countSlot l)).val+192) (2^256)
  have scratch := Nat.mod_le ((word (pointer.val+224*(s (countSlot l)).val+192)).val+224) (2^256)
  have rows := FinalMemoryRows.endPointer_bound l s (s (countSlot l)).val 0
    (word ((word (pointer.val+224*(s (countSlot l)).val+192)).val+224))
  have capacity := Nat.mod_le
    ((FinalMemoryRows.endPointer l s (s (countSlot l)).val 0
      (word ((word (pointer.val+224*(s (countSlot l)).val+192)).val+224))).val+
      32*(s (countSlot l)).val+32) (2^256)
  simp only [endPointer, finalPointer, word] at rows capacity scratch prefixMod ⊢
  omega

#print axioms afterPrefix_exact
#print axioms guardedProducer_exact
#print axioms producer_exact
#print axioms endPointer_bound
end LidoSRv3.Audit.Source.TrioComposition.FinalMemoryProducer
