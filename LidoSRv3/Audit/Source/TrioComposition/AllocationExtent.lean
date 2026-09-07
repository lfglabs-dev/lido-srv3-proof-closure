import LidoSRv3.Audit.Source.TrioAlloc1.AllocationMemory
import LidoSRv3.Audit.Source.TrioAlloc2.ABIComposition

/-! Extent consequences of successful compiler allocation primitives. These
lemmas have no fixed module-count cap. The complete compiler schedule must still
be connected to producer execution before the parent premise can be removed. -/
namespace LidoSRv3.Audit.Source.TrioComposition
open TrioAlloc1

theorem allocated_array_extent (pointer count next : Word)
    (executed : AllocationMemory.allocateArray pointer count = .ok next) :
    next.val = pointer.val + 32*count.val + 32 ∧ next.val < 2^64 := by
  unfold AllocationMemory.allocateArray AllocationMemory.arraySize at executed
  split at executed
  · cases executed
  · rename_i countBound
    have countSmall : count.val ≤ 2^64-1 := by
      simpa only [AllocationMemory.limit, Nat.not_lt] using countBound
    have sizeBound : 32*count.val+32 < 2^256 := by omega
    have roundBound : 32*count.val+32+31 < 2^256 := by omega
    have rounded : AllocationMemory.roundedSize (word (32*count.val+32)) =
        32*count.val+32 := by
      simp only [AllocationMemory.roundedSize, word, Nat.mod_eq_of_lt sizeBound,
        Nat.mod_eq_of_lt roundBound]
      omega
    simp only [bind, Except.bind] at executed
    have bounds := AllocationMemory.finalize_success_bounds pointer
      (word (32*count.val+32)) next executed
    unfold AllocationMemory.finalize at executed
    rw [rounded] at executed
    dsimp only at executed
    split at executed
    · cases executed
    · cases executed
      simp only [word, AllocationMemory.limit] at bounds ⊢
      have pointerBound := pointer.isLt
      omega

/-- Two nonoverlapping equal-length allocations after the three-word argument
head establish the canonical packet bound used by the library decoder. Gaps
between arrays are allowed. Success includes panic-0x41 allocation checks. -/
theorem two_allocations_abi_extent (output : CapacityOutput) (demand : Word)
    (pointer firstEnd secondPointer secondEnd count : Word)
    (countValue : count.val = output.allocations.length)
    (headSpace : 96 ≤ pointer.val)
    (first : AllocationMemory.allocateArray pointer count = .ok firstEnd)
    (separate : firstEnd.val ≤ secondPointer.val)
    (second : AllocationMemory.allocateArray secondPointer count = .ok secondEnd) :
    (TrioAlloc2.LibraryABI.encodeArguments (TrioAlloc2.producerArguments output demand)).length < 2^64 := by
  have firstExtent := allocated_array_extent pointer count firstEnd first
  have secondExtent := allocated_array_extent secondPointer count secondEnd second
  have lengths := output_lengths_equal output
  simp only [TrioAlloc2.LibraryABI.encodeArguments, TrioAlloc2.producerArguments,
    List.length_append, encodeWord_length, encodeArray_length]
  omega

#print axioms allocated_array_extent
#print axioms two_allocations_abi_extent
end LidoSRv3.Audit.Source.TrioComposition
