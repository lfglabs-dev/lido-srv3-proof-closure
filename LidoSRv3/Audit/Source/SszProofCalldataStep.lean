import LidoSRv3.Audit.Source.SszWordBytes
import LidoSRv3.Audit.Source.SszShaCallMemory
import LidoSRv3.Audit.Source.SszProofFold

/-! Raw proof calldata and one SSZ.sol:179–249 source iteration.
The raw layout boundary is explicit; the reads, scratch bytes and pointer bounds
are derived. Existing EvmYul primitives are used directly. This does not execute
the Solidity ABI decoder, full opcode/gas dispatcher or complete proof loop. -/
namespace LidoSRv3.Audit.Source.SszProofCalldataStep
open EvmYul EvmYul.EVM SszWordBytes SszScratchByteArray

theorem calldata_read_fit (b : ByteArray) (start : Nat) (hfit : start + 32 ≤ b.size) :
    b.readBytes start 32 = b.extract start (start+32) := by
  have hr : (if start < 2^64 && 32 < 2^64 then b.copySlice start ByteArray.empty 0 32
      else ⟨⟨b.toList.drop start |>.take 32⟩⟩) = b.extract start (start+32) := by
    split
    · apply ByteArray.ext
      rw [ByteArray.data_copySlice]
      simp [ByteArray.data_extract]
    · apply ByteArray.ext
      simp only [byteList_data, ByteArray.data_extract]
      apply Array.ext'
      simp [List.take_drop]
  have hs : (b.extract start (start+32)).size = 32 := by
    simp only [ByteArray.size_extract]
    omega
  unfold ByteArray.readBytes
  rw [hr]
  simp only [hs, BitVec.sub_self]
  exact append_zeros_zero _

/-- Independent list of fixed-width big-endian words in calldata order. -/
def wordStream : List UInt256 → ByteArray
  | [] => ByteArray.empty
  | w :: rest => fixedBE 32 w.toNat ++ wordStream rest

@[simp] theorem fixed_size (w : UInt256) : (fixedBE 32 w.toNat).size = 32 := by
  simp [fixedBE]

@[simp] theorem stream_size (ws : List UInt256) : (wordStream ws).size = 32 * ws.length := by
  induction ws with
  | nil => rfl
  | cons w rest ih => simp [wordStream, ih, Nat.mul_add, Nat.add_comm]

theorem stream_append (xs ys : List UInt256) : wordStream (xs ++ ys) = wordStream xs ++ wordStream ys := by
  induction xs with
  | nil => simp [wordStream]
  | cons x xs ih => simp [wordStream, ih, ByteArray.append_assoc]

/-- A semantic decomposition selects a row; it does not supply its read result. -/
def layout (prebytes suffix : ByteArray) (before : List UInt256) (w : UInt256)
    (after : List UInt256) : ByteArray :=
  prebytes ++ wordStream (before ++ w :: after) ++ suffix

def cursor (prebytes : ByteArray) (before : List UInt256) : Nat := prebytes.size + 32 * before.length

theorem layout_selected (prebytes suffix : ByteArray) (before after : List UInt256) (w : UInt256) :
    (layout prebytes suffix before w after).extract (cursor prebytes before) (cursor prebytes before + 32) =
      fixedBE 32 w.toNat := by
  unfold layout cursor
  rw [stream_append]
  simp only [wordStream, ByteArray.append_assoc]
  rw [← show (prebytes ++ wordStream before).size = prebytes.size + 32 * before.length by simp]
  rw [← ByteArray.append_assoc]
  change ((prebytes ++ wordStream before) ++ (fixedBE 32 w.toNat ++ (wordStream after ++ suffix))).extract
    ((prebytes ++ wordStream before).size + 0) ((prebytes ++ wordStream before).size + 32) = _
  rw [ByteArray.extract_append_size_add]
  exact ByteArray.extract_append_eq_left (fixed_size w).symm

theorem layout_extent (prebytes suffix : ByteArray) (before after : List UInt256) (w : UInt256) :
    cursor prebytes before + 32 ≤ (layout prebytes suffix before w after).size := by
  simp only [cursor, layout, ByteArray.size_append, stream_size, List.length_append, List.length_cons]
  omega

