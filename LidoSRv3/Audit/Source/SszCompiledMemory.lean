import LidoSRv3.Audit.Source.SszProofCommitted

/-! Concrete compiler memory operations for the pinned viaIR leaf pipeline.
These operations are consumed by SszCompiledConsumer; SszCompiledMerkle derives
their initialization, framing and typed-leaf connection. -/
namespace LidoSRv3.Audit.Source.SszCompiledMemory
open EvmYul EvmYul.EVM SszWordBytes SszScratchByteArray

theorem ffi_zeros_bounded (n : Nat) (hn : n ≤ 576) :
    ffi.ByteArray.zeroes (⟨n⟩ : USize) = zeros n := by
  have hu : (⟨n⟩ : USize).toNat = n := by
    change n % 2 ^ System.Platform.numBits = n
    rcases System.Platform.numBits_eq with h | h <;> rw [h] <;> norm_num <;> omega
  apply ByteArray.ext
  change Array.replicate ((⟨n⟩ : USize).toNat) 0 = Array.replicate n 0
  rw [hu]

theorem write_fit (src dest : ByteArray) (s d n : Nat)
    (hn : 0 < n) (hfit : s + n ≤ src.size) (hd : d ≤ 576) :
    (src.write s dest d n).data =
      (dest.data.extract 0 d ++ Array.replicate (d - dest.size) 0) ++
      src.data.extract s (s + n) ++ dest.data.extract (d + n) dest.size := by
  have hsrc : ¬ s ≥ src.size := by omega
  have hp : min n (src.size - s) = n := by omega
  have hz : min dest.size (d + n) - (d + n) = 0 := by omega
  have hpad : d - dest.size ≤ 576 := by omega
  unfold ByteArray.write
  simp only [Nat.ne_of_gt hn, ↓reduceIte, hsrc, hp, hz, ffi_zeros_bounded 0 (by omega),
    ffi_zeros_bounded _ hpad, append_zeros_zero, Nat.add_zero]
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

theorem write_word_shape (old : ByteArray) (offset : Nat) (word : UInt256)
    (hoffset : offset ≤ 576) :
    (word.toByteArray.write 0 old offset 32).data =
      (old.data.extract 0 offset ++ Array.replicate (offset-old.size) 0) ++
      word.toByteArray.data ++ old.data.extract (offset+32) old.size := by
  rw [write_fit _ _ 0 offset 32 (by omega) (by rw [actual_word_size]) hoffset]
  have hs : word.toByteArray.data.size = 32 := actual_word_size word
  simp only [Nat.zero_add,← hs,Array.extract_size]

theorem write_word_read (old : ByteArray) (offset : Nat) (word : UInt256)
    (hoffset : offset ≤ 576) :
    (word.toByteArray.write 0 old offset 32).readWithPadding offset 32 = word.toByteArray := by
  have hs : word.toByteArray.data.size = 32 := actual_word_size word
  have hp : (old.data.extract 0 offset ++ Array.replicate (offset-old.size) 0).size = offset := by
    simp
    omega
  have hm := write_word_shape old offset word hoffset
  have hsize : offset + 32 ≤ (word.toByteArray.write 0 old offset 32).size := by
    change offset + 32 ≤ (word.toByteArray.write 0 old offset 32).data.size
    rw [hm]
    simp only [Array.size_append,hp,hs]
    omega
  rw [SszShaCallBytes.read_fit _ offset 32 hsize (by omega)]
  apply ByteArray.ext
  rw [ByteArray.data_extract,hm]
  generalize hpre : old.data.extract 0 offset ++ Array.replicate (offset-old.size) 0 = preceding at hp ⊢
  generalize htail : old.data.extract (offset+32) old.size = suffix
  simp only [Array.extract_append,Array.size_append,hp,hs]
  simp only [Nat.sub_self,Nat.add_sub_cancel_left]
  rw [Array.extract_empty_of_size_le_start (by omega : preceding.size ≤ offset),Array.empty_append]
  rw [Array.extract_empty_of_stop_le_start (Nat.zero_le _),Array.append_empty]
  have he := Array.extract_size (xs := word.toByteArray.data)
  rw [hs] at he
  exact he

theorem store_words (machine : MachineState) (offset : Nat) (word : UInt256)
    (hoffset : offset ≤ 576) :
    (machine.mstore (UInt256.ofNat offset) word).activeWords.toNat =
      max machine.activeWords.toNat ((offset+63)/32) := by
  have ho : (UInt256.ofNat offset).toNat = offset := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  simp only [MachineState.mstore,MachineState.M,ho]
  change max machine.activeWords.toNat ((offset+32+31)/32) % UInt256.size = _
  rw [Nat.mod_eq_of_lt]
  have hf : machine.activeWords.toNat < UInt256.size := machine.activeWords.val.isLt
  unfold UInt256.size at *
  omega

