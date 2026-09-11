import LidoSRv3.Audit.Source.SszCompiledFrame

/-! `_getParentBlockRoot` (CLValidatorVerifier.sol:103-107) after the STATICCALL,
transcribed from the inspected SszRootCallHarness runtime IR
(audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul:116-166): the
`returndatasize` switch, the `bytes memory data` allocation through the free
pointer, `returndatacopy`, the `!success || data.length == 0` guard, the ABI
`bytes32` decoder length guard and the final word load. The reply bytes are
the machine's actual returndata; the decoded word is proved to be the typed
`firstWord` of those same bytes, the value the typed entry consumes. -/
namespace LidoSRv3.Audit.Source.SszCompiledReply
open EvmYul EvmYul.EVM SszWordBytes SszScratchByteArray SszCompiledMemory SszCompiledMerkle
open SszCompiledFrame

inductive Error where
  | panic41 | rootNotFound | abiDecodeFailure
  deriving DecidableEq, Repr

/-- IR 116-145. `and(add(and(add(n,31),not(31)),63),not(31))` is `n` rounded up to
32 plus one length word; both `and`s are evaluated on the uint64-guarded size. -/
def copyReply (st : EVM.State) : Except Error (UInt256 × EVM.State) :=
  let size := st.returnData.size
  if size = 0 then .ok (UInt256.ofNat 96, st)
  else if size > 2 ^ 64 - 1 then .error .panic41
  else
    let (memPtr, st) := load st 64
    let newFree := memPtr + UInt256.ofNat ((size + 31) / 32 * 32) + UInt256.ofNat 32
    if newFree.toNat > 2 ^ 64 - 1 ∨ newFree < memPtr then .error .panic41
    else
      let st := store st 64 newFree
      let st := store st memPtr.toNat (UInt256.ofNat size)
      let st : EVM.State := { st with toSharedState := { st.toSharedState with toMachineState :=
        st.toMachineState.returndatacopy (memPtr + UInt256.ofNat 32) (UInt256.ofNat 0)
          (UInt256.ofNat size) } }
      .ok (memPtr, st)

