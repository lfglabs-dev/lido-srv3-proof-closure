import LidoSRv3.Audit.Source.SszWitnessAbi

namespace LidoSRv3.Audit.Source.SszShaCommitted
open EvmYul EvmYul.EVM SszShaCallMemory

/-- Successful actual SHA CALL cannot arise from the depth-rejection branch. -/
theorem call_success_depth (fuel gasCost : Nat) (source gas : UInt256)
    (st afterState : EVM.State) (flag : UInt256)
    (h : callSha (fuel+2) gasCost source gas st = .ok (flag,afterState))
    (hn : flag ≠ UInt256.ofNat 0) : st.executionEnv.depth < 1024 := by
  by_contra hd
  unfold callSha at h
  rw [EVM.call] at h
  have hz (v : UInt256) : UInt256.ofNat 0 ≤ v := by change 0 ≤ v.toNat; omega
  simp only [hz,hd,and_false,if_false,Bind.bind,Except.bind,Pure.pure,Except.pure,
    Bool.not_false,Bool.true_or,if_true,Except.ok.injEq,Prod.mk.injEq] at h
  exact hn h.1.symm

/-- The real CALL transition computes memory extent from its literal 64/32
operands even when the callee state or returned success flag is arbitrary. -/
theorem call_words (fuel gasCost : Nat) (source gas : UInt256)
    (st afterState : EVM.State) (flag : UInt256)
    (h : callSha (fuel+2) gasCost source gas st = .ok (flag,afterState)) :
    afterState.activeWords = UInt256.ofNat (max st.activeWords.toNat 2) := by
  unfold callSha at h
  rw [EVM.call] at h
  dsimp only at h
  split at h
  · simp only [Bind.bind,Except.bind,Pure.pure,Except.pure] at h
    split at h
    · cases h
    · cases h
      change UInt256.ofNat (MachineState.M (MachineState.M st.activeWords.toNat 0 64) 0 32) = _
      congr 1
      simp only [MachineState.M]
      omega
  · cases h
    change UInt256.ofNat (MachineState.M (MachineState.M st.activeWords.toNat 0 64) 0 32) = _
    congr 1
    simp only [MachineState.M]
    omega

private theorem theta_underfunded (fuel : Nat) (st : EVM.State)
    (origin : AccountAddress) (access : Substate) (gas : UInt256) (input : ByteArray)
    (hlen : input.size = 64) (hgas : gas.toNat < 84) :
    EVM.Θ (fuel+1) st.executionEnv.blobVersionedHashes st.createdAccounts
      st.genesisBlockHeader st.blocks st.accountMap st.σ₀ access
      origin st.executionEnv.sender shaAddress (.Precompiled shaAddress)
      gas (UInt256.ofNat st.executionEnv.gasPrice) (UInt256.ofNat 0) (UInt256.ofNat 0)
      input (st.executionEnv.depth+1) st.executionEnv.header false =
      .ok (∅,st.accountMap,UInt256.ofNat 0,access,false,ByteArray.empty) := by
  simp only [EVM.Θ,shaAddress,Ξ_SHA256,hlen]
  have hg : gas.toNat < 60 + 12 * ((64+31)/32) := by omega
  simp only [hg,↓reduceIte]
  rfl

