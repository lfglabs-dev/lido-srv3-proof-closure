import LidoSRv3.Audit.Source.SszCompiledMerkle

/-! Pointer-parametric frame lemmas for the compiled CL entry. The existing
initialized-harness lemmas (SszCompiledMemory / SszCompiledMerkle) are stated
for the fixed leaf pointer 128 inside a 576-byte frame. In the CL entry the
leaf array follows the variable-length EIP-4788 reply allocation, so the same
allocator, store, load and pair-call facts are restated for any cell below the
allocator's own uint64 guard, carrying the engine's active-word extent as a
bound below 2^64. Every executable consumed here is the existing one
(`store`, `load`, `allocate`, `pairStore`, `merkle`); no memory interpreter is
introduced, and the fixed-frame lemmas remain untouched. -/
namespace LidoSRv3.Audit.Source.SszCompiledFrame
open EvmYul EvmYul.EVM SszWordBytes SszScratchByteArray SszCompiledMemory SszCompiledMerkle

theorem word_nat (n : Nat) (h : n < 2 ^ 64) : (UInt256.ofNat n).toNat = n :=
  Nat.mod_eq_of_lt (by unfold UInt256.size; omega)

theorem ofNat_add (a b : Nat) (h : a + b < UInt256.size) :
    UInt256.ofNat a + UInt256.ofNat b = UInt256.ofNat (a + b) := by
  apply congrArg UInt256.mk
  apply Fin.ext
  change (a % UInt256.size + b % UInt256.size) % UInt256.size = (a + b) % UInt256.size
  rw [Nat.mod_eq_of_lt (show a < UInt256.size by omega),
    Nat.mod_eq_of_lt (show b < UInt256.size by omega)]

theorem small_add (a b : Nat) (h : a + b < 2 ^ 64) :
    UInt256.ofNat a + UInt256.ofNat b = UInt256.ofNat (a + b) :=
  ofNat_add a b (by unfold UInt256.size; omega)

