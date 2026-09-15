import EvmYul.MachineStateOps
import Mathlib.Tactic.NormNum

/-! In-bounds byte-memory facts for the existing EvmYul primitives. These
lemmas need no fixed small-address cutoff: when both slices fit, all FFI
padding lengths are zero, independently of the platform word size. -/
namespace LidoSRv3.Audit.Source.ByteMemory
open EvmYul

theorem write_in_bounds (source destination : ByteArray) (s d n : Nat)
    (nonempty : 0 < n) (sourceFits : s + n ≤ source.size)
    (destinationFits : d + n ≤ destination.size) :
    (source.write s destination d n).data =
      destination.data.extract 0 d ++ source.data.extract s (s+n) ++
        destination.data.extract (d+n) destination.size := by
  have starts : ¬ s ≥ source.size := by omega
  have practical : min n (source.size - s) = n := by omega
  have padding : min destination.size (d+n) - (d+n) = 0 := by omega
  have gap : d - destination.size = 0 := by omega
  unfold ByteArray.write
  simp only [Nat.ne_of_gt nonempty, ↓reduceIte, starts, practical, padding, gap,
    Nat.add_zero]
  simp [ffi.ByteArray.zeroes, USize.toNat, ByteArray.data_copySlice, practical]

theorem write_in_bounds_bytes (source destination : ByteArray) (s d n : Nat)
    (nonempty : 0 < n) (sourceFits : s + n ≤ source.size)
    (destinationFits : d + n ≤ destination.size) :
    source.write s destination d n =
      destination.extract 0 d ++ source.extract s (s+n) ++
        destination.extract (d+n) destination.size := by
  apply ByteArray.ext
  simpa only [ByteArray.data_append, ByteArray.data_extract] using
    write_in_bounds source destination s d n nonempty sourceFits destinationFits

theorem write_in_bounds_size (source destination : ByteArray) (s d n : Nat)
    (nonempty : 0 < n) (sourceFits : s + n ≤ source.size)
    (destinationFits : d + n ≤ destination.size) :
    (source.write s destination d n).size = destination.size := by
  change (source.write s destination d n).data.size = destination.size
  rw [write_in_bounds source destination s d n nonempty sourceFits destinationFits]
  simp only [Array.size_append, Array.size_extract, ByteArray.size_data]
  omega

theorem read_in_bounds (memory : ByteArray) (offset length : Nat)
    (fits : offset + length ≤ memory.size) (width : length < 2^64) :
    memory.readWithPadding offset length = memory.extract offset (offset+length) := by
  have read : memory.readWithoutPadding offset length = memory.extract offset (offset+length) := by
    unfold ByteArray.readWithoutPadding
    split
    · have empty : length = 0 := by omega
      simp [empty]
    · rw [Nat.min_eq_left (by omega)]
  have size : (memory.extract offset (offset+length)).size = length := by
    simp only [ByteArray.size_extract]
    omega
  unfold ByteArray.readWithPadding
  rw [if_neg (by omega), read]
  simp [size, ffi.ByteArray.zeroes, USize.toNat]
  apply ByteArray.ext
  simp [ByteArray.data_append]

end LidoSRv3.Audit.Source.ByteMemory