/-- The nonzero flag of an actual 64-byte SHA call derives its own precompile
charge admission; no successful-calldata consumer supplies a gas premise. -/
theorem call_success_gas (fuel gasCost : Nat) (source gas : UInt256)
    (st afterState : EVM.State) (flag : UInt256)
    (hinput : (st.memory.readWithPadding 0 64).size = 64)
    (h : callSha (fuel+2) gasCost source gas st = .ok (flag,afterState))
    (hn : flag ≠ UInt256.ofNat 0) :
    84 ≤ Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas
      st.accountMap st.toMachineState st.substate := by
  have hd := call_success_depth fuel gasCost source gas st afterState flag h hn
  have hfit := gas_fits gas st
  by_contra hg
  have hlow : (UInt256.ofNat (Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas
      st.accountMap st.toMachineState st.substate)).toNat < 84 := by
    change _ % UInt256.size < 84
    rw [Nat.mod_eq_of_lt hfit]
    omega
  have ht := theta_underfunded fuel st (AccountAddress.ofUInt256 source)
    (st.addAccessedAccount shaAddress).substate
    (UInt256.ofNat (Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas
      st.accountMap st.toMachineState st.substate))
    (st.memory.readWithPadding 0 64) hinput hlow
  unfold callSha at h
  rw [EVM.call] at h
  have hz (v : UInt256) : UInt256.ofNat 0 ≤ v := by change 0 ≤ v.toNat; omega
  simp only [show AccountAddress.ofUInt256 (UInt256.ofNat 2) = shaAddress from rfl,
    sha_selected,hz,hd,and_self,if_true] at h
  rw [show (UInt256.ofNat 0).toNat = 0 by decide +kernel,
    show (UInt256.ofNat 64).toNat = 64 by decide +kernel] at h
  rw [ht] at h
  simp only [
    Bind.bind,Except.bind,Pure.pure,Except.pure,Bool.not_false,Bool.true_or,
    if_true,Except.ok.injEq,Prod.mk.injEq] at h
  exact hn h.1.symm

/-- Actual successful SHA execution determines returndata without an output-size
or resource assumption. The input length is later discharged by scratch writes. -/
theorem call_success_output (fuel gasCost : Nat) (source gas : UInt256)
    (st afterState : EVM.State) (flag : UInt256)
    (hinput : (st.memory.readWithPadding 0 64).size = 64)
    (h : callSha (fuel+2) gasCost source gas st = .ok (flag,afterState))
    (hn : flag ≠ UInt256.ofNat 0) :
    afterState.returnData = shaOutput (st.memory.readWithPadding 0 64) := by
  have hd := call_success_depth fuel gasCost source gas st afterState flag h hn
  have hg := call_success_gas fuel gasCost source gas st afterState flag hinput h hn
  have hfit := gas_fits gas st
  have hactual : 84 ≤ (UInt256.ofNat (Ccallgas shaAddress shaAddress
      (UInt256.ofNat 0) gas st.accountMap st.toMachineState st.substate)).toNat := by
    change 84 ≤ _ % UInt256.size
    rwa [Nat.mod_eq_of_lt hfit]
  obtain ⟨accounts,access,ht⟩ := theta_sha fuel st (AccountAddress.ofUInt256 source)
    (st.addAccessedAccount shaAddress).substate
    (UInt256.ofNat (Ccallgas shaAddress shaAddress (UInt256.ofNat 0) gas
      st.accountMap st.toMachineState st.substate))
    (st.memory.readWithPadding 0 64) hinput hactual
  unfold callSha at h
  rw [EVM.call] at h
  have hz (v : UInt256) : UInt256.ofNat 0 ≤ v := by change 0 ≤ v.toNat; omega
  simp only [show AccountAddress.ofUInt256 (UInt256.ofNat 2) = shaAddress from rfl,
    sha_selected,hz,hd,and_self,if_true] at h
  rw [show (UInt256.ofNat 0).toNat = 0 by decide +kernel,
    show (UInt256.ofNat 64).toNat = 64 by decide +kernel,ht] at h
  simp only [Bind.bind,Except.bind,Pure.pure,Except.pure,Except.ok.injEq,Prod.mk.injEq] at h
  exact congrArg (fun s : EVM.State => s.returnData) h.2.symm

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

/-- The real pair consumer's guard derives the opaque SHA result's size. Its
input block comes from the two actual mstore operations, not a supplied layout. -/
theorem pair_success_output (fuel : Nat) (st : EVM.State) (left right : UInt256)
    (result : SszBlsComposition.Result)
    (h : SszBlsComposition.pairRun fuel st left right = .ok result) :
    let bytes := shaOutput (SszWordBytes.fixedBE 32 left.toNat ++
      SszWordBytes.fixedBE 32 right.toNat)
    result.state.returnData = bytes ∧ bytes.size = 32 ∧ st.executionEnv.depth < 1024 := by
  obtain ⟨flag,called,hc,hn,hlen,he,_,_⟩ := finish_success _ _ h
  let prep := SszBlsComposition.preparePair st left right
  have hi : (prep.memory.readWithPadding 0 64).size = 64 := by
    rw [SszBlsComposition.prepared_read]
    simp [SszWordBytes.fixedBE]
  let charge := Ccall shaAddress shaAddress (UInt256.ofNat 0) prep.gasAvailable
    prep.accountMap prep.toMachineState prep.substate
  let source := UInt256.ofNat prep.executionEnv.codeOwner.val
  have ho := call_success_output fuel charge source prep.gasAvailable prep called flag hi hc hn
  have hd := call_success_depth fuel charge source prep.gasAvailable prep called flag hc hn
  rw [SszBlsComposition.prepared_read] at ho
  exact ⟨he.trans ho,ho ▸ hlen,hd⟩