theorem load_words (machine : MachineState) (offset : Nat) (hoffset : offset ≤ 576) :
    (machine.mload (UInt256.ofNat offset)).2.activeWords.toNat =
      max machine.activeWords.toNat ((offset+63)/32) := by
  have ho : (UInt256.ofNat offset).toNat = offset := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  simp only [MachineState.mload,MachineState.M,ho]
  change max machine.activeWords.toNat ((offset+32+31)/32) % UInt256.size = _
  rw [Nat.mod_eq_of_lt]
  have hf : machine.activeWords.toNat < UInt256.size := machine.activeWords.val.isLt
  unfold UInt256.size at *
  omega

theorem store_size (machine : MachineState) (offset : Nat) (word : UInt256)
    (hoffset : offset ≤ 576) :
    offset+32 ≤ (machine.mstore (UInt256.ofNat offset) word).memory.size := by
  have ho : (UInt256.ofNat offset).toNat = offset := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  change offset+32 ≤ (word.toByteArray.write 0 machine.memory (UInt256.ofNat offset).toNat 32).size
  rw [ho]
  change offset+32 ≤ (word.toByteArray.write 0 machine.memory offset 32).data.size
  rw [write_word_shape _ _ _ hoffset]
  simp only [Array.size_append,Array.size_extract,Array.size_replicate,ByteArray.size_data,actual_word_size]
  omega

theorem store_load (machine : MachineState) (offset : Nat) (word : UInt256)
    (hoffset : offset ≤ 576) (hwidth : machine.activeWords.toNat < 2^251) :
    ((machine.mstore (UInt256.ofNat offset) word).mload (UInt256.ofNat offset)).1 = word := by
  let written := machine.mstore (UInt256.ofNat offset) word
  have ho : (UInt256.ofNat offset).toNat = offset := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  have hw : written.activeWords.toNat = max machine.activeWords.toNat ((offset+63)/32) :=
    store_words machine offset word hoffset
  have hm : written.memory = word.toByteArray.write 0 machine.memory offset 32 := by
    simp only [written,MachineState.mstore,MachineState.writeWord,writeBytes,ho]
  have hs : offset < written.memory.size := by
    rw [hm]
    change offset < (word.toByteArray.write 0 machine.memory offset 32).data.size
    rw [write_word_shape _ _ _ hoffset]
    simp only [Array.size_append,Array.size_extract,Array.size_replicate,ByteArray.size_data]
    rw [actual_word_size]
    omega
  have hx : offset < (written.activeWords * (UInt256.ofNat 32)).toNat := by
    change offset < written.activeWords.toNat * 32 % UInt256.size
    rw [Nat.mod_eq_of_lt]
    · rw [hw]
      omega
    · rw [hw]
      unfold UInt256.size
      omega
  have hr : written.memory.readWithPadding offset 32 = word.toByteArray := by
    rw [hm]; exact write_word_read _ _ _ hoffset
  change (written.mload (UInt256.ofNat offset)).1 = word
  simp only [MachineState.mload,MachineState.lookupMemory,ho]
  rw [if_neg (by
    push Not
    constructor
    · exact hs
    · change ¬ (UInt256.ofNat offset).toNat ≥ (written.activeWords * (UInt256.ofNat 32)).toNat
      rw [ho]
      omega)]
  rw [hr,actual_memory_decode]
  apply congrArg UInt256.mk
  apply Fin.ext
  exact Nat.mod_eq_of_lt word.val.isLt

theorem extract_copy_before (src old : ByteArray) (srcAt destAt count start stop : Nat)
    (hd : stop ≤ destAt) (hs : stop ≤ old.size) :
    (src.copySlice srcAt old destAt count).extract start stop = old.extract start stop := by
  apply ByteArray.ext
  simp only [ByteArray.data_extract,ByteArray.data_copySlice]
  rw [Array.extract_append,Array.extract_append]
  have hpre : (old.data.extract 0 destAt).size = min destAt old.size := by simp
  have hlen : stop ≤ (old.data.extract 0 destAt ++ src.data.extract srcAt (srcAt+count)).size := by
    simp only [Array.size_append,hpre]
    omega
  rw [Nat.sub_eq_zero_of_le hlen,Array.extract_empty_of_stop_le_start (Nat.zero_le _),Array.append_empty]
  rw [hpre,Nat.sub_eq_zero_of_le (by omega : stop ≤ min destAt old.size),
    Array.extract_empty_of_stop_le_start (Nat.zero_le _),Array.append_empty]
  simp only [Array.extract_extract,Nat.zero_add,Nat.min_eq_left hd]