theorem layout_read (prebytes suffix : ByteArray) (before after : List UInt256) (w : UInt256) :
    (layout prebytes suffix before w after).readBytes (cursor prebytes before) 32 = fixedBE 32 w.toNat := by
  rw [calldata_read_fit _ _ (layout_extent prebytes suffix before after w)]
  exact layout_selected prebytes suffix before after w


/-- The actual word cursor is computed, not supplied as a readback premise. -/
def proofOffset (prebytes : ByteArray) (before : List UInt256) : UInt256 :=
  UInt256.ofNat (cursor prebytes before)

theorem actual_sibling {τ : OperationType} (st : EvmYul.State τ)
    (prebytes suffix : ByteArray) (before after : List UInt256) (w : UInt256)
    (hlayout : st.executionEnv.calldata = layout prebytes suffix before w after)
    (hsize : st.executionEnv.calldata.size < UInt256.size) :
    st.calldataload (proofOffset prebytes before) = w := by
  have hfit := layout_extent prebytes suffix before after w
  rw [← hlayout] at hfit
  have hc : cursor prebytes before < UInt256.size := by omega
  have hp : (proofOffset prebytes before).toNat = cursor prebytes before := by
    change cursor prebytes before % UInt256.size = cursor prebytes before
    exact Nat.mod_eq_of_lt hc
  unfold EvmYul.State.calldataload
  rw [hp, hlayout, layout_read, ← actual_word_bytes]
  exact actual_word_decode w


open SszShaCallBytes SszShaCallMemory

theorem writes_left (left right old : ByteArray) (hl : left.size = 32) (hr : right.size = 32) :
    right.write 0 (left.write 0 old 0 32) 32 32 = left ++ right ++ old.extract 64 old.size := by
  rw [write32 left old hl]
  apply ByteArray.ext
  rw [write_fit _ _ 0 32 32 (by omega) (by omega) (by omega)]
  have hld : left.data.size = 32 := hl
  have hrd : right.data.size = 32 := hr
  simp [ByteArray.data_append, ByteArray.data_extract, Array.extract_append,
    ← ByteArray.size_data, hld, Array.extract_extract]
  rw [Array.extract_eq_self_of_le (by omega : left.data.size ≤ 32),
    Array.extract_eq_self_of_le (by omega : right.data.size ≤ 32),
    Array.extract_eq_empty_of_le (by omega : min (32 + (old.data.size - 32)) left.data.size ≤ 64)]
  have hm : min (32 + (old.data.size - 32)) old.data.size = old.data.size := by omega
  rw [hm]
  simp


theorem high_write (right old : ByteArray) (hr : right.size = 32) :
    (right.write 0 old 32 32).data =
      (old.data.extract 0 32 ++ Array.replicate (32-old.size) 0) ++ right.data ++ old.data.extract 64 old.size := by
  rw [write_fit _ _ 0 32 32 (by omega) (by omega) (by omega)]
  have hrd : right.data.size ≤ 32 := by change right.size ≤ 32; omega
  simp [Array.extract_eq_self_of_le hrd]

theorem writes_right (left right old : ByteArray) (hl : left.size = 32) (hr : right.size = 32) :
    left.write 0 (right.write 0 old 32 32) 0 32 = left ++ right ++ old.extract 64 old.size := by
  rw [write32 left _ hl]
  apply ByteArray.ext
  simp only [ByteArray.data_append, ByteArray.data_extract]
  rw [high_write right old hr]
  generalize hlo : (old.data.extract 0 32 ++ Array.replicate (32-old.size) 0) = lower at *
  have hlower : lower.size = 32 := by rw [← hlo]; exact lower_size old
  have hrd : right.data.size = 32 := hr
  change left.data ++ (lower ++ right.data ++ old.data.extract 64 old.size).extract 32
    (right.write 0 old 32 32).size = _
  have hsize : (right.write 0 old 32 32).size = (lower ++ right.data ++ old.data.extract 64 old.size).size := by
    change (right.write 0 old 32 32).data.size = _
    rw [high_write right old hr, hlo]
  rw [hsize]
  simp only [Array.extract_append, Array.size_append, hlower, hrd]
  simp [← ByteArray.size_data, Array.extract_extract]
  rw [Array.extract_eq_empty_of_le (by omega : min (64 + (old.data.size - 64)) lower.size ≤ 32),
    Array.extract_eq_self_of_le (by omega : right.data.size ≤ 64 + (old.data.size - 64) - 32)]
  have hm : min (64 + (old.data.size - 64)) old.data.size = old.data.size := by omega
  rw [hm]
  simp