/-- The actual pair result computes the independent digest. The only retained
condition is the engine's initial memory-extent representation invariant;
depth, gas, FFI output size and successful call are derived from this execution. -/
theorem pair_success_digest (fuel : Nat) (st : EVM.State) (left right : UInt256)
    (result : SszBlsComposition.Result)
    (h : SszBlsComposition.pairRun fuel st left right = .ok result)
    (hwidth : st.activeWords.toNat < 2^251) :
    result.digest = SszBlsComposition.pairDigest left right := by
  obtain ⟨flag,called,hc,hn,hlen,_,hdigest,_⟩ := finish_success _ _ h
  let prep := SszBlsComposition.preparePair st left right
  let charge := Ccall shaAddress shaAddress (UInt256.ofNat 0) prep.gasAvailable
    prep.accountMap prep.toMachineState prep.substate
  let source := UInt256.ofNat prep.executionEnv.codeOwner.val
  have hi : (prep.memory.readWithPadding 0 64).size = 64 := by
    rw [SszBlsComposition.prepared_read]
    simp [SszWordBytes.fixedBE]
  have ho := call_success_output fuel charge source prep.gasAvailable prep called flag hi hc hn
  have hd := call_success_depth fuel charge source prep.gasAvailable prep called flag hc hn
  have hg := call_success_gas fuel charge source prep.gasAvailable prep called flag hi hc hn
  have hout : (shaOutput (prep.memory.readWithPadding 0 64)).size = 32 := ho ▸ hlen
  obtain ⟨afterState,ha,hr,hm,hw⟩ := call_sha_bytes fuel charge source prep.gasAvailable prep hd hg hi hout
  change callSha (fuel+2) charge source prep.gasAvailable prep = .ok (flag,called) at hc
  rw [hc] at ha
  obtain ⟨_,he⟩ := Prod.mk.inj (Except.ok.inj ha)
  subst afterState
  have hwords : called.activeWords.toNat = max st.activeWords.toNat 2 := by
    rw [hw,SszBlsComposition.prepared_words]
    have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    change max (max st.activeWords.toNat 2) 2 % UInt256.size = _
    rw [max_eq_left (by omega),Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)]
  have hv := SszShaCallBytes.mload32 called.toMachineState _ _ hm hout
    (by rw [hwords]; omega) (by rw [hwords]; omega)
  rw [SszBlsComposition.prepared_read] at hv
  exact hdigest.trans hv

/-- The actual pair's mstore/CALL/mload transitions preserve the derived
extent invariant; later pairs need no independently supplied state bound. -/
theorem pair_success_words (fuel : Nat) (st : EVM.State) (left right : UInt256)
    (result : SszBlsComposition.Result)
    (h : SszBlsComposition.pairRun fuel st left right = .ok result) :
    result.state.activeWords.toNat = max st.activeWords.toNat 2 := by
  obtain ⟨flag,called,hc,_,_,_,_,he⟩ := finish_success _ _ h
  let prep := SszBlsComposition.preparePair st left right
  let charge := Ccall shaAddress shaAddress (UInt256.ofNat 0) prep.gasAvailable
    prep.accountMap prep.toMachineState prep.substate
  let source := UInt256.ofNat prep.executionEnv.codeOwner.val
  have hw := call_words fuel charge source prep.gasAvailable prep called flag hc
  have hn : called.activeWords.toNat = max st.activeWords.toNat 2 := by
    rw [hw,SszBlsComposition.prepared_words]
    have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    change max (max st.activeWords.toNat 2) 2 % UInt256.size = _
    rw [max_eq_left (by omega),Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)]
  rw [he]
  simp only [MachineState.mload,MachineState.M]
  change max called.activeWords.toNat 1 % UInt256.size = _
  rw [hn,max_eq_left (by omega),Nat.mod_eq_of_lt]
  have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
  unfold UInt256.size at *
  omega

