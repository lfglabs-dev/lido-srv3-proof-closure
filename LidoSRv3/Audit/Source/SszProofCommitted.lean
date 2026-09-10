import LidoSRv3.Audit.Source.SszPubkeyBytes

/-! Necessary effects of the existing proof loop. The sibling is the word
actually read by the source transition, including padded/wrapping offsets.
No independent calldata layout, resource budget or caller depth is supplied.
-/
namespace LidoSRv3.Audit.Source.SszProofCommitted
open EvmYul EvmYul.EVM SszWordBytes SszProofCalldataStep SszShaCallMemory

theorem prepared_memory (st : EVM.State) (index leaf offset : UInt256) :
    (preparedStep st index leaf offset).memory =
      pairInput index leaf (st.calldataload offset) ++ st.memory.extract 64 st.memory.size := by
  by_cases he : index.toNat % 2 = 0
  · have ha := scratch_even index he
    have hx : UInt256.ofNat 0 ^^^ UInt256.ofNat 32 = UInt256.ofNat 32 := by decide +kernel
    unfold preparedStep
    dsimp only
    rw [ha, hx]
    change (st.calldataload offset).toByteArray.write 0
      (leaf.toByteArray.write 0 st.memory 0 32) 32 32 = _
    rw [writes_left _ _ _ (actual_word_size leaf) (actual_word_size (st.calldataload offset))]
    simp [pairInput, he, actual_word_bytes]
  · have ha := scratch_odd index (by omega)
    have hx : UInt256.ofNat 32 ^^^ UInt256.ofNat 32 = UInt256.ofNat 0 := by decide +kernel
    unfold preparedStep
    dsimp only
    rw [ha, hx]
    change (st.calldataload offset).toByteArray.write 0
      (leaf.toByteArray.write 0 st.memory 32 32) 0 32 = _
    rw [writes_right _ _ _ (actual_word_size (st.calldataload offset)) (actual_word_size leaf)]
    simp [pairInput, he, actual_word_bytes]

theorem prepared_read (st : EVM.State) (index leaf offset : UInt256) :
    (preparedStep st index leaf offset).memory.readWithPadding 0 64 =
      pairInput index leaf (st.calldataload offset) := by
  rw [prepared_memory]
  exact SszScratchByteArray.read_prefix _ _ (pair_size _ _ _)

theorem step_call_digest (fuel : Nat) (st called : EVM.State)
    (index leaf offset flag : UInt256)
    (hc : stepCall fuel st index leaf offset = .ok (flag,called))
    (hn : flag ≠ UInt256.ofNat 0)
    (hout : (shaOutput (pairInput index leaf (st.calldataload offset))).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    (called.toMachineState.mload (UInt256.ofNat 0)).1 =
      UInt256.ofNat (fromByteArrayBigEndian (shaOutput (pairInput index leaf (st.calldataload offset)))) ∧
    called.activeWords.toNat = max st.activeWords.toNat 2 ∧
    called.executionEnv = st.executionEnv := by
  let prep := preparedStep st index leaf offset
  let charge := Ccall shaAddress shaAddress (UInt256.ofNat 0) prep.gasAvailable
    prep.accountMap prep.toMachineState prep.substate
  let source := UInt256.ofNat prep.executionEnv.codeOwner.val
  change callSha (fuel+2) charge source prep.gasAvailable prep = .ok (flag,called) at hc
  have hi : (prep.memory.readWithPadding 0 64).size = 64 := by
    rw [prepared_read]; exact pair_size _ _ _
  have hd := SszShaCommitted.call_success_depth fuel charge source prep.gasAvailable prep called flag hc hn
  have hg := SszShaCommitted.call_success_gas fuel charge source prep.gasAvailable prep called flag hi hc hn
  have hs : (shaOutput (prep.memory.readWithPadding 0 64)).size = 32 := by
    rw [prepared_read]; exact hout
  obtain ⟨afterState,ha,hr,hm,hw⟩ := call_sha_bytes fuel charge source prep.gasAvailable prep hd hg hi hs
  rw [hc] at ha
  obtain ⟨_,he⟩ := Prod.mk.inj (Except.ok.inj ha)
  subst afterState
  have hwords : called.activeWords.toNat = max st.activeWords.toNat 2 := by
    rw [hw,SszProofCalldataStep.prepared_words]
    have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    change max (max st.activeWords.toNat 2) 2 % UInt256.size = _
    rw [max_eq_left (by omega),Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)]
  have hv := SszShaCallBytes.mload32 called.toMachineState _ _ hm hs
    (by rw [hwords]; omega) (by rw [hwords]; omega)
  rw [prepared_read] at hv
  have he := SszWitnessAbi.call_environment fuel charge source prep.gasAvailable prep called flag hc
  exact ⟨hv,hwords,he⟩

