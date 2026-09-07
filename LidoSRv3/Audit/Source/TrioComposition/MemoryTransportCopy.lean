import LidoSRv3.Audit.Source.TrioComposition.MemoryTransport

/-! Sequential copying between separate memory spaces, with a live same-space
copy refinement for disjoint regions. The caller array survives both library
memory mutation and decoding into fresh caller memory. -/
namespace LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
open TrioAlloc1

/-- Each recursive step performs one source read followed by one destination store. -/
def copyWords (source : MemoryWords) (src : Nat) (destination : MemoryWords) (dst : Nat) :
    Nat → MemoryWords
  | 0 => destination
  | count+1 => copyWords source (src+32) (store destination dst (source src)) (dst+32) count

theorem copyWords_outside (source destination : MemoryWords) (src dst count address : Nat)
    (outside : address < dst ∨ dst+32*count ≤ address) :
    copyWords source src destination dst count address = destination address := by
  induction count generalizing src dst destination with
  | zero => rfl
  | succ count ih =>
    rw [copyWords, ih _ _ _ (by omega)]
    have ne : address ≠ dst := by omega
    simp [store, ne]

theorem copyWords_read (source destination : MemoryWords) (src dst count : Nat)
    (i : Fin count) :
    copyWords source src destination dst count (dst+32*i.val) = source (src+32*i.val) := by
  induction count generalizing src dst destination with
  | zero => exact Fin.elim0 i
  | succ count ih =>
    cases i with
    | mk i hi =>
      cases i with
      | zero =>
        simp only [Nat.mul_zero, Nat.add_zero, copyWords]
        rw [copyWords_outside _ _ _ _ _ dst (Or.inl (by omega))]
        simp [store]
      | succ i =>
        have bound : i < count := by omega
        have destAddr : dst+32*(i+1) = dst+32+32*i := by omega
        have srcAddr : src+32*(i+1) = src+32+32*i := by omega
        simpa only [copyWords, destAddr, srcAddr] using
          ih (store destination dst (source src)) (src+32) (dst+32) ⟨i,bound⟩

/-- A full length-prefixed array copy reads its actual source header. -/
def copyArray (source : MemoryWords) (src : Nat) (destination : MemoryWords) (dst : Nat) :
    MemoryWords := copyWords source src destination dst ((source src).val+1)

theorem copyArray_related (source destination : MemoryWords) (src dst : Nat)
    (values : List Word) (related : ArrayAt source src values) :
    ArrayAt (copyArray source src destination dst) dst values := by
  constructor
  · have header := copyWords_read source destination src dst ((source src).val+1) ⟨0,by omega⟩
    simp only [Nat.mul_zero, Nat.add_zero] at header
    exact (congrArg Fin.val header).trans related.1
  · intro i
    have bound : i.val+1 < (source src).val+1 := by rw [related.1]; exact Nat.add_lt_add_right i.isLt 1
    exact (copyWords_read source destination src dst _ ⟨i.val+1,bound⟩).trans (related.2 i)

theorem copyArray_outside (source destination : MemoryWords) (src dst : Nat) :
    OutsideUnchanged destination (copyArray source src destination dst) dst (source src).val := by
  intro address outside
  apply copyWords_outside
  simp only [InRegion] at outside
  omega

theorem copyArray_frame (source destination : MemoryWords) (src dst original : Nat)
    (values : List Word) (related : ArrayAt destination original values)
    (separate : Disjoint dst (source src).val original values.length) :
    ArrayAt (copyArray source src destination dst) original values :=
  frame_array _ _ dst (source src).val original values
    (copyArray_outside source destination src dst) separate related

/-- This version reads the evolving memory, matching a same-call mload/mstore loop. -/
def copyWordsLive (memory : MemoryWords) (src dst : Nat) : Nat → MemoryWords
  | 0 => memory
  | count+1 => copyWordsLive (store memory dst (memory src)) (src+32) (dst+32) count

theorem copyWords_source_congr (source other destination : MemoryWords) (src dst count : Nat)
    (agree : ∀ i, i < count → source (src+32*i) = other (src+32*i)) :
    copyWords source src destination dst count = copyWords other src destination dst count := by
  induction count generalizing src dst destination with
  | zero => rfl
  | succ count ih =>
    have head := agree 0 (by omega)
    simp only [Nat.mul_zero, Nat.add_zero] at head
    simp only [copyWords, head]
    apply ih
    intro i hi
    have tail := agree (i+1) (by omega)
    have addr : src+32*(i+1) = src+32+32*i := by omega
    simpa only [addr] using tail

/-- Disjointness justifies replacing repeated live reads with a source snapshot;
it is proved from individual writes, not an assumed final memory relation. -/
theorem copyWordsLive_eq (memory : MemoryWords) (src dst count : Nat)
    (separate : src+32*count ≤ dst ∨ dst+32*count ≤ src) :
    copyWordsLive memory src dst count = copyWords memory src memory dst count := by
  induction count generalizing memory src dst with
  | zero => rfl
  | succ count ih =>
    simp only [copyWordsLive, copyWords]
    rw [ih _ _ _ (by omega)]
    apply copyWords_source_congr
    intro i hi
    have ne : src+32+32*i ≠ dst := by omega
    simp [store, ne]

/-- Decoding canonical library return bytes into a distinct caller array. -/
def importReturn (caller : MemoryWords) (dst : Nat) (result : TrioAlloc2.StepOutput) : MemoryWords :=
  copyArray (fun address => decodeWord (TrioAlloc2.LibraryABI.encodeReturn result) address)
    64 caller dst

theorem returnSource_related (result : TrioAlloc2.StepOutput)
    (bound : result.buckets.length < 2^256) :
    ArrayAt (fun address => decodeWord (TrioAlloc2.LibraryABI.encodeReturn result) address)
      64 result.buckets := by
  have h := encodedArray_related result.buckets
    (encodeWord result.amount ++ encodeWord (word 64)) [] bound
  simpa only [TrioAlloc2.LibraryABI.encodeReturn, List.length_append,
    encodeWord_length, List.append_nil] using h

theorem importReturn_related (caller : MemoryWords) (dst : Nat) (result : TrioAlloc2.StepOutput)
    (bound : result.buckets.length < 2^256) :
    ArrayAt (importReturn caller dst result) dst result.buckets :=
  copyArray_related _ caller 64 dst result.buckets (returnSource_related result bound)

theorem importReturn_preserves (caller : MemoryWords) (dst original : Nat)
    (result : TrioAlloc2.StepOutput) (values : List Word)
    (bound : result.buckets.length < 2^256)
    (separate : Disjoint dst result.buckets.length original values.length)
    (related : ArrayAt caller original values) :
    ArrayAt (importReturn caller dst result) original values := by
  apply copyArray_frame _ caller 64 dst original values related
  rw [(returnSource_related result bound).1]
  exact separate

#print axioms copyArray_related
#print axioms copyWordsLive_eq
#print axioms importReturn_preserves
end LidoSRv3.Audit.Source.TrioComposition.MemoryTransport