/-- The actual pubkey preparation, CALL and mload preserve the same memory
extent invariant, independently of calldata layout and callee return size. -/
theorem pubkey_success_words (fuel : Nat) (st : EVM.State) (offset : UInt256) (length : Nat)
    (result : SszBlsComposition.Result)
    (h : SszBlsComposition.pubkeyRun fuel st offset length = .ok result) :
    result.state.activeWords.toNat = max st.activeWords.toNat 2 := by
  unfold SszBlsComposition.pubkeyRun at h
  split at h
  · cases h
  ·
    obtain ⟨flag,called,hc,_,_,_,_,he⟩ := finish_success _ _ h
    let prep := SszShaCallMemory.prepared st offset
    let charge := Ccall shaAddress shaAddress (UInt256.ofNat 0) prep.gasAvailable
      prep.accountMap prep.toMachineState prep.substate
    let source := UInt256.ofNat prep.executionEnv.codeOwner.val
    have hw := call_words fuel charge source prep.gasAvailable prep called flag hc
    have hn : called.activeWords.toNat = max st.activeWords.toNat 2 := by
      rw [hw,SszShaCallMemory.prepared_words]
      have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
      change max (max st.activeWords.toNat 2) 2 % UInt256.size = _
      rw [max_eq_left (by omega),Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)]
    rw [he]
    simp only [MachineState.mload,MachineState.M]
    change max called.activeWords.toNat 1 % UInt256.size = _
    rw [hn,max_eq_left (by omega),Nat.mod_eq_of_lt]
    have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    unfold UInt256.size at *
    omega

