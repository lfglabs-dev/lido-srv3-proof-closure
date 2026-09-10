import LidoSRv3.Audit.Source.SszCompiledConsumer

/-! The fixed compiler memory consumer of the seven validator-tree SHA calls.
Its local memory facts are intended to be consumed by the public successful
validator-branch theorem, starting at the fresh frame, not caller premises. -/
namespace LidoSRv3.Audit.Source.SszCompiledMerkle
open EvmYul EvmYul.EVM SszCompiledMemory SszCompiledConsumer

/-- A physical word, independently of the value an eventual load returns. -/
def Stored (st : EVM.State) (offset : Nat) (value : UInt256) : Prop :=
  offset + 32 ≤ st.memory.size ∧
  st.memory.readWithPadding offset 32 = value.toByteArray ∧
  offset < st.activeWords.toNat * 32

theorem stored_load (st : EVM.State) (offset : Nat) (value : UInt256)
    (h : Stored st offset value) (ho : offset ≤ 576)
    (hw : st.activeWords.toNat ≤ 20) : (load st offset).1 = value :=
  mload_of_read _ _ _ ho h.1 h.2.1 h.2.2 (by omega)

theorem load_memory (st : EVM.State) (offset : Nat) :
    (load st offset).2.memory = st.memory := rfl

theorem load_environment (st : EVM.State) (offset : Nat) :
    (load st offset).2.executionEnv = st.executionEnv := rfl

theorem load_bounded (st : EVM.State) (offset : Nat)
    (ho : offset ≤ 576) (hw : st.activeWords.toNat ≤ 20) :
    (load st offset).2.activeWords.toNat ≤ 20 := by
  change (st.toMachineState.mload (UInt256.ofNat offset)).2.activeWords.toNat ≤ 20
  rw [load_words _ _ ho]
  omega

theorem stored_after_load (st : EVM.State) (loadAt offset : Nat) (value : UInt256)
    (h : Stored st offset value) (ha : loadAt ≤ 576) :
    Stored (load st loadAt).2 offset value := by
  refine ⟨h.1,h.2.1,?_⟩
  change offset < (st.toMachineState.mload (UInt256.ofNat loadAt)).2.activeWords.toNat * 32
  rw [load_words _ _ ha]
  have := h.2.2
  omega

theorem store_bounded (st : EVM.State) (offset : Nat) (value : UInt256)
    (ho : offset ≤ 576) (hw : st.activeWords.toNat ≤ 20) :
    (store st offset value).activeWords.toNat ≤ 20 := by
  change (st.toMachineState.mstore (UInt256.ofNat offset) value).activeWords.toNat ≤ 20
  rw [store_words _ _ _ ho]
  omega

theorem stored_written (st : EVM.State) (offset : Nat) (value : UInt256)
    (ho : offset ≤ 576) : Stored (store st offset value) offset value := by
  have hn : (UInt256.ofNat offset).toNat = offset := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  refine ⟨store_size _ _ _ ho,?_,?_⟩
  · change (value.toByteArray.write 0 st.memory (UInt256.ofNat offset).toNat 32).readWithPadding offset 32 = _
    rw [hn]
    exact write_word_read _ _ _ ho
  · change offset < (st.toMachineState.mstore (UInt256.ofNat offset) value).activeWords.toNat * 32
    rw [store_words _ _ _ ho]
    omega

theorem stored_preserved (st : EVM.State) (dest offset : Nat) (word value : UInt256)
    (h : Stored st offset value) (hd : dest ≤ 576)
    (apart : offset+32 ≤ dest ∨ dest+32 ≤ offset) :
    Stored (store st dest word) offset value := by
  refine ⟨Nat.le_trans h.1 (store_memory_size_mono _ _ _),?_,?_⟩
  · rcases apart with hb | ha
    · rw [store_read_before _ _ _ _ hd hb h.1]; exact h.2.1
    · rw [store_read_after _ _ _ _ hd ha h.1]; exact h.2.1
  · change offset < (st.toMachineState.mstore (UInt256.ofNat dest) word).activeWords.toNat * 32
    rw [store_words _ _ _ hd]
    have := h.2.2
    omega

theorem pair_stored (fuel : Nat) (st : EVM.State) (left right : UInt256)
    (result : SszBlsComposition.Result) (offset : Nat) (value : UInt256)
    (hs : SszBlsComposition.pairRun fuel st left right = .ok result)
    (h : Stored st offset value) (ho : 64 ≤ offset) :
    Stored result.state offset value := by
  have hm := pair_memory fuel st left right result hs (by have := h.1;omega)
  have hw := SszShaCommitted.pair_success_words fuel st left right result hs
  refine ⟨Nat.le_trans h.1 hm.2,?_,?_⟩
  · rw [pair_stored_word fuel st left right result offset hs ho h.1]
    exact h.2.1
  · rw [hw]
    have := h.2.2
    omega

