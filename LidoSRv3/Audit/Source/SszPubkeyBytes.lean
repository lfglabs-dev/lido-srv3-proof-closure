import LidoSRv3.Audit.Source.SszShaCommitted

namespace LidoSRv3.Audit.Source.SszPubkeyBytes
open EvmYul EvmYul.EVM SszScratchByteArray SszScratchEvmMemory

/-- Independent zero-extended 48-byte calldata view. No extent assumption. -/
def keyBytes (raw : ByteArray) (offset : Nat) : ByteArray :=
  ⟨raw.data.extract offset (offset+48) ++
    Array.replicate (48 - min 48 (raw.size-offset)) 0⟩

def blockBytes (raw : ByteArray) (offset : Nat) : ByteArray :=
  keyBytes raw offset ++ zeros 16

theorem key_size (raw : ByteArray) (offset : Nat) : (keyBytes raw offset).size = 48 := by
  simp only [keyBytes,ByteArray.size,Array.size_append,Array.size_extract,Array.size_replicate]
  change min (offset+48) raw.size - offset + (48 - min 48 (raw.size-offset)) = 48
  omega

theorem block_size (raw : ByteArray) (offset : Nat) : (blockBytes raw offset).size = 64 := by
  simp [blockBytes,key_size]

/-- The existing copy operates on the actual cleared scratch shape, including
short or entirely absent calldata. -/
theorem copy_padded (raw : ByteArray) (offset : Nat) (lower tail : Array UInt8)
    (hlower : lower.size = 32) :
    (raw.write offset ⟨lower ++ Array.replicate 32 0 ++ tail⟩ 0 48).data =
      (keyBytes raw offset).data ++ Array.replicate 16 0 ++ tail := by
  by_cases ho : offset ≥ raw.size
  · unfold ByteArray.write
    simp only [show ¬ (48:Nat)=0 by omega,if_false,ho,if_true]
    have hlen : min 48 ((⟨lower ++ Array.replicate 32 0 ++ tail⟩ : ByteArray).size - 0) = 48 := by
      simp only [ByteArray.size,Array.size_append,Array.size_replicate,hlower,Nat.sub_zero,Nat.zero_add]
      omega
    rw [hlen,ffi_zeros 48 (by omega)]
    simp only [Nat.zero_min,ByteArray.data_copySlice]
    simp [zeros,keyBytes,hlower,Array.extract_append,Array.extract_replicate,
      show raw.size - offset = 0 by omega,
      Array.extract_empty_of_size_le_start ho,
      Array.extract_empty_of_stop_le_start (by omega : 32 ≤ 48)]
    simp only [← Array.append_assoc,Array.replicate_append_replicate]
  · unfold ByteArray.write
    simp only [show ¬ (48:Nat)=0 by omega,if_false,ho]
    have he : min (⟨lower ++ Array.replicate 32 0 ++ tail⟩ : ByteArray).size (0+48) = 48 := by
      simp only [ByteArray.size,Array.size_append,Array.size_replicate,hlower,Nat.sub_zero,Nat.zero_add]
      omega
    rw [he,ffi_zeros (48 - (0 + min 48 (raw.size-offset))) (by omega),
      ffi_zeros (0 - (⟨lower ++ Array.replicate 32 0 ++ tail⟩ : ByteArray).size) (by omega)]
    simp only [Nat.zero_add,Nat.zero_sub,append_zeros_zero]
    rw [ByteArray.data_copySlice]
    have hc : min 48 (raw.size + (48 - min 48 (raw.size-offset)) - offset) = 48 := by omega
    have hp : min (offset+48-raw.size) (48-min 48 (raw.size-offset)) - (offset-raw.size) =
        48-min 48 (raw.size-offset) := by omega
    simp [zeros,keyBytes,hlower,Array.extract_append,Array.extract_replicate,hc,hp,
      Array.extract_empty_of_stop_le_start (by omega : 32 ≤ 48)]
    simp only [← Array.append_assoc,Array.replicate_append_replicate]