def scratchAddress (index : UInt256) : UInt256 :=
  (index &&& UInt256.ofNat 1) <<< UInt256.ofNat 5

theorem scratch_even (index : UInt256) (h : index.toNat % 2 = 0) :
    scratchAddress index = UInt256.ofNat 0 := by
  unfold scratchAddress
  have hb : index &&& UInt256.ofNat 1 = UInt256.ofNat 0 := by
    apply congrArg UInt256.mk
    apply Fin.ext
    change (index.toNat &&& 1) % UInt256.size = 0
    simp [Nat.and_one_is_mod, h]
  rw [hb]
  decide +kernel

theorem scratch_odd (index : UInt256) (h : index.toNat % 2 = 1) :
    scratchAddress index = UInt256.ofNat 32 := by
  unfold scratchAddress
  have hb : index &&& UInt256.ofNat 1 = UInt256.ofNat 1 := by
    apply congrArg UInt256.mk
    apply Fin.ext
    change (index.toNat &&& 1) % UInt256.size = 1
    simp [Nat.and_one_is_mod, h, UInt256.size]
  rw [hb]
  decide +kernel


theorem word_nat {n : Nat} (h : n < UInt256.size) : (UInt256.ofNat n).toNat = n := Nat.mod_eq_of_lt h

theorem stride_nat (n : Nat) (hn : 32*n < UInt256.size) :
    (UInt256.ofNat n <<< UInt256.ofNat 5).toNat = 32*n := by
  have hsmall : n < UInt256.size := by omega
  change ((n % UInt256.size) <<< 5) % UInt256.size = 32*n
  rw [Nat.mod_eq_of_lt hsmall]
  simpa [Nat.shiftLeft_eq, Nat.mul_comm] using Nat.mod_eq_of_lt hn

def sourceEnd (prebytes : ByteArray) (count : Nat) : UInt256 :=
  UInt256.ofNat prebytes.size + (UInt256.ofNat count <<< UInt256.ofNat 5)

theorem end_nat (prebytes : ByteArray) (count : Nat)
    (h : prebytes.size + 32*count < UInt256.size) :
    (sourceEnd prebytes count).toNat = prebytes.size + 32*count := by
  change ((UInt256.ofNat prebytes.size).toNat + (UInt256.ofNat count <<< UInt256.ofNat 5).toNat) % UInt256.size = _
  rw [word_nat (by omega), stride_nat count (by omega), Nat.mod_eq_of_lt h]


theorem layout_end (prebytes suffix : ByteArray) (before after : List UInt256) (w : UInt256)
    (hsize : (layout prebytes suffix before w after).size < UInt256.size) :
    (sourceEnd prebytes (before ++ w :: after).length).toNat =
      cursor prebytes before + 32 + 32*after.length := by
  have hs : prebytes.size + 32 * (before ++ w :: after).length < UInt256.size := by
    simp only [layout, ByteArray.size_append, stream_size] at hsize
    omega
  rw [end_nat prebytes _ hs]
  simp only [cursor, List.length_append, List.length_cons]
  omega

theorem layout_next (prebytes suffix : ByteArray) (before after : List UInt256) (w : UInt256)
    (hsize : (layout prebytes suffix before w after).size < UInt256.size) :
    (proofOffset prebytes before + UInt256.ofNat 32).toNat = cursor prebytes before + 32 := by
  have hf := layout_extent prebytes suffix before after w
  have hc : cursor prebytes before < UInt256.size := by omega
  change ((cursor prebytes before % UInt256.size) + 32) % UInt256.size = _
  rw [Nat.mod_eq_of_lt hc, Nat.mod_eq_of_lt (by omega)]