private theorem bind_success {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β} (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error e => cases h
  | ok x => exact ⟨x, rfl, h⟩

private theorem map_success {ε ε' α : Type} (f : ε → ε') (step : Except ε α)
    (value : α) (h : step.mapError f = .ok value) : step = .ok value := by
  cases step with
  | error e => cases h
  | ok x => cases h; rfl

/-! ## Byte-array writes with bounded padding -/

/-- Exact write normal form when the destination lies at most 576 bytes past the
current array end; the destination address itself is unbounded. -/
theorem write_fit (src dest : ByteArray) (s d n : Nat)
    (hn : 0 < n) (hfit : s + n ≤ src.size) (hd : d ≤ dest.size + 576) :
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
    (hoffset : offset ≤ old.size + 576) :
    (word.toByteArray.write 0 old offset 32).data =
      (old.data.extract 0 offset ++ Array.replicate (offset - old.size) 0) ++
      word.toByteArray.data ++ old.data.extract (offset + 32) old.size := by
  rw [write_fit _ _ 0 offset 32 (by omega) (by rw [actual_word_size]) hoffset]
  have hs : word.toByteArray.data.size = 32 := actual_word_size word
  simp only [Nat.zero_add, ← hs, Array.extract_size]

theorem write_word_read (old : ByteArray) (offset : Nat) (word : UInt256)
    (hoffset : offset ≤ old.size + 576) :
    (word.toByteArray.write 0 old offset 32).readWithPadding offset 32 = word.toByteArray := by
  have hs : word.toByteArray.data.size = 32 := actual_word_size word
  have hp : (old.data.extract 0 offset ++ Array.replicate (offset - old.size) 0).size = offset := by
    simp
    omega
  have hm := write_word_shape old offset word hoffset
  have hsize : offset + 32 ≤ (word.toByteArray.write 0 old offset 32).size := by
    change offset + 32 ≤ (word.toByteArray.write 0 old offset 32).data.size
    rw [hm]
    simp only [Array.size_append, hp, hs]
    omega
  rw [SszShaCallBytes.read_fit _ offset 32 hsize (by omega)]
  apply ByteArray.ext
  rw [ByteArray.data_extract, hm]
  generalize hpre : old.data.extract 0 offset ++ Array.replicate (offset - old.size) 0 = preceding at hp ⊢
  generalize htail : old.data.extract (offset + 32) old.size = suffix
  simp only [Array.extract_append, Array.size_append, hp, hs]
  simp only [Nat.sub_self, Nat.add_sub_cancel_left]
  rw [Array.extract_empty_of_size_le_start (by omega : preceding.size ≤ offset), Array.empty_append]
  rw [Array.extract_empty_of_stop_le_start (Nat.zero_le _), Array.append_empty]
  have he := Array.extract_size (xs := word.toByteArray.data)
  rw [hs] at he
  exact he

/-- A store past the current array end pads the gap with zeros: any whole word
strictly inside the gap reads back as the zero word. -/
theorem write_pad_read (old : ByteArray) (dest offset : Nat) (word : UInt256)
    (hdm : dest ≤ old.size + 576) (hlow : old.size ≤ offset) (hhigh : offset + 32 ≤ dest) :
    (word.toByteArray.write 0 old dest 32).readWithPadding offset 32 = zeros 32 := by
  have hsrc : ¬ (0 ≥ word.toByteArray.size) := by rw [actual_word_size]; omega
  have hp : min 32 (word.toByteArray.size - 0) = 32 := by rw [actual_word_size]; omega
  have hz : min old.size (dest + 32) - (dest + 32) = 0 := by omega
  have hpad : dest - old.size ≤ 576 := by omega
  unfold ByteArray.write
  simp only [(by decide : ¬ (32 = 0)), ↓reduceIte, hsrc, hp, hz, ffi_zeros_bounded 0 (by omega),
    ffi_zeros_bounded _ hpad, append_zeros_zero, Nat.add_zero]
  have hsz : offset + 32 ≤
      (word.toByteArray.copySlice 0 (old ++ zeros (dest - old.size)) dest 32).size := by
    refine Nat.le_trans ?_ (copy_size_mono _ _ _ _ _)
    simp only [ByteArray.size_append, zeros_size]
    omega
  rw [SszShaCallBytes.read_fit _ offset 32 hsz (by omega)]
  rw [extract_copy_before word.toByteArray (old ++ zeros (dest - old.size)) 0 dest 32 offset (offset + 32)
    hhigh (by simp only [ByteArray.size_append, zeros_size]; omega)]
  rw [show offset = old.size + (offset - old.size) by omega,
    show old.size + (offset - old.size) + 32 = old.size + (offset - old.size + 32) by omega,
    ByteArray.extract_append_size_add]
  apply ByteArray.ext
  simp only [ByteArray.data_extract, zeros, Array.extract_replicate]
  congr 1
  omega

/-! ## Machine operations at arbitrary small cells -/

theorem store_words (machine : MachineState) (offset : Nat) (word : UInt256)
    (hoffset : offset < 2 ^ 64) :
    (machine.mstore (UInt256.ofNat offset) word).activeWords.toNat =
      max machine.activeWords.toNat ((offset + 63) / 32) := by
  have ho : (UInt256.ofNat offset).toNat = offset := word_nat offset hoffset
  simp only [MachineState.mstore, MachineState.M, ho]
  change max machine.activeWords.toNat ((offset + 32 + 31) / 32) % UInt256.size = _
  rw [Nat.mod_eq_of_lt]
  have hf : machine.activeWords.toNat < UInt256.size := machine.activeWords.val.isLt
  unfold UInt256.size at *
  omega

theorem load_words (machine : MachineState) (offset : Nat) (hoffset : offset < 2 ^ 64) :
    (machine.mload (UInt256.ofNat offset)).2.activeWords.toNat =
      max machine.activeWords.toNat ((offset + 63) / 32) := by
  have ho : (UInt256.ofNat offset).toNat = offset := word_nat offset hoffset
  simp only [MachineState.mload, MachineState.M, ho]
  change max machine.activeWords.toNat ((offset + 32 + 31) / 32) % UInt256.size = _
  rw [Nat.mod_eq_of_lt]
  have hf : machine.activeWords.toNat < UInt256.size := machine.activeWords.val.isLt
  unfold UInt256.size at *
  omega

theorem store_size (machine : MachineState) (offset : Nat) (word : UInt256)
    (hoffset : offset < 2 ^ 64) (hmem : offset ≤ machine.memory.size + 576) :
    offset + 32 ≤ (machine.mstore (UInt256.ofNat offset) word).memory.size := by
  have ho : (UInt256.ofNat offset).toNat = offset := word_nat offset hoffset
  change offset + 32 ≤ (word.toByteArray.write 0 machine.memory (UInt256.ofNat offset).toNat 32).size
  rw [ho]
  change offset + 32 ≤ (word.toByteArray.write 0 machine.memory offset 32).data.size
  rw [write_word_shape _ _ _ hmem]
  simp only [Array.size_append, Array.size_extract, Array.size_replicate, ByteArray.size_data,
    actual_word_size]
  omega

theorem mload_of_read (machine : MachineState) (offset : Nat) (word : UInt256)
    (hoffset : offset < 2 ^ 64) (hsize : offset + 32 ≤ machine.memory.size)
    (hread : machine.memory.readWithPadding offset 32 = word.toByteArray)
    (hpos : offset < machine.activeWords.toNat * 32)
    (hwidth : machine.activeWords.toNat < 2 ^ 251) :
    (machine.mload (UInt256.ofNat offset)).1 = word := by
  have ho : (UInt256.ofNat offset).toNat = offset := word_nat offset hoffset
  have hx : ¬ UInt256.ofNat offset ≥ machine.activeWords * (UInt256.ofNat 32) := by
    change ¬ (UInt256.ofNat offset).toNat ≥ machine.activeWords.toNat * 32 % UInt256.size
    rw [ho, Nat.mod_eq_of_lt (by unfold UInt256.size; omega)]
    omega
  have h32 : (⟨32⟩ : UInt256) = UInt256.ofNat 32 := by decide +kernel
  simp only [MachineState.mload, MachineState.lookupMemory, ho, h32]
  rw [if_neg (by exact not_or.mpr ⟨by omega, hx⟩), hread, actual_memory_decode]
  apply congrArg UInt256.mk
  apply Fin.ext
  exact Nat.mod_eq_of_lt word.val.isLt

theorem store_read_before (st : EVM.State) (dest offset : Nat) (word : UInt256)
    (hd : dest < 2 ^ 64) (ho : offset + 32 ≤ dest) (hs : offset + 32 ≤ st.memory.size) :
    (store st dest word).memory.readWithPadding offset 32 = st.memory.readWithPadding offset 32 := by
  have hn : (UInt256.ofNat dest).toNat = dest := word_nat dest hd
  have hsz := store_memory_size_mono st dest word
  rw [SszShaCallBytes.read_fit _ offset 32 (by omega) (by omega),
    SszShaCallBytes.read_fit _ offset 32 hs (by omega)]
  change (word.toByteArray.write 0 st.memory (UInt256.ofNat dest).toNat 32).extract offset (offset + 32) = _
  rw [hn]
  exact write_preserves_before _ _ _ _ _ _ _ ho hs

theorem store_read_after (st : EVM.State) (dest offset : Nat) (word : UInt256)
    (hd : dest < 2 ^ 64) (ho : dest + 32 ≤ offset) (hs : offset + 32 ≤ st.memory.size) :
    (store st dest word).memory.readWithPadding offset 32 = st.memory.readWithPadding offset 32 := by
  have hn : (UInt256.ofNat dest).toNat = dest := word_nat dest hd
  have hp : (st.memory.extract 0 dest ++ word.toByteArray).size = dest + 32 := by
    simp only [ByteArray.size_append, ByteArray.size_extract, actual_word_size]
    omega
  have hm : (store st dest word).memory =
      (st.memory.extract 0 dest ++ word.toByteArray) ++ st.memory.extract (dest + 32) st.memory.size := by
    apply ByteArray.ext
    change (word.toByteArray.write 0 st.memory (UInt256.ofNat dest).toNat 32).data = _
    rw [hn, write_word_shape _ _ _ (by omega)]
    have hz : dest - st.memory.size = 0 := by omega
    simp only [hz, Array.replicate_zero, Array.append_empty, ByteArray.data_append, ByteArray.data_extract]
  rw [hm]
  exact read_after_prefix _ _ (dest + 32) offset hp ho hs

/-! ## Stored cells -/

theorem stored_load (st : EVM.State) (offset : Nat) (value : UInt256)
    (h : Stored st offset value) (ho : offset < 2 ^ 64)
    (hw : st.activeWords.toNat < 2 ^ 251) : (load st offset).1 = value :=
  mload_of_read _ _ _ ho h.1 h.2.1 h.2.2 hw

theorem load_bounded (st : EVM.State) (offset : Nat)
    (ho : offset < 2 ^ 64) (hw : st.activeWords.toNat < 2 ^ 64) :
    (load st offset).2.activeWords.toNat < 2 ^ 64 := by
  change (st.toMachineState.mload (UInt256.ofNat offset)).2.activeWords.toNat < 2 ^ 64
  rw [load_words _ _ ho]
  omega

theorem stored_after_load (st : EVM.State) (loadAt offset : Nat) (value : UInt256)
    (h : Stored st offset value) (ha : loadAt < 2 ^ 64) :
    Stored (load st loadAt).2 offset value := by
  refine ⟨h.1, h.2.1, ?_⟩
  change offset < (st.toMachineState.mload (UInt256.ofNat loadAt)).2.activeWords.toNat * 32
  rw [load_words _ _ ha]
  have := h.2.2
  omega

theorem store_bounded (st : EVM.State) (offset : Nat) (value : UInt256)
    (ho : offset < 2 ^ 64) (hw : st.activeWords.toNat < 2 ^ 64) :
    (store st offset value).activeWords.toNat < 2 ^ 64 := by
  change (st.toMachineState.mstore (UInt256.ofNat offset) value).activeWords.toNat < 2 ^ 64
  rw [store_words _ _ _ ho]
  omega

theorem stored_written (st : EVM.State) (offset : Nat) (value : UInt256)
    (ho : offset < 2 ^ 64) (hm : offset ≤ st.memory.size + 576) :
    Stored (store st offset value) offset value := by
  have hn : (UInt256.ofNat offset).toNat = offset := word_nat offset ho
  refine ⟨store_size _ _ _ ho hm, ?_, ?_⟩
  · change (value.toByteArray.write 0 st.memory (UInt256.ofNat offset).toNat 32).readWithPadding offset 32 = _
    rw [hn]
    exact write_word_read _ _ _ hm
  · change offset < (st.toMachineState.mstore (UInt256.ofNat offset) value).activeWords.toNat * 32
    rw [store_words _ _ _ ho]
    omega

theorem stored_preserved (st : EVM.State) (dest offset : Nat) (word value : UInt256)
    (h : Stored st offset value) (hd : dest < 2 ^ 64)
    (apart : offset + 32 ≤ dest ∨ dest + 32 ≤ offset) :
    Stored (store st dest word) offset value := by
  refine ⟨Nat.le_trans h.1 (store_memory_size_mono _ _ _), ?_, ?_⟩
  · rcases apart with hb | ha
    · rw [store_read_before _ _ _ _ hd hb h.1]; exact h.2.1
    · rw [store_read_after _ _ _ _ hd ha h.1]; exact h.2.1
  · change offset < (st.toMachineState.mstore (UInt256.ofNat dest) word).activeWords.toNat * 32
    rw [store_words _ _ _ hd]
    have := h.2.2
    omega

/-- The zero word materialized by a store's padding gap. -/
theorem stored_pad_zero (st : EVM.State) (dest offset : Nat) (word : UInt256)
    (hd : dest < 2 ^ 64) (hdm : dest ≤ st.memory.size + 576)
    (hlow : st.memory.size ≤ offset) (hhigh : offset + 32 ≤ dest) :
    Stored (store st dest word) offset (UInt256.ofNat 0) := by
  have hn : (UInt256.ofNat dest).toNat = dest := word_nat dest hd
  refine ⟨Nat.le_trans (by omega) (store_size st.toMachineState dest word hd hdm), ?_, ?_⟩
  · change (word.toByteArray.write 0 st.memory (UInt256.ofNat dest).toNat 32).readWithPadding offset 32 = _
    rw [hn, write_pad_read _ _ _ _ hdm hlow hhigh, word_zero]
  · change offset < (st.toMachineState.mstore (UInt256.ofNat dest) word).activeWords.toNat * 32
    rw [store_words _ _ _ hd]
    omega

/-- Cells survive any transition that keeps the byte array and does not shrink
the active extent (the external STATICCALL boundary and returndata bookkeeping). -/
theorem stored_of_same_memory (st st' : EVM.State) (offset : Nat) (value : UInt256)
    (h : Stored st offset value) (hm : st'.memory = st.memory)
    (hw : st.activeWords.toNat ≤ st'.activeWords.toNat) : Stored st' offset value := by
  refine ⟨?_, ?_, ?_⟩
  · rw [hm]; exact h.1
  · rw [hm]; exact h.2.1
  · have := h.2.2; omega

/-- A stored cell keeps its value across one actual pair call (scratch writes and
the returned digest touch only bytes 0-63) and across the following store. -/
theorem pairStore_effects (fuel : Nat) (st : EVM.State) (leftAt rightAt dest : Nat)
    (left right : UInt256) (result : SszBlsComposition.Result)
    (h : SszCompiledConsumer.pairStore fuel st (UInt256.ofNat leftAt) (UInt256.ofNat rightAt)
      (UInt256.ofNat dest) = .ok result)
    (hl : Stored st leftAt left) (hr : Stored st rightAt right)
    (hla : leftAt < 2 ^ 64) (hra : rightAt < 2 ^ 64) (hd : dest < 2 ^ 64)
    (hl64 : 64 ≤ leftAt) (hdm : dest ≤ st.memory.size + 576)
    (hw : st.activeWords.toNat < 2 ^ 64) :
    result.digest = SszBlsComposition.pairDigest left right ∧
    Stored result.state dest result.digest ∧
    result.state.activeWords.toNat < 2 ^ 64 ∧
    result.state.executionEnv = st.executionEnv ∧
    st.memory.size ≤ result.state.memory.size ∧
    ∀ offset value, Stored st offset value → 64 ≤ offset →
      (offset + 32 ≤ dest ∨ dest + 32 ≤ offset) → Stored result.state offset value := by
  have nl : (UInt256.ofNat leftAt).toNat = leftAt := word_nat _ hla
  have nr : (UInt256.ofNat rightAt).toNat = rightAt := word_nat _ hra
  have nd : (UInt256.ofNat dest).toNat = dest := word_nat _ hd
  have hw251 : st.activeWords.toNat < 2 ^ 251 := by omega
  let loadedLeft := (load st leftAt).2
  let loadedRight := (load loadedLeft rightAt).2
  have vl := stored_load st leftAt left hl hla hw251
  have wl : loadedLeft.activeWords.toNat < 2 ^ 64 := load_bounded st leftAt hla hw
  have wl251 : loadedLeft.activeWords.toNat < 2 ^ 251 := by
    change (load st leftAt).2.activeWords.toNat < 2 ^ 251
    have := wl
    change (load st leftAt).2.activeWords.toNat < 2 ^ 64 at this
    omega
  have vr := stored_load loadedLeft rightAt right (stored_after_load st leftAt rightAt right hr hla) hra wl251
  have wr : loadedRight.activeWords.toNat < 2 ^ 64 := load_bounded loadedLeft rightAt hra wl
  have wr251 : loadedRight.activeWords.toNat < 2 ^ 251 := by omega
  unfold SszCompiledConsumer.pairStore at h
  simp only [nl, nr, nd] at h
  change ((SszBlsComposition.pairRun fuel loadedRight (load st leftAt).1
    (load loadedLeft rightAt).1).mapError SszCompiledConsumer.Error.bls >>= fun r =>
      pure (SszBlsComposition.Result.mk (store r.state dest r.digest) r.digest)) = .ok result at h
  rw [vl, vr] at h
  obtain ⟨called, hc, h⟩ := bind_success h
  have call := map_success SszCompiledConsumer.Error.bls _ _ hc
  change Except.ok _ = Except.ok result at h
  cases h
  have digest := SszShaCommitted.pair_success_digest fuel loadedRight left right called call wr251
  have words := SszShaCommitted.pair_success_words fuel loadedRight left right called call
  have env := SszWitnessAbi.pair_environment fuel loadedRight left right called call
  have hmem : 96 ≤ loadedRight.memory.size := by
    change 96 ≤ st.memory.size
    have := hl.1
    omega
  have hsize : loadedRight.memory.size ≤ called.state.memory.size :=
    (pair_memory fuel loadedRight left right called call hmem).2
  have hsize' : st.memory.size ≤ called.state.memory.size := hsize
  have hcw : called.state.activeWords.toNat < 2 ^ 64 := by rw [words]; omega
  refine ⟨digest, stored_written _ _ _ hd (by omega), store_bounded _ _ _ hd hcw, env,
    Nat.le_trans hsize' (store_memory_size_mono _ _ _), ?_⟩
  intro offset value stored hoff apart
  exact stored_preserved _ _ _ _ _
    (pair_stored fuel loadedRight left right called offset value call
      (stored_after_load loadedLeft rightAt offset value
        (stored_after_load st leftAt offset value stored hla) hra) hoff) hd apart

/-! ## The allocator at an arbitrary free pointer -/

theorem allocate_read_before (st afterState : EVM.State) (ptr bytes offset : Nat)
    (hfree : (load st 64).1 = UInt256.ofNat ptr)
    (h : allocate st bytes = .ok (UInt256.ofNat ptr, afterState))
    (hp : ptr < 2 ^ 64) (hoff : 96 ≤ offset) (hend : offset + 32 ≤ ptr)
    (hsize : offset + 32 ≤ st.memory.size) :
    afterState.memory.readWithPadding offset 32 = st.memory.readWithPadding offset 32 := by
  have hn : (UInt256.ofNat ptr).toNat = ptr := word_nat ptr hp
  let readState := (load st 64).2
  let written := store readState 64 (UInt256.ofNat ptr + UInt256.ofNat bytes)
  have hs : offset + 32 ≤ written.memory.size :=
    Nat.le_trans hsize (store_memory_size_mono readState 64 _)
  have ha : offset + 32 ≤ (written.executionEnv.calldata.write
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
    rw [hn, SszShaCallBytes.read_fit _ offset 32 ha (by omega),
      write_preserves_before _ _ _ _ _ _ _ hend hs,
      ← SszShaCallBytes.read_fit _ offset 32 hs (by omega)]
    rw [show written.memory.readWithPadding offset 32 = readState.memory.readWithPadding offset 32 from
      store_read_after readState 64 offset _ (by decide) (by omega)
        (by change offset + 32 ≤ st.memory.size; exact hsize)]
    rfl

theorem allocate_effects (st : EVM.State) (ptr bytes : Nat)
    (hfree : (load st 64).1 = UInt256.ofNat ptr)
    (hptr : 96 ≤ ptr) (hbytes : 0 < bytes) (hbound : ptr + bytes ≤ 2 ^ 64 - 1)
    (hwords : 3 ≤ st.activeWords.toNat) (hwidth : st.activeWords.toNat < 2 ^ 64) :
    ∃ afterState,
      allocate st bytes = .ok (UInt256.ofNat ptr, afterState) ∧
      (load afterState 64).1 = UInt256.ofNat (ptr + bytes) ∧
      afterState.activeWords.toNat = max st.activeWords.toNat ((ptr + bytes + 31) / 32) ∧
      afterState.executionEnv = st.executionEnv ∧
      st.memory.size ≤ afterState.memory.size ∧
      96 ≤ afterState.memory.size ∧
      afterState.memory.readWithPadding 64 32 = (UInt256.ofNat (ptr + bytes)).toByteArray := by
  let readState := (load st 64).2
  let written := store readState 64 (UInt256.ofNat (ptr + bytes))
  let cleared := written.toSharedState.calldatacopy
    (UInt256.ofNat ptr) (UInt256.ofNat written.executionEnv.calldata.size) (UInt256.ofNat bytes)
  let afterState : EVM.State := {written with toSharedState := cleared}
  have hp : (UInt256.ofNat ptr).toNat = ptr := word_nat ptr (by omega)
  have hb : (UInt256.ofNat bytes).toNat = bytes := word_nat bytes (by omega)
  have hnext : UInt256.ofNat ptr + UInt256.ofNat bytes = UInt256.ofNat (ptr + bytes) :=
    small_add ptr bytes (by omega)
  have hn : (UInt256.ofNat (ptr + bytes)).toNat = ptr + bytes := word_nat _ (by omega)
  have hrw : readState.activeWords.toNat = st.activeWords.toNat := by
    rw [show readState.activeWords.toNat = max st.activeWords.toNat ((64 + 63) / 32) from
      load_words _ 64 (by decide)]
    omega
  have hww : written.activeWords.toNat = st.activeWords.toNat := by
    rw [show written.activeWords.toNat = max readState.activeWords.toNat ((64 + 63) / 32) from
      store_words _ 64 _ (by decide), hrw]
    omega
  have haw : afterState.activeWords.toNat = max st.activeWords.toNat ((ptr + bytes + 31) / 32) := by
    change (MachineState.M written.activeWords.toNat (UInt256.ofNat ptr).toNat (UInt256.ofNat bytes).toNat) % UInt256.size = _
    rw [hp, hb]
    have hm : MachineState.M written.activeWords.toNat ptr bytes =
        max written.activeWords.toNat ((ptr + bytes + 31) / 32) := by
      cases bytes with
      | zero => omega
      | succ n => rfl
    rw [hm, hww]
    rw [Nat.mod_eq_of_lt]
    have hf : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    unfold UInt256.size at *
    omega
  have hsz : 96 ≤ written.memory.size := store_size _ 64 _ (by decide) (by omega)
  have hasz : 96 ≤ afterState.memory.size := by
    exact Nat.le_trans hsz (write_size_mono _ _ _ _ _)
  have hmono : st.memory.size ≤ afterState.memory.size := by
    exact Nat.le_trans (store_memory_size_mono readState 64 _) (write_size_mono _ _ _ _ _)
  have hr : afterState.memory.readWithPadding 64 32 = (UInt256.ofNat (ptr + bytes)).toByteArray := by
    rw [SszShaCallBytes.read_fit _ 64 32 hasz (by omega)]
    change (written.executionEnv.calldata.write _ written.memory (UInt256.ofNat ptr).toNat _).extract 64 96 = _
    rw [hp, write_preserves_before _ _ _ _ _ _ _ hptr hsz]
    rw [← SszShaCallBytes.read_fit _ 64 32 hsz (by omega)]
    exact write_word_read _ 64 _ (by omega)
  refine ⟨afterState, ?_, ?_, haw, rfl, hmono, hasz, hr⟩
  · unfold allocate
    dsimp only
    rw [hfree, hnext]
    rw [if_neg (by
      change ¬ ((UInt256.ofNat (ptr + bytes)).toNat > 2 ^ 64 - 1 ∨
        (UInt256.ofNat (ptr + bytes)).toNat < (UInt256.ofNat ptr).toNat)
      rw [hn, hp]
      omega)]
    rfl
  · exact mload_of_read _ 64 _ (by decide) hasz hr (by rw [haw]; omega) (by rw [haw]; omega)

/-- The allocator's own guard, on the pointer the current free word holds. -/
theorem allocate_bound (st afterState : EVM.State) (bytes ptr : Nat) (p : UInt256)
    (hfree : (load st 64).1 = UInt256.ofNat ptr) (hptr : ptr < 2 ^ 64) (hbytes : bytes < 2 ^ 64)
    (h : allocate st bytes = .ok (p, afterState)) :
    p = UInt256.ofNat ptr ∧ ptr + bytes ≤ 2 ^ 64 - 1 := by
  obtain ⟨hp, hb, _⟩ := allocate_success_bound st afterState bytes p h
  subst hp
  rw [hfree] at hb ⊢
  have hlt : ptr + bytes < UInt256.size := by unfold UInt256.size; omega
  rw [ofNat_add _ _ hlt] at hb
  change (ptr + bytes) % UInt256.size ≤ 2 ^ 64 - 1 at hb
  rw [Nat.mod_eq_of_lt hlt] at hb
  exact ⟨rfl, hb⟩

/-- Successful allocation at the current free pointer: pointer identity, the
guard-derived bound, the advanced free word, extent, environment, monotone
array size, and preservation of every cell below the pointer. -/
theorem allocate_frame (st afterState : EVM.State) (p : UInt256) (ptr bytes : Nat)
    (h : allocate st bytes = .ok (p, afterState))
    (hfree : (load st 64).1 = UInt256.ofNat ptr)
    (hp : 96 ≤ ptr) (hpb : ptr < 2 ^ 64) (hb : 0 < bytes) (hbb : bytes < 2 ^ 64)
    (hw : 3 ≤ st.activeWords.toNat) (hwidth : st.activeWords.toNat < 2 ^ 64) :
    p = UInt256.ofNat ptr ∧ ptr + bytes ≤ 2 ^ 64 - 1 ∧
    Stored afterState 64 (UInt256.ofNat (ptr + bytes)) ∧
    afterState.activeWords.toNat = max st.activeWords.toNat ((ptr + bytes + 31) / 32) ∧
    afterState.activeWords.toNat < 2 ^ 64 ∧
    afterState.executionEnv = st.executionEnv ∧
    st.memory.size ≤ afterState.memory.size ∧
    ∀ offset value, Stored st offset value → 96 ≤ offset → offset + 32 ≤ ptr →
      Stored afterState offset value := by
  obtain ⟨hpe, hbound⟩ := allocate_bound st afterState bytes ptr p hfree hpb hbb h
  subst hpe
  obtain ⟨after', ha, hf, words, env, hmono, hs, hr⟩ :=
    allocate_effects st ptr bytes hfree hp hb hbound hw hwidth
  rw [ha] at h
  obtain ⟨_, heq⟩ := Prod.mk.inj (Except.ok.inj h)
  subst heq
  refine ⟨rfl, hbound, ⟨hs, hr, by rw [words]; omega⟩, words, by rw [words]; omega, env, hmono, ?_⟩
  intro offset value stored hoff hout
  have hm := allocate_read_before st _ ptr bytes offset hfree ha hpb hoff hout stored.1
  exact ⟨Nat.le_trans stored.1 hmono, hm.trans stored.2.1, by rw [words]; have := stored.2.2; omega⟩

/-! ## The seven pair calls at an arbitrary leaf pointer -/

/-- Seven real SHA calls consume the words loaded from the arrays allocated after
the leaf pointer `P`; the leaf pointer is any cell admitted by the allocator. -/
theorem merkle_effects (fuel : Nat) (st : EVM.State) (P : Nat)
    (v0 v1 v2 v3 v4 v5 v6 v7 : UInt256) (result : SszBlsComposition.Result)
    (h : SszCompiledConsumer.merkle fuel st (UInt256.ofNat P) = .ok result)
    (hP : 96 ≤ P) (hPb : P + 256 < 2 ^ 64)
    (hf : Stored st 64 (UInt256.ofNat (P + 256)))
    (hw : st.activeWords.toNat < 2 ^ 64)
    (h0 : Stored st P v0) (h1 : Stored st (P + 32) v1) (h2 : Stored st (P + 64) v2)
    (h3 : Stored st (P + 96) v3) (h4 : Stored st (P + 128) v4) (h5 : Stored st (P + 160) v5)
    (h6 : Stored st (P + 192) v6) (h7 : Stored st (P + 224) v7) :
    result.digest = SszBlsComposition.pairDigest
        (SszBlsComposition.pairDigest
          (SszBlsComposition.pairDigest v0 v1) (SszBlsComposition.pairDigest v2 v3))
        (SszBlsComposition.pairDigest
          (SszBlsComposition.pairDigest v4 v5) (SszBlsComposition.pairDigest v6 v7)) ∧
      result.state.activeWords.toNat < 2 ^ 64 ∧ result.state.executionEnv = st.executionEnv := by
  have hw251 : st.activeWords.toNat < 2 ^ 251 := by omega
  have free := stored_load st 64 _ hf (by decide) hw251
  have low : 3 ≤ st.activeWords.toNat := by have := hf.2.2; omega
  have e32 : UInt256.ofNat P + UInt256.ofNat 32 = UInt256.ofNat (P + 32) := small_add _ _ (by omega)
  have e64 : UInt256.ofNat P + UInt256.ofNat 64 = UInt256.ofNat (P + 64) := small_add _ _ (by omega)
  have e96 : UInt256.ofNat P + UInt256.ofNat 96 = UInt256.ofNat (P + 96) := small_add _ _ (by omega)
  have e128 : UInt256.ofNat P + UInt256.ofNat 128 = UInt256.ofNat (P + 128) := small_add _ _ (by omega)
  have e160 : UInt256.ofNat P + UInt256.ofNat 160 = UInt256.ofNat (P + 160) := small_add _ _ (by omega)
  have e192 : UInt256.ofNat P + UInt256.ofNat 192 = UInt256.ofNat (P + 192) := small_add _ _ (by omega)
  have e224 : UInt256.ofNat P + UInt256.ofNat 224 = UInt256.ofNat (P + 224) := small_add _ _ (by omega)
  unfold SszCompiledConsumer.merkle at h
  dsimp only at h
  obtain ⟨pr, hpr, h⟩ := bind_success h
  rcases pr with ⟨l1, st1⟩
  dsimp only at h
  have alloc1 : allocate st 128 = .ok (l1, st1) := map_success _ _ _ hpr
  obtain ⟨hl1, hb1, free0, words0, bound0, env0, mono0, keep0⟩ :=
    allocate_frame st st1 l1 (P + 256) 128 alloc1 free (by omega) (by omega) (by decide) (by decide) low hw
  subst hl1
  have eA32 : UInt256.ofNat (P + 256) + UInt256.ofNat 32 = UInt256.ofNat (P + 256 + 32) := small_add _ _ (by omega)
  have eA64 : UInt256.ofNat (P + 256) + UInt256.ofNat 64 = UInt256.ofNat (P + 256 + 64) := small_add _ _ (by omega)
  have eA96 : UInt256.ofNat (P + 256) + UInt256.ofNat 96 = UInt256.ofNat (P + 256 + 96) := small_add _ _ (by omega)
  simp only [e32, e64, e96, e128, e160, e192, e224, eA32, eA64, eA96] at h
  have cell0_0 := keep0 P v0 h0 hP (by omega)
  have cell0_32 := keep0 (P + 32) v1 h1 (by omega) (by omega)
  have cell0_64 := keep0 (P + 64) v2 h2 (by omega) (by omega)
  have cell0_96 := keep0 (P + 96) v3 h3 (by omega) (by omega)
  have cell0_128 := keep0 (P + 128) v4 h4 (by omega) (by omega)
  have cell0_160 := keep0 (P + 160) v5 h5 (by omega) (by omega)
  have cell0_192 := keep0 (P + 192) v6 h6 (by omega) (by omega)
  have cell0_224 := keep0 (P + 224) v7 h7 (by omega) (by omega)
  have size0 : P + 256 ≤ st1.memory.size := Nat.le_trans h7.1 mono0
  obtain ⟨a, ha, h⟩ := bind_success h
  have ⟨adigest, astored, abound, aenv, amono, akeep⟩ := pairStore_effects fuel st1 P (P + 32) (P + 256)
    v0 v1 a ha cell0_0 cell0_32 (by omega) (by omega) (by omega) (by omega) (by omega) bound0
  have aenvroot : a.state.executionEnv = st.executionEnv := aenv.trans env0
  have acell64 := akeep 64 (UInt256.ofNat (P + 256 + 128)) free0 (by omega) (by omega)
  have acell64' := akeep (P + 64) v2 cell0_64 (by omega) (by omega)
  have acell96 := akeep (P + 96) v3 cell0_96 (by omega) (by omega)
  have acell128 := akeep (P + 128) v4 cell0_128 (by omega) (by omega)
  have acell160 := akeep (P + 160) v5 cell0_160 (by omega) (by omega)
  have acell192 := akeep (P + 192) v6 cell0_192 (by omega) (by omega)
  have acell224 := akeep (P + 224) v7 cell0_224 (by omega) (by omega)
  obtain ⟨b, hb, h⟩ := bind_success h
  have ⟨bdigest, bstored, bbound, benv, bmono, bkeep⟩ := pairStore_effects fuel a.state (P + 64) (P + 96)
    (P + 256 + 32) v2 v3 b hb acell64' acell96 (by omega) (by omega) (by omega) (by omega) (by omega) abound
  have benvroot : b.state.executionEnv = st.executionEnv := benv.trans aenvroot
  have bcellA := bkeep (P + 256) a.digest astored (by omega) (by omega)
  have bcell64 := bkeep 64 (UInt256.ofNat (P + 256 + 128)) acell64 (by omega) (by omega)
  have bcell128 := bkeep (P + 128) v4 acell128 (by omega) (by omega)
  have bcell160 := bkeep (P + 160) v5 acell160 (by omega) (by omega)
  have bcell192 := bkeep (P + 192) v6 acell192 (by omega) (by omega)
  have bcell224 := bkeep (P + 224) v7 acell224 (by omega) (by omega)
  obtain ⟨c, hc, h⟩ := bind_success h
  have ⟨cdigest, cstored, cbound, cenv, cmono, ckeep⟩ := pairStore_effects fuel b.state (P + 128) (P + 160)
    (P + 256 + 64) v4 v5 c hc bcell128 bcell160 (by omega) (by omega) (by omega) (by omega) (by omega) bbound
  have cenvroot : c.state.executionEnv = st.executionEnv := cenv.trans benvroot
  have ccellB := ckeep (P + 256 + 32) b.digest bstored (by omega) (by omega)
  have ccellA := ckeep (P + 256) a.digest bcellA (by omega) (by omega)
  have ccell64 := ckeep 64 (UInt256.ofNat (P + 256 + 128)) bcell64 (by omega) (by omega)
  have ccell192 := ckeep (P + 192) v6 bcell192 (by omega) (by omega)
  have ccell224 := ckeep (P + 224) v7 bcell224 (by omega) (by omega)
  obtain ⟨d, hd, h⟩ := bind_success h
  have ⟨ddigest, dstored, dbound, denv, dmono, dkeep⟩ := pairStore_effects fuel c.state (P + 192) (P + 224)
    (P + 256 + 96) v6 v7 d hd ccell192 ccell224 (by omega) (by omega) (by omega) (by omega) (by omega) cbound
  have denvroot : d.state.executionEnv = st.executionEnv := denv.trans cenvroot
  have dcellC := dkeep (P + 256 + 64) c.digest cstored (by omega) (by omega)
  have dcellB := dkeep (P + 256 + 32) b.digest ccellB (by omega) (by omega)
  have dcellA := dkeep (P + 256) a.digest ccellA (by omega) (by omega)
  have dcell64 := dkeep 64 (UInt256.ofNat (P + 256 + 128)) ccell64 (by omega) (by omega)
  have dw251 : d.state.activeWords.toNat < 2 ^ 251 := by omega
  have free1 := stored_load d.state 64 _ dcell64 (by decide) dw251
  have low1 : 3 ≤ d.state.activeWords.toNat := by have := dcell64.2.2; omega
  obtain ⟨pr2, hpr2, h⟩ := bind_success h
  rcases pr2 with ⟨l2, st2⟩
  dsimp only at h
  have alloc2 : allocate d.state 64 = .ok (l2, st2) := map_success _ _ _ hpr2
  obtain ⟨hl2, hb2, free2, words1, bound1, env1, mono1, keep1⟩ :=
    allocate_frame d.state st2 l2 (P + 256 + 128) 64 alloc2 free1 (by omega) (by omega) (by decide) (by decide) low1 dbound
  subst hl2
  have eB32 : UInt256.ofNat (P + 256 + 128) + UInt256.ofNat 32 = UInt256.ofNat (P + 256 + 128 + 32) :=
    small_add _ _ (by omega)
  simp only [eB32] at h
  have cell1_D := keep1 (P + 256 + 96) d.digest dstored (by omega) (by omega)
  have cell1_C := keep1 (P + 256 + 64) c.digest dcellC (by omega) (by omega)
  have cell1_B := keep1 (P + 256 + 32) b.digest dcellB (by omega) (by omega)
  have cell1_A := keep1 (P + 256) a.digest dcellA (by omega) (by omega)
  obtain ⟨e, he, h⟩ := bind_success h
  have ⟨edigest, estored, ebound, eenv, emono, ekeep⟩ := pairStore_effects fuel st2 (P + 256) (P + 256 + 32)
    (P + 256 + 128) a.digest b.digest e he cell1_A cell1_B (by omega) (by omega) (by omega) (by omega)
    (by have := cell1_D.1; omega) bound1
  have eenvroot : e.state.executionEnv = st.executionEnv := eenv.trans (env1.trans denvroot)
  have ecellD := ekeep (P + 256 + 96) d.digest cell1_D (by omega) (by omega)
  have ecellC := ekeep (P + 256 + 64) c.digest cell1_C (by omega) (by omega)
  obtain ⟨f, hf', h⟩ := bind_success h
  have ⟨fdigest, fstored, fbound, fenv, fmono, fkeep⟩ := pairStore_effects fuel e.state (P + 256 + 64)
    (P + 256 + 96) (P + 256 + 128 + 32) c.digest d.digest f hf' ecellC ecellD (by omega) (by omega) (by omega)
    (by omega) (by have := estored.1; omega) ebound
  have fenvroot : f.state.executionEnv = st.executionEnv := fenv.trans eenvroot
  have fcellE := fkeep (P + 256 + 128) e.digest estored (by omega) (by omega)
  have fw251 : f.state.activeWords.toNat < 2 ^ 251 := by omega
  have leftValue := stored_load f.state (P + 256 + 128) e.digest fcellE (by omega) fw251
  have wn : (UInt256.ofNat (P + 256 + 128)).toNat = P + 256 + 128 := word_nat _ (by omega)
  have finalBound : (load f.state (P + 256 + 128)).2.activeWords.toNat < 2 ^ 64 :=
    load_bounded f.state (P + 256 + 128) (by omega) fbound
  have finalCall := map_success SszCompiledConsumer.Error.bls _ _ h
  change SszBlsComposition.pairRun fuel (load f.state (UInt256.ofNat (P + 256 + 128)).toNat).2
    (load f.state (UInt256.ofNat (P + 256 + 128)).toNat).1 f.digest = .ok result at finalCall
  rw [wn, leftValue] at finalCall
  have finalDigest := SszShaCommitted.pair_success_digest fuel (load f.state (P + 256 + 128)).2
    e.digest f.digest result finalCall (by omega)
  have finalWords := SszShaCommitted.pair_success_words fuel (load f.state (P + 256 + 128)).2
    e.digest f.digest result finalCall
  have finalEnv := SszWitnessAbi.pair_environment fuel (load f.state (P + 256 + 128)).2
    e.digest f.digest result finalCall
  refine ⟨?_, by rw [finalWords]; omega, finalEnv.trans fenvroot⟩
  rw [finalDigest, edigest, fdigest, adigest, bdigest, cdigest, ddigest]

/-! ## The eight leaf stores at an arbitrary leaf pointer -/

/-- IR 282-320: the expected credentials from calldata word 164
(`_expectedWithdrawalCredentials` of the CL entry) and the six guarded uint64/bool
field stores, in the inspected order, at the allocated leaf array. -/
def storeFields (st : EVM.State) (h ptr : UInt256) : Except SszCompiledConsumer.Error EVM.State := do
  let st := store st (ptr + UInt256.ofNat 32).toNat (st.calldataload (UInt256.ofNat 164))
  let balance ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 68)).mapError SszCompiledConsumer.Error.abi
  let st := store st (ptr + UInt256.ofNat 64).toNat (SszBlsComposition.chunk balance)
  let slashed ← (SszWitnessAbi.readBool st (h + UInt256.ofNat 228)).mapError SszCompiledConsumer.Error.abi
  let st := store st (ptr + UInt256.ofNat 96).toNat (SszBlsComposition.chunk (if slashed then 1 else 0))
  let eligible ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 100)).mapError SszCompiledConsumer.Error.abi
  let st := store st (ptr + UInt256.ofNat 128).toNat (SszBlsComposition.chunk eligible)
  let activation ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 132)).mapError SszCompiledConsumer.Error.abi
  let st := store st (ptr + UInt256.ofNat 160).toNat (SszBlsComposition.chunk activation)
  let exit ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 164)).mapError SszCompiledConsumer.Error.abi
  let st := store st (ptr + UInt256.ofNat 192).toNat (SszBlsComposition.chunk exit)
  let withdrawable ← (SszWitnessAbi.read64 st (h + UInt256.ofNat 196)).mapError SszCompiledConsumer.Error.abi
  pure (store st (ptr + UInt256.ofNat 224).toNat (SszBlsComposition.chunk withdrawable))