theorem extract_append_before (old extra : ByteArray) (start stop : Nat)
    (hs : stop ≤ old.size) :
    (old ++ extra).extract start stop = old.extract start stop := by
  apply ByteArray.ext
  simp only [ByteArray.data_extract,ByteArray.data_append,Array.extract_append,ByteArray.size_data]
  rw [Nat.sub_eq_zero_of_le hs,Array.extract_empty_of_stop_le_start (Nat.zero_le _),Array.append_empty]

/-- Every actual calldata-copy branch preserves already allocated bytes below
its destination, including the engine's clipped absent-source branch. -/
theorem write_preserves_before (src old : ByteArray) (srcAt destAt count start stop : Nat)
    (hd : stop ≤ destAt) (hs : stop ≤ old.size) :
    (src.write srcAt old destAt count).extract start stop = old.extract start stop := by
  unfold ByteArray.write
  split
  · rfl
  · split
    · apply extract_copy_before
      · omega
      · exact hs
    · rw [extract_copy_before]
      · exact extract_append_before _ _ _ _ hs
      · exact hd
      · simp only [ByteArray.size_append]
        omega

theorem copy_size_mono (src old : ByteArray) (srcAt destAt count : Nat) :
    old.size ≤ (src.copySlice srcAt old destAt count).size := by
  change old.size ≤ (src.copySlice srcAt old destAt count).data.size
  rw [ByteArray.data_copySlice]
  simp only [Array.size_append,Array.size_extract,ByteArray.size_data]
  omega

theorem write_size_mono (src old : ByteArray) (srcAt destAt count : Nat) :
    old.size ≤ (src.write srcAt old destAt count).size := by
  unfold ByteArray.write
  split
  · exact Nat.le_refl _
  · split
    · exact copy_size_mono _ _ _ _ _
    · exact Nat.le_trans (by simp only [ByteArray.size_append];omega) (copy_size_mono _ _ _ _ _)

theorem mload_of_read (machine : MachineState) (offset : Nat) (word : UInt256)
    (hoffset : offset ≤ 576) (hsize : offset+32 ≤ machine.memory.size)
    (hread : machine.memory.readWithPadding offset 32 = word.toByteArray)
    (hpos : offset < machine.activeWords.toNat * 32)
    (hwidth : machine.activeWords.toNat < 2^251) :
    (machine.mload (UInt256.ofNat offset)).1 = word := by
  have ho : (UInt256.ofNat offset).toNat = offset := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  have hx : ¬ UInt256.ofNat offset ≥ machine.activeWords * (UInt256.ofNat 32) := by
    change ¬ (UInt256.ofNat offset).toNat ≥ machine.activeWords.toNat * 32 % UInt256.size
    rw [ho,Nat.mod_eq_of_lt (by unfold UInt256.size;omega)]
    omega
  have h32 : (⟨32⟩ : UInt256) = UInt256.ofNat 32 := by decide +kernel
  simp only [MachineState.mload,MachineState.lookupMemory,ho,h32]
  rw [if_neg (by exact not_or.mpr ⟨by omega,hx⟩),hread,actual_memory_decode]
  apply congrArg UInt256.mk
  apply Fin.ext
  exact Nat.mod_eq_of_lt word.val.isLt

theorem read64_write32 (reply old : ByteArray) (hlen : reply.size = 32) (hsize : 96 ≤ old.size) :
    (reply.write 0 old 0 32).readWithPadding 64 32 = old.readWithPadding 64 32 := by
  have hnew : 96 ≤ (reply.write 0 old 0 32).size := Nat.le_trans hsize (write_size_mono _ _ _ _ _)
  rw [SszShaCallBytes.read_fit _ 64 32 hnew (by omega),SszShaCallBytes.read_fit _ 64 32 hsize (by omega)]
  rw [SszShaCallBytes.write32 reply old hlen]
  apply ByteArray.ext
  simp only [ByteArray.data_extract,ByteArray.data_append,Array.extract_append,ByteArray.size_data,hlen]
  rw [Array.extract_empty_of_size_le_start (by simpa using (show reply.size ≤ 64 by omega)),Array.empty_append]
  simp only [Array.extract_extract]
  have hmin : min (32+(96-32)) old.size = 96 := by omega
  simp only [hmin]