private theorem bind_success {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β} (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error e => cases h
  | ok x => exact ⟨x,rfl,h⟩

private theorem map_success {ε α : Type} (f : ε → SszCompiledConsumer.Error)
    (step : Except ε α) (value : α) (h : step.mapError f = .ok value) : step = .ok value := by
  cases step with
  | error e => cases h
  | ok x => cases h; rfl

/-- Actual mload operands feed SHA; its returned digest is then written to
actual memory. Other stored words survive the scratch CALL and disjoint store. -/
theorem pairStore_effects (fuel : Nat) (st : EVM.State) (leftAt rightAt dest : Nat)
    (left right : UInt256) (result : SszBlsComposition.Result)
    (h : pairStore fuel st (UInt256.ofNat leftAt) (UInt256.ofNat rightAt)
      (UInt256.ofNat dest) = .ok result)
    (hl : Stored st leftAt left) (hr : Stored st rightAt right)
    (hla : leftAt ≤ 576) (hra : rightAt ≤ 576) (hd : dest ≤ 576)
    (hw : st.activeWords.toNat ≤ 20) :
    result.digest = SszBlsComposition.pairDigest left right ∧
    Stored result.state dest result.digest ∧
    result.state.activeWords.toNat ≤ 20 ∧
    result.state.executionEnv = st.executionEnv ∧
    ∀ offset value, Stored st offset value → 64 ≤ offset →
      (offset+32 ≤ dest ∨ dest+32 ≤ offset) → Stored result.state offset value := by
  have nl : (UInt256.ofNat leftAt).toNat = leftAt := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  have nr : (UInt256.ofNat rightAt).toNat = rightAt := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  have nd : (UInt256.ofNat dest).toNat = dest := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  let loadedLeft := (load st leftAt).2
  let loadedRight := (load loadedLeft rightAt).2
  have vl := stored_load st leftAt left hl hla hw
  have wl := load_bounded st leftAt hla hw
  have vr := stored_load loadedLeft rightAt right (stored_after_load st leftAt rightAt right hr hla) hra wl
  have wr : loadedRight.activeWords.toNat ≤ 20 := load_bounded loadedLeft rightAt hra wl
  unfold pairStore at h
  simp only [nl,nr,nd] at h
  change ((SszBlsComposition.pairRun fuel loadedRight (load st leftAt).1
    (load loadedLeft rightAt).1).mapError SszCompiledConsumer.Error.bls >>= fun r =>
      pure (SszBlsComposition.Result.mk (store r.state dest r.digest) r.digest)) = .ok result at h
  rw [vl,vr] at h
  obtain ⟨called,hc,h⟩ := bind_success h
  have call := map_success SszCompiledConsumer.Error.bls _ _ hc
  change Except.ok _ = Except.ok result at h
  cases h
  have digest := SszShaCommitted.pair_success_digest fuel loadedRight left right called call (by omega)
  have words := SszShaCommitted.pair_success_words fuel loadedRight left right called call
  have env := SszWitnessAbi.pair_environment fuel loadedRight left right called call
  refine ⟨digest,stored_written _ _ _ hd,store_bounded _ _ _ hd (by rw [words];omega),env,?_⟩
  intro offset value stored hoff apart
  exact stored_preserved _ _ _ _ _
    (pair_stored fuel loadedRight left right called offset value call
      (stored_after_load loadedLeft rightAt offset value
        (stored_after_load st leftAt offset value stored hla) hra) hoff) hd apart

/-- The allocator clears its new region; previously stored words between the
free-pointer word and that region are physically preserved. -/
theorem allocate_read_before (st afterState : EVM.State) (ptr bytes offset : Nat)
    (hfree : (load st 64).1 = UInt256.ofNat ptr)
    (h : allocate st bytes = .ok (UInt256.ofNat ptr,afterState))
    (hp : ptr ≤ 576) (hoff : 96 ≤ offset) (hend : offset+32 ≤ ptr)
    (hsize : offset+32 ≤ st.memory.size) :
    afterState.memory.readWithPadding offset 32 = st.memory.readWithPadding offset 32 := by
  have hn : (UInt256.ofNat ptr).toNat = ptr := Nat.mod_eq_of_lt (by unfold UInt256.size;omega)
  let readState := (load st 64).2
  let written := store readState 64 (UInt256.ofNat ptr + UInt256.ofNat bytes)
  have hs : offset+32 ≤ written.memory.size :=
    Nat.le_trans hsize (store_memory_size_mono readState 64 _)
  have ha : offset+32 ≤ (written.executionEnv.calldata.write
      (UInt256.ofNat written.executionEnv.calldata.size).toNat written.memory ptr
      (UInt256.ofNat bytes).toNat).size := Nat.le_trans hs (write_size_mono _ _ _ _ _)
  unfold allocate at h
  dsimp only at h
  rw [hfree] at h
  split at h
  · cases h
  · cases h
    change (written.executionEnv.calldata.write
      (UInt256.ofNat written.executionEnv.calldata.size).toNat written.memory
      (UInt256.ofNat ptr).toNat (UInt256.ofNat bytes).toNat).readWithPadding offset 32 = _
    rw [hn,SszShaCallBytes.read_fit _ offset 32 ha (by omega),
      write_preserves_before _ _ _ _ _ _ _ hend hs,
      ← SszShaCallBytes.read_fit _ offset 32 hs (by omega)]
    rw [show written.memory.readWithPadding offset 32 = readState.memory.readWithPadding offset 32 from
      store_read_after readState 64 offset _ (by omega) (by omega) hsize]
    rfl

/-- Allocation facts and frame preservation are derived from the actual
allocator; these local bounds will be instantiated with its constant sizes. -/
theorem allocate_frame (st : EVM.State) (ptr bytes : Nat)
    (hfree : (load st 64).1 = UInt256.ofNat ptr)
    (hp : 96 ≤ ptr) (hb : 0 < bytes) (hend : ptr+bytes ≤ 576)
    (hw : 3 ≤ st.activeWords.toNat) (hwidth : st.activeWords.toNat ≤ 20) :
    ∃ afterState, allocate st bytes = .ok (UInt256.ofNat ptr,afterState) ∧
      Stored afterState 64 (UInt256.ofNat (ptr+bytes)) ∧
      afterState.activeWords.toNat ≤ 20 ∧
      afterState.executionEnv = st.executionEnv ∧
      ∀ offset value, Stored st offset value → 96 ≤ offset → offset+32 ≤ ptr →
        Stored afterState offset value := by
  obtain ⟨afterState,ha,hf,words,env,hs,hr⟩ := allocate_effects st ptr bytes hfree hp hb hend hw (by omega)
  have hbnd : afterState.activeWords.toNat ≤ 20 := by rw [words];omega
  refine ⟨afterState,ha,⟨hs,hr,by rw [words];omega⟩,hbnd,env,?_⟩
  intro offset value stored hoff hout
  have hm := allocate_read_before st afterState ptr bytes offset hfree ha (by omega) hoff hout stored.1
  refine ⟨?_,hm.trans stored.2.1,?_⟩
  · unfold allocate at ha
    dsimp only at ha
    rw [hfree] at ha
    split at ha
    · cases ha
    · cases ha
      exact Nat.le_trans stored.1 (Nat.le_trans (store_memory_size_mono _ _ _) (write_size_mono _ _ _ _ _))
  · rw [words]
    have := stored.2.2
    omega

/-- Seven real SHA calls consume the words loaded from their allocated arrays.
The fixed memory cells are intermediate facts to be derived by `run`'s stores. -/
theorem merkle_effects (fuel : Nat) (st : EVM.State)
    (v0 v1 v2 v3 v4 v5 v6 v7 : UInt256) (result : SszBlsComposition.Result)
    (h : merkle fuel st (UInt256.ofNat 128) = .ok result)
    (hf : Stored st 64 (UInt256.ofNat 384))
    (hw : st.activeWords.toNat ≤ 20)
    (h0 : Stored st 128 v0)
    (h1 : Stored st 160 v1)
    (h2 : Stored st 192 v2)
    (h3 : Stored st 224 v3)
    (h4 : Stored st 256 v4)
    (h5 : Stored st 288 v5)
    (h6 : Stored st 320 v6)
    (h7 : Stored st 352 v7)
    : result.digest = SszBlsComposition.pairDigest
        (SszBlsComposition.pairDigest
          (SszBlsComposition.pairDigest v0 v1) (SszBlsComposition.pairDigest v2 v3))
        (SszBlsComposition.pairDigest
          (SszBlsComposition.pairDigest v4 v5) (SszBlsComposition.pairDigest v6 v7)) ∧
      result.state.activeWords.toNat ≤ 20 ∧ result.state.executionEnv = st.executionEnv := by
  have free := stored_load st 64 _ hf (by omega) hw
  have low : 3 ≤ st.activeWords.toNat := by have := hf.2.2;omega
  obtain ⟨allocated0,alloc0,free0,bound0,env0,keep0⟩ := allocate_frame st 384 128 free (by omega) (by omega) (by omega) low hw
  unfold merkle at h
  dsimp only at h
  rw [alloc0] at h
  dsimp only [Except.mapError,bind,Except.bind] at h
  have cell0_128 := keep0 128 v0 h0 (by omega) (by omega)
  have cell0_160 := keep0 160 v1 h1 (by omega) (by omega)
  have cell0_192 := keep0 192 v2 h2 (by omega) (by omega)
  have cell0_224 := keep0 224 v3 h3 (by omega) (by omega)
  have cell0_256 := keep0 256 v4 h4 (by omega) (by omega)
  have cell0_288 := keep0 288 v5 h5 (by omega) (by omega)
  have cell0_320 := keep0 320 v6 h6 (by omega) (by omega)
  have cell0_352 := keep0 352 v7 h7 (by omega) (by omega)
  obtain ⟨a,ha,h⟩ := bind_success h
  have ⟨adigest,astored,abound,aenv,akeep⟩ := pairStore_effects fuel allocated0 128 160 384 (v0) (v1) a ha cell0_128 cell0_160 (by omega) (by omega) (by omega) bound0
  have aenvroot : a.state.executionEnv = st.executionEnv := aenv.trans (env0)
  have acell64 := akeep 64 (UInt256.ofNat 512) free0 (by omega) (by omega)
  have acell128 := akeep 128 (v0) cell0_128 (by omega) (by omega)
  have acell160 := akeep 160 (v1) cell0_160 (by omega) (by omega)
  have acell192 := akeep 192 (v2) cell0_192 (by omega) (by omega)
  have acell224 := akeep 224 (v3) cell0_224 (by omega) (by omega)
  have acell256 := akeep 256 (v4) cell0_256 (by omega) (by omega)
  have acell288 := akeep 288 (v5) cell0_288 (by omega) (by omega)
  have acell320 := akeep 320 (v6) cell0_320 (by omega) (by omega)
  have acell352 := akeep 352 (v7) cell0_352 (by omega) (by omega)
  obtain ⟨b,hb,h⟩ := bind_success h
  have ⟨bdigest,bstored,bbound,benv,bkeep⟩ := pairStore_effects fuel a.state 192 224 416 (v2) (v3) b hb acell192 acell224 (by omega) (by omega) (by omega) abound
  have benvroot : b.state.executionEnv = st.executionEnv := benv.trans (aenvroot)
  have bcell384 := bkeep 384 (a.digest) astored (by omega) (by omega)
  have bcell64 := bkeep 64 (UInt256.ofNat 512) acell64 (by omega) (by omega)
  have bcell128 := bkeep 128 (v0) acell128 (by omega) (by omega)
  have bcell160 := bkeep 160 (v1) acell160 (by omega) (by omega)
  have bcell192 := bkeep 192 (v2) acell192 (by omega) (by omega)
  have bcell224 := bkeep 224 (v3) acell224 (by omega) (by omega)
  have bcell256 := bkeep 256 (v4) acell256 (by omega) (by omega)
  have bcell288 := bkeep 288 (v5) acell288 (by omega) (by omega)
  have bcell320 := bkeep 320 (v6) acell320 (by omega) (by omega)
  have bcell352 := bkeep 352 (v7) acell352 (by omega) (by omega)
  obtain ⟨c,hc,h⟩ := bind_success h
  have ⟨cdigest,cstored,cbound,cenv,ckeep⟩ := pairStore_effects fuel b.state 256 288 448 (v4) (v5) c hc bcell256 bcell288 (by omega) (by omega) (by omega) bbound
  have cenvroot : c.state.executionEnv = st.executionEnv := cenv.trans (benvroot)
  have ccell416 := ckeep 416 (b.digest) bstored (by omega) (by omega)
  have ccell384 := ckeep 384 (a.digest) bcell384 (by omega) (by omega)
  have ccell64 := ckeep 64 (UInt256.ofNat 512) bcell64 (by omega) (by omega)
  have ccell128 := ckeep 128 (v0) bcell128 (by omega) (by omega)
  have ccell160 := ckeep 160 (v1) bcell160 (by omega) (by omega)
  have ccell192 := ckeep 192 (v2) bcell192 (by omega) (by omega)
  have ccell224 := ckeep 224 (v3) bcell224 (by omega) (by omega)
  have ccell256 := ckeep 256 (v4) bcell256 (by omega) (by omega)
  have ccell288 := ckeep 288 (v5) bcell288 (by omega) (by omega)
  have ccell320 := ckeep 320 (v6) bcell320 (by omega) (by omega)
  have ccell352 := ckeep 352 (v7) bcell352 (by omega) (by omega)
  obtain ⟨d,hd,h⟩ := bind_success h
  have ⟨ddigest,dstored,dbound,denv,dkeep⟩ := pairStore_effects fuel c.state 320 352 480 (v6) (v7) d hd ccell320 ccell352 (by omega) (by omega) (by omega) cbound
  have denvroot : d.state.executionEnv = st.executionEnv := denv.trans (cenvroot)
  have dcell448 := dkeep 448 (c.digest) cstored (by omega) (by omega)
  have dcell416 := dkeep 416 (b.digest) ccell416 (by omega) (by omega)
  have dcell384 := dkeep 384 (a.digest) ccell384 (by omega) (by omega)
  have dcell64 := dkeep 64 (UInt256.ofNat 512) ccell64 (by omega) (by omega)
  have dcell128 := dkeep 128 (v0) ccell128 (by omega) (by omega)
  have dcell160 := dkeep 160 (v1) ccell160 (by omega) (by omega)
  have dcell192 := dkeep 192 (v2) ccell192 (by omega) (by omega)
  have dcell224 := dkeep 224 (v3) ccell224 (by omega) (by omega)
  have dcell256 := dkeep 256 (v4) ccell256 (by omega) (by omega)
  have dcell288 := dkeep 288 (v5) ccell288 (by omega) (by omega)
  have dcell320 := dkeep 320 (v6) ccell320 (by omega) (by omega)
  have dcell352 := dkeep 352 (v7) ccell352 (by omega) (by omega)
  have free1 := stored_load d.state 64 _ dcell64 (by omega) dbound
  have low1 : 3 ≤ d.state.activeWords.toNat := by have := dcell64.2.2;omega
  obtain ⟨allocated1,alloc1,free2,bound1,env1,keep1⟩ := allocate_frame d.state 512 64 free1 (by omega) (by omega) (by omega) low1 dbound
  rw [alloc1] at h
  dsimp only [Except.mapError,bind,Except.bind] at h
  have cell1_480 := keep1 480 (d.digest) dstored (by omega) (by omega)
  have cell1_448 := keep1 448 (c.digest) dcell448 (by omega) (by omega)
  have cell1_416 := keep1 416 (b.digest) dcell416 (by omega) (by omega)
  have cell1_384 := keep1 384 (a.digest) dcell384 (by omega) (by omega)
  have cell1_128 := keep1 128 (v0) dcell128 (by omega) (by omega)
  have cell1_160 := keep1 160 (v1) dcell160 (by omega) (by omega)
  have cell1_192 := keep1 192 (v2) dcell192 (by omega) (by omega)
  have cell1_224 := keep1 224 (v3) dcell224 (by omega) (by omega)
  have cell1_256 := keep1 256 (v4) dcell256 (by omega) (by omega)
  have cell1_288 := keep1 288 (v5) dcell288 (by omega) (by omega)
  have cell1_320 := keep1 320 (v6) dcell320 (by omega) (by omega)
  have cell1_352 := keep1 352 (v7) dcell352 (by omega) (by omega)
  obtain ⟨e,he,h⟩ := bind_success h
  have ⟨edigest,estored,ebound,eenv,ekeep⟩ := pairStore_effects fuel allocated1 384 416 512 (a.digest) (b.digest) e he cell1_384 cell1_416 (by omega) (by omega) (by omega) bound1
  have eenvroot : e.state.executionEnv = st.executionEnv := eenv.trans (env1.trans denvroot)
  have ecell64 := ekeep 64 (UInt256.ofNat 576) free2 (by omega) (by omega)
  have ecell480 := ekeep 480 (d.digest) cell1_480 (by omega) (by omega)
  have ecell448 := ekeep 448 (c.digest) cell1_448 (by omega) (by omega)
  have ecell416 := ekeep 416 (b.digest) cell1_416 (by omega) (by omega)
  have ecell384 := ekeep 384 (a.digest) cell1_384 (by omega) (by omega)
  have ecell128 := ekeep 128 (v0) cell1_128 (by omega) (by omega)
  have ecell160 := ekeep 160 (v1) cell1_160 (by omega) (by omega)
  have ecell192 := ekeep 192 (v2) cell1_192 (by omega) (by omega)
  have ecell224 := ekeep 224 (v3) cell1_224 (by omega) (by omega)
  have ecell256 := ekeep 256 (v4) cell1_256 (by omega) (by omega)
  have ecell288 := ekeep 288 (v5) cell1_288 (by omega) (by omega)
  have ecell320 := ekeep 320 (v6) cell1_320 (by omega) (by omega)
  have ecell352 := ekeep 352 (v7) cell1_352 (by omega) (by omega)
  obtain ⟨f,hf,h⟩ := bind_success h
  have ⟨fdigest,fstored,fbound,fenv,fkeep⟩ := pairStore_effects fuel e.state 448 480 544 (c.digest) (d.digest) f hf ecell448 ecell480 (by omega) (by omega) (by omega) ebound
  have fenvroot : f.state.executionEnv = st.executionEnv := fenv.trans (eenvroot)
  have fcell512 := fkeep 512 (e.digest) estored (by omega) (by omega)
  have fcell64 := fkeep 64 (UInt256.ofNat 576) ecell64 (by omega) (by omega)
  have fcell480 := fkeep 480 (d.digest) ecell480 (by omega) (by omega)
  have fcell448 := fkeep 448 (c.digest) ecell448 (by omega) (by omega)
  have fcell416 := fkeep 416 (b.digest) ecell416 (by omega) (by omega)
  have fcell384 := fkeep 384 (a.digest) ecell384 (by omega) (by omega)
  have fcell128 := fkeep 128 (v0) ecell128 (by omega) (by omega)
  have fcell160 := fkeep 160 (v1) ecell160 (by omega) (by omega)
  have fcell192 := fkeep 192 (v2) ecell192 (by omega) (by omega)
  have fcell224 := fkeep 224 (v3) ecell224 (by omega) (by omega)
  have fcell256 := fkeep 256 (v4) ecell256 (by omega) (by omega)
  have fcell288 := fkeep 288 (v5) ecell288 (by omega) (by omega)
  have fcell320 := fkeep 320 (v6) ecell320 (by omega) (by omega)
  have fcell352 := fkeep 352 (v7) ecell352 (by omega) (by omega)
  have leftValue := stored_load f.state 512 e.digest fcell512 (by omega) fbound
  have finalBound := load_bounded f.state 512 (by omega) fbound
  have finalCall := map_success SszCompiledConsumer.Error.bls _ _ h
  change SszBlsComposition.pairRun fuel (load f.state 512).2 (load f.state 512).1 f.digest = .ok result at finalCall
  rw [leftValue] at finalCall
  have finalDigest := SszShaCommitted.pair_success_digest fuel (load f.state 512).2 e.digest f.digest result finalCall (by omega)
  have finalWords := SszShaCommitted.pair_success_words fuel (load f.state 512).2 e.digest f.digest result finalCall
  have finalEnv := SszWitnessAbi.pair_environment fuel (load f.state 512).2 e.digest f.digest result finalCall
  refine ⟨?_,by rw [finalWords];omega,finalEnv.trans fenvroot⟩
  rw [finalDigest,edigest,fdigest,adigest,bdigest,cdigest,ddigest]

theorem read64_store (st : EVM.State) (dest : Nat) (value offset : UInt256) :
    SszWitnessAbi.read64 (store st dest value) offset = SszWitnessAbi.read64 st offset := rfl

theorem readBool_store (st : EVM.State) (dest : Nat) (value offset : UInt256) :
    SszWitnessAbi.readBool (store st dest value) offset = SszWitnessAbi.readBool st offset := rfl

theorem calldata_store (st : EVM.State) (dest : Nat) (value offset : UInt256) :
    (store st dest value).calldataload offset = st.calldataload offset := rfl

/-- Source field guards and stores derive the complete array consumed by the
memory-based Merkle execution. No array content is supplied as its output. -/
theorem fields_effects (st afterState : EVM.State) (head key : UInt256)
    (h : storeFields st head (UInt256.ofNat 128) = .ok afterState)
    (hk : Stored st 128 key) (hf : Stored st 64 (UInt256.ofNat 384))
    (hw : st.activeWords.toNat ≤ 20) :
    ∃ f, SszWitnessAbi.FieldsMatch st head f ∧
      Stored afterState 64 (UInt256.ofNat 384) ∧ Stored afterState 128 key ∧
      Stored afterState 160 (st.calldataload (UInt256.ofNat 36)) ∧
      Stored afterState 192 (SszBlsComposition.chunk f.effectiveBalance) ∧
      Stored afterState 224 (SszBlsComposition.chunk (if f.slashed then 1 else 0)) ∧
      Stored afterState 256 (SszBlsComposition.chunk f.activationEligibilityEpoch) ∧
      Stored afterState 288 (SszBlsComposition.chunk f.activationEpoch) ∧
      Stored afterState 320 (SszBlsComposition.chunk f.exitEpoch) ∧
      Stored afterState 352 (SszBlsComposition.chunk f.withdrawableEpoch) ∧
      afterState.activeWords.toNat ≤ 20 ∧ afterState.executionEnv = st.executionEnv := by
  unfold storeFields at h
  dsimp only at h
  simp only [read64_store,readBool_store] at h
  obtain ⟨balance,hbalance,h⟩ := bind_success h
  have cbalance := map_success SszCompiledConsumer.Error.abi _ _ hbalance
  obtain ⟨slashed,hslashed,h⟩ := bind_success h
  have cslashed := map_success SszCompiledConsumer.Error.abi _ _ hslashed
  obtain ⟨eligible,heligible,h⟩ := bind_success h
  have celigible := map_success SszCompiledConsumer.Error.abi _ _ heligible
  obtain ⟨active,hactive,h⟩ := bind_success h
  have cactive := map_success SszCompiledConsumer.Error.abi _ _ hactive
  obtain ⟨exited,hexited,h⟩ := bind_success h
  have cexited := map_success SszCompiledConsumer.Error.abi _ _ hexited
  obtain ⟨withdrawable,hwithdrawable,h⟩ := bind_success h
  have cwithdrawable := map_success SszCompiledConsumer.Error.abi _ _ hwithdrawable
  change Except.ok _ = Except.ok afterState at h
  cases h
  let f : SszBlsComposition.Fields := ⟨balance,slashed,eligible,active,exited,withdrawable⟩
  have decoded : SszWitnessAbi.fields st head = .ok f := by
    simp only [SszWitnessAbi.fields,cbalance,cslashed,celigible,cactive,cexited,cwithdrawable]
    rfl
  have fm := SszWitnessAbi.fields_success st head f decoded
  let st0 := store st 160 (st.calldataload (UInt256.ofNat 36))
  have bound0 : st0.activeWords.toNat ≤ 20 := store_bounded st 160 (st.calldataload (UInt256.ofNat 36)) (by omega) hw
  have written0 : Stored st0 160 (st.calldataload (UInt256.ofNat 36)) := stored_written st 160 (st.calldataload (UInt256.ofNat 36)) (by omega)
  have s0cell64 : Stored st0 64 (UInt256.ofNat 384) := stored_preserved st 160 64 (st.calldataload (UInt256.ofNat 36)) (UInt256.ofNat 384) hf (by omega) (by omega)
  have s0cell128 : Stored st0 128 (key) := stored_preserved st 160 128 (st.calldataload (UInt256.ofNat 36)) (key) hk (by omega) (by omega)
  let st1 := store st0 192 (SszBlsComposition.chunk balance)
  have bound1 : st1.activeWords.toNat ≤ 20 := store_bounded st0 192 (SszBlsComposition.chunk balance) (by omega) bound0
  have written1 : Stored st1 192 (SszBlsComposition.chunk balance) := stored_written st0 192 (SszBlsComposition.chunk balance) (by omega)
  have s1cell160 : Stored st1 160 (st.calldataload (UInt256.ofNat 36)) := stored_preserved st0 192 160 (SszBlsComposition.chunk balance) (st.calldataload (UInt256.ofNat 36)) written0 (by omega) (by omega)
  have s1cell64 : Stored st1 64 (UInt256.ofNat 384) := stored_preserved st0 192 64 (SszBlsComposition.chunk balance) (UInt256.ofNat 384) s0cell64 (by omega) (by omega)
  have s1cell128 : Stored st1 128 (key) := stored_preserved st0 192 128 (SszBlsComposition.chunk balance) (key) s0cell128 (by omega) (by omega)
  let st2 := store st1 224 (SszBlsComposition.chunk (if slashed then 1 else 0))
  have bound2 : st2.activeWords.toNat ≤ 20 := store_bounded st1 224 (SszBlsComposition.chunk (if slashed then 1 else 0)) (by omega) bound1
  have written2 : Stored st2 224 (SszBlsComposition.chunk (if slashed then 1 else 0)) := stored_written st1 224 (SszBlsComposition.chunk (if slashed then 1 else 0)) (by omega)
  have s2cell192 : Stored st2 192 (SszBlsComposition.chunk balance) := stored_preserved st1 224 192 (SszBlsComposition.chunk (if slashed then 1 else 0)) (SszBlsComposition.chunk balance) written1 (by omega) (by omega)
  have s2cell160 : Stored st2 160 (st.calldataload (UInt256.ofNat 36)) := stored_preserved st1 224 160 (SszBlsComposition.chunk (if slashed then 1 else 0)) (st.calldataload (UInt256.ofNat 36)) s1cell160 (by omega) (by omega)
  have s2cell64 : Stored st2 64 (UInt256.ofNat 384) := stored_preserved st1 224 64 (SszBlsComposition.chunk (if slashed then 1 else 0)) (UInt256.ofNat 384) s1cell64 (by omega) (by omega)
  have s2cell128 : Stored st2 128 (key) := stored_preserved st1 224 128 (SszBlsComposition.chunk (if slashed then 1 else 0)) (key) s1cell128 (by omega) (by omega)
  let st3 := store st2 256 (SszBlsComposition.chunk eligible)
  have bound3 : st3.activeWords.toNat ≤ 20 := store_bounded st2 256 (SszBlsComposition.chunk eligible) (by omega) bound2
  have written3 : Stored st3 256 (SszBlsComposition.chunk eligible) := stored_written st2 256 (SszBlsComposition.chunk eligible) (by omega)
  have s3cell224 : Stored st3 224 (SszBlsComposition.chunk (if slashed then 1 else 0)) := stored_preserved st2 256 224 (SszBlsComposition.chunk eligible) (SszBlsComposition.chunk (if slashed then 1 else 0)) written2 (by omega) (by omega)
  have s3cell192 : Stored st3 192 (SszBlsComposition.chunk balance) := stored_preserved st2 256 192 (SszBlsComposition.chunk eligible) (SszBlsComposition.chunk balance) s2cell192 (by omega) (by omega)
  have s3cell160 : Stored st3 160 (st.calldataload (UInt256.ofNat 36)) := stored_preserved st2 256 160 (SszBlsComposition.chunk eligible) (st.calldataload (UInt256.ofNat 36)) s2cell160 (by omega) (by omega)
  have s3cell64 : Stored st3 64 (UInt256.ofNat 384) := stored_preserved st2 256 64 (SszBlsComposition.chunk eligible) (UInt256.ofNat 384) s2cell64 (by omega) (by omega)
  have s3cell128 : Stored st3 128 (key) := stored_preserved st2 256 128 (SszBlsComposition.chunk eligible) (key) s2cell128 (by omega) (by omega)
  let st4 := store st3 288 (SszBlsComposition.chunk active)
  have bound4 : st4.activeWords.toNat ≤ 20 := store_bounded st3 288 (SszBlsComposition.chunk active) (by omega) bound3
  have written4 : Stored st4 288 (SszBlsComposition.chunk active) := stored_written st3 288 (SszBlsComposition.chunk active) (by omega)
  have s4cell256 : Stored st4 256 (SszBlsComposition.chunk eligible) := stored_preserved st3 288 256 (SszBlsComposition.chunk active) (SszBlsComposition.chunk eligible) written3 (by omega) (by omega)
  have s4cell224 : Stored st4 224 (SszBlsComposition.chunk (if slashed then 1 else 0)) := stored_preserved st3 288 224 (SszBlsComposition.chunk active) (SszBlsComposition.chunk (if slashed then 1 else 0)) s3cell224 (by omega) (by omega)
  have s4cell192 : Stored st4 192 (SszBlsComposition.chunk balance) := stored_preserved st3 288 192 (SszBlsComposition.chunk active) (SszBlsComposition.chunk balance) s3cell192 (by omega) (by omega)
  have s4cell160 : Stored st4 160 (st.calldataload (UInt256.ofNat 36)) := stored_preserved st3 288 160 (SszBlsComposition.chunk active) (st.calldataload (UInt256.ofNat 36)) s3cell160 (by omega) (by omega)
  have s4cell64 : Stored st4 64 (UInt256.ofNat 384) := stored_preserved st3 288 64 (SszBlsComposition.chunk active) (UInt256.ofNat 384) s3cell64 (by omega) (by omega)
  have s4cell128 : Stored st4 128 (key) := stored_preserved st3 288 128 (SszBlsComposition.chunk active) (key) s3cell128 (by omega) (by omega)
  let st5 := store st4 320 (SszBlsComposition.chunk exited)
  have bound5 : st5.activeWords.toNat ≤ 20 := store_bounded st4 320 (SszBlsComposition.chunk exited) (by omega) bound4
  have written5 : Stored st5 320 (SszBlsComposition.chunk exited) := stored_written st4 320 (SszBlsComposition.chunk exited) (by omega)
  have s5cell288 : Stored st5 288 (SszBlsComposition.chunk active) := stored_preserved st4 320 288 (SszBlsComposition.chunk exited) (SszBlsComposition.chunk active) written4 (by omega) (by omega)
  have s5cell256 : Stored st5 256 (SszBlsComposition.chunk eligible) := stored_preserved st4 320 256 (SszBlsComposition.chunk exited) (SszBlsComposition.chunk eligible) s4cell256 (by omega) (by omega)
  have s5cell224 : Stored st5 224 (SszBlsComposition.chunk (if slashed then 1 else 0)) := stored_preserved st4 320 224 (SszBlsComposition.chunk exited) (SszBlsComposition.chunk (if slashed then 1 else 0)) s4cell224 (by omega) (by omega)
  have s5cell192 : Stored st5 192 (SszBlsComposition.chunk balance) := stored_preserved st4 320 192 (SszBlsComposition.chunk exited) (SszBlsComposition.chunk balance) s4cell192 (by omega) (by omega)
  have s5cell160 : Stored st5 160 (st.calldataload (UInt256.ofNat 36)) := stored_preserved st4 320 160 (SszBlsComposition.chunk exited) (st.calldataload (UInt256.ofNat 36)) s4cell160 (by omega) (by omega)
  have s5cell64 : Stored st5 64 (UInt256.ofNat 384) := stored_preserved st4 320 64 (SszBlsComposition.chunk exited) (UInt256.ofNat 384) s4cell64 (by omega) (by omega)
  have s5cell128 : Stored st5 128 (key) := stored_preserved st4 320 128 (SszBlsComposition.chunk exited) (key) s4cell128 (by omega) (by omega)
  let st6 := store st5 352 (SszBlsComposition.chunk withdrawable)
  have bound6 : st6.activeWords.toNat ≤ 20 := store_bounded st5 352 (SszBlsComposition.chunk withdrawable) (by omega) bound5
  have written6 : Stored st6 352 (SszBlsComposition.chunk withdrawable) := stored_written st5 352 (SszBlsComposition.chunk withdrawable) (by omega)
  have s6cell320 : Stored st6 320 (SszBlsComposition.chunk exited) := stored_preserved st5 352 320 (SszBlsComposition.chunk withdrawable) (SszBlsComposition.chunk exited) written5 (by omega) (by omega)
  have s6cell288 : Stored st6 288 (SszBlsComposition.chunk active) := stored_preserved st5 352 288 (SszBlsComposition.chunk withdrawable) (SszBlsComposition.chunk active) s5cell288 (by omega) (by omega)
  have s6cell256 : Stored st6 256 (SszBlsComposition.chunk eligible) := stored_preserved st5 352 256 (SszBlsComposition.chunk withdrawable) (SszBlsComposition.chunk eligible) s5cell256 (by omega) (by omega)
  have s6cell224 : Stored st6 224 (SszBlsComposition.chunk (if slashed then 1 else 0)) := stored_preserved st5 352 224 (SszBlsComposition.chunk withdrawable) (SszBlsComposition.chunk (if slashed then 1 else 0)) s5cell224 (by omega) (by omega)
  have s6cell192 : Stored st6 192 (SszBlsComposition.chunk balance) := stored_preserved st5 352 192 (SszBlsComposition.chunk withdrawable) (SszBlsComposition.chunk balance) s5cell192 (by omega) (by omega)
  have s6cell160 : Stored st6 160 (st.calldataload (UInt256.ofNat 36)) := stored_preserved st5 352 160 (SszBlsComposition.chunk withdrawable) (st.calldataload (UInt256.ofNat 36)) s5cell160 (by omega) (by omega)
  have s6cell64 : Stored st6 64 (UInt256.ofNat 384) := stored_preserved st5 352 64 (SszBlsComposition.chunk withdrawable) (UInt256.ofNat 384) s5cell64 (by omega) (by omega)
  have s6cell128 : Stored st6 128 (key) := stored_preserved st5 352 128 (SszBlsComposition.chunk withdrawable) (key) s5cell128 (by omega) (by omega)
  exact ⟨f,fm,s6cell64,s6cell128,s6cell160,s6cell192,s6cell224,s6cell256,s6cell288,s6cell320,written6,bound6,rfl⟩

/-- The first allocation and actual key CALL establish memory and value
facts from the engine's fresh frame; no initial memory bound is assumed. -/
theorem begin_values (fuel : Nat) (context : EVM.State) (b : Beginning)
    (h : begin fuel context = .ok b) :
    b.leaves = UInt256.ofNat 128 ∧ b.key.state.activeWords.toNat = 12 ∧
    b.key.state.executionEnv = context.executionEnv ∧
    Stored b.key.state 64 (UInt256.ofNat 384) ∧
    ∃ slice, SszWitnessAbi.header context = .ok b.head ∧
      SszWitnessAbi.tail context b.head (UInt256.ofNat 36) 1 = .ok slice ∧
      slice.length = 48 ∧ b.key.digest = SszPubkeyBytes.pubkeyDigest context slice.offset := by
  obtain ⟨allocated,ha,hfree,hw,he,hs,hread⟩ := allocate_effects (prologue context) 128 256
    (prologue_free_pointer context) (by omega) (by omega) (by omega)
    (by rw [prologue_words]) (by rw [prologue_words];omega)
  have hwa : allocated.activeWords.toNat = 12 := by rw [hw,prologue_words];decide +kernel
  have hea : allocated.executionEnv = context.executionEnv := he.trans (prologue_environment context)
  unfold begin at h
  dsimp only at h
  obtain ⟨head,hhead,h⟩ := bind_success h
  have header := map_success SszCompiledConsumer.Error.abi _ _ hhead
  change SszWitnessAbi.header context = .ok head at header
  rw [ha] at h
  dsimp only [Except.mapError,bind,Except.bind] at h
  obtain ⟨slice,htail,h⟩ := bind_success h
  have tail := map_success SszCompiledConsumer.Error.abi _ _ htail
  obtain ⟨key,hkey,h⟩ := bind_success h
  have call := map_success SszCompiledConsumer.Error.bls _ _ hkey
  change Except.ok (Beginning.mk head (UInt256.ofNat 128) key) = Except.ok b at h
  cases h
  have words := SszShaCommitted.pubkey_success_words fuel allocated slice.offset slice.length key call
  have env := SszWitnessAbi.pubkey_environment fuel allocated slice.offset slice.length key call
  have memory := pubkey_memory fuel allocated slice.offset slice.length key call hs
  have digest := SszPubkeyBytes.pubkey_success_digest fuel allocated slice.offset slice.length key call (by rw [hwa];omega)
  refine ⟨rfl,by rw [words,hwa];decide +kernel,env.trans hea,
    ⟨Nat.le_trans hs memory.2,memory.1.trans hread,by rw [words,hwa];decide +kernel⟩,slice,header,?_,digest.2.2,?_⟩
  · simpa only [SszWitnessAbi.tail,EvmYul.State.calldataload,hea] using tail
  · simpa only [SszPubkeyBytes.pubkeyDigest,hea] using digest.1

/-- The initialized memory consumer computes the typed validator leaf and
passes that leaf and the original input's root/index to the actual verifier.
All memory bounds are derived from initialization, allocations and transitions. -/
theorem run_computed_leaf (fuel : Nat) (context afterState : EVM.State)
    (h : SszCompiledConsumer.run fuel context = .ok afterState) :
    ∃ head keySlice f, ∃ (leaf : SszBlsComposition.Result), ∃ branch,
      SszWitnessAbi.header context = .ok head ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 36) 1 = .ok keySlice ∧
      keySlice.length = 48 ∧ SszWitnessAbi.FieldsMatch context head f ∧
      leaf.digest = SszProofCommitted.validatorLeaf context keySlice.offset f ∧
      leaf.state.executionEnv = context.executionEnv ∧ leaf.state.activeWords.toNat ≤ 20 ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 4) 32 = .ok branch ∧
      SszProofCalldataLoop.verify fuel leaf.state
        (context.calldataload (UInt256.ofNat 100)) leaf.digest
        (context.calldataload (UInt256.ofNat 68)) branch.offset branch.length = .ok afterState := by
  unfold SszCompiledConsumer.run at h
  obtain ⟨b,hb,h⟩ := bind_success h
  obtain ⟨ptr,words,env,free,slice,header,tail,len,key⟩ := begin_values fuel context b hb
  rw [ptr] at h
  dsimp only at h
  obtain ⟨stored,hs,h⟩ := bind_success h
  let keyed := store b.key.state 128 b.key.digest
  have hk : Stored keyed 128 b.key.digest := stored_written _ _ _ (by omega)
  have hf : Stored keyed 64 (UInt256.ofNat 384) := stored_preserved _ _ _ _ _ free (by omega) (by omega)
  have hw : keyed.activeWords.toNat ≤ 20 := store_bounded _ _ _ (by omega) (by rw [words];omega)
  obtain ⟨f,fields,free1,v0,v1,v2,v3,v4,v5,v6,v7,ws,es⟩ := fields_effects keyed stored b.head b.key.digest hs hk hf hw
  obtain ⟨leaf,hl,h⟩ := bind_success h
  obtain ⟨digest,wl,el⟩ := merkle_effects fuel stored b.key.digest
    (keyed.calldataload (UInt256.ofNat 36)) _ _ _ _ _ _ leaf hl free1 ws v0 v1 v2 v3 v4 v5 v6 v7
  have es0 : stored.executionEnv = context.executionEnv := es.trans env
  have el0 : leaf.state.executionEnv = context.executionEnv := el.trans es0
  have typed : leaf.digest = SszProofCommitted.validatorLeaf context slice.offset f := by
    change leaf.digest = SszBlsComposition.merkleDigest b.key.digest
      (keyed.calldataload (UInt256.ofNat 36)) _ _ _ _ _ _ at digest
    rw [key] at digest
    simpa only [EvmYul.State.calldataload,show keyed.executionEnv = context.executionEnv from env,
      SszPubkeyBytes.computed_leaf_typed,SszProofCommitted.validatorLeaf] using digest
  obtain ⟨branch,hp,h⟩ := bind_success h
  have hp0 := map_success SszCompiledConsumer.Error.abi _ _ hp
  have verify := map_success SszCompiledConsumer.Error.proof _ _ h
  have fm : SszWitnessAbi.FieldsMatch context b.head f := by
    rcases fields with ⟨a,b,c,d,e,g⟩
    constructor
    · simpa only [EvmYul.State.calldataload,show keyed.executionEnv = context.executionEnv from env] using a
    · simpa only [EvmYul.State.calldataload,show keyed.executionEnv = context.executionEnv from env] using b
    · simpa only [EvmYul.State.calldataload,show keyed.executionEnv = context.executionEnv from env] using c
    · simpa only [EvmYul.State.calldataload,show keyed.executionEnv = context.executionEnv from env] using d
    · simpa only [EvmYul.State.calldataload,show keyed.executionEnv = context.executionEnv from env] using e
    · simpa only [EvmYul.State.calldataload,show keyed.executionEnv = context.executionEnv from env] using g
  refine ⟨b.head,slice,f,leaf,branch,header,tail,len,fm,typed,el0,wl,?_,?_⟩
  · simpa only [SszWitnessAbi.tail,EvmYul.State.calldataload,el0] using hp0
  · simpa only [EvmYul.State.calldataload,el0] using verify

