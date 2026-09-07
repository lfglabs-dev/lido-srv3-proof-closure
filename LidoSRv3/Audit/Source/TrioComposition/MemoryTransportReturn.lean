import LidoSRv3.Audit.Source.TrioComposition.MemoryTransportABI

/-! Two distinct caller regions model SRLib.ir.yul's successful returndata copy
followed by the forward mload/mstore decoder loop into a newly allocated array.
The scratch return buffer and decoded array both preserve the earlier allocations.
Canonical word-copy to byte-copy refinement and allocator pointer identification
remain local compiler obligations. -/
namespace LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
open TrioAlloc1

def returnWords (result : TrioAlloc2.StepOutput) : MemoryWords :=
  fun address => decodeWord (TrioAlloc2.LibraryABI.encodeReturn result) address

/-- amount, offset, array length, then elements, copied into caller memory. -/
def stageReturn (caller : MemoryWords) (buffer : Nat) (result : TrioAlloc2.StepOutput) : MemoryWords :=
  copyWords (returnWords result) 0 caller buffer (result.buckets.length+3)

theorem stageReturn_related (caller : MemoryWords) (buffer : Nat)
    (result : TrioAlloc2.StepOutput) (bound : result.buckets.length < 2^256) :
    ArrayAt (stageReturn caller buffer result) (buffer+64) result.buckets := by
  have source := returnSource_related result bound
  constructor
  · have header := copyWords_read (returnWords result) caller 0 buffer
      (result.buckets.length+3) ⟨2,by omega⟩
    change stageReturn caller buffer result (buffer+64) = returnWords result 64 at header
    exact (congrArg Fin.val header).trans source.1
  · intro i
    have copied := copyWords_read (returnWords result) caller 0 buffer
      (result.buckets.length+3) ⟨i.val+3,by have hi := i.isLt; omega⟩
    have destAddr : buffer+32*(i.val+3) = buffer+64+32*(i.val+1) := by omega
    have srcAddr : 0+32*(i.val+3) = 64+32*(i.val+1) := by omega
    rw [destAddr, srcAddr] at copied
    exact copied.trans (source.2 i)

theorem stageReturn_preserves (caller : MemoryWords) (buffer original : Nat)
    (result : TrioAlloc2.StepOutput) (values : List Word)
    (beforeBuffer : original+32*(values.length+1) ≤ buffer)
    (related : ArrayAt caller original values) :
    ArrayAt (stageReturn caller buffer result) original values := by
  constructor
  · have eq := copyWords_outside (returnWords result) caller 0 buffer
      (result.buckets.length+3) original (Or.inl (by omega))
    exact (congrArg Fin.val eq).trans related.1
  · intro i
    have hi := i.isLt
    exact (copyWords_outside (returnWords result) caller 0 buffer
      (result.buckets.length+3) (original+32*(i.val+1)) (Or.inl (by omega))).trans (related.2 i)

/-- The decoder reads evolving caller memory, after the return buffer was copied. -/
def decodeStagedReturn (caller : MemoryWords) (buffer decoded : Nat)
    (result : TrioAlloc2.StepOutput) : MemoryWords :=
  let staged := stageReturn caller buffer result
  copyWordsLive staged (buffer+64) decoded ((staged (buffer+64)).val+1)

theorem decodeStagedReturn_eq_copyArray (caller : MemoryWords) (buffer decoded : Nat)
    (result : TrioAlloc2.StepOutput) (bound : result.buckets.length < 2^256)
    (fresh : buffer+32*(result.buckets.length+3) ≤ decoded) :
    decodeStagedReturn caller buffer decoded result =
      copyArray (stageReturn caller buffer result) (buffer+64)
        (stageReturn caller buffer result) decoded := by
  have header := (stageReturn_related caller buffer result bound).1
  apply copyWordsLive_eq
  rw [header]
  exact Or.inl (by omega)

/-- Actual sequential return-buffer stores and same-memory decoder copies yield
the new array and retain the original array for subsequent delta conversion. -/
theorem staged_return_arrays (caller : MemoryWords) (original buffer decoded : Nat)
    (result : TrioAlloc2.StepOutput) (values : List Word)
    (related : ArrayAt caller original values)
    (beforeBuffer : original+32*(values.length+1) ≤ buffer)
    (fresh : buffer+32*(result.buckets.length+3) ≤ decoded)
    (extent : decoded+32*(result.buckets.length+1) ≤ 2^64) :
    ArrayAt (decodeStagedReturn caller buffer decoded result) decoded result.buckets ∧
    ArrayAt (decodeStagedReturn caller buffer decoded result) original values ∧
    TrioAlloc2.readMemoryArray (decodeStagedReturn caller buffer decoded result) original = values := by
  have bound : result.buckets.length < 2^256 := by omega
  rw [decodeStagedReturn_eq_copyArray caller buffer decoded result bound fresh]
  have staged := stageReturn_related caller buffer result bound
  have preserved := stageReturn_preserves caller buffer original result values beforeBuffer related
  have separation : Disjoint decoded
      ((stageReturn caller buffer result) (buffer+64)).val original values.length := by
    rw [staged.1]
    exact Or.inr (by omega)
  have kept := copyArray_frame _ _ (buffer+64) decoded original values preserved separation
  exact ⟨copyArray_related _ _ _ _ result.buckets staged, kept,
    TrioAlloc2.readMemoryArray_eq _ original values kept⟩

#print axioms staged_return_arrays
end LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