theorem read64_after_scratch (head old : ByteArray) (hlen : head.size = 64) (hsize : 96 ≤ old.size) :
    (head ++ old.extract 64 old.size).readWithPadding 64 32 = old.readWithPadding 64 32 := by
  have hnew : 96 ≤ (head ++ old.extract 64 old.size).size := by simp [hlen];omega
  rw [SszShaCallBytes.read_fit _ 64 32 hnew (by omega),SszShaCallBytes.read_fit _ 64 32 hsize (by omega)]
  apply ByteArray.ext
  simp only [ByteArray.data_extract,ByteArray.data_append,Array.extract_append,ByteArray.size_data,hlen]
  rw [Array.extract_empty_of_size_le_start (by simpa using (show head.size ≤ 64 by omega)),Array.empty_append]
  simp only [Array.extract_extract]
  have hmin : min (64+(96-64)) old.size = 96 := by omega
  simp only [hmin]

theorem finish_memory (called : Except EVM.ExecutionException (UInt256 × EVM.State))
    (result : SszBlsComposition.Result) (h : SszBlsComposition.finish called = .ok result) :
    ∃ flag st, called = .ok (flag,st) ∧ flag ≠ UInt256.ofNat 0 ∧ st.returnData.size = 32 ∧
      result.state.memory = st.memory := by
  cases called with
  | error e => cases h
  | ok pair =>
    rcases pair with ⟨flag,st⟩
    by_cases bad : flag = UInt256.ofNat 0 ∨ st.returnData.size ≠ 32
    · simp only [SszBlsComposition.finish,bad,if_true] at h
      cases h
    · simp only [SszBlsComposition.finish,bad,if_false] at h
      cases h
      exact ⟨flag,st,rfl,(not_or.mp bad).1,Classical.not_not.mp (not_or.mp bad).2,rfl⟩

theorem call_preserves_free_pointer_bytes (fuel gasCost : Nat) (source gas : UInt256)
    (st called : EVM.State) (flag : UInt256)
    (hc : SszShaCallMemory.callSha (fuel+2) gasCost source gas st = .ok (flag,called))
    (hn : flag ≠ UInt256.ofNat 0) (hsize : called.returnData.size = 32)
    (hi : (st.memory.readWithPadding 0 64).size = 64) (hmem : 96 ≤ st.memory.size) :
    called.memory.readWithPadding 64 32 = st.memory.readWithPadding 64 32 ∧
    st.memory.size ≤ called.memory.size := by
  have ho := SszShaCommitted.call_success_output fuel gasCost source gas st called flag hi hc hn
  have hout : (SszShaCallMemory.shaOutput (st.memory.readWithPadding 0 64)).size = 32 := ho ▸ hsize
  have hd := SszShaCommitted.call_success_depth fuel gasCost source gas st called flag hc hn
  have hg := SszShaCommitted.call_success_gas fuel gasCost source gas st called flag hi hc hn
  obtain ⟨afterState,ha,_,hm,_⟩ := SszShaCallMemory.call_sha_bytes fuel gasCost source gas st hd hg hi hout
  rw [hc] at ha
  obtain ⟨_,he⟩ := Prod.mk.inj (Except.ok.inj ha)
  subst afterState
  rw [hm,← SszShaCallBytes.write32 _ _ hout]
  exact ⟨read64_write32 _ _ hout hmem,write_size_mono _ _ _ _ _⟩

theorem finished_scratch_call_memory (fuel gasCost : Nat) (source gas : UInt256)
    (original prep : EVM.State) (blockBytes : ByteArray) (result : SszBlsComposition.Result)
    (h : SszBlsComposition.finish (SszShaCallMemory.callSha (fuel+2) gasCost source gas prep) = .ok result)
    (hblock : blockBytes.size = 64)
    (hprep : prep.memory = blockBytes ++ original.memory.extract 64 original.memory.size)
    (hsize : 96 ≤ original.memory.size) :
    result.state.memory.readWithPadding 64 32 = original.memory.readWithPadding 64 32 ∧
    original.memory.size ≤ result.state.memory.size := by
  obtain ⟨flag,called,hc,hn,hlen,hm⟩ := finish_memory _ _ h
  have hps : original.memory.size ≤ prep.memory.size := by rw [hprep];simp [hblock];omega
  have hi : (prep.memory.readWithPadding 0 64).size = 64 := by
    rw [hprep,SszScratchByteArray.read_prefix _ _ hblock]
    exact hblock
  obtain ⟨hr,hs⟩ := call_preserves_free_pointer_bytes fuel gasCost source gas prep called flag
    hc hn hlen hi (by omega)
  rw [hm]
  refine ⟨?_,Nat.le_trans hps hs⟩
  rw [hr,hprep]
  exact read64_after_scratch _ _ hblock hsize