theorem step_success_shape (fuel : Nat) (st : EVM.State)
    (index leaf offset ending : UInt256) (result : StepResult)
    (h : sourceStep fuel st index leaf offset ending = .ok result) :
    ∃ flag called, stepCall fuel st index leaf offset = .ok (flag,called) ∧
      flag ≠ UInt256.ofNat 0 ∧ 1 < index.toNat ∧
      result = {
        state := {called with toSharedState := {called.toSharedState with
          toMachineState := (called.toMachineState.mload (UInt256.ofNat 0)).2}}
        index := parentIndex index
        leaf := (called.toMachineState.mload (UInt256.ofNat 0)).1
        offset := offset + UInt256.ofNat 32
        continues := decide (offset + UInt256.ofNat 32 < ending)} := by
  by_cases hp : parentIndex index = UInt256.ofNat 0
  · simp only [sourceStep,hp,if_true] at h
    cases h
  · simp only [sourceStep,hp,if_false] at h
    cases hc : stepCall fuel st index leaf offset with
    | error e => simp only [hc] at h; cases h
    | ok p =>
      rcases p with ⟨flag,called⟩
      simp only [hc] at h
      by_cases hn : flag = UInt256.ofNat 0
      · simp only [hn,if_true] at h
        cases h
      · simp only [hn,if_false] at h
        have hi : 1 < index.toNat := by
          by_contra bad
          apply hp
          apply SszProofCalldataLoop.word_ext
          rw [parent_nat]
          change index.toNat / 2 = 0
          omega
        cases h
        exact ⟨flag,called,rfl,hn,hi,rfl⟩

/-- Reuse the previously explicit SHA-width boundary. SSZ checks only the
success flag; it cannot derive BLS's independent returndata-size guard. -/
abbrev ShaWidth : Prop := ∀ left right : UInt256,
  (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)).size = 32

theorem step_success_effects (fuel : Nat) (st : EVM.State)
    (index leaf offset ending : UInt256) (result : StepResult)
    (h : sourceStep fuel st index leaf offset ending = .ok result)
    (hffi : ShaWidth) (hwidth : st.activeWords.toNat < 2^251) :
    SszProofFold.sourceFold ffiPair index.toNat leaf [st.calldataload offset] =
      .ok (result.index.toNat,result.leaf) ∧
    result.state.executionEnv = st.executionEnv ∧
    result.state.activeWords.toNat = max st.activeWords.toNat 2 ∧
    result.offset = offset + UInt256.ofNat 32 ∧
    result.continues = decide (offset + UInt256.ofNat 32 < ending) := by
  obtain ⟨flag,called,hc,hn,hi,rfl⟩ := step_success_shape fuel st index leaf offset ending result h
  have hout : (shaOutput (pairInput index leaf (st.calldataload offset))).size = 32 := by
    unfold pairInput
    split <;> apply hffi
  obtain ⟨hv,hw,he⟩ := step_call_digest fuel st called index leaf offset flag hc hn hout hwidth
  refine ⟨?_,he,?_,rfl,rfl⟩
  · dsimp only
    rw [parent_nat,hv]
    exact typed_one_step index leaf (st.calldataload offset) hi
  · simp only [MachineState.mload,MachineState.M]
    change max called.activeWords.toNat 1 % UInt256.size = _
    rw [hw,max_eq_left (by omega),Nat.mod_eq_of_lt]
    have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    unfold UInt256.size at *
    omega

/-- Independent calldata word view, using the pinned engine's zero-padded
byte decoder. The uint256 cursor retains source wrap and termination behavior. -/
def rawWord (raw : ByteArray) (offset : UInt256) : UInt256 :=
  uInt256OfByteArray (raw.readBytes offset.toNat 32)

def proofWords : Nat → ByteArray → UInt256 → UInt256 → List UInt256
  | 0, _, _, _ => []
  | rounds+1, raw, offset, ending =>
    rawWord raw offset :: if decide (offset + UInt256.ofNat 32 < ending) then
      proofWords rounds raw (offset + UInt256.ofNat 32) ending else []

theorem proofWords_length_le (rounds : Nat) (raw : ByteArray) (offset ending : UInt256) :
    (proofWords rounds raw offset ending).length ≤ rounds := by
  induction rounds generalizing offset with
  | zero => exact Nat.le_refl 0
  | succ rounds ih =>
    simp only [proofWords,List.length_cons]
    split
    · exact Nat.succ_le_succ (ih _)
    · exact Nat.succ_le_succ (Nat.zero_le _)

