import EvmYul.SharedStateOps
import Mathlib.Tactic.NormNum

/-!
Local byte-array lemmas for the existing EvmYul memory operations. No alternative
memory interpreter is introduced. All equalities below unfold EvmYul's actual
`ByteArray.write` / `readWithPadding`, including their bounded USize padding.
-/
namespace LidoSRv3.Audit.Source.SszScratchByteArray

/-- Mathematical zero bytes, independent of the FFI padding implementation. -/
def zeros (n : Nat) : ByteArray := ⟨Array.replicate n 0⟩

@[simp] theorem zeros_size (n : Nat) : (zeros n).size = n := by
  simp [zeros, ByteArray.size]

private theorem usize_small (n : Nat) (hn : n ≤ 64) :
    (⟨n⟩ : USize).toNat = n := by
  change n % 2 ^ System.Platform.numBits = n
  rcases System.Platform.numBits_eq with h | h <;> rw [h] <;> norm_num <;> omega

theorem ffi_zeros (n : Nat) (hn : n ≤ 64) :
    ffi.ByteArray.zeroes (⟨n⟩ : USize) = zeros n := by
  apply ByteArray.ext
  change Array.replicate ((⟨n⟩ : USize).toNat) 0 = Array.replicate n 0
  rw [usize_small n hn]

@[simp] theorem append_zeros_zero (b : ByteArray) : b ++ zeros 0 = b := by
  apply ByteArray.ext
  simp [zeros]

/-- Exact write normal form for an in-bounds source and a small destination
address; the destination itself may have arbitrary size and arbitrary bytes. -/
theorem write_fit (src dest : ByteArray) (s d n : Nat)
    (hn : 0 < n) (hfit : s + n ≤ src.size) (hd : d ≤ 64) :
    (src.write s dest d n).data =
      (dest.data.extract 0 d ++ Array.replicate (d - dest.size) 0) ++
      src.data.extract s (s + n) ++ dest.data.extract (d + n) dest.size := by
  have hsrc : ¬ s ≥ src.size := by omega
  have hp : min n (src.size - s) = n := by omega
  have hz : min dest.size (d + n) - (d + n) = 0 := by omega
  have hpad : d - dest.size ≤ 64 := by omega
  unfold ByteArray.write
  simp only [Nat.ne_of_gt hn, ↓reduceIte, hsrc, hp, hz, ffi_zeros 0 (by omega),
    ffi_zeros _ hpad, append_zeros_zero, Nat.add_zero]
  rw [ByteArray.data_copySlice]
  simp only [ByteArray.data_append, zeros, Array.size_append, Array.size_replicate,
    ByteArray.size_data, Array.extract_append, Array.extract_replicate]
  try simp only [show min n (src.size - s) = n from hp]
  have hpad1 : min (d - dest.size) (d - dest.size) = d - dest.size := by omega
  have hpad2 : min (dest.size + (d - dest.size) - dest.size) (d - dest.size) - (d + n - dest.size) = 0 := by omega
  simp only [Nat.zero_sub, Nat.sub_zero, hpad1, hpad2, Array.replicate_zero,
    Array.append_empty]
  congr 1
  apply Array.ext
  · simp
  · intro i h₁ h₂
    simp

/-- A zero word uses exactly 32 zero bytes in EvmYul's real big-endian codec. -/
theorem word_zero : (EvmYul.UInt256.ofNat 0).toByteArray = zeros 32 := by
  unfold EvmYul.UInt256.toByteArray
  have hb : BE (EvmYul.UInt256.ofNat 0).toNat = ByteArray.empty := by decide +kernel
  rw [hb]
  apply ByteArray.ext
  simp [ffi.ByteArray.zeroes, zeros]
  exact usize_small 32 (by omega)