theorem pair_memory (fuel : Nat) (st : EVM.State) (left right : UInt256)
    (result : SszBlsComposition.Result)
    (h : SszBlsComposition.pairRun fuel st left right = .ok result)
    (hsize : 96 ≤ st.memory.size) :
    result.state.memory.readWithPadding 64 32 = st.memory.readWithPadding 64 32 ∧
    st.memory.size ≤ result.state.memory.size := by
  let prep := SszBlsComposition.preparePair st left right
  exact finished_scratch_call_memory fuel
    (Ccall SszShaCallMemory.shaAddress SszShaCallMemory.shaAddress (UInt256.ofNat 0)
      prep.gasAvailable prep.accountMap prep.toMachineState prep.substate)
    (UInt256.ofNat prep.executionEnv.codeOwner.val) prep.gasAvailable st prep
    (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat) result h
    (by simp [fixedBE]) (SszBlsComposition.prepared_memory st left right) hsize

theorem pubkey_memory (fuel : Nat) (st : EVM.State) (offset : UInt256) (length : Nat)
    (result : SszBlsComposition.Result)
    (h : SszBlsComposition.pubkeyRun fuel st offset length = .ok result)
    (hsize : 96 ≤ st.memory.size) :
    result.state.memory.readWithPadding 64 32 = st.memory.readWithPadding 64 32 ∧
    st.memory.size ≤ result.state.memory.size := by
  unfold SszBlsComposition.pubkeyRun at h
  split at h
  · cases h
  · let prep := SszShaCallMemory.prepared st offset
    exact finished_scratch_call_memory fuel
      (Ccall SszShaCallMemory.shaAddress SszShaCallMemory.shaAddress (UInt256.ofNat 0)
        prep.gasAvailable prep.accountMap prep.toMachineState prep.substate)
      (UInt256.ofNat prep.executionEnv.codeOwner.val) prep.gasAvailable st prep
      (SszPubkeyBytes.blockBytes st.executionEnv.calldata offset.toNat) result h
      (SszPubkeyBytes.block_size _ _) (SszPubkeyBytes.memory_exact st.toSharedState offset) hsize

/-- Scratch prefixes preserve every previously stored word at or above 64,
not just the compiler's free-pointer word. -/
theorem read_after_prefix (head old : ByteArray) (n offset : Nat)
    (hlen : head.size = n) (hn : n ≤ offset) (hsize : offset+32 ≤ old.size) :
    (head ++ old.extract n old.size).readWithPadding offset 32 = old.readWithPadding offset 32 := by
  have hnew : offset+32 ≤ (head ++ old.extract n old.size).size := by simp [hlen];omega
  rw [SszShaCallBytes.read_fit _ offset 32 hnew (by omega),
    SszShaCallBytes.read_fit _ offset 32 hsize (by omega)]
  apply ByteArray.ext
  simp only [ByteArray.data_extract,ByteArray.data_append,Array.extract_append,ByteArray.size_data,hlen]
  rw [Array.extract_empty_of_size_le_start (by simpa [hlen] using hn),Array.empty_append]
  simp only [Array.extract_extract]
  have ha : n + (offset-n) = offset := by omega
  have hb : n + (offset+32-n) = offset+32 := by omega
  rw [ha,hb,Nat.min_eq_left hsize]

theorem call_preserves_stored_word (fuel gasCost : Nat) (source gas : UInt256)
    (st called : EVM.State) (flag : UInt256) (offset : Nat)
    (hc : SszShaCallMemory.callSha (fuel+2) gasCost source gas st = .ok (flag,called))
    (hn : flag ≠ UInt256.ofNat 0) (hsize : called.returnData.size = 32)
    (hi : (st.memory.readWithPadding 0 64).size = 64)
    (hoff : 64 ≤ offset) (hmem : offset+32 ≤ st.memory.size) :
    called.memory.readWithPadding offset 32 = st.memory.readWithPadding offset 32 := by
  have ho := SszShaCommitted.call_success_output fuel gasCost source gas st called flag hi hc hn
  have hout : (SszShaCallMemory.shaOutput (st.memory.readWithPadding 0 64)).size = 32 := ho ▸ hsize
  have hd := SszShaCommitted.call_success_depth fuel gasCost source gas st called flag hc hn
  have hg := SszShaCommitted.call_success_gas fuel gasCost source gas st called flag hi hc hn
  obtain ⟨afterState,ha,_,hm,_⟩ := SszShaCallMemory.call_sha_bytes fuel gasCost source gas st hd hg hi hout
  rw [hc] at ha
  obtain ⟨_,he⟩ := Prod.mk.inj (Except.ok.inj ha)
  subst afterState
  rw [hm]
  exact read_after_prefix _ _ 32 offset hout (by omega) hmem