private theorem bind_success {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β} (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error e => cases h
  | ok x => exact ⟨x,rfl,h⟩

/-- Success of the existing seven-call consumer derives its independent leaf
and exact memory extent. Every later memory bound follows from the preceding
actual transition; no gas, depth, per-call success or FFI-size premise remains. -/
theorem merkle_success_digest (fuel : Nat) (st : EVM.State) (a b c d e f g h : UInt256)
    (result : SszBlsComposition.Result)
    (ok : SszBlsComposition.merkleRun fuel st a b c d e f g h = .ok result)
    (hwidth : st.activeWords.toNat < 2^251) :
    result.digest = SszBlsComposition.merkleDigest a b c d e f g h ∧
    result.state.activeWords.toNat = max st.activeWords.toNat 2 := by
  unfold SszBlsComposition.merkleRun at ok
  obtain ⟨r0,c0,ok⟩ := bind_success ok
  obtain ⟨r1,c1,ok⟩ := bind_success ok
  obtain ⟨r2,c2,ok⟩ := bind_success ok
  obtain ⟨r3,c3,ok⟩ := bind_success ok
  obtain ⟨r4,c4,ok⟩ := bind_success ok
  obtain ⟨r5,c5,ok⟩ := bind_success ok
  have w0 := pair_success_words fuel st _ _ r0 c0
  have d0 := pair_success_digest fuel st _ _ r0 c0 hwidth
  have b0 : r0.state.activeWords.toNat < 2^251 := by rw [w0]; omega
  have w1 := pair_success_words fuel r0.state _ _ r1 c1
  have d1 := pair_success_digest fuel r0.state _ _ r1 c1 b0
  have b1 : r1.state.activeWords.toNat < 2^251 := by rw [w1]; omega
  have w2 := pair_success_words fuel r1.state _ _ r2 c2
  have d2 := pair_success_digest fuel r1.state _ _ r2 c2 b1
  have b2 : r2.state.activeWords.toNat < 2^251 := by rw [w2]; omega
  have w3 := pair_success_words fuel r2.state _ _ r3 c3
  have d3 := pair_success_digest fuel r2.state _ _ r3 c3 b2
  have b3 : r3.state.activeWords.toNat < 2^251 := by rw [w3]; omega
  have w4 := pair_success_words fuel r3.state _ _ r4 c4
  have d4 := pair_success_digest fuel r3.state _ _ r4 c4 b3
  have b4 : r4.state.activeWords.toNat < 2^251 := by rw [w4]; omega
  have w5 := pair_success_words fuel r4.state _ _ r5 c5
  have d5 := pair_success_digest fuel r4.state _ _ r5 c5 b4
  have b5 : r5.state.activeWords.toNat < 2^251 := by rw [w5]; omega
  have w6 := pair_success_words fuel r5.state _ _ result ok
  have d6 := pair_success_digest fuel r5.state _ _ result ok b5
  constructor
  · rw [d6,d4,d5,d0,d1,d2,d3]
    rfl
  · rw [w6,w5,w4,w3,w2,w1,w0]
    omega

/-- The existing raw witness consumer actually passes the independently
computed seven-pair leaf into its proof verifier on the real returned state.
Raw fields remain bound to original calldata. Initial memory extent is the
single retained engine invariant, not seven per-call premises; its derivation
from full entry initialization remains separate required work. -/
theorem run_success_computed_merkle (fuel : Nat) (st afterState : EVM.State)
    (h : SszWitnessAbi.run fuel st = .ok afterState)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ offset keySlice key f leaf branch,
      SszWitnessAbi.header st = .ok offset ∧
      SszWitnessAbi.tail st offset (SszWitnessAbi.abiWord 36) 1 = .ok keySlice ∧
      SszBlsComposition.pubkeyRun fuel st keySlice.offset keySlice.length = .ok key ∧
      key.state.executionEnv = st.executionEnv ∧
      SszWitnessAbi.FieldsMatch st offset f ∧
      SszBlsComposition.merkleRun fuel key.state key.digest (st.calldataload (SszWitnessAbi.abiWord 36))
        (SszBlsComposition.chunk f.effectiveBalance) (SszBlsComposition.chunk (if f.slashed then 1 else 0))
        (SszBlsComposition.chunk f.activationEligibilityEpoch) (SszBlsComposition.chunk f.activationEpoch)
        (SszBlsComposition.chunk f.exitEpoch) (SszBlsComposition.chunk f.withdrawableEpoch) = .ok leaf ∧
      leaf.state.executionEnv = st.executionEnv ∧
      leaf.state.activeWords.toNat = max st.activeWords.toNat 2 ∧
      SszWitnessAbi.tail st offset (SszWitnessAbi.abiWord 4) 32 = .ok branch ∧
      SszProofCalldataLoop.verify fuel leaf.state
        (st.calldataload (SszWitnessAbi.abiWord 100))
        (SszBlsComposition.merkleDigest key.digest (st.calldataload (SszWitnessAbi.abiWord 36))
          (SszBlsComposition.chunk f.effectiveBalance) (SszBlsComposition.chunk (if f.slashed then 1 else 0))
          (SszBlsComposition.chunk f.activationEligibilityEpoch) (SszBlsComposition.chunk f.activationEpoch)
          (SszBlsComposition.chunk f.exitEpoch) (SszBlsComposition.chunk f.withdrawableEpoch))
        (st.calldataload (SszWitnessAbi.abiWord 68)) branch.offset branch.length = .ok afterState ∧
      keySlice.length = 48 ∧ branch.length ≤ 2^64-1 := by
  obtain ⟨offset,keySlice,key,f,leaf,branch,ho,hks,hk,he,fm,hl,hle,hp,hv,hkl,hpl⟩ :=
    SszWitnessAbi.run_success_input_binding fuel st afterState h
  have hkw := pubkey_success_words fuel st keySlice.offset keySlice.length key hk
  have hw : key.state.activeWords.toNat < 2^251 := by rw [hkw]; omega
  have hd := merkle_success_digest fuel key.state _ _ _ _ _ _ _ _ leaf hl hw
  rw [hd.1] at hv
  refine ⟨offset,keySlice,key,f,leaf,branch,ho,hks,hk,he,fm,hl,hle,?_,hp,hv,hkl,hpl⟩
  rw [hd.2,hkw]
  omega

#print axioms run_success_computed_merkle
#print axioms pubkey_success_words
#print axioms merkle_success_digest
#print axioms call_words
#print axioms pair_success_words
#print axioms pair_success_digest
#print axioms call_success_output
#print axioms pair_success_output
#print axioms call_success_gas
#print axioms call_success_depth
end LidoSRv3.Audit.Source.SszShaCommitted
