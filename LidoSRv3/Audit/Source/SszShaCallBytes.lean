import LidoSRv3.Audit.Source.SszScratchEvmMemory

/-! Local output-buffer lemmas over the existing EvmYul byte operations.
The input and output can overlap; the source array is the immutable CALL reply.
-/
namespace LidoSRv3.Audit.Source.SszShaCallBytes
open EvmYul SszScratchByteArray

/-- Bounded in-range reader normalization, including a zero-length read at end. -/
theorem read_fit (bytes : ByteArray) (offset n : Nat)
    (hfit : offset+n ≤ bytes.size) (hn : n ≤ 64) :
    bytes.readWithPadding offset n = bytes.extract offset (offset+n) := by
  have hread : bytes.readWithoutPadding offset n = bytes.extract offset (offset+n) := by
    unfold ByteArray.readWithoutPadding
    split
    · have hz : n = 0 := by omega
      simp [hz]
    · rw [Nat.min_eq_left (by omega)]
  have hsize : (bytes.extract offset (offset+n)).size = n := by
    simp only [ByteArray.size_extract]
    omega
  unfold ByteArray.readWithPadding
  rw [if_neg (by omega), hread]
  simp only [hsize, BitVec.sub_self]
  exact append_zeros_zero _

theorem write32 (reply old : ByteArray) (hlen : reply.size = 32) :
    reply.write 0 old 0 32 = reply ++ old.extract 32 old.size := by
  apply ByteArray.ext
  rw [write_fit _ _ 0 0 32 (by omega) (by omega) (by omega)]
  simp only [Array.extract_zero, Nat.zero_sub, Array.replicate_zero, Array.append_empty,
    Array.empty_append, Nat.zero_add, ByteArray.data_append, ByteArray.data_extract]
  have hsize : reply.data.size = 32 := hlen
  rw [← hsize, Array.extract_size]

theorem read32_prefix (head tail : ByteArray) (hlen : head.size = 32) :
    (head ++ tail).readWithPadding 0 32 = head := by
  have hnonempty : ¬ 0 ≥ (head ++ tail).size := by simp [hlen]
  have hmin : min 32 (head ++ tail).size = 32 := by simp [hlen]
  unfold ByteArray.readWithPadding ByteArray.readWithoutPadding
  simp only [show ¬ 32 ≥ 2 ^ 64 by decide, ↓reduceIte, hnonempty, hmin, Nat.zero_add]
  rw [ByteArray.extract_append_eq_left hlen.symm]
  simp only [hlen, BitVec.sub_self]
  exact append_zeros_zero head

theorem frame32 (reply old : ByteArray) (hlen : reply.size = 32) (i : Nat) (hi : 32 ≤ i) :
    (reply ++ old.extract 32 old.size).data.getD i 0 = old.data.getD i 0 := by
  have hh : reply.data.size = 32 := hlen
  simp only [ByteArray.data_append, ByteArray.data_extract, Array.getD_eq_getD_getElem?,
    Array.getElem?_append, hh, show ¬ i < 32 by omega, ↓reduceIte,
    Array.getElem?_extract, ByteArray.size_data, Nat.min_self]
  have hi' : 32 + (i - 32) = i := by omega
  by_cases hb : i < old.size
  · simp only [show i - 32 < old.size - 32 by omega, ↓reduceIte, hi']
  · simp only [show ¬ i - 32 < old.size - 32 by omega, ↓reduceIte]
    rw [Array.getElem?_eq_none (by simpa using hb)]

/-- An independent size bound makes the actual EvmYul word extent readable.
It is not needed by the stronger unrestricted byte-array copy theorem. -/
theorem mload32 (machine : MachineState) (reply tail : ByteArray)
    (hm : machine.memory = reply ++ tail) (hlen : reply.size = 32)
    (hpos : 0 < machine.activeWords.toNat) (hwidth : machine.activeWords.toNat < 2^251) :
    (machine.mload (UInt256.ofNat 0)).1 = UInt256.ofNat (fromByteArrayBigEndian reply) := by
  have hmul : ¬ (UInt256.ofNat 0) ≥ machine.activeWords * (UInt256.ofNat 32) := by
    change ¬ 0 ≥ (machine.activeWords.toNat * 32) % UInt256.size
    have hfit : machine.activeWords.toNat * 32 < UInt256.size := by
      unfold UInt256.size
      omega
    rw [Nat.mod_eq_of_lt hfit]
    omega
  have hsize : ¬ (UInt256.ofNat 0).toNat ≥ machine.memory.size := by
    rw [hm]
    change ¬ 0 ≥ (reply ++ tail).size
    simp [hlen]
  have h32 : (⟨32⟩ : UInt256) = UInt256.ofNat 32 := by decide +kernel
  simp only [MachineState.mload, MachineState.lookupMemory, h32, hsize, hmul,
    or_self, ↓reduceIte]
  rw [hm]
  exact congrArg UInt256.ofNat (congrArg fromByteArrayBigEndian (read32_prefix reply tail hlen))

/-- This is an actual engine representation limitation: at 2^251 active words,
its UInt256 extent product wraps to zero, irrespective of the copied memory. -/
theorem mload_wrap (machine : MachineState)
    (hwords : machine.activeWords = UInt256.ofNat (2^251)) :
    (machine.mload (UInt256.ofNat 0)).1 = UInt256.ofNat 0 := by
  have hmul : UInt256.ofNat (2^251) * (⟨32⟩ : UInt256) = UInt256.ofNat 0 := by decide +kernel
  simp only [MachineState.mload, MachineState.lookupMemory, hwords, hmul, le_refl,
    or_true, ↓reduceIte]
  decide +kernel

end LidoSRv3.Audit.Source.SszShaCallBytes