theorem finished_scratch_stored_word (fuel gasCost : Nat) (source gas : UInt256)
    (original prep : EVM.State) (blockBytes : ByteArray) (result : SszBlsComposition.Result)
    (offset : Nat)
    (h : SszBlsComposition.finish (SszShaCallMemory.callSha (fuel+2) gasCost source gas prep) = .ok result)
    (hblock : blockBytes.size = 64)
    (hprep : prep.memory = blockBytes ++ original.memory.extract 64 original.memory.size)
    (hoff : 64 ≤ offset) (hsize : offset+32 ≤ original.memory.size) :
    result.state.memory.readWithPadding offset 32 = original.memory.readWithPadding offset 32 := by
  obtain ⟨flag,called,hc,hn,hlen,hm⟩ := finish_memory _ _ h
  have hps : original.memory.size ≤ prep.memory.size := by rw [hprep];simp [hblock];omega
  have hi : (prep.memory.readWithPadding 0 64).size = 64 := by
    rw [hprep,SszScratchByteArray.read_prefix _ _ hblock]
    exact hblock
  rw [hm,call_preserves_stored_word fuel gasCost source gas prep called flag offset hc hn hlen hi hoff (by omega),hprep]
  exact read_after_prefix _ _ 64 offset hblock hoff hsize

theorem pair_stored_word (fuel : Nat) (st : EVM.State) (left right : UInt256)
    (result : SszBlsComposition.Result) (offset : Nat)
    (h : SszBlsComposition.pairRun fuel st left right = .ok result)
    (hoff : 64 ≤ offset) (hsize : offset+32 ≤ st.memory.size) :
    result.state.memory.readWithPadding offset 32 = st.memory.readWithPadding offset 32 := by
  let prep := SszBlsComposition.preparePair st left right
  exact finished_scratch_stored_word fuel
    (Ccall SszShaCallMemory.shaAddress SszShaCallMemory.shaAddress (UInt256.ofNat 0)
      prep.gasAvailable prep.accountMap prep.toMachineState prep.substate)
    (UInt256.ofNat prep.executionEnv.codeOwner.val) prep.gasAvailable st prep
    (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat) result offset h
    (by simp [fixedBE]) (SszBlsComposition.prepared_memory st left right) hoff hsize

/-- Exactly the fresh machine initialization used by EVM.Ξ, retaining the
execution context fields that Ξ receives and resetting pc, stack and memory. -/
def fresh (context : EVM.State) : EVM.State :=
  { (default : EVM.State) with
    accountMap := context.accountMap
    σ₀ := context.σ₀
    executionEnv := context.executionEnv
    substate := context.substate
    createdAccounts := context.createdAccounts
    gasAvailable := context.gasAvailable
    blocks := context.blocks
    genesisBlockHeader := context.genesisBlockHeader }

/-- The initializer above is definitionally the state consumed by the pinned
engine's real code-execution entry, not an independently supplied memory. -/
theorem xi_uses_fresh (fuel : Nat) (context : EVM.State) :
    Ξ (fuel+1) context.createdAccounts context.genesisBlockHeader context.blocks
      context.accountMap context.σ₀ context.gasAvailable context.substate context.executionEnv =
    (do
      let result ← X fuel (D_J context.executionEnv.code (UInt256.ofNat 0)) (fresh context)
      match result with
      | .success afterState output =>
        pure (.success (afterState.createdAccounts,afterState.accountMap,
          afterState.gasAvailable,afterState.substate) output)
      | .revert gas output => pure (.revert gas output)) := by
  rfl

def store (st : EVM.State) (offset : Nat) (word : UInt256) : EVM.State :=
  {st with toSharedState := {st.toSharedState with
    toMachineState := st.toMachineState.mstore (UInt256.ofNat offset) word}}

def load (st : EVM.State) (offset : Nat) : UInt256 × EVM.State :=
  let result := st.toMachineState.mload (UInt256.ofNat offset)
  (result.1, {st with toSharedState := {st.toSharedState with toMachineState := result.2}})

theorem store_memory_size_mono (st : EVM.State) (offset : Nat) (word : UInt256) :
    st.memory.size ≤ (store st offset word).memory.size := by
  change st.memory.size ≤ (word.toByteArray.write 0 st.memory (UInt256.ofNat offset).toNat 32).size
  exact write_size_mono _ _ _ _ _