/-- The clearing write produces a 32-byte arbitrary lower prefix, a zero word,
and the unchanged old tail beginning at byte 64. -/
theorem clear_shape (old : ByteArray) :
    ((zeros 32).write 0 old 32 32).data =
      (old.data.extract 0 32 ++ Array.replicate (32 - old.size) 0) ++
      Array.replicate 32 0 ++ old.data.extract 64 old.size := by
  rw [write_fit _ _ 0 32 32 (by omega) (by simp) (by omega)]
  simp [zeros]

theorem lower_size (old : ByteArray) :
    (old.data.extract 0 32 ++ Array.replicate (32 - old.size) (0 : UInt8)).size = 32 := by
  simp
  omega

/-- Copying 48 real source bytes into that shape overwrites all lower bytes
and half the zero word, leaving exactly sixteen zeros and the arbitrary tail. -/
theorem copy_shape (src : ByteArray) (s : Nat) (hfit : s + 48 ≤ src.size)
    (lower tail : Array UInt8) (hlower : lower.size = 32) :
    (src.write s ⟨lower ++ Array.replicate 32 0 ++ tail⟩ 0 48).data =
      src.data.extract s (s + 48) ++ Array.replicate 16 0 ++ tail := by
  rw [write_fit _ _ s 0 48 (by omega) hfit (by omega)]
  simp [-ByteArray.size_data, Array.extract_append, hlower, ByteArray.size, Array.extract_replicate,
    Array.append_assoc, Array.extract_empty_of_stop_le_start (by omega : 32 ≤ 48)]

/-- Full memory equality for the exact two-byte-operation block. -/
theorem scratch_shape (src old : ByteArray) (s : Nat) (hfit : s + 48 ≤ src.size) :
    (src.write s ((zeros 32).write 0 old 32 32) 0 48).data =
      src.data.extract s (s + 48) ++ Array.replicate 16 0 ++ old.data.extract 64 old.size := by
  have hclear : (zeros 32).write 0 old 32 32 =
      ⟨(old.data.extract 0 32 ++ Array.replicate (32 - old.size) 0) ++
        Array.replicate 32 0 ++ old.data.extract 64 old.size⟩ := by
    apply ByteArray.ext
    exact clear_shape old
  rw [hclear]
  exact copy_shape src s hfit _ _ (lower_size old)

/-- The actual padded read observes precisely a complete 64-byte prefix. -/
theorem read_prefix (head tail : ByteArray) (hhead : head.size = 64) :
    (head ++ tail).readWithPadding 0 64 = head := by
  have hnonempty : ¬ 0 ≥ (head ++ tail).size := by simp [hhead]
  have hmin : min 64 (head ++ tail).size = 64 := by simp [hhead]
  unfold ByteArray.readWithPadding ByteArray.readWithoutPadding
  simp only [show ¬ 64 ≥ 2 ^ 64 by decide, ↓reduceIte, hnonempty, hmin, Nat.zero_add]
  rw [ByteArray.extract_append_eq_left hhead.symm]
  simp only [hhead, BitVec.sub_self]
  exact append_zeros_zero head

/-- Byte observations, including zero beyond the allocated array, frame the
old memory outside the 64-byte scratch interval. -/
theorem frame_byte (head old : ByteArray) (hhead : head.size = 64)
    (i : Nat) (hi : 64 ≤ i) :
    (head.data ++ old.data.extract 64 old.size).getD i 0 = old.data.getD i 0 := by
  have hh : head.data.size = 64 := hhead
  simp only [Array.getD_eq_getD_getElem?, Array.getElem?_append, hh,
    show ¬ i < 64 by omega, ↓reduceIte, Array.getElem?_extract, ByteArray.size_data,
    Nat.min_self]
  have hi' : 64 + (i - 64) = i := by omega
  by_cases hb : i < old.size
  · simp only [show i - 64 < old.size - 64 by omega, ↓reduceIte, hi']
  · simp only [show ¬ i - 64 < old.size - 64 by omega, ↓reduceIte]
    rw [Array.getElem?_eq_none (by simpa using hb)]

end LidoSRv3.Audit.Source.SszScratchByteArray