/-- IR 146-166: `!success || data.length == 0` (the length load only on success),
the decoder's `slt(sub(add(data, mload(data)), data), 32)` guard, `mload(data + 32)`. -/
def decodeRoot (st : EVM.State) (success : Bool) (data : UInt256) :
    Except Error (UInt256 × EVM.State) :=
  if !success then .error .rootNotFound
  else
    let (length, st) := load st data.toNat
    if length = UInt256.ofNat 0 then .error .rootNotFound
    else
      let (length', st) := load st data.toNat
      if UInt256.sltBool ((data + length') - data) (UInt256.ofNat 32) then .error .abiDecodeFailure
      else
        let (root, st) := load st (data + UInt256.ofNat 32).toNat
        .ok (root, st)

/-! ## Word/byte round trips -/

theorem fromBytes'_lt : ∀ l : List UInt8, fromBytes' l < 2 ^ (8 * l.length)
  | [] => by simp [fromBytes']
  | b :: rest => by
    have ih := fromBytes'_lt rest
    have hb : b.toFin.val < 2 ^ 8 := b.toFin.isLt
    simp only [fromBytes', List.length_cons]
    rw [Nat.mul_succ, Nat.pow_add]
    omega

theorem fixedLE_fromBytes' : ∀ l : List UInt8, fixedLE l.length (fromBytes' l) = l
  | [] => rfl
  | b :: rest => by
    have ih := fixedLE_fromBytes' rest
    have hb : b.toFin.val < 2 ^ 8 := b.toFin.isLt
    simp only [fromBytes', List.length_cons, fixedLE]
    have hdiv : (b.toFin.val + 2 ^ 8 * fromBytes' rest) / 256 = fromBytes' rest := by omega
    rw [hdiv, ih]
    congr 1
    apply UInt8.toNat_inj.mp
    simp only [UInt8.toNat_ofNat']
    change (b.toFin.val + 2 ^ 8 * fromBytes' rest) % 2 ^ 8 = b.toFin.val
    omega

theorem list_toByteArray_data (l : List UInt8) : l.toByteArray = ⟨l.toArray⟩ := by
  apply ByteArray.ext
  exact List.data_toByteArray

/-- A 32-byte array is the encoding of the word it decodes to. -/
theorem word_of_bytes (B : ByteArray) (h : B.size = 32) :
    (UInt256.ofNat (fromByteArrayBigEndian B)).toByteArray = B := by
  have hlen : B.toList.reverse.length = 32 := by
    rw [List.length_reverse, byteList_data, Array.length_toList]
    exact h
  have hlt : fromByteArrayBigEndian B < UInt256.size := by
    have := fromBytes'_lt B.toList.reverse
    rw [hlen] at this
    unfold fromByteArrayBigEndian fromBytesBigEndian
    exact this
  have hn : (UInt256.ofNat (fromByteArrayBigEndian B)).toNat = fromByteArrayBigEndian B :=
    Nat.mod_eq_of_lt hlt
  rw [actual_word_bytes, hn]
  unfold fixedBE fromByteArrayBigEndian fromBytesBigEndian
  change (fixedLE 32 (fromBytes' B.toList.reverse)).reverse.toByteArray = B
  rw [← hlen, fixedLE_fromBytes', List.reverse_reverse, byteList_data, list_toByteArray_data]
  apply ByteArray.ext
  exact Array.toArray_toList

theorem bitvec_roundtrip (b : SszValidatorLeaf.Byte) : (UInt8.ofNat b.toNat).toBitVec = b := by
  rw [UInt8.toBitVec_ofNat']
  apply BitVec.eq_of_toNat_eq
  rw [BitVec.toNat_ofNat]
  exact Nat.mod_eq_of_lt b.isLt

theorem typedBytes_bytes (l : List SszValidatorLeaf.Byte) :
    SszScratchEvmMemory.typedBytes (SszTypedFfiBridge.bytes l) = l := by
  unfold SszScratchEvmMemory.typedBytes SszTypedFfiBridge.bytes
  rw [List.data_toByteArray, Array.toList_toArray, List.map_map]
  simp only [Function.comp_def, bitvec_roundtrip, List.map_id']

theorem typedBytes_append (a b : ByteArray) :
    SszScratchEvmMemory.typedBytes (a ++ b) =
      SszScratchEvmMemory.typedBytes a ++ SszScratchEvmMemory.typedBytes b := by
  simp [SszScratchEvmMemory.typedBytes, ByteArray.data_append]

theorem extract_split (D : ByteArray) (h : 32 ≤ D.size) :
    D = D.extract 0 32 ++ D.extract 32 D.size := by
  apply ByteArray.ext
  simp only [ByteArray.data_append, ByteArray.data_extract]
  rw [Array.extract_append_extract]
  have h1 : min 0 32 = 0 := rfl
  have h2 : max 32 D.size = D.size := by omega
  rw [h1, h2]
  exact Array.extract_size.symm

/-- The decoded root word of a reply of at least 32 bytes is the typed
`firstWord` of the same bytes. -/
theorem root_word_typed (D : ByteArray) (h : 32 ≤ D.size) :
    SszTypedFfiBridge.toWord (SszVerifierEntry.firstWord (SszScratchEvmMemory.typedBytes D)) =
      UInt256.ofNat (fromByteArrayBigEndian (D.extract 0 32)) := by
  have hB : (D.extract 0 32).size = 32 := by
    rw [ByteArray.size_extract]
    omega
  have hw := word_of_bytes (D.extract 0 32) hB
  have hsplit := extract_split D h
  generalize UInt256.ofNat (fromByteArrayBigEndian (D.extract 0 32)) = w at hw ⊢
  have hdig : SszScratchEvmMemory.typedBytes (D.extract 0 32) =
      SszValidatorLeaf.digestBytes (SszTypedFfiBridge.toDigest w) := by
    rw [← hw, ← SszTypedFfiBridge.digest_actual_word, typedBytes_bytes]
  conv_lhs => rw [hsplit]
  rw [typedBytes_append, hdig, SszVerifierEntry.first_word_encoded]
  rfl

/-- The typed entry's reply bytes are the machine bytes copied here. -/
theorem fromBytes_typed (data : List UInt8) :
    SszRootCall.fromBytes data = SszScratchEvmMemory.typedBytes ⟨data.toArray⟩ := by
  unfold SszRootCall.fromBytes SszScratchEvmMemory.typedBytes
  rw [Array.toList_toArray]
  apply List.map_congr_left
  intro b _
  show BitVec.ofNat 8 b.toBitVec.toNat = b.toBitVec
  apply BitVec.eq_of_toNat_eq
  rw [BitVec.toNat_ofNat]
  exact Nat.mod_eq_of_lt b.toBitVec.isLt

/-! ## Word arithmetic of the decoder -/

theorem add_sub_self_word (a b : Nat) (h : a + b < UInt256.size) :
    UInt256.ofNat a + UInt256.ofNat b - UInt256.ofNat a = UInt256.ofNat b := by
  rw [ofNat_add a b h]
  apply congrArg UInt256.mk
  apply Fin.ext
  change ((UInt256.size - a % UInt256.size) + (a + b) % UInt256.size) % UInt256.size = b % UInt256.size
  rw [Nat.mod_eq_of_lt (show a < UInt256.size by omega), Nat.mod_eq_of_lt h]
  unfold UInt256.size at *
  omega

theorem sltBool_small (a b : Nat) (ha : a < 2 ^ 64) (hb : b < 2 ^ 64) :
    UInt256.sltBool (UInt256.ofNat a) (UInt256.ofNat b) = decide (a < b) := by
  unfold UInt256.sltBool
  rw [word_nat a ha, word_nat b hb]
  have h1 : ¬ (a ≥ 2 ^ 255) := by omega
  have h2 : ¬ (b ≥ 2 ^ 255) := by omega
  rw [if_neg h1, if_neg h2]
  apply decide_eq_decide.mpr
  change (UInt256.ofNat a).toNat < (UInt256.ofNat b).toNat ↔ a < b
  rw [word_nat a ha, word_nat b hb]

theorem ofNat_ne_zero (n : Nat) (h0 : n ≠ 0) (hn : n < 2 ^ 64) :
    UInt256.ofNat n ≠ UInt256.ofNat 0 := by
  intro heq
  have := congrArg UInt256.toNat heq
  rw [word_nat n hn, show (UInt256.ofNat 0).toNat = 0 by decide +kernel] at this
  exact h0 this

/-! ## returndatacopy -/

/-- Bytes copied from the reply are read back exactly (first 32 of them). -/
theorem write_read_inside (src dest : ByteArray) (s d n : Nat)
    (hn : 32 ≤ n) (hfit : s + n ≤ src.size) (hd : d ≤ dest.size + 576) :
    (src.write s dest d n).readWithPadding d 32 = src.extract s (s + 32) ∧
    d + n ≤ (src.write s dest d n).size := by
  have hdata := write_fit src dest s d n (by omega) hfit hd
  have hshape : src.write s dest d n =
      (⟨dest.data.extract 0 d ++ Array.replicate (d - dest.size) 0⟩ : ByteArray) ++
        (src.extract s (s + n) ++ (⟨dest.data.extract (d + n) dest.size⟩ : ByteArray)) := by
    apply ByteArray.ext
    rw [hdata]
    simp only [ByteArray.data_append, ByteArray.data_extract, Array.append_assoc]
  have hpre : (⟨dest.data.extract 0 d ++ Array.replicate (d - dest.size) 0⟩ : ByteArray).size = d := by
    change (dest.data.extract 0 d ++ Array.replicate (d - dest.size) 0).size = d
    simp only [Array.size_append, Array.size_extract, Array.size_replicate]
    omega
  have hmid : (src.extract s (s + n)).size = n := by
    rw [ByteArray.size_extract]
    omega
  have hsz : d + n ≤ (src.write s dest d n).size := by
    rw [hshape]
    simp only [ByteArray.size_append, hpre, hmid]
    omega
  refine ⟨?_, hsz⟩
  rw [SszShaCallBytes.read_fit (src.write s dest d n) d 32 (by omega) (by omega), hshape]
  show (_ ++ _).extract (d + 0) (d + 32) = _
  rw [ByteArray.extract_append_size_add' hpre.symm,
    extract_append_before (src.extract s (s + n)) ⟨dest.data.extract (d + n) dest.size⟩ 0 32
      (by rw [hmid]; omega)]
  apply ByteArray.ext
  simp only [ByteArray.data_extract, Array.extract_extract, Nat.add_zero]
  congr 1
  omega

/-- A stored cell below the copy destination survives `returndatacopy`. -/
theorem stored_returndatacopy (st : EVM.State) (mstart size offset : Nat) (value : UInt256)
    (h : Stored st offset value) (hoff : offset + 32 ≤ mstart)
    (hm : mstart < 2 ^ 64) (hs : size < 2 ^ 64) :
    Stored { st with toSharedState := { st.toSharedState with toMachineState :=
      st.toMachineState.returndatacopy (UInt256.ofNat mstart) (UInt256.ofNat 0)
        (UInt256.ofNat size) } } offset value := by
  have h0 : (UInt256.ofNat 0).toNat = 0 := by decide +kernel
  have hmn := word_nat mstart hm
  have hsn := word_nat size hs
  have hmem : ({ st with toSharedState := { st.toSharedState with toMachineState :=
      st.toMachineState.returndatacopy (UInt256.ofNat mstart) (UInt256.ofNat 0)
        (UInt256.ofNat size) } } : EVM.State).memory =
      st.returnData.write 0 st.memory mstart size := by
    change st.returnData.write (UInt256.ofNat 0).toNat st.memory (UInt256.ofNat mstart).toNat
      (UInt256.ofNat size).toNat = _
    rw [h0, hmn, hsn]
  have hM : st.activeWords.toNat ≤ MachineState.M st.activeWords.toNat mstart size := by
    cases size with
    | zero => exact Nat.le_refl _
    | succ k => exact Nat.le_max_left _ _
  have hMlt : MachineState.M st.activeWords.toNat mstart size < UInt256.size := by
    have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    cases size with
    | zero => exact hf
    | succ k =>
      show max st.activeWords.toNat ((mstart + (k + 1) + 31) / 32) < UInt256.size
      unfold UInt256.size at *
      omega
  refine ⟨?_, ?_, ?_⟩
  · rw [hmem]
    exact Nat.le_trans h.1 (write_size_mono _ _ _ _ _)
  · rw [hmem, SszShaCallBytes.read_fit _ offset 32
      (Nat.le_trans h.1 (write_size_mono _ _ _ _ _)) (by omega),
      write_preserves_before _ _ _ _ _ _ _ hoff h.1,
      ← SszShaCallBytes.read_fit _ offset 32 h.1 (by omega)]
    exact h.2.1
  · have hMn : (UInt256.ofNat (MachineState.M st.activeWords.toNat mstart size)).toNat =
        MachineState.M st.activeWords.toNat mstart size := Nat.mod_eq_of_lt hMlt
    change offset < (UInt256.ofNat (MachineState.M st.activeWords.toNat (UInt256.ofNat mstart).toNat
      (UInt256.ofNat size).toNat)).toNat * 32
    rw [hmn, hsn, hMn]
    have := h.2.2
    omega

/-- The first reply word lands at the copy destination. -/
theorem stored_reply_word (st : EVM.State) (mstart : Nat)
    (hm : mstart < 2 ^ 64) (hs : st.returnData.size < 2 ^ 64) (h32 : 32 ≤ st.returnData.size)
    (hmem : mstart ≤ st.memory.size + 576) :
    Stored { st with toSharedState := { st.toSharedState with toMachineState :=
      st.toMachineState.returndatacopy (UInt256.ofNat mstart) (UInt256.ofNat 0)
        (UInt256.ofNat st.returnData.size) } } mstart
      (UInt256.ofNat (fromByteArrayBigEndian (st.returnData.extract 0 32))) := by
  have h0 : (UInt256.ofNat 0).toNat = 0 := by decide +kernel
  have hmn := word_nat mstart hm
  have hsn := word_nat _ hs
  have hmemeq : ({ st with toSharedState := { st.toSharedState with toMachineState :=
      st.toMachineState.returndatacopy (UInt256.ofNat mstart) (UInt256.ofNat 0)
        (UInt256.ofNat st.returnData.size) } } : EVM.State).memory =
      st.returnData.write 0 st.memory mstart st.returnData.size := by
    change st.returnData.write (UInt256.ofNat 0).toNat st.memory (UInt256.ofNat mstart).toNat
      (UInt256.ofNat st.returnData.size).toNat = _
    rw [h0, hmn, hsn]
  obtain ⟨hread, hsize⟩ := write_read_inside st.returnData st.memory 0 mstart st.returnData.size
    h32 (by omega) hmem
  have hB : (st.returnData.extract 0 32).size = 32 := by
    rw [ByteArray.size_extract]
    omega
  refine ⟨?_, ?_, ?_⟩
  · rw [hmemeq]
    omega
  · rw [hmemeq, hread, word_of_bytes _ hB]
    rfl
  · change mstart < (UInt256.ofNat (MachineState.M st.activeWords.toNat (UInt256.ofNat mstart).toNat
      (UInt256.ofNat st.returnData.size).toNat)).toNat * 32
    rw [hmn, hsn]
    obtain ⟨k, hk⟩ : ∃ k, st.returnData.size = k + 1 := ⟨st.returnData.size - 1, by omega⟩
    rw [hk]
    show mstart < (UInt256.ofNat (max st.activeWords.toNat ((mstart + (k + 1) + 31) / 32))).toNat * 32
    have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    have hMn : (UInt256.ofNat (max st.activeWords.toNat ((mstart + (k + 1) + 31) / 32))).toNat =
        max st.activeWords.toNat ((mstart + (k + 1) + 31) / 32) :=
      Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)
    rw [hMn]
    omega

theorem returndatacopy_words (st : EVM.State) (mstart size : Nat)
    (hm : mstart < 2 ^ 64) (hs : size < 2 ^ 64) (hw : st.activeWords.toNat < 2 ^ 64) :
    ({ st with toSharedState := { st.toSharedState with toMachineState :=
      st.toMachineState.returndatacopy (UInt256.ofNat mstart) (UInt256.ofNat 0)
        (UInt256.ofNat size) } } : EVM.State).activeWords.toNat < 2 ^ 64 := by
  have hmn := word_nat mstart hm
  have hsn := word_nat size hs
  change (UInt256.ofNat (MachineState.M st.activeWords.toNat (UInt256.ofNat mstart).toNat
    (UInt256.ofNat size).toNat)).toNat < 2 ^ 64
  rw [hmn, hsn]
  cases size with
  | zero =>
    show (UInt256.ofNat st.activeWords.toNat).toNat < 2 ^ 64
    rw [word_nat _ hw]
    exact hw
  | succ k =>
    show (UInt256.ofNat (max st.activeWords.toNat ((mstart + (k + 1) + 31) / 32))).toNat < 2 ^ 64
    rw [word_nat (max st.activeWords.toNat ((mstart + (k + 1) + 31) / 32)) (by omega)]
    omega

theorem returndatacopy_size (st : EVM.State) (mstart : Nat)
    (hm : mstart < 2 ^ 64) (hs : st.returnData.size < 2 ^ 64) (h32 : 32 ≤ st.returnData.size)
    (hmem : mstart ≤ st.memory.size + 576) :
    mstart + st.returnData.size ≤
      ({ st with toSharedState := { st.toSharedState with toMachineState :=
        st.toMachineState.returndatacopy (UInt256.ofNat mstart) (UInt256.ofNat 0)
          (UInt256.ofNat st.returnData.size) } } : EVM.State).memory.size := by
  have h0 : (UInt256.ofNat 0).toNat = 0 := by decide +kernel
  have hmn := word_nat mstart hm
  have hsn := word_nat _ hs
  change mstart + st.returnData.size ≤ (st.returnData.write (UInt256.ofNat 0).toNat st.memory
    (UInt256.ofNat mstart).toNat (UInt256.ofNat st.returnData.size).toNat).size
  rw [h0, hmn, hsn]
  exact (write_read_inside st.returnData st.memory 0 mstart st.returnData.size h32 (by omega) hmem).2

/-! ## Success of the reply phase -/

private theorem prod_ok {α β : Type} {ε : Type} {a a' : α} {b b' : β}
    (h : (Except.ok (a, b) : Except ε (α × β)) = Except.ok (a', b')) : a = a' ∧ b = b' :=
  Prod.mk.inj (Except.ok.inj h)

/-- Success of the copy and decode phases derives: the call succeeded with at
least 32 reply bytes, the decoded word is the reply's first word, the new free
pointer, the extent bound and the array-size relation the leaf allocation needs.
Inputs are only the previous phase's free pointer and the zero slot. -/
theorem reply_success (st st1 st2 : EVM.State) (success : Bool) (data root : UInt256)
    (hc : copyReply st = .ok (data, st1))
    (hd : decodeRoot st1 success data = .ok (root, st2))
    (hf : Stored st 64 (UInt256.ofNat 192))
    (hz : Stored st 96 (UInt256.ofNat 0))
    (hw : st.activeWords.toNat < 2 ^ 64) :
    success = true ∧ 32 ≤ st.returnData.size ∧ st.returnData.size ≤ 2 ^ 64 - 1 ∧
    192 + (st.returnData.size + 31) / 32 * 32 + 32 ≤ 2 ^ 64 - 1 ∧
    root = UInt256.ofNat (fromByteArrayBigEndian (st.returnData.extract 0 32)) ∧
    Stored st2 64 (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32)) ∧
    st2.activeWords.toNat < 2 ^ 64 ∧
    st2.executionEnv = st.executionEnv ∧
    192 + (st.returnData.size + 31) / 32 * 32 + 32 ≤ st2.memory.size + 31 := by
  have hw251 : st.activeWords.toNat < 2 ^ 251 := by omega
  have h192 : (UInt256.ofNat 192).toNat = 192 := by decide +kernel
  have h96 : (UInt256.ofNat 96).toNat = 96 := by decide +kernel
  have h224 : (UInt256.ofNat 224).toNat = 224 := by decide +kernel
  unfold copyReply at hc
  dsimp only at hc
  split at hc
  · rename_i h0
    obtain ⟨hdata, hst⟩ := prod_ok hc
    subst hdata
    subst hst
    exfalso
    unfold decodeRoot at hd
    split at hd
    · cases hd
    · dsimp only at hd
      simp only [h96] at hd
      rw [stored_load st 96 _ hz (by decide) hw251, if_pos rfl] at hd
      cases hd
  · rename_i hne0
    split at hc
    · cases hc
    · rename_i hbig
      rw [stored_load st 64 _ hf (by decide) hw251] at hc
      have hsize : st.returnData.size ≤ 2 ^ 64 - 1 := by omega
      have eR : UInt256.ofNat 192 + UInt256.ofNat ((st.returnData.size + 31) / 32 * 32) =
          UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32) :=
        ofNat_add _ _ (by unfold UInt256.size; omega)
      have eF : UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32) + UInt256.ofNat 32 =
          UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32) :=
        ofNat_add _ _ (by unfold UInt256.size; omega)
      have e224 : UInt256.ofNat 192 + UInt256.ofNat 32 = UInt256.ofNat 224 := small_add _ _ (by decide)
      simp only [eR, eF, e224, h192] at hc
      split at hc
      · cases hc
      · rename_i hguard
        have hFt : (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32)).toNat =
            192 + (st.returnData.size + 31) / 32 * 32 + 32 :=
          Nat.mod_eq_of_lt (by unfold UInt256.size; omega)
        have hF : 192 + (st.returnData.size + 31) / 32 * 32 + 32 ≤ 2 ^ 64 - 1 := by
          by_contra hlt
          exact hguard (Or.inl (by rw [hFt]; omega))
        obtain ⟨hdata, hst⟩ := prod_ok hc
        subst hdata
        -- the state after the two stores
        have wa : (load st 64).2.activeWords.toNat < 2 ^ 64 := load_bounded st 64 (by decide) hw
        have hfa : Stored (store (load st 64).2 64
            (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32))) 64
            (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32)) :=
          stored_written _ 64 _ (by decide) (Nat.le_trans (by decide) (Nat.le_add_left 576 _))
        have wb := store_bounded (load st 64).2 64
          (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32)) (by decide) wa
        have hfb : Stored (store (store (load st 64).2 64
            (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32))) 192
            (UInt256.ofNat st.returnData.size)) 64
            (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32)) :=
          stored_preserved _ 192 64 _ _ hfa (by decide) (by omega)
        have hlb : Stored (store (store (load st 64).2 64
            (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32))) 192
            (UInt256.ofNat st.returnData.size)) 192 (UInt256.ofNat st.returnData.size) :=
          stored_written _ 192 _ (by decide) (Nat.le_trans (by decide) (Nat.le_add_left 576 _))
        have wc := store_bounded (store (load st 64).2 64
          (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32))) 192
          (UInt256.ofNat st.returnData.size) (by decide) wb
        have hs1 : Stored st1 192 (UInt256.ofNat st.returnData.size) := by
          rw [← hst]
          exact stored_returndatacopy _ 224 _ 192 _ hlb (by omega) (by decide) (by omega)
        have hs64 : Stored st1 64 (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32)) := by
          rw [← hst]
          exact stored_returndatacopy _ 224 _ 64 _ hfb (by omega) (by decide) (by omega)
        have w1 : st1.activeWords.toNat < 2 ^ 64 := by
          rw [← hst]
          exact returndatacopy_words _ 224 st.returnData.size (by decide) (by omega) wc
        have w251 : st1.activeWords.toNat < 2 ^ 251 := by omega
        have henv1 : st1.executionEnv = st.executionEnv := by
          rw [← hst]
          rfl
        -- decode
        unfold decodeRoot at hd
        split at hd
        · cases hd
        · rename_i hsucc
          dsimp only at hd
          simp only [h192, e224, h224] at hd
          rw [stored_load st1 192 _ hs1 (by decide) w251,
            if_neg (ofNat_ne_zero _ hne0 (by omega))] at hd
          have hs1' := stored_after_load st1 192 192 _ hs1 (by decide)
          have w1' := load_bounded st1 192 (by decide) w1
          rw [stored_load _ 192 _ hs1' (by decide) (by omega),
            add_sub_self_word 192 st.returnData.size (by unfold UInt256.size; omega),
            sltBool_small st.returnData.size 32 (by omega) (by decide)] at hd
          split at hd
          · cases hd
          · rename_i hge
            simp only [decide_eq_true_eq] at hge
            have h32 : 32 ≤ st.returnData.size := by omega
            have hroot : Stored st1 224
                (UInt256.ofNat (fromByteArrayBigEndian (st.returnData.extract 0 32))) := by
              rw [← hst]
              exact stored_reply_word _ 224 (by decide) (by show st.returnData.size < 2 ^ 64; omega)
                (by show 32 ≤ st.returnData.size; exact h32)
                (Nat.le_trans (by decide) (Nat.le_add_left 576 _))
            have hsz : 224 + st.returnData.size ≤ st1.memory.size := by
              rw [← hst]
              exact returndatacopy_size _ 224 (by decide) (by show st.returnData.size < 2 ^ 64; omega)
                (by show 32 ≤ st.returnData.size; exact h32)
                (Nat.le_trans (by decide) (Nat.le_add_left 576 _))
            have hroot' := stored_after_load _ 192 224 _
              (stored_after_load st1 192 224 _ hroot (by decide)) (by decide)
            have w2 := load_bounded (load st1 192).2 192 (by decide) w1'
            rw [stored_load _ 224 _ hroot' (by decide) (by omega)] at hd
            obtain ⟨hr, hst2⟩ := prod_ok hd
            subst hr
            subst hst2
            have hs64' := stored_after_load _ 224 64 _ (stored_after_load _ 192 64 _
              (stored_after_load st1 192 64 _ hs64 (by decide)) (by decide)) (by decide)
            refine ⟨by simpa using hsucc, h32, hsize, hF, rfl, hs64', ?_, henv1, ?_⟩
            · exact load_bounded _ 224 (by decide) w2
            · change 192 + (st.returnData.size + 31) / 32 * 32 + 32 ≤ st1.memory.size + 31
              omega

#print axioms reply_success
#print axioms root_word_typed
end LidoSRv3.Audit.Source.SszCompiledReply