theorem layout_continue (prebytes suffix : ByteArray) (before after : List UInt256) (w : UInt256)
    (hsize : (layout prebytes suffix before w after).size < UInt256.size) :
    (proofOffset prebytes before + UInt256.ofNat 32 < sourceEnd prebytes (before ++ w :: after).length) ↔ after ≠ [] := by
  change (proofOffset prebytes before + UInt256.ofNat 32).toNat <
    (sourceEnd prebytes (before ++ w :: after).length).toNat ↔ _
  rw [layout_next prebytes suffix before after w hsize, layout_end prebytes suffix before after w hsize]
  simp only [← List.length_pos_iff_ne_nil]
  omega


/-- The first store precedes the calldata load and second store. -/
def preparedStep (st : EVM.State) (index leaf offset : UInt256) : EVM.State :=
  let side := scratchAddress index
  let first : EVM.State := { st with toSharedState :=
    { st.toSharedState with toMachineState := st.toMachineState.mstore side leaf } }
  let loaded := first.toState.calldataload offset
  let second := first.toMachineState.mstore (side ^^^ UInt256.ofNat 32) loaded
  { first with toSharedState := { first.toSharedState with toMachineState := second } }

def pairInput (index leaf sibling : UInt256) : ByteArray :=
  if index.toNat % 2 = 0 then fixedBE 32 leaf.toNat ++ fixedBE 32 sibling.toNat
  else fixedBE 32 sibling.toNat ++ fixedBE 32 leaf.toNat

theorem prepared_memory (st : EVM.State) (index leaf : UInt256)
    (prebytes suffix : ByteArray) (before after : List UInt256) (sibling : UInt256)
    (hlayout : st.executionEnv.calldata = layout prebytes suffix before sibling after)
    (hsize : st.executionEnv.calldata.size < UInt256.size) :
    (preparedStep st index leaf (proofOffset prebytes before)).memory =
      pairInput index leaf sibling ++ st.memory.extract 64 st.memory.size := by
  have hload := actual_sibling st.toState prebytes suffix before after sibling hlayout hsize
  by_cases he : index.toNat % 2 = 0
  · have ha := scratch_even index he
    have hx : UInt256.ofNat 0 ^^^ UInt256.ofNat 32 = UInt256.ofNat 32 := by decide +kernel
    unfold preparedStep
    dsimp only
    rw [ha, hx, hload]
    change sibling.toByteArray.write 0 (leaf.toByteArray.write 0 st.memory 0 32) 32 32 = _
    rw [writes_left _ _ _ (actual_word_size leaf) (actual_word_size sibling)]
    simp [pairInput, he, actual_word_bytes]
  · have ho : index.toNat % 2 = 1 := by omega
    have ha := scratch_odd index ho
    have hx : UInt256.ofNat 32 ^^^ UInt256.ofNat 32 = UInt256.ofNat 0 := by decide +kernel
    unfold preparedStep
    dsimp only
    rw [ha, hx, hload]
    change sibling.toByteArray.write 0 (leaf.toByteArray.write 0 st.memory 32 32) 0 32 = _
    rw [writes_right _ _ _ (actual_word_size sibling) (actual_word_size leaf)]
    simp [pairInput, he, actual_word_bytes]


@[simp] theorem pair_size (index leaf sibling : UInt256) : (pairInput index leaf sibling).size = 64 := by
  unfold pairInput
  split <;> simp

theorem prepared_read (st : EVM.State) (index leaf : UInt256)
    (prebytes suffix : ByteArray) (before after : List UInt256) (sibling : UInt256)
    (hlayout : st.executionEnv.calldata = layout prebytes suffix before sibling after)
    (hsize : st.executionEnv.calldata.size < UInt256.size) :
    (preparedStep st index leaf (proofOffset prebytes before)).memory.readWithPadding 0 64 =
      pairInput index leaf sibling := by
  rw [prepared_memory st index leaf prebytes suffix before after sibling hlayout hsize]
  exact SszScratchByteArray.read_prefix _ _ (pair_size index leaf sibling)