theorem store_read_before (st : EVM.State) (dest offset : Nat) (word : UInt256)
    (hd : dest ≤ 576) (ho : offset+32 ≤ dest) (hs : offset+32 ≤ st.memory.size) :
    (store st dest word).memory.readWithPadding offset 32 = st.memory.readWithPadding offset 32 := by
  have hn : (UInt256.ofNat dest).toNat = dest := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  have hsz := store_memory_size_mono st dest word
  rw [SszShaCallBytes.read_fit _ offset 32 (by omega) (by omega),
    SszShaCallBytes.read_fit _ offset 32 hs (by omega)]
  change (word.toByteArray.write 0 st.memory (UInt256.ofNat dest).toNat 32).extract offset (offset+32) = _
  rw [hn]
  exact write_preserves_before _ _ _ _ _ _ _ ho hs

theorem store_read_after (st : EVM.State) (dest offset : Nat) (word : UInt256)
    (hd : dest ≤ 576) (ho : dest+32 ≤ offset) (hs : offset+32 ≤ st.memory.size) :
    (store st dest word).memory.readWithPadding offset 32 = st.memory.readWithPadding offset 32 := by
  have hn : (UInt256.ofNat dest).toNat = dest := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  have hp : (st.memory.extract 0 dest ++ word.toByteArray).size = dest+32 := by
    simp only [ByteArray.size_append,ByteArray.size_extract,actual_word_size]
    omega
  have hm : (store st dest word).memory =
      (st.memory.extract 0 dest ++ word.toByteArray) ++ st.memory.extract (dest+32) st.memory.size := by
    apply ByteArray.ext
    change (word.toByteArray.write 0 st.memory (UInt256.ofNat dest).toNat 32).data = _
    rw [hn,write_word_shape _ _ _ hd]
    have hz : dest-st.memory.size = 0 := by omega
    simp only [hz,Array.replicate_zero,Array.append_empty,ByteArray.data_append,ByteArray.data_extract]
  rw [hm]
  exact read_after_prefix _ _ (dest+32) offset hp ho hs

/-- The runtime's actual first memory write, mstore(64,128). -/
def prologue (context : EVM.State) : EVM.State :=
  store (fresh context) 64 (UInt256.ofNat 128)

theorem fresh_words (context : EVM.State) : (fresh context).activeWords.toNat = 0 := rfl

theorem prologue_words (context : EVM.State) : (prologue context).activeWords.toNat = 3 := by
  change ((fresh context).toMachineState.mstore (UInt256.ofNat 64) (UInt256.ofNat 128)).activeWords.toNat = 3
  rw [store_words _ _ _ (by omega),fresh_words]
  decide +kernel

theorem prologue_free_pointer (context : EVM.State) :
    (load (prologue context) 64).1 = UInt256.ofNat 128 := by
  exact store_load (fresh context).toMachineState 64 (UInt256.ofNat 128) (by omega) (by rw [fresh_words];omega)

theorem prologue_environment (context : EVM.State) :
    (prologue context).executionEnv = context.executionEnv := rfl

inductive AllocationError where
  | panic41
  deriving DecidableEq, Repr

/-- Compiler allocator in the inspected viaIR runtime: load the free pointer,
check uint64 bound and uint256 addition wrap, store it, and clear with actual
calldatacopy from calldatasize. Allocation size is a compiler constant. -/
def allocate (st : EVM.State) (bytes : Nat) : Except AllocationError (UInt256 × EVM.State) := do
  let (ptr,readState) := load st 64
  let next := ptr + UInt256.ofNat bytes
  if next.toNat > 2^64-1 ∨ next < ptr then throw .panic41
  let written := store readState 64 next
  let cleared := written.toSharedState.calldatacopy ptr
    (UInt256.ofNat written.executionEnv.calldata.size) (UInt256.ofNat bytes)
  pure (ptr,{written with toSharedState := cleared})

theorem allocate_success_bound (st afterState : EVM.State) (bytes : Nat) (ptr : UInt256)
    (h : allocate st bytes = .ok (ptr,afterState)) :
    ptr = (load st 64).1 ∧
    (ptr + UInt256.ofNat bytes).toNat ≤ 2^64-1 ∧
    ¬ ptr + UInt256.ofNat bytes < ptr := by
  unfold allocate at h
  dsimp only at h
  split at h
  · cases h
  · rename_i hg
    cases h
    exact ⟨rfl,by omega,by tauto⟩

