import LidoSRv3.Audit.Source.ByteMemory

namespace LidoSRv3.Audit.Source.ByteMemory
open EvmYul

/-- An actual in-bounds byte write preserves every disjoint slice. The
caller must derive both allocation bounds and separation; this lemma does
not assume that a Solidity pointer came from the supported allocator. -/
theorem write_disjoint_extract (source destination : ByteArray)
    (s d n offset length : Nat)
    (nonempty : 0 < n) (sourceFits : s + n ≤ source.size)
    (destinationFits : d + n ≤ destination.size)
    (readFits : offset + length ≤ destination.size)
    (separate : offset + length ≤ d ∨ d + n ≤ offset) :
    (source.write s destination d n).extract offset (offset + length) =
      destination.extract offset (offset + length) := by
  apply ByteArray.ext
  simp only [ByteArray.data_extract]
  rw [write_in_bounds source destination s d n nonempty sourceFits destinationFits]
  apply Array.ext
  · simp only [Array.size_extract, Array.size_append, ByteArray.size_data]
    omega
  · intro i hi hj
    simp only [Array.size_extract, Array.size_append, ByteArray.size_data] at hi hj
    simp only [Array.getElem_extract, Array.getElem_append,
      Array.size_extract, Array.size_append, ByteArray.size_data]
    split_ifs <;> first | rfl | omega | (congr 1 <;> omega)

/-- The EvmYul padded-read primitive observes the same bytes across a
separated write when the original read fits allocated memory. -/
theorem write_disjoint_read (source destination : ByteArray)
    (s d n offset length : Nat)
    (nonempty : 0 < n) (sourceFits : s + n ≤ source.size)
    (destinationFits : d + n ≤ destination.size)
    (readFits : offset + length ≤ destination.size) (width : length < 2^64)
    (separate : offset + length ≤ d ∨ d + n ≤ offset) :
    (source.write s destination d n).readWithPadding offset length =
      destination.readWithPadding offset length := by
  have afterFits : offset + length ≤ (source.write s destination d n).size := by
    rw [write_in_bounds_size source destination s d n nonempty sourceFits destinationFits]
    exact readFits
  rw [read_in_bounds _ offset length afterFits width,
    read_in_bounds destination offset length readFits width]
  exact write_disjoint_extract source destination s d n offset length
    nonempty sourceFits destinationFits readFits separate

end LidoSRv3.Audit.Source.ByteMemory