/-- Successful initialized memory execution binds the actual consumed branch
to the typed leaf and original root. The SHA-width boundary is inherited; no
initial-memory, successful-substage, gas, depth or stored-cell premise remains. -/
theorem run_success_branch (fuel : Nat) (context afterState : EVM.State)
    (h : SszCompiledConsumer.run fuel context = .ok afterState)
    (hffi : SszProofCommitted.ShaWidth) :
    ∃ head keySlice f branch,
      SszWitnessAbi.header context = .ok head ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 36) 1 = .ok keySlice ∧
      keySlice.length = 48 ∧ SszWitnessAbi.FieldsMatch context head f ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 4) 32 = .ok branch ∧
      branch.length ≤ 2^64-1 ∧
      let words := SszProofCommitted.proofWords branch.length context.executionEnv.calldata
        branch.offset (SszProofCommitted.endOffset branch.offset branch.length)
      words ≠ [] ∧
      SszProofFold.Branch SszProofCalldataStep.ffiPair
        (SszProofCalldataStep.decodeIndex (context.calldataload (UInt256.ofNat 100))).toNat
        (SszProofCommitted.validatorLeaf context keySlice.offset f) words
        (context.calldataload (UInt256.ofNat 68)) ∧
      afterState.executionEnv = context.executionEnv ∧ afterState.activeWords.toNat ≤ 20 := by
  obtain ⟨head,keySlice,f,leaf,branch,header,tail,len,fields,digest,env,width,proofTail,verify⟩ :=
    run_computed_leaf fuel context afterState h
  obtain ⟨nonempty,bound,envAfter,widthAfter⟩ := SszProofCommitted.verify_success_branch
    fuel branch.length leaf.state afterState (context.calldataload (UInt256.ofNat 100))
    leaf.digest (context.calldataload (UInt256.ofNat 68)) branch.offset verify hffi (by omega)
  rw [env] at nonempty bound
  rw [digest] at bound
  refine ⟨head,keySlice,f,branch,header,tail,len,fields,proofTail,
    SszWitnessAbi.tail_success_length _ _ _ _ _ proofTail,nonempty,bound,envAfter.trans env,?_⟩
  rw [widthAfter]
  omega

#print axioms run_success_branch
#print axioms run_computed_leaf
#print axioms begin_values
#print axioms fields_effects
#print axioms merkle_effects
#print axioms allocate_frame
#print axioms pairStore_effects
end LidoSRv3.Audit.Source.SszCompiledMerkle
