import LidoSRv3.Audit.Source.SszScratchByteArray

namespace LidoSRv3.Audit.Source.SszWordBytes
open EvmYul

/-! Universal byte-encoding facts for the existing pinned EvmYul word writer.
The local recurrence exposes the exact recursive body by a definitional bridge,
without importing generated private declaration names or changing the engine.
The fixed-width independent digit specification is developed below. -/
theorem encode_zero : toBytesBigEndian 0 = [] := by decide +kernel

theorem public_roundtrip (n : Nat) : fromBytesBigEndian (toBytesBigEndian n) = n := by
  simp [fromBytesBigEndian, toBytesBigEndian]

def minimalLE : Nat → List UInt8
  | 0 => []
  | n@(.succ n') =>
    let byte : UInt8 := ⟨Nat.mod n UInt8.size, Nat.mod_lt _ (by linarith)⟩
    have : n / UInt8.size < n' + 1 := by
      rename_i h
      rw [h]
      apply Nat.div_lt_self <;> simp
    byte :: minimalLE (n / UInt8.size)

theorem public_encoder_bridge (n : Nat) :
    toBytesBigEndian n = (minimalLE n).reverse := by
  unfold toBytesBigEndian
  with_unfolding_all rfl

theorem minimal_length {n k : Nat} (h : n < 2^(8*k)) : (minimalLE n).length ≤ k := by
  induction k generalizing n with
  | zero =>
    have hn : n = 0 := by simpa using h
    simp [hn, minimalLE]
  | succ k ih =>
    cases n with
    | zero => simp [minimalLE]
    | succ n =>
      unfold minimalLE
      simp only [List.length_cons, Nat.succ_le_succ_iff]
      apply ih
      have hpow : 2 ^ (8 * (k + 1)) = 2^(8*k) * 256 := by
        rw [Nat.mul_add, Nat.pow_add]
      apply Nat.div_lt_of_lt_mul
      rw [hpow] at h
      simpa only [UInt8.size, Nat.mul_comm] using h

theorem public_length {n k : Nat} (h : n < 2^(8*k)) : (toBytesBigEndian n).length ≤ k := by
  rw [public_encoder_bridge, List.length_reverse]
  exact minimal_length h

theorem actual_word_size (w : UInt256) : w.toByteArray.size = 32 := by
  have hb : (BE w.toNat).size ≤ 32 := by
    simp only [BE, Function.comp_apply, List.size_toByteArray]
    exact public_length w.val.isLt
  have hwide : (BE w.toNat).size < 2 ^ System.Platform.numBits := by
    rcases System.Platform.numBits_eq with h | h <;> rw [h] <;> norm_num <;> omega
  have hsub : BitVec.ofNat System.Platform.numBits 32 - BitVec.ofNat _ (BE w.toNat).size =
      BitVec.ofNat _ (32 - (BE w.toNat).size) :=
    BitVec.ofNat_sub_ofNat_of_le 32 _ hwide hb
  unfold UInt256.toByteArray
  dsimp only
  change (ffi.ByteArray.zeroes ⟨BitVec.ofNat _ 32 - BitVec.ofNat _ (BE w.toNat).size⟩ ++ BE w.toNat).size = 32
  rw [hsub]
  have hz := LidoSRv3.Audit.Source.SszScratchByteArray.ffi_zeros (32 - (BE w.toNat).size) (by omega)
  change ffi.ByteArray.zeroes ⟨BitVec.ofNat _ (32 - (BE w.toNat).size)⟩ = _ at hz
  rw [hz]
  simp only [ByteArray.size_append, LidoSRv3.Audit.Source.SszScratchByteArray.zeros_size]
  omega

def fixedLE : Nat → Nat → List UInt8
  | 0, _ => []
  | k+1, n => UInt8.ofNat n :: fixedLE k (n / 256)

@[simp] theorem fixedLE_zero (k : Nat) : fixedLE k 0 = List.replicate k 0 := by
  induction k with
  | zero => rfl
  | succ k ih => simp [fixedLE, ih, List.replicate_succ]

theorem padded_minimal {n k : Nat} (h : n < 2^(8*k)) :
    minimalLE n ++ List.replicate (k - (minimalLE n).length) 0 = fixedLE k n := by
  induction k generalizing n with
  | zero =>
    have hn : n = 0 := by simpa using h
    simp [hn, minimalLE, fixedLE]
  | succ k ih =>
    cases n with
    | zero => simp [minimalLE]
    | succ n =>
      have hdiv : (n+1)/256 < 2^(8*k) := by
        apply Nat.div_lt_of_lt_mul
        have hpow : 2^(8*(k+1)) = 2^(8*k)*256 := by rw [Nat.mul_add, Nat.pow_add]
        rw [hpow] at h
        simpa only [Nat.mul_comm] using h
      have ht := ih hdiv
      simp only [minimalLE, fixedLE, UInt8.size, List.length_cons, Nat.add_sub_add_right, List.cons_append, List.cons.injEq]
      exact ⟨rfl, ht⟩

-- Independent, exactly k digits, including leading zero bytes.
def fixedBE (k n : Nat) : ByteArray := (fixedLE k n).reverse.toByteArray

theorem actual_word_bytes (w : UInt256) : w.toByteArray = fixedBE 32 w.toNat := by
  have hb : (BE w.toNat).size ≤ 32 := by
    simp only [BE, Function.comp_apply, List.size_toByteArray]
    exact public_length w.val.isLt
  have hwide : (BE w.toNat).size < 2 ^ System.Platform.numBits := by
    rcases System.Platform.numBits_eq with h | h <;> rw [h] <;> norm_num <;> omega
  have hsub : BitVec.ofNat System.Platform.numBits 32 - BitVec.ofNat _ (BE w.toNat).size =
      BitVec.ofNat _ (32 - (BE w.toNat).size) :=
    BitVec.ofNat_sub_ofNat_of_le 32 _ hwide hb
  unfold UInt256.toByteArray
  dsimp only
  change (ffi.ByteArray.zeroes ⟨BitVec.ofNat _ 32 - BitVec.ofNat _ (BE w.toNat).size⟩ ++ BE w.toNat) = _
  rw [hsub]
  have hz := LidoSRv3.Audit.Source.SszScratchByteArray.ffi_zeros (32 - (BE w.toNat).size) (by omega)
  change ffi.ByteArray.zeroes ⟨BitVec.ofNat _ (32 - (BE w.toNat).size)⟩ = _ at hz
  rw [hz]
  have hp := padded_minimal (n := w.toNat) (k := 32) w.val.isLt
  unfold fixedBE
  rw [← hp, List.reverse_append, List.reverse_replicate]
  apply ByteArray.ext
  simp [BE, public_encoder_bridge, LidoSRv3.Audit.Source.SszScratchByteArray.zeros]


@[simp] theorem fixedLE_length (k n : Nat) : (fixedLE k n).length = k := by
  induction k generalizing n with
  | zero => rfl
  | succ k ih => simp [fixedLE, ih]

theorem fixedLE_value {k n : Nat} (h : n < 2^(8*k)) :
    fromBytes' (fixedLE k n) = n := by
  induction k generalizing n with
  | zero => have hn : n = 0 := by simpa using h
            simp [fixedLE, fromBytes', hn]
  | succ k ih =>
    have hdiv : n/256 < 2^(8*k) := by
      apply Nat.div_lt_of_lt_mul
      have hpow : 2^(8*(k+1)) = 2^(8*k)*256 := by rw [Nat.mul_add, Nat.pow_add]
      rw [hpow] at h
      simpa only [Nat.mul_comm] using h
    simp only [fixedLE, fromBytes', ih hdiv]
    change n % 256 + 256 * (n / 256) = n
    exact Nat.mod_add_div n 256

theorem fixedBE_decode {k n : Nat} (h : n < 2^(8*k)) :
    fromBytes' (fixedBE k n).data.toList.reverse = n := by
  simpa [fixedBE] using fixedLE_value h

theorem actual_word_decode (w : UInt256) : uInt256OfByteArray w.toByteArray = w := by
  rw [actual_word_bytes]
  have hv := fixedBE_decode (n := w.toNat) (k := 32) w.val.isLt
  unfold uInt256OfByteArray
  rw [hv]
  have hf : Fin.ofNat UInt256.size w.toNat = w.val := Fin.ext (Nat.mod_eq_of_lt w.val.isLt)
  change UInt256.mk (Fin.ofNat UInt256.size w.toNat) = w
  rw [hf]


theorem byteList_loop (b : ByteArray) (i : Nat) (r : List UInt8) :
    ByteArray.toList.loop b i r = r.reverse ++ b.data.toList.drop i := by
  fun_induction ByteArray.toList.loop b i r with
  | case1 i r h ih =>
    rw [ih]
    simp only [List.reverse_cons, List.append_assoc]
    congr 1
    have hd : b.data.toList.drop i = b.get! i :: b.data.toList.drop (i+1) := by
      simpa [ByteArray.get!, h] using (List.drop_eq_getElem_cons (l := b.data.toList) (i := i) h)
    simpa using hd.symm
  | case2 i r h =>
    have hd : b.data.toList.drop i = [] := List.drop_eq_nil_iff.mpr (by simpa using Nat.le_of_not_gt h)
    simp [hd]

theorem byteList_data (b : ByteArray) : b.toList = b.data.toList := by
  simpa [ByteArray.toList] using byteList_loop b 0 []

/-- The other decoder, used by actual memory loads, sees the same bytes. -/
theorem actual_memory_decode (w : UInt256) : fromByteArrayBigEndian w.toByteArray = w.toNat := by
  unfold fromByteArrayBigEndian fromBytesBigEndian
  simp only [Function.comp_apply, byteList_data]
  rw [actual_word_bytes]
  exact fixedBE_decode w.val.isLt

end LidoSRv3.Audit.Source.SszWordBytes