theorem prepared_words (st : EVM.State) (index leaf offset : UInt256) :
    (preparedStep st index leaf offset).activeWords.toNat = max st.activeWords.toNat 2 := by
  have hf1 : max st.activeWords.toNat 1 < UInt256.size := by
    have hs : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    unfold UInt256.size at *
    omega
  have hf2 : max st.activeWords.toNat 2 < UInt256.size := by
    have hs : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    unfold UInt256.size at *
    omega
  by_cases he : index.toNat % 2 = 0
  · have ha := scratch_even index he
    have hx : UInt256.ofNat 0 ^^^ UInt256.ofNat 32 = UInt256.ofNat 32 := by decide +kernel
    simp only [preparedStep, ha, hx, MachineState.mstore, MachineState.M]
    change (max ((max st.activeWords.toNat 1) % UInt256.size) 2) % UInt256.size = _
    rw [Nat.mod_eq_of_lt hf1]
    have hm : max (max st.activeWords.toNat 1) 2 = max st.activeWords.toNat 2 := by omega
    rw [hm, Nat.mod_eq_of_lt hf2]
  · have ho : index.toNat % 2 = 1 := by omega
    have ha := scratch_odd index ho
    have hx : UInt256.ofNat 32 ^^^ UInt256.ofNat 32 = UInt256.ofNat 0 := by decide +kernel
    simp only [preparedStep, ha, hx, MachineState.mstore, MachineState.M]
    change (max ((max st.activeWords.toNat 2) % UInt256.size) 1) % UInt256.size = _
    rw [Nat.mod_eq_of_lt hf2]
    have hm : max (max st.activeWords.toNat 2) 1 = max st.activeWords.toNat 2 := by omega
    rw [hm, Nat.mod_eq_of_lt hf2]