/-- Complete scratch memory follows from the actual clear and copy operations;
dirty upper memory is retained and short calldata is explicitly zero-extended. -/
theorem memory_exact {τ : OperationType} (st : SharedState τ) (offset : UInt256) :
    (scratch st offset).memory = blockBytes st.executionEnv.calldata offset.toNat ++
      st.memory.extract 64 st.memory.size := by
  apply ByteArray.ext
  change (st.executionEnv.calldata.write offset.toNat
    ((UInt256.ofNat 0).toByteArray.write 0 st.memory 32 32) 0 48).data = _
  rw [word_zero]
  have hc : (zeros 32).write 0 st.memory 32 32 =
      ⟨(st.memory.data.extract 0 32 ++ Array.replicate (32-st.memory.size) 0) ++
        Array.replicate 32 0 ++ st.memory.data.extract 64 st.memory.size⟩ := by
    apply ByteArray.ext
    exact clear_shape st.memory
  rw [hc,copy_padded _ _ _ _ (lower_size st.memory)]
  simp only [blockBytes,ByteArray.data_append,ByteArray.data_extract,zeros]

theorem read_exact {τ : OperationType} (st : SharedState τ) (offset : UInt256) :
    (scratch st offset).memory.readWithPadding 0 64 =
      blockBytes st.executionEnv.calldata offset.toNat := by
  rw [memory_exact]
  exact read_prefix _ _ (block_size _ _)

/-- When the raw key fits, this universal view agrees with the previously
accepted unpadded slice; that earlier result is reused, not redefined. -/
theorem block_eq_raw (raw : ByteArray) (offset : Nat) (hfit : offset+48 ≤ raw.size) :
    blockBytes raw offset = rawBlock raw offset := by
  simp only [blockBytes,keyBytes,rawBlock]
  have hp : 48-min 48 (raw.size-offset) = 0 := by omega
  rw [hp]
  apply ByteArray.ext
  simp only [ByteArray.data_append,ByteArray.data_extract,Array.replicate_zero,Array.append_empty]

private theorem finish_success (called : Except EVM.ExecutionException (UInt256 × EVM.State))
    (result : SszBlsComposition.Result) (h : SszBlsComposition.finish called = .ok result) :
    ∃ flag st, called = .ok (flag,st) ∧ flag ≠ UInt256.ofNat 0 ∧ st.returnData.size = 32 ∧
      result.state.returnData = st.returnData ∧
      result.digest = (st.toMachineState.mload (UInt256.ofNat 0)).1 ∧
      result.state.activeWords = (st.toMachineState.mload (UInt256.ofNat 0)).2.activeWords := by
  cases called with
  | error e => cases h
  | ok pair =>
    rcases pair with ⟨flag,st⟩
    by_cases bad : flag = UInt256.ofNat 0 ∨ st.returnData.size ≠ 32
    · simp only [SszBlsComposition.finish,bad,if_true] at h
      cases h
    · simp only [SszBlsComposition.finish,bad,if_false] at h
      cases h
      exact ⟨flag,st,rfl,(not_or.mp bad).1,Classical.not_not.mp (not_or.mp bad).2,rfl,rfl,rfl⟩

/-- Digest specification from the independent zero-extended key octets. -/
def pubkeyDigest (st : EVM.State) (offset : UInt256) : UInt256 :=
  UInt256.ofNat (fromByteArrayBigEndian
    (SszShaCallMemory.shaOutput (blockBytes st.executionEnv.calldata offset.toNat)))