theorem fields_effects (st afterState : EVM.State) (head : UInt256) (P : Nat) (key : UInt256)
    (h : storeFields st head (UInt256.ofNat P) = .ok afterState)
    (hP : 96 ≤ P) (hPb : P + 256 < 2 ^ 64)
    (hk : Stored st P key) (hf : Stored st 64 (UInt256.ofNat (P + 256)))
    (hw : st.activeWords.toNat < 2 ^ 64) :
    ∃ f, SszWitnessAbi.FieldsMatch st head f ∧
      Stored afterState 64 (UInt256.ofNat (P + 256)) ∧ Stored afterState P key ∧
      Stored afterState (P + 32) (st.calldataload (UInt256.ofNat 164)) ∧
      Stored afterState (P + 64) (SszBlsComposition.chunk f.effectiveBalance) ∧
      Stored afterState (P + 96) (SszBlsComposition.chunk (if f.slashed then 1 else 0)) ∧
      Stored afterState (P + 128) (SszBlsComposition.chunk f.activationEligibilityEpoch) ∧
      Stored afterState (P + 160) (SszBlsComposition.chunk f.activationEpoch) ∧
      Stored afterState (P + 192) (SszBlsComposition.chunk f.exitEpoch) ∧
      Stored afterState (P + 224) (SszBlsComposition.chunk f.withdrawableEpoch) ∧
      afterState.activeWords.toNat < 2 ^ 64 ∧ afterState.executionEnv = st.executionEnv := by
  have e32 : UInt256.ofNat P + UInt256.ofNat 32 = UInt256.ofNat (P + 32) := small_add _ _ (by omega)
  have e64 : UInt256.ofNat P + UInt256.ofNat 64 = UInt256.ofNat (P + 64) := small_add _ _ (by omega)
  have e96 : UInt256.ofNat P + UInt256.ofNat 96 = UInt256.ofNat (P + 96) := small_add _ _ (by omega)
  have e128 : UInt256.ofNat P + UInt256.ofNat 128 = UInt256.ofNat (P + 128) := small_add _ _ (by omega)
  have e160 : UInt256.ofNat P + UInt256.ofNat 160 = UInt256.ofNat (P + 160) := small_add _ _ (by omega)
  have e192 : UInt256.ofNat P + UInt256.ofNat 192 = UInt256.ofNat (P + 192) := small_add _ _ (by omega)
  have e224 : UInt256.ofNat P + UInt256.ofNat 224 = UInt256.ofNat (P + 224) := small_add _ _ (by omega)
  have w32 : (UInt256.ofNat (P + 32)).toNat = P + 32 := word_nat _ (by omega)
  have w64 : (UInt256.ofNat (P + 64)).toNat = P + 64 := word_nat _ (by omega)
  have w96 : (UInt256.ofNat (P + 96)).toNat = P + 96 := word_nat _ (by omega)
  have w128 : (UInt256.ofNat (P + 128)).toNat = P + 128 := word_nat _ (by omega)
  have w160 : (UInt256.ofNat (P + 160)).toNat = P + 160 := word_nat _ (by omega)
  have w192 : (UInt256.ofNat (P + 192)).toNat = P + 192 := word_nat _ (by omega)
  have w224 : (UInt256.ofNat (P + 224)).toNat = P + 224 := word_nat _ (by omega)
  unfold storeFields at h
  dsimp only at h
  simp only [e32, e64, e96, e128, e160, e192, e224, w32, w64, w96, w128, w160, w192, w224,
    read64_store, readBool_store] at h
  obtain ⟨balance, hbalance, h⟩ := bind_success h
  have cbalance := map_success SszCompiledConsumer.Error.abi _ _ hbalance
  obtain ⟨slashed, hslashed, h⟩ := bind_success h
  have cslashed := map_success SszCompiledConsumer.Error.abi _ _ hslashed
  obtain ⟨eligible, heligible, h⟩ := bind_success h
  have celigible := map_success SszCompiledConsumer.Error.abi _ _ heligible
  obtain ⟨active, hactive, h⟩ := bind_success h
  have cactive := map_success SszCompiledConsumer.Error.abi _ _ hactive
  obtain ⟨exited, hexited, h⟩ := bind_success h
  have cexited := map_success SszCompiledConsumer.Error.abi _ _ hexited
  obtain ⟨withdrawable, hwithdrawable, h⟩ := bind_success h
  have cwithdrawable := map_success SszCompiledConsumer.Error.abi _ _ hwithdrawable
  change Except.ok _ = Except.ok afterState at h
  cases h
  let f : SszBlsComposition.Fields := ⟨balance, slashed, eligible, active, exited, withdrawable⟩
  have decoded : SszWitnessAbi.fields st head = .ok f := by
    simp only [SszWitnessAbi.fields, cbalance, cslashed, celigible, cactive, cexited, cwithdrawable]
    rfl
  have fm := SszWitnessAbi.fields_success st head f decoded
  have hsize : P + 32 ≤ st.memory.size := hk.1
  let st0 := store st (P + 32) (st.calldataload (UInt256.ofNat 164))
  have bound0 : st0.activeWords.toNat < 2 ^ 64 := store_bounded st (P + 32) _ (by omega) hw
  have written0 : Stored st0 (P + 32) (st.calldataload (UInt256.ofNat 164)) :=
    stored_written st (P + 32) _ (by omega) (by omega)
  have s0cell64 : Stored st0 64 (UInt256.ofNat (P + 256)) := stored_preserved st (P + 32) 64 _ _ hf (by omega) (by omega)
  have s0cellP : Stored st0 P key := stored_preserved st (P + 32) P _ key hk (by omega) (by omega)
  let st1 := store st0 (P + 64) (SszBlsComposition.chunk balance)
  have bound1 : st1.activeWords.toNat < 2 ^ 64 := store_bounded st0 (P + 64) _ (by omega) bound0
  have written1 : Stored st1 (P + 64) (SszBlsComposition.chunk balance) :=
    stored_written st0 (P + 64) _ (by omega) (by have := written0.1; omega)
  have s1cell32 : Stored st1 (P + 32) (st.calldataload (UInt256.ofNat 164)) := stored_preserved st0 (P + 64) (P + 32) _ _ written0 (by omega) (by omega)
  have s1cell64 : Stored st1 64 (UInt256.ofNat (P + 256)) := stored_preserved st0 (P + 64) 64 _ _ s0cell64 (by omega) (by omega)
  have s1cellP : Stored st1 P key := stored_preserved st0 (P + 64) P _ key s0cellP (by omega) (by omega)
  let st2 := store st1 (P + 96) (SszBlsComposition.chunk (if slashed then 1 else 0))
  have bound2 : st2.activeWords.toNat < 2 ^ 64 := store_bounded st1 (P + 96) _ (by omega) bound1
  have written2 : Stored st2 (P + 96) (SszBlsComposition.chunk (if slashed then 1 else 0)) :=
    stored_written st1 (P + 96) _ (by omega) (by have := written1.1; omega)
  have s2cell64' : Stored st2 (P + 64) (SszBlsComposition.chunk balance) := stored_preserved st1 (P + 96) (P + 64) _ _ written1 (by omega) (by omega)
  have s2cell32 : Stored st2 (P + 32) (st.calldataload (UInt256.ofNat 164)) := stored_preserved st1 (P + 96) (P + 32) _ _ s1cell32 (by omega) (by omega)
  have s2cell64 : Stored st2 64 (UInt256.ofNat (P + 256)) := stored_preserved st1 (P + 96) 64 _ _ s1cell64 (by omega) (by omega)
  have s2cellP : Stored st2 P key := stored_preserved st1 (P + 96) P _ key s1cellP (by omega) (by omega)
  let st3 := store st2 (P + 128) (SszBlsComposition.chunk eligible)
  have bound3 : st3.activeWords.toNat < 2 ^ 64 := store_bounded st2 (P + 128) _ (by omega) bound2
  have written3 : Stored st3 (P + 128) (SszBlsComposition.chunk eligible) :=
    stored_written st2 (P + 128) _ (by omega) (by have := written2.1; omega)
  have s3cell96 : Stored st3 (P + 96) (SszBlsComposition.chunk (if slashed then 1 else 0)) := stored_preserved st2 (P + 128) (P + 96) _ _ written2 (by omega) (by omega)
  have s3cell64' : Stored st3 (P + 64) (SszBlsComposition.chunk balance) := stored_preserved st2 (P + 128) (P + 64) _ _ s2cell64' (by omega) (by omega)
  have s3cell32 : Stored st3 (P + 32) (st.calldataload (UInt256.ofNat 164)) := stored_preserved st2 (P + 128) (P + 32) _ _ s2cell32 (by omega) (by omega)
  have s3cell64 : Stored st3 64 (UInt256.ofNat (P + 256)) := stored_preserved st2 (P + 128) 64 _ _ s2cell64 (by omega) (by omega)
  have s3cellP : Stored st3 P key := stored_preserved st2 (P + 128) P _ key s2cellP (by omega) (by omega)
  let st4 := store st3 (P + 160) (SszBlsComposition.chunk active)
  have bound4 : st4.activeWords.toNat < 2 ^ 64 := store_bounded st3 (P + 160) _ (by omega) bound3
  have written4 : Stored st4 (P + 160) (SszBlsComposition.chunk active) :=
    stored_written st3 (P + 160) _ (by omega) (by have := written3.1; omega)
  have s4cell128 : Stored st4 (P + 128) (SszBlsComposition.chunk eligible) := stored_preserved st3 (P + 160) (P + 128) _ _ written3 (by omega) (by omega)
  have s4cell96 : Stored st4 (P + 96) (SszBlsComposition.chunk (if slashed then 1 else 0)) := stored_preserved st3 (P + 160) (P + 96) _ _ s3cell96 (by omega) (by omega)
  have s4cell64' : Stored st4 (P + 64) (SszBlsComposition.chunk balance) := stored_preserved st3 (P + 160) (P + 64) _ _ s3cell64' (by omega) (by omega)
  have s4cell32 : Stored st4 (P + 32) (st.calldataload (UInt256.ofNat 164)) := stored_preserved st3 (P + 160) (P + 32) _ _ s3cell32 (by omega) (by omega)
  have s4cell64 : Stored st4 64 (UInt256.ofNat (P + 256)) := stored_preserved st3 (P + 160) 64 _ _ s3cell64 (by omega) (by omega)
  have s4cellP : Stored st4 P key := stored_preserved st3 (P + 160) P _ key s3cellP (by omega) (by omega)
  let st5 := store st4 (P + 192) (SszBlsComposition.chunk exited)
  have bound5 : st5.activeWords.toNat < 2 ^ 64 := store_bounded st4 (P + 192) _ (by omega) bound4
  have written5 : Stored st5 (P + 192) (SszBlsComposition.chunk exited) :=
    stored_written st4 (P + 192) _ (by omega) (by have := written4.1; omega)
  have s5cell160 : Stored st5 (P + 160) (SszBlsComposition.chunk active) := stored_preserved st4 (P + 192) (P + 160) _ _ written4 (by omega) (by omega)
  have s5cell128 : Stored st5 (P + 128) (SszBlsComposition.chunk eligible) := stored_preserved st4 (P + 192) (P + 128) _ _ s4cell128 (by omega) (by omega)
  have s5cell96 : Stored st5 (P + 96) (SszBlsComposition.chunk (if slashed then 1 else 0)) := stored_preserved st4 (P + 192) (P + 96) _ _ s4cell96 (by omega) (by omega)
  have s5cell64' : Stored st5 (P + 64) (SszBlsComposition.chunk balance) := stored_preserved st4 (P + 192) (P + 64) _ _ s4cell64' (by omega) (by omega)
  have s5cell32 : Stored st5 (P + 32) (st.calldataload (UInt256.ofNat 164)) := stored_preserved st4 (P + 192) (P + 32) _ _ s4cell32 (by omega) (by omega)
  have s5cell64 : Stored st5 64 (UInt256.ofNat (P + 256)) := stored_preserved st4 (P + 192) 64 _ _ s4cell64 (by omega) (by omega)
  have s5cellP : Stored st5 P key := stored_preserved st4 (P + 192) P _ key s4cellP (by omega) (by omega)
  let st6 := store st5 (P + 224) (SszBlsComposition.chunk withdrawable)
  have bound6 : st6.activeWords.toNat < 2 ^ 64 := store_bounded st5 (P + 224) _ (by omega) bound5
  have written6 : Stored st6 (P + 224) (SszBlsComposition.chunk withdrawable) :=
    stored_written st5 (P + 224) _ (by omega) (by have := written5.1; omega)
  have s6cell192 : Stored st6 (P + 192) (SszBlsComposition.chunk exited) := stored_preserved st5 (P + 224) (P + 192) _ _ written5 (by omega) (by omega)
  have s6cell160 : Stored st6 (P + 160) (SszBlsComposition.chunk active) := stored_preserved st5 (P + 224) (P + 160) _ _ s5cell160 (by omega) (by omega)
  have s6cell128 : Stored st6 (P + 128) (SszBlsComposition.chunk eligible) := stored_preserved st5 (P + 224) (P + 128) _ _ s5cell128 (by omega) (by omega)
  have s6cell96 : Stored st6 (P + 96) (SszBlsComposition.chunk (if slashed then 1 else 0)) := stored_preserved st5 (P + 224) (P + 96) _ _ s5cell96 (by omega) (by omega)
  have s6cell64' : Stored st6 (P + 64) (SszBlsComposition.chunk balance) := stored_preserved st5 (P + 224) (P + 64) _ _ s5cell64' (by omega) (by omega)
  have s6cell32 : Stored st6 (P + 32) (st.calldataload (UInt256.ofNat 164)) := stored_preserved st5 (P + 224) (P + 32) _ _ s5cell32 (by omega) (by omega)
  have s6cell64 : Stored st6 64 (UInt256.ofNat (P + 256)) := stored_preserved st5 (P + 224) 64 _ _ s5cell64 (by omega) (by omega)
  have s6cellP : Stored st6 P key := stored_preserved st5 (P + 224) P _ key s5cellP (by omega) (by omega)
  exact ⟨f, fm, s6cell64, s6cellP, s6cell32, s6cell64', s6cell96, s6cell128, s6cell160, s6cell192,
    written6, bound6, rfl⟩

#print axioms write_pad_read
#print axioms allocate_frame
#print axioms pairStore_effects
#print axioms merkle_effects
#print axioms fields_effects
end LidoSRv3.Audit.Source.SszCompiledFrame