def stepCall (fuel : Nat) (st : EVM.State) (index leaf offset : UInt256) :=
  let st' := preparedStep st index leaf offset
  callSha (fuel+2)
    (Ccall shaAddress shaAddress (UInt256.ofNat 0) st'.gasAvailable
      st'.accountMap st'.toMachineState st'.substate)
    (UInt256.ofNat st'.executionEnv.codeOwner.val) st'.gasAvailable st'

theorem prepared_call (fuel : Nat) (st : EVM.State) (index leaf : UInt256)
    (prebytes suffix : ByteArray) (before after : List UInt256) (sibling : UInt256)
    (hlayout : st.executionEnv.calldata = layout prebytes suffix before sibling after)
    (hsize : st.executionEnv.calldata.size < UInt256.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hgas : 84 ≤ Ccallgas shaAddress shaAddress (UInt256.ofNat 0)
      (preparedStep st index leaf (proofOffset prebytes before)).gasAvailable
      (preparedStep st index leaf (proofOffset prebytes before)).accountMap
      (preparedStep st index leaf (proofOffset prebytes before)).toMachineState
      (preparedStep st index leaf (proofOffset prebytes before)).substate)
    (hout : (shaOutput (pairInput index leaf sibling)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ afterState : EVM.State,
      stepCall fuel st index leaf (proofOffset prebytes before) = .ok (UInt256.ofNat 1, afterState) ∧
      afterState.returnData = shaOutput (pairInput index leaf sibling) ∧
      afterState.memory = shaOutput (pairInput index leaf sibling) ++
        (preparedStep st index leaf (proofOffset prebytes before)).memory.extract 32
          (preparedStep st index leaf (proofOffset prebytes before)).memory.size ∧
      (afterState.toMachineState.mload (UInt256.ofNat 0)).1 =
        UInt256.ofNat (fromByteArrayBigEndian (shaOutput (pairInput index leaf sibling))) := by
  have hr := prepared_read st index leaf prebytes suffix before after sibling hlayout hsize
  obtain ⟨afterState, hc, ho, hm, hw⟩ := call_sha_bytes fuel _
    (UInt256.ofNat (preparedStep st index leaf (proofOffset prebytes before)).executionEnv.codeOwner.val)
    (preparedStep st index leaf (proofOffset prebytes before)).gasAvailable
    (preparedStep st index leaf (proofOffset prebytes before)) hdepth hgas
    (by rw [hr]; exact pair_size index leaf sibling) (by rw [hr]; exact hout)
  rw [hr] at ho hm
  have hwords : afterState.activeWords.toNat = max st.activeWords.toNat 2 := by
    rw [hw, prepared_words]
    change (max (max st.activeWords.toNat 2) 2) % UInt256.size = _
    rw [max_eq_left (by omega), Nat.mod_eq_of_lt (by unfold UInt256.size; omega)]
  refine ⟨afterState, hc, ho, hm, ?_⟩
  exact mload32 afterState.toMachineState _ _ hm hout
    (by rw [hwords]; omega) (by rw [hwords]; omega)



def parentIndex (index : UInt256) : UInt256 := index >>> UInt256.ofNat 1

theorem parent_nat (index : UInt256) : (parentIndex index).toNat = index.toNat / 2 := by
  change (index.toNat >>> 1) % UInt256.size = index.toNat / 2
  simp only [Nat.shiftRight_eq_div_pow]
  have hi : index.toNat < UInt256.size := index.val.isLt
  exact Nat.mod_eq_of_lt (by omega)

/-- Explicit error tags for this primitive slice, not Solidity revert-byte ABI. -/
inductive StepError where
  | extraItem | hashFailure | engineFailure
  deriving DecidableEq, Repr

structure StepResult where
  state : EVM.State
  index : UInt256
  leaf : UInt256
  offset : UInt256
  continues : Bool

/-- One nonempty-loop iteration. Success checks the CALL flag only, as SSZ.sol
requires; there is deliberately no returndata-length check in this program. -/
def sourceStep (fuel : Nat) (st : EVM.State) (index leaf offset endOffset : UInt256) :
    Except StepError StepResult :=
  let parent := parentIndex index
  if parent = UInt256.ofNat 0 then .error .extraItem else
  match stepCall fuel st index leaf offset with
  | .error _ => .error .engineFailure
  | .ok (flag, called) =>
    if flag = UInt256.ofNat 0 then .error .hashFailure else
    let (digest, machine) := called.toMachineState.mload (UInt256.ofNat 0)
    let next := offset + UInt256.ofNat 32
    .ok {
      state := {called with toSharedState := {called.toSharedState with toMachineState := machine}}
      index := parent
      leaf := digest
      offset := next
      continues := decide (next < endOffset)}

/-- Same concrete opaque FFI digest, interpreted as the typed fold's pair function.
This function does not claim hash correctness or unconditional runtime success. -/
def ffiPair (left right : UInt256) : Option UInt256 :=
  some (UInt256.ofNat (fromByteArrayBigEndian (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat))))

theorem typed_one_step (index leaf sibling : UInt256) (h : 1 < index.toNat) :
    SszProofFold.sourceFold ffiPair index.toNat leaf [sibling] =
      .ok (index.toNat / 2, UInt256.ofNat (fromByteArrayBigEndian (shaOutput (pairInput index leaf sibling)))) := by
  have hp : index.toNat / 2 ≠ 0 := by omega
  by_cases he : index.toNat % 2 = 0
  · simp [SszProofFold.sourceFold, Nat.and_one_is_mod, Nat.shiftRight_eq_div_pow, he, hp, ffiPair, pairInput]
  · have ho : index.toNat % 2 = 1 := by omega
    simp [SszProofFold.sourceFold, Nat.and_one_is_mod, Nat.shiftRight_eq_div_pow, ho, hp, ffiPair, pairInput]


theorem sourceStep_success (fuel : Nat) (st : EVM.State) (index leaf : UInt256)
    (prebytes suffix : ByteArray) (before after : List UInt256) (sibling : UInt256)
    (hlayout : st.executionEnv.calldata = layout prebytes suffix before sibling after)
    (hsize : st.executionEnv.calldata.size < UInt256.size)
    (hindex : 1 < index.toNat)
    (hdepth : st.executionEnv.depth < 1024)
    (hgas : 84 ≤ Ccallgas shaAddress shaAddress (UInt256.ofNat 0)
      (preparedStep st index leaf (proofOffset prebytes before)).gasAvailable
      (preparedStep st index leaf (proofOffset prebytes before)).accountMap
      (preparedStep st index leaf (proofOffset prebytes before)).toMachineState
      (preparedStep st index leaf (proofOffset prebytes before)).substate)
    (hpaid : Ccall shaAddress shaAddress (UInt256.ofNat 0)
      (preparedStep st index leaf (proofOffset prebytes before)).gasAvailable
      (preparedStep st index leaf (proofOffset prebytes before)).accountMap
      (preparedStep st index leaf (proofOffset prebytes before)).toMachineState
      (preparedStep st index leaf (proofOffset prebytes before)).substate ≤
      (preparedStep st index leaf (proofOffset prebytes before)).gasAvailable.toNat)
    (hout : (shaOutput (pairInput index leaf sibling)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ result : StepResult,
      sourceStep fuel st index leaf (proofOffset prebytes before)
        (sourceEnd prebytes (before ++ sibling :: after).length) = .ok result ∧
      SszProofFold.sourceFold ffiPair index.toNat leaf [sibling] = .ok (result.index.toNat, result.leaf) ∧
      result.offset.toNat = cursor prebytes before + 32 ∧
      result.continues = decide (after ≠ []) ∧
      Ccall shaAddress shaAddress (UInt256.ofNat 0)
        (preparedStep st index leaf (proofOffset prebytes before)).gasAvailable
        (preparedStep st index leaf (proofOffset prebytes before)).accountMap
        (preparedStep st index leaf (proofOffset prebytes before)).toMachineState
        (preparedStep st index leaf (proofOffset prebytes before)).substate < UInt256.size := by
  have hparent : parentIndex index ≠ UInt256.ofNat 0 := by
    intro hz
    have hh := congrArg UInt256.toNat hz
    rw [parent_nat] at hh
    change index.toNat / 2 = 0 at hh
    omega
  obtain ⟨called, hc, hret, hmem, hm⟩ := prepared_call fuel st index leaf prebytes suffix before after sibling
    hlayout hsize hdepth hgas hout hwidth
  let next := proofOffset prebytes before + UInt256.ofNat 32
  let result : StepResult := {
    state := {called with toSharedState := {called.toSharedState with toMachineState :=
      (called.toMachineState.mload (UInt256.ofNat 0)).2}},
    index := parentIndex index,
    leaf := (called.toMachineState.mload (UInt256.ofNat 0)).1,
    offset := next,
    continues := decide (next < sourceEnd prebytes (before ++ sibling :: after).length)}
  refine ⟨result, ?_, ?_, ?_, ?_, ?_⟩
  · simp only [sourceStep, hparent, ↓reduceIte, hc]
    have hn : UInt256.ofNat 1 ≠ UInt256.ofNat 0 := by decide +kernel
    simp only [hn, ↓reduceIte]
    rfl
  · change SszProofFold.sourceFold ffiPair index.toNat leaf [sibling] =
      .ok ((parentIndex index).toNat, (called.toMachineState.mload (UInt256.ofNat 0)).1)
    rw [parent_nat, hm]
    exact typed_one_step index leaf sibling hindex
  · exact layout_next prebytes suffix before after sibling (by rwa [← hlayout])
  · change decide (proofOffset prebytes before + UInt256.ofNat 32 <
      sourceEnd prebytes (before ++ sibling :: after).length) = decide (after ≠ [])
    simp only [layout_continue prebytes suffix before after sibling (by rwa [← hlayout])]
  · exact lt_of_le_of_lt hpaid (preparedStep st index leaf (proofOffset prebytes before)).gasAvailable.val.isLt


/-- GIndex.sol's actual word shift discards the eight metadata bits. -/
def decodeIndex (raw : UInt256) : UInt256 := raw >>> UInt256.ofNat 8

theorem decode_nat (raw : UInt256) : (decodeIndex raw).toNat = raw.toNat / 256 := by
  change (raw.toNat >>> 8) % UInt256.size = raw.toNat / 256
  simp only [Nat.shiftRight_eq_div_pow]
  have hi : raw.toNat < UInt256.size := raw.val.isLt
  exact Nat.mod_eq_of_lt (by omega)

theorem decode_width (raw : UInt256) : (decodeIndex raw).toNat < 2^248 := by
  rw [decode_nat]
  have hi : raw.toNat < UInt256.size := raw.val.isLt
  unfold UInt256.size at hi
  omega

theorem sourceStep_extra (fuel : Nat) (st : EVM.State) (index leaf offset endOffset : UInt256)
    (hi : index.toNat ≤ 1) : sourceStep fuel st index leaf offset endOffset = .error .extraItem := by
  have hp : parentIndex index = UInt256.ofNat 0 := by
    have hv : (parentIndex index).toNat = 0 := by rw [parent_nat]; omega
    have hf : (parentIndex index).val = (UInt256.ofNat 0).val := Fin.ext hv
    exact congrArg UInt256.mk hf
  simp [sourceStep, hp]


end LidoSRv3.Audit.Source.SszProofCalldataStep