/-- Necessary value of the actual key call. Its own successful guard derives
length, depth, precompile gas and opaque SHA size; scratch layout is proved for
all calldata offsets, without a new calldata-extent admission. -/
theorem pubkey_success_digest (fuel : Nat) (st : EVM.State) (offset : UInt256)
    (length : Nat) (result : SszBlsComposition.Result)
    (h : SszBlsComposition.pubkeyRun fuel st offset length = .ok result)
    (hwidth : st.activeWords.toNat < 2^251) :
    result.digest = pubkeyDigest st offset ∧
    result.state.returnData = SszShaCallMemory.shaOutput
      (blockBytes st.executionEnv.calldata offset.toNat) ∧ length = 48 := by
  unfold SszBlsComposition.pubkeyRun at h
  split at h
  · cases h
  · rename_i hlen
    have hlength : length = 48 := by omega
    obtain ⟨flag,called,hc,hn,hlen,he,hdigest,_⟩ := finish_success _ _ h
    let prep := SszShaCallMemory.prepared st offset
    let charge := Ccall SszShaCallMemory.shaAddress SszShaCallMemory.shaAddress (UInt256.ofNat 0)
      prep.gasAvailable prep.accountMap prep.toMachineState prep.substate
    let source := UInt256.ofNat prep.executionEnv.codeOwner.val
    have hr : (prep.memory.readWithPadding 0 64) = blockBytes st.executionEnv.calldata offset.toNat :=
      read_exact st.toSharedState offset
    have hi : (prep.memory.readWithPadding 0 64).size = 64 := by rw [hr]; exact block_size _ _
    have ho := SszShaCommitted.call_success_output fuel charge source prep.gasAvailable prep called flag hi hc hn
    have hd := SszShaCommitted.call_success_depth fuel charge source prep.gasAvailable prep called flag hc hn
    have hg := SszShaCommitted.call_success_gas fuel charge source prep.gasAvailable prep called flag hi hc hn
    have hout : (SszShaCallMemory.shaOutput (prep.memory.readWithPadding 0 64)).size = 32 := ho ▸ hlen
    obtain ⟨afterState,ha,_,hm,hw⟩ := SszShaCallMemory.call_sha_bytes fuel charge source prep.gasAvailable
      prep hd hg hi hout
    change SszShaCallMemory.callSha (fuel+2) charge source prep.gasAvailable prep = .ok (flag,called) at hc
    rw [hc] at ha
    obtain ⟨_,heq⟩ := Prod.mk.inj (Except.ok.inj ha)
    subst afterState
    have hwords : called.activeWords.toNat = max st.activeWords.toNat 2 := by
      rw [hw,SszShaCallMemory.prepared_words]
      have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
      change max (max st.activeWords.toNat 2) 2 % UInt256.size = _
      rw [max_eq_left (by omega),Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)]
    have hv := SszShaCallBytes.mload32 called.toMachineState _ _ hm hout
      (by rw [hwords]; omega) (by rw [hwords]; omega)
    rw [hr] at hv ho
    exact ⟨hdigest.trans hv,he.trans ho,hlength⟩

/-- Typed witness from the same zero-extended calldata key and decoded fields. -/
def witnessAt (st : EVM.State) (offset : UInt256) (f : SszBlsComposition.Fields) :
    SszValidatorLeaf.Witness :=
  {pubkey := typedBytes (keyBytes st.executionEnv.calldata offset.toNat),
    effectiveBalance := f.effectiveBalance, slashed := f.slashed,
    activationEligibilityEpoch := f.activationEligibilityEpoch,
    activationEpoch := f.activationEpoch, exitEpoch := f.exitEpoch,
    withdrawableEpoch := f.withdrawableEpoch}

theorem witness_key_length (st : EVM.State) (offset : UInt256) (f : SszBlsComposition.Fields) :
    (witnessAt st offset f).pubkey.length = 48 := by
  simp only [witnessAt,typedBytes,List.length_map,Array.length_toList]
  exact key_size _ _

theorem pubkey_digest_typed (st : EVM.State) (offset : UInt256) (f : SszBlsComposition.Fields) :
    pubkeyDigest st offset = SszTypedFfiBridge.toWord (SszTypedFfiBridge.ffiSha
      (SszValidatorLeaf.pubkeyBlock (witnessAt st offset f).pubkey)) := by
  have hb : SszTypedFfiBridge.bytes (SszValidatorLeaf.pubkeyBlock (witnessAt st offset f).pubkey) =
      blockBytes st.executionEnv.calldata offset.toNat := by
    simp only [witnessAt,SszValidatorLeaf.pubkeyBlock,SszTypedFfiBridge.bytes_append,
      SszBlsComposition.bytes_typed]
    rfl
  simp only [SszTypedFfiBridge.ffiSha,hb,SszTypedFfiBridge.word_digest]
  rfl