theorem loop_success_fold (rounds fuel : Nat) (st : EVM.State)
    (index leaf offset ending : UInt256) (result : StepResult)
    (h : SszProofCalldataLoop.loop rounds fuel st index leaf offset ending = .ok result)
    (hffi : ShaWidth) (hwidth : st.activeWords.toNat < 2^251) :
    SszProofFold.sourceFold ffiPair index.toNat leaf
      (proofWords rounds st.executionEnv.calldata offset ending) =
      .ok (result.index.toNat,result.leaf) ∧
    result.state.executionEnv = st.executionEnv ∧
    result.state.activeWords.toNat = max st.activeWords.toNat 2 := by
  induction rounds generalizing st index leaf offset with
  | zero => cases h
  | succ rounds ih =>
    cases hs : sourceStep fuel st index leaf offset ending with
    | error e => simp only [SszProofCalldataLoop.loop,hs,bind,Except.bind] at h; cases h
    | ok step =>
      obtain ⟨hf,he,hw,ho,hc⟩ := step_success_effects fuel st index leaf offset ending step hs hffi hwidth
      cases hb : step.continues with
      | false =>
        simp only [SszProofCalldataLoop.loop,hs,bind,Except.bind,hb,Bool.false_eq_true,if_false] at h
        cases h
        refine ⟨?_,he,hw⟩
        have hb' := hc.symm.trans hb
        simpa only [proofWords,hb',Bool.false_eq_true,if_false,rawWord,EvmYul.State.calldataload] using hf
      | true =>
        simp only [SszProofCalldataLoop.loop,hs,bind,Except.bind,hb,if_true] at h
        obtain ⟨hfold,henv,hwords⟩ := ih step.state step.index step.leaf step.offset h (by rw [hw];omega)
        refine ⟨?_,henv.trans he,?_⟩
        · have hb' := hc.symm.trans hb
          simp only [proofWords,hb',if_true]
          change SszProofFold.sourceFold ffiPair index.toNat leaf
            (st.calldataload offset :: proofWords rounds st.executionEnv.calldata
              (offset + UInt256.ofNat 32) ending) = _
          rw [SszProofCalldataLoop.fold_cons_of_step ffiPair _ _ _ _ _ _ hf]
          rw [he,ho] at hfold
          exact hfold
        · rw [hwords,hw]
          omega

def endOffset (offset : UInt256) (count : Nat) : UInt256 :=
  offset + (UInt256.ofNat count <<< UInt256.ofNat 5)

theorem verify_success_branch (fuel count : Nat) (st afterState : EVM.State)
    (rawIndex leaf root offset : UInt256)
    (h : SszProofCalldataLoop.verify fuel st rawIndex leaf root offset count = .ok afterState)
    (hffi : ShaWidth) (hwidth : st.activeWords.toNat < 2^251) :
    proofWords count st.executionEnv.calldata offset (endOffset offset count) ≠ [] ∧
    SszProofFold.Branch ffiPair (decodeIndex rawIndex).toNat leaf
      (proofWords count st.executionEnv.calldata offset (endOffset offset count)) root ∧
    afterState.executionEnv = st.executionEnv ∧
    afterState.activeWords.toNat = max st.activeWords.toNat 2 := by
  by_cases hz : count = 0
  · simp only [SszProofCalldataLoop.verify,hz,if_true] at h
    cases h
  · simp only [SszProofCalldataLoop.verify,hz,if_false] at h
    cases hl : SszProofCalldataLoop.loop count fuel st (decodeIndex rawIndex) leaf offset
        (endOffset offset count) with
    | error e =>
      change (match SszProofCalldataLoop.loop count fuel st (decodeIndex rawIndex) leaf offset
        (endOffset offset count) with
        | .error e => Except.error (SszProofCalldataLoop.liftError e)
        | .ok r => SszProofCalldataLoop.finish root r) = .ok afterState at h
      rw [hl] at h
      cases h
    | ok result =>
      change (match SszProofCalldataLoop.loop count fuel st (decodeIndex rawIndex) leaf offset
        (endOffset offset count) with
        | .error e => Except.error (SszProofCalldataLoop.liftError e)
        | .ok r => SszProofCalldataLoop.finish root r) = .ok afterState at h
      rw [hl] at h
      obtain ⟨hf,he,hw⟩ := loop_success_fold count fuel st (decodeIndex rawIndex) leaf offset
        (endOffset offset count) result hl hffi hwidth
      have hn : proofWords count st.executionEnv.calldata offset (endOffset offset count) ≠ [] := by
        cases count with
        | zero => exact False.elim (hz rfl)
        | succ n => exact List.cons_ne_nil _ _
      simp only [SszProofCalldataLoop.finish] at h
      split at h
      · rename_i hi
        split at h
        · rename_i hr
          cases h
          refine ⟨hn,?_,he,hw⟩
          have hi' : result.index.toNat = 1 := (SszProofCalldataLoop.word_one _).mp hi
          rw [hi',hr] at hf
          exact SszProofFold.fold_branch _ _ _ _ hf
        · cases h
      · cases h

theorem verify_success_depth (fuel count : Nat) (st afterState : EVM.State)
    (rawIndex leaf root offset : UInt256)
    (h : SszProofCalldataLoop.verify fuel st rawIndex leaf root offset count = .ok afterState)
    (hffi : ShaWidth) (hwidth : st.activeWords.toNat < 2^251) :
    let words := proofWords count st.executionEnv.calldata offset (endOffset offset count)
    0 < words.length ∧ words.length = (decodeIndex rawIndex).toNat.log2 ∧ words.length ≤ 247 := by
  obtain ⟨hn,hb,_,_⟩ := verify_success_branch fuel count st afterState rawIndex leaf root offset h hffi hwidth
  have hv := (SszProofFold.verify_success_iff ffiPair (SszTypedFfiBridge.typedIndex rawIndex)
    leaf root (proofWords count st.executionEnv.calldata offset (endOffset offset count))).mpr ⟨hn,hb⟩
  exact SszProofFold.verify_depth ffiPair (SszTypedFfiBridge.typedIndex rawIndex) leaf root _ hv

/-- A name for the existing typed tree, not a replacement hashing model. -/
def validatorLeaf (st : EVM.State) (offset : UInt256) (f : SszBlsComposition.Fields) : UInt256 :=
  SszTypedFfiBridge.toWord (SszWrapperIndex.treeDigest
    (SszValidatorLeaf.pair SszTypedFfiBridge.ffiSha)
    (SszValidatorLeaf.validatorTree SszTypedFfiBridge.ffiSha (SszPubkeyBytes.witnessAt st offset f)
      (SszTypedFfiBridge.toDigest (st.calldataload (SszWitnessAbi.abiWord 36)))))

/-- The unchanged raw consumer's successful execution implies a nonempty
independent Merkle branch from its typed validator leaf to its original root.
The words follow the actual unsigned cursor/continuation semantics, including
wrap. Equality with the ABI-declared full list is not presumed. -/
theorem run_success_branch (fuel : Nat) (st afterState : EVM.State)
    (h : SszWitnessAbi.run fuel st = .ok afterState)
    (hffi : ShaWidth) (hwidth : st.activeWords.toNat < 2^251) :
    ∃ offset keySlice f branch,
      SszWitnessAbi.header st = .ok offset ∧
      SszWitnessAbi.tail st offset (SszWitnessAbi.abiWord 36) 1 = .ok keySlice ∧
      SszWitnessAbi.FieldsMatch st offset f ∧
      SszWitnessAbi.tail st offset (SszWitnessAbi.abiWord 4) 32 = .ok branch ∧
      keySlice.length = 48 ∧ branch.length ≤ 2^64-1 ∧
      proofWords branch.length st.executionEnv.calldata branch.offset
        (endOffset branch.offset branch.length) ≠ [] ∧
      SszProofFold.Branch ffiPair (decodeIndex (st.calldataload (SszWitnessAbi.abiWord 100))).toNat
        (validatorLeaf st keySlice.offset f)
        (proofWords branch.length st.executionEnv.calldata branch.offset
          (endOffset branch.offset branch.length))
        (st.calldataload (SszWitnessAbi.abiWord 68)) ∧
      afterState.executionEnv = st.executionEnv ∧
      afterState.activeWords.toNat = max st.activeWords.toNat 2 := by
  obtain ⟨offset,keySlice,key,f,leaf,branch,ho,hks,hk,hkey,he,fm,hl,hle,hw,hp,hv,hkl,hpl⟩ :=
    SszPubkeyBytes.run_success_computed_leaf fuel st afterState h hwidth
  obtain ⟨hn,hb,hen,hwn⟩ := verify_success_branch fuel branch.length leaf.state afterState
    (st.calldataload (SszWitnessAbi.abiWord 100)) (validatorLeaf st keySlice.offset f)
    (st.calldataload (SszWitnessAbi.abiWord 68)) branch.offset hv hffi (by rw [hw];omega)
  rw [hle] at hn hb
  refine ⟨offset,keySlice,f,branch,ho,hks,fm,hp,hkl,hpl,hn,hb,hen.trans hle,?_⟩
  rw [hwn,hw]
  omega

#print axioms proofWords_length_le
#print axioms verify_success_depth
#print axioms run_success_branch
#print axioms verify_success_branch
#print axioms loop_success_fold
#print axioms step_success_effects
#print axioms step_call_digest
#print axioms step_success_shape
#print axioms prepared_memory
#print axioms prepared_read
end LidoSRv3.Audit.Source.SszProofCommitted