theorem allocate_effects (st : EVM.State) (ptr bytes : Nat)
    (hfree : (load st 64).1 = UInt256.ofNat ptr)
    (hptr : 96 ≤ ptr) (hbytes : 0 < bytes) (hbound : ptr+bytes ≤ 576)
    (hwords : 3 ≤ st.activeWords.toNat) (hwidth : st.activeWords.toNat < 2^251) :
    ∃ afterState,
      allocate st bytes = .ok (UInt256.ofNat ptr,afterState) ∧
      (load afterState 64).1 = UInt256.ofNat (ptr+bytes) ∧
      afterState.activeWords.toNat = max st.activeWords.toNat ((ptr+bytes+31)/32) ∧
      afterState.executionEnv = st.executionEnv ∧ 96 ≤ afterState.memory.size ∧
      afterState.memory.readWithPadding 64 32 = (UInt256.ofNat (ptr+bytes)).toByteArray := by
  let readState := (load st 64).2
  let written := store readState 64 (UInt256.ofNat (ptr+bytes))
  let cleared := written.toSharedState.calldatacopy
    (UInt256.ofNat ptr) (UInt256.ofNat written.executionEnv.calldata.size) (UInt256.ofNat bytes)
  let afterState : EVM.State := {written with toSharedState := cleared}
  have hp : (UInt256.ofNat ptr).toNat = ptr := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  have hb : (UInt256.ofNat bytes).toNat = bytes := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  have hnext : UInt256.ofNat ptr + UInt256.ofNat bytes = UInt256.ofNat (ptr+bytes) := by
    apply congrArg UInt256.mk
    apply Fin.ext
    change (ptr % UInt256.size + bytes % UInt256.size) % UInt256.size = (ptr+bytes) % UInt256.size
    rw [Nat.mod_eq_of_lt (show ptr < UInt256.size by unfold UInt256.size;omega),
      Nat.mod_eq_of_lt (show bytes < UInt256.size by unfold UInt256.size;omega)]
  have hn : (UInt256.ofNat (ptr+bytes)).toNat = ptr+bytes := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  have hrw : readState.activeWords.toNat = st.activeWords.toNat := by
    rw [show readState.activeWords.toNat = max st.activeWords.toNat ((64+63)/32) from load_words _ 64 (by omega)]
    omega
  have hww : written.activeWords.toNat = st.activeWords.toNat := by
    rw [show written.activeWords.toNat = max readState.activeWords.toNat ((64+63)/32) from store_words _ 64 _ (by omega),hrw]
    omega
  have haw : afterState.activeWords.toNat = max st.activeWords.toNat ((ptr+bytes+31)/32) := by
    change (MachineState.M written.activeWords.toNat (UInt256.ofNat ptr).toNat (UInt256.ofNat bytes).toNat) % UInt256.size = _
    rw [hp,hb]
    have hm : MachineState.M written.activeWords.toNat ptr bytes =
        max written.activeWords.toNat ((ptr+bytes+31)/32) := by
      cases bytes with
      | zero => omega
      | succ n => rfl
    rw [hm,hww]
    rw [Nat.mod_eq_of_lt]
    have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    unfold UInt256.size at *
    omega
  have hsz : 96 ≤ written.memory.size := store_size _ 64 _ (by omega)
  have hasz : 96 ≤ afterState.memory.size := by
    exact Nat.le_trans hsz (write_size_mono _ _ _ _ _)
  have hr : afterState.memory.readWithPadding 64 32 = (UInt256.ofNat (ptr+bytes)).toByteArray := by
    rw [SszShaCallBytes.read_fit _ 64 32 hasz (by omega)]
    change (written.executionEnv.calldata.write _ written.memory (UInt256.ofNat ptr).toNat _).extract 64 96 = _
    rw [hp,write_preserves_before _ _ _ _ _ _ _ hptr hsz]
    rw [← SszShaCallBytes.read_fit _ 64 32 hsz (by omega)]
    exact write_word_read _ 64 _ (by omega)
  refine ⟨afterState,?_,?_,haw,rfl,hasz,hr⟩
  · unfold allocate
    dsimp only
    rw [hfree,hnext]
    rw [if_neg (by
      change ¬ ((UInt256.ofNat (ptr+bytes)).toNat > 2^64-1 ∨
        (UInt256.ofNat (ptr+bytes)).toNat < (UInt256.ofNat ptr).toNat)
      rw [hn,hp]
      omega)]
    rfl
  · exact mload_of_read _ 64 _ (by omega) hasz hr (by rw [haw];omega) (by rw [haw];omega)

#print axioms write_word_read
#print axioms store_load
#print axioms xi_uses_fresh
#print axioms prologue_free_pointer
#print axioms allocate_success_bound
#print axioms allocate_effects
#print axioms pair_memory
#print axioms pubkey_memory
end LidoSRv3.Audit.Source.SszCompiledMemory