theorem computed_leaf_typed (st : EVM.State) (offset wc : UInt256) (f : SszBlsComposition.Fields) :
    SszBlsComposition.merkleDigest (pubkeyDigest st offset) wc
      (SszBlsComposition.chunk f.effectiveBalance) (SszBlsComposition.chunk (if f.slashed then 1 else 0))
      (SszBlsComposition.chunk f.activationEligibilityEpoch) (SszBlsComposition.chunk f.activationEpoch)
      (SszBlsComposition.chunk f.exitEpoch) (SszBlsComposition.chunk f.withdrawableEpoch) =
    SszTypedFfiBridge.toWord (SszWrapperIndex.treeDigest (SszValidatorLeaf.pair SszTypedFfiBridge.ffiSha)
      (SszValidatorLeaf.validatorTree SszTypedFfiBridge.ffiSha (witnessAt st offset f) (SszTypedFfiBridge.toDigest wc))) := by
  rw [pubkey_digest_typed st offset f]
  change SszBlsComposition.merkleDigest _ (SszTypedFfiBridge.toWord (SszTypedFfiBridge.toDigest wc)) _ _ _ _ _ _ = _
  unfold SszBlsComposition.chunk
  rw [SszBlsComposition.merkle_digest_typed]
  simp only [SszValidatorLeaf.validatorTree,SszWrapperIndex.treeDigest,
    SszLittleEndianCorrespondence.source_uint64_chunk]
  cases hs : f.slashed <;> simp only [witnessAt,hs,Bool.false_eq_true,↓reduceIte]
  all_goals rfl

/-- The existing raw consumer passes the leaf computed from independent
zero-extended pubkey bytes and original decoded fields into the actual proof
verifier on the same returned state. No calldata-extent, per-call resource or
opaque output-size premise is added; initial memory reachability stays open. -/
theorem run_success_computed_leaf (fuel : Nat) (st afterState : EVM.State)
    (h : SszWitnessAbi.run fuel st = .ok afterState)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ offset keySlice key f leaf branch,
      SszWitnessAbi.header st = .ok offset ∧
      SszWitnessAbi.tail st offset (SszWitnessAbi.abiWord 36) 1 = .ok keySlice ∧
      SszBlsComposition.pubkeyRun fuel st keySlice.offset keySlice.length = .ok key ∧
      key.digest = pubkeyDigest st keySlice.offset ∧
      key.state.executionEnv = st.executionEnv ∧
      SszWitnessAbi.FieldsMatch st offset f ∧
      SszBlsComposition.merkleRun fuel key.state (pubkeyDigest st keySlice.offset) (st.calldataload (SszWitnessAbi.abiWord 36))
        (SszBlsComposition.chunk f.effectiveBalance) (SszBlsComposition.chunk (if f.slashed then 1 else 0))
        (SszBlsComposition.chunk f.activationEligibilityEpoch) (SszBlsComposition.chunk f.activationEpoch)
        (SszBlsComposition.chunk f.exitEpoch) (SszBlsComposition.chunk f.withdrawableEpoch) = .ok leaf ∧
      leaf.state.executionEnv = st.executionEnv ∧
      leaf.state.activeWords.toNat = max st.activeWords.toNat 2 ∧
      SszWitnessAbi.tail st offset (SszWitnessAbi.abiWord 4) 32 = .ok branch ∧
      SszProofCalldataLoop.verify fuel leaf.state
        (st.calldataload (SszWitnessAbi.abiWord 100))
        (SszTypedFfiBridge.toWord (SszWrapperIndex.treeDigest
          (SszValidatorLeaf.pair SszTypedFfiBridge.ffiSha)
          (SszValidatorLeaf.validatorTree SszTypedFfiBridge.ffiSha (witnessAt st keySlice.offset f)
            (SszTypedFfiBridge.toDigest (st.calldataload (SszWitnessAbi.abiWord 36))))))
        (st.calldataload (SszWitnessAbi.abiWord 68)) branch.offset branch.length = .ok afterState ∧
      keySlice.length = 48 ∧ branch.length ≤ 2^64-1 := by
  obtain ⟨offset,keySlice,key,f,leaf,branch,ho,hks,hk,he,fm,hl,hle,hw,hp,hv,hkl,hpl⟩ :=
    SszShaCommitted.run_success_computed_merkle fuel st afterState h hwidth
  have hd := pubkey_success_digest fuel st keySlice.offset keySlice.length key hk hwidth
  rw [hd.1] at hl hv
  rw [computed_leaf_typed] at hv
  exact ⟨offset,keySlice,key,f,leaf,branch,ho,hks,hk,hd.1,he,fm,hl,hle,hw,hp,hv,hkl,hpl⟩

#print axioms key_size
#print axioms block_size
#print axioms block_eq_raw
#print axioms pubkey_digest_typed
#print axioms computed_leaf_typed
#print axioms witness_key_length
#print axioms run_success_computed_leaf
#print axioms pubkey_success_digest
#print axioms memory_exact
#print axioms read_exact
#print axioms copy_padded
end LidoSRv3.Audit.Source.SszPubkeyBytes
