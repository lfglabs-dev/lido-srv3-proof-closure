import LidoSRv3.Audit.Source.SszCompiledReply
import LidoSRv3.Audit.Source.SszCompiledGIndex
import LidoSRv3.Audit.Source.SszRootCall

/-! Selected compiled execution of the complete CL entry
`SszRootCallHarness.verify(BeaconRootData,ValidatorWitness,uint256,bytes32)` →
unmodified `CLValidatorVerifier._verifyValidator` (lines 44-57) at core pin
17005714f151e5502c559932319a3f2f74ac2436, selector `0x2e77b4ba`, transcribed from
the inspected solc 0.8.25/viaIR/200/Cancun runtime IR
(audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul:43-417) on the
existing EvmYul `EVM.State` with the existing memory, SHA-call, allocator, leaf
and proof-loop routines.

Source order: dispatcher guards, `_verifySlot` (proof tail, slot/proposer words,
one real pair SHA, checked `length - 2`, sibling compare), `_getParentBlockRoot`
(the `abi.encode` allocation, the STATICCALL whose 32-byte input is read back
from machine memory, the reply copied into a caller allocation and ABI-decoded),
`concat(GI_STATE_ROOT, _getValidatorGI(index, slot))` on the constructor words,
then the existing leaf pipeline and `SSZ.verifyProof` with the decoded root
and packed index as stack operands.

Explicit boundaries kept: the BEACON_ROOTS callee is the accepted typed
`StaticCall.External` interpreter over a `Live.World` (the same object the typed
entry uses); the immutables are the typed `Configuration`'s `pack` words; SHA is
the opaque engine FFI. Gas of the outer opcodes and EIP-4788 authenticity are
not represented. -/
namespace LidoSRv3.Audit.Source.SszCompiledClEntry
open EvmYul EvmYul.EVM SszCompiledMemory SszCompiledConsumer SszBlsComposition
open SszCompiledFrame SszCompiledReply SszWrapperIndex TrioReserve1
open SszCompiledMerkle (Stored)
set_option autoImplicit false
set_option maxRecDepth 4096

inductive Error where
  | abi (error : SszWitnessAbi.Error)
  | allocation (error : AllocationError)
  | gindex (error : SszCompiledGIndex.Error)
  | reply (error : SszCompiledReply.Error)
  | panic11
  | panic32
  | invalidSlot
  | bls (error : SszBlsComposition.Error)
  | proof (error : SszProofCalldataLoop.VerifyError)

def liftConsumer : SszCompiledConsumer.Error → Error
  | .abi e => .abi e
  | .allocation e => .allocation e
  | .bls e => .bls e
  | .proof e => .proof e

/-- IR 40-55: selector `0x2e77b4ba`, the six-word head, the witness offset at
word 100 and its eight-word head extent. -/
def header (st : EVM.State) : Except Error UInt256 := do
  let size := UInt256.ofNat st.executionEnv.calldata.size
  if st.executionEnv.weiValue.toNat ≠ 0 then throw (.abi .abi)
  if size.toNat < 4 then throw (.abi .abi)
  if (st.calldataload (UInt256.ofNat 0)).toNat / 2 ^ 224 ≠ 0x2e77b4ba then throw (.abi .abi)
  if UInt256.sltBool (size - UInt256.ofNat 4) (UInt256.ofNat 192) then throw (.abi .abi)
  if UInt256.sltBool (size - UInt256.ofNat 4) (UInt256.ofNat 96) then throw (.abi .abi)
  let offset := st.calldataload (UInt256.ofNat 100)
  if offset.toNat > 2 ^ 64 - 1 then throw (.abi .abi)
  if UInt256.sltBool (size - offset - UInt256.ofNat 4) (UInt256.ofNat 256) then throw (.abi .abi)
  pure offset

/-- IR 70-97: `_proof[_proof.length - 2] != parentSlotProposer` after the pair
SHA: checked subtraction (panic 0x11), bounds check (panic 0x32), load, compare. -/
def slotSibling (st : EVM.State) (branch : SszWitnessAbi.Slice) (expected : UInt256) :
    Except Error Unit :=
  if branch.length < 2 then .error .panic11
  else
    let diff := branch.length - 2
    if ¬ diff < branch.length then .error .panic32
    else if st.calldataload (branch.offset + UInt256.ofNat (diff * 32)) = expected then .ok ()
    else .error .invalidSlot

/-- The machine's code owner as the typed caller address of the STATICCALL. -/
def callerOf (st : EVM.State) : Live.Address :=
  Verity.Core.Address.ofNat st.executionEnv.codeOwner.val

/-- Machine bytes as the typed call payload/reply bytes, and back. -/
def liveBytes (b : ByteArray) : Live.Bytes := b.data.toList
def machineBytes (b : Live.Bytes) : ByteArray := ⟨b.toArray⟩

structure RootOutcome where
  success : Bool
  attempts : List Live.NestedAttempt

/-- IR 101-114: `abi.encode(_childBlockTimestamp)` at the free pointer (length
word 32 and the value word), `finalize_allocation`, then
`staticcall(gas(), BEACON_ROOTS, ptr+32, mload(ptr), 0, 0)`. The 32-byte input is
read from machine memory; the reply becomes the machine's returndata. The callee
is the accepted typed external interpreter on the typed world (explicit). -/
def rootCall (external : StaticCall.External) (world : Live.World) (st : EVM.State)
    (timestamp : UInt256) : Except Error (EVM.State × RootOutcome) :=
  let (ptr, st) := load st 64
  let st := store st (ptr + UInt256.ofNat 32).toNat timestamp
  let st := store st ptr.toNat (UInt256.ofNat 32)
  let next := ptr + UInt256.ofNat 64
  if next.toNat > 2 ^ 64 - 1 ∨ next < ptr then .error (.allocation .panic41)
  else
    let st := store st 64 next
    let (len, st) := load st ptr.toNat
    let input := st.memory.readWithPadding (ptr + UInt256.ofNat 32).toNat len.toNat
    let result := audit.trio.consolidation.lowLevelStaticCall external (callerOf st)
      SszRootCall.target (liveBytes input) world
    let (success, reply) : Bool × ByteArray := match result.outcome with
      | .ok data => (true, machineBytes data)
      | .error data => (false, machineBytes data)
    let st : EVM.State := { st with toSharedState := { st.toSharedState with toMachineState :=
      { st.toMachineState with
        returnData := reply
        activeWords := UInt256.ofNat (MachineState.M (MachineState.M st.activeWords.toNat
          (ptr + UInt256.ofNat 32).toNat len.toNat) 0 0) } } }
    .ok (st, ⟨success, result.attempts⟩)

structure Before where
  state : EVM.State
  head : UInt256
  branch : SszWitnessAbi.Slice
  timestamp : UInt256
  index : UInt256

/-- IR 43-100: prologue, dispatcher, validator index word, proof tail, slot and
proposer words, the slot pair SHA, the sibling compare and the timestamp word. -/
def beforeRoot (fuel : Nat) (context : EVM.State) : Except Error Before := do
  let st := prologue context
  let h ← header st
  let n := st.calldataload (UInt256.ofNat 132)
  let branch ← (SszWitnessAbi.tail st h (UInt256.ofNat 4) 32).mapError Error.abi
  let slot ← (SszWitnessAbi.read64 st (UInt256.ofNat 36)).mapError Error.abi
  let proposer ← (SszWitnessAbi.read64 st (UInt256.ofNat 68)).mapError Error.abi
  let expected ← (pairRun fuel st (chunk slot) (chunk proposer)).mapError Error.bls
  slotSibling expected.state branch expected.digest
  let _ ← (SszWitnessAbi.read64 expected.state (UInt256.ofNat 4)).mapError Error.abi
  pure ⟨expected.state, h, branch, expected.state.calldataload (UInt256.ofNat 4), n⟩

/-- IR 116-417: reply copy/decode, the second slot read, the generalized index on
the constructor words, the leaf array, the key call, field stores, seven pair
calls, the proof tail and `SSZ.verifyProof` with the decoded root and the packed
index as stack operands. -/
def afterRoot (fuel : Nat) (cfg : Configuration) (st : EVM.State) (h : UInt256)
    (success : Bool) (n : UInt256) : Except Error EVM.State := do
  let (data, st) ← (copyReply st).mapError Error.reply
  let (root, st) ← (decodeRoot st success data).mapError Error.reply
  let slot ← (SszWitnessAbi.read64 st (UInt256.ofNat 36)).mapError Error.abi
  let raw ← (SszCompiledGIndex.wrapper (SszCompiledGIndex.cfgWords cfg) slot.toNat n.toNat).mapError
    Error.gindex
  let rawIndex := UInt256.ofNat raw
  let (ptr, st) ← (allocate st 256).mapError Error.allocation
  let keySlice ← (SszWitnessAbi.tail st h (UInt256.ofNat 36) 1).mapError Error.abi
  let key ← (pubkeyRun fuel st keySlice.offset keySlice.length).mapError Error.bls
  let st := store key.state ptr.toNat key.digest
  let st ← (SszCompiledFrame.storeFields st h ptr).mapError liftConsumer
  let leaf ← (SszCompiledConsumer.merkle fuel st ptr).mapError liftConsumer
  let branch ← (SszWitnessAbi.tail leaf.state h (UInt256.ofNat 4) 32).mapError Error.abi
  (SszProofCalldataLoop.verify fuel leaf.state rawIndex leaf.digest root
    branch.offset branch.length).mapError Error.proof

structure Result where
  outcome : Except Error EVM.State
  attempts : List Live.NestedAttempt

/-- The whole selected entry. The root attempt list is the low-level call's own. -/
def run (fuel : Nat) (cfg : Configuration) (external : StaticCall.External) (world : Live.World)
    (context : EVM.State) : Result :=
  match beforeRoot fuel context with
  | .error e => ⟨.error e, []⟩
  | .ok b =>
    match rootCall external world b.state b.timestamp with
    | .error e => ⟨.error e, []⟩
    | .ok (st, out) => ⟨afterRoot fuel cfg st b.head out.success b.index, out.attempts⟩

/-- The typed validator leaf of this entry: pubkey octets from the key slice,
decoded fields, credentials from calldata word 164. -/
def validatorLeaf (st : EVM.State) (keyOffset : UInt256) (f : SszBlsComposition.Fields) : UInt256 :=
  SszTypedFfiBridge.toWord (SszWrapperIndex.treeDigest
    (SszValidatorLeaf.pair SszTypedFfiBridge.ffiSha)
    (SszValidatorLeaf.validatorTree SszTypedFfiBridge.ffiSha
      (SszPubkeyBytes.witnessAt st keyOffset f)
      (SszTypedFfiBridge.toDigest (st.calldataload (UInt256.ofNat 164)))))

/-! ## Environment transport -/

theorem calldataload_env (st st' : EVM.State) (h : st'.executionEnv = st.executionEnv)
    (x : UInt256) : st'.calldataload x = st.calldataload x := by
  simp only [EvmYul.State.calldataload, h]

theorem read64_env (st st' : EVM.State) (h : st'.executionEnv = st.executionEnv) (x : UInt256) :
    SszWitnessAbi.read64 st' x = SszWitnessAbi.read64 st x := by
  simp only [SszWitnessAbi.read64, EvmYul.State.calldataload, h]

theorem tail_env (st st' : EVM.State) (h : st'.executionEnv = st.executionEnv)
    (a b : UInt256) (s : Nat) : SszWitnessAbi.tail st' a b s = SszWitnessAbi.tail st a b s := by
  simp only [SszWitnessAbi.tail, EvmYul.State.calldataload, h]

theorem header_env (st st' : EVM.State) (h : st'.executionEnv = st.executionEnv) :
    header st' = header st := by
  simp only [header, EvmYul.State.calldataload, h]

theorem callerOf_env (st st' : EVM.State) (h : st'.executionEnv = st.executionEnv) :
    callerOf st' = callerOf st := by
  unfold callerOf
  rw [h]

theorem fieldsMatch_env (st st' : EVM.State) (h : st'.executionEnv = st.executionEnv)
    (head : UInt256) (f : SszBlsComposition.Fields) (fm : SszWitnessAbi.FieldsMatch st' head f) :
    SszWitnessAbi.FieldsMatch st head f := by
  rcases fm with ⟨a, b, c, d, e, g⟩
  constructor
  · simpa only [EvmYul.State.calldataload, h] using a
  · simpa only [EvmYul.State.calldataload, h] using b
  · simpa only [EvmYul.State.calldataload, h] using c
  · simpa only [EvmYul.State.calldataload, h] using d
  · simpa only [EvmYul.State.calldataload, h] using e
  · simpa only [EvmYul.State.calldataload, h] using g

theorem pubkeyDigest_env (st st' : EVM.State) (h : st'.executionEnv = st.executionEnv)
    (offset : UInt256) : SszPubkeyBytes.pubkeyDigest st' offset = SszPubkeyBytes.pubkeyDigest st offset := by
  simp only [SszPubkeyBytes.pubkeyDigest, h]

theorem validatorLeaf_env (st st' : EVM.State) (h : st'.executionEnv = st.executionEnv)
    (offset : UInt256) (f : SszBlsComposition.Fields) :
    validatorLeaf st' offset f = validatorLeaf st offset f := by
  simp only [validatorLeaf, SszPubkeyBytes.witnessAt, EvmYul.State.calldataload, h]

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

/-! ## The prologue frame -/

theorem prologue_size (context : EVM.State) : (prologue context).memory.size = 96 := by
  have h64 : (UInt256.ofNat 64).toNat = 64 := by decide +kernel
  change ((UInt256.ofNat 128).toByteArray.write 0 (fresh context).memory
    (UInt256.ofNat 64).toNat 32).size = 96
  rw [h64]
  change ((UInt256.ofNat 128).toByteArray.write 0 ByteArray.empty 64 32).data.size = 96
  rw [SszCompiledFrame.write_word_shape ByteArray.empty 64 (UInt256.ofNat 128)
    (Nat.le_trans (by decide : 64 ≤ 576) (Nat.le_add_left 576 ByteArray.empty.size))]
  simp only [Array.size_append, Array.size_extract, Array.size_replicate, ByteArray.size_data,
    SszWordBytes.actual_word_size, ByteArray.size_empty]
  try decide

theorem prologue_stored (context : EVM.State) : Stored (prologue context) 64 (UInt256.ofNat 128) := by
  have h64 : (UInt256.ofNat 64).toNat = 64 := by decide +kernel
  refine ⟨by have := prologue_size context; omega, ?_, by have := prologue_words context; omega⟩
  change ((UInt256.ofNat 128).toByteArray.write 0 (fresh context).memory
    (UInt256.ofNat 64).toNat 32).readWithPadding 64 32 = _
  rw [h64]
  exact SszCompiledFrame.write_word_read (fresh context).memory 64 (UInt256.ofNat 128)
    (Nat.le_trans (by decide : 64 ≤ 576) (Nat.le_add_left 576 (fresh context).memory.size))

/-- One real pair call keeps the byte-array size (its scratch writes stay inside
the first 64 bytes of an array holding at least 64 bytes). -/
theorem pair_memory_size (fuel : Nat) (st : EVM.State) (left right : UInt256)
    (result : SszBlsComposition.Result)
    (h : SszBlsComposition.pairRun fuel st left right = .ok result) (hsize : 64 ≤ st.memory.size) :
    result.state.memory.size = st.memory.size := by
  obtain ⟨flag, called, hc, hn, hlen, hm⟩ := finish_memory _ _ h
  let prep := SszBlsComposition.preparePair st left right
  let charge := Ccall SszShaCallMemory.shaAddress SszShaCallMemory.shaAddress (UInt256.ofNat 0)
    prep.gasAvailable prep.accountMap prep.toMachineState prep.substate
  let source := UInt256.ofNat prep.executionEnv.codeOwner.val
  have hi : (prep.memory.readWithPadding 0 64).size = 64 := by
    rw [SszBlsComposition.prepared_read]
    simp [SszWordBytes.fixedBE]
  have ho := SszShaCommitted.call_success_output fuel charge source prep.gasAvailable prep called flag hi hc hn
  have hd := SszShaCommitted.call_success_depth fuel charge source prep.gasAvailable prep called flag hc hn
  have hg := SszShaCommitted.call_success_gas fuel charge source prep.gasAvailable prep called flag hi hc hn
  have hout : (SszShaCallMemory.shaOutput (prep.memory.readWithPadding 0 64)).size = 32 := ho ▸ hlen
  obtain ⟨afterState, ha, _, hmem, _⟩ :=
    SszShaCallMemory.call_sha_bytes fuel charge source prep.gasAvailable prep hd hg hi hout
  change SszShaCallMemory.callSha (fuel + 2) charge source prep.gasAvailable prep = .ok (flag, called) at hc
  rw [hc] at ha
  obtain ⟨_, he⟩ := Prod.mk.inj (Except.ok.inj ha)
  subst afterState
  have hp : prep.memory.size = st.memory.size := by
    show (SszBlsComposition.preparePair st left right).memory.size = st.memory.size
    rw [SszBlsComposition.prepared_memory]
    simp only [ByteArray.size_append, ByteArray.size_extract, SszProofCalldataStep.fixed_size]
    omega
  rw [hm, hmem]
  simp only [ByteArray.size_append, ByteArray.size_extract, hout, hp]
  omega

/-! ## Phase 1: before the root call -/

theorem beforeRoot_success (fuel : Nat) (context : EVM.State) (b : Before)
    (h : beforeRoot fuel context = .ok b) :
    ∃ slot proposer,
      header context = .ok b.head ∧
      SszWitnessAbi.tail context b.head (UInt256.ofNat 4) 32 = .ok b.branch ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 36) = .ok slot ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 68) = .ok proposer ∧
      2 ≤ b.branch.length ∧
      context.calldataload (b.branch.offset + UInt256.ofNat ((b.branch.length - 2) * 32)) =
        SszBlsComposition.pairDigest (chunk slot) (chunk proposer) ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 4) =
        .ok (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat) ∧
      b.timestamp = context.calldataload (UInt256.ofNat 4) ∧
      b.timestamp.toNat < 2 ^ 64 ∧
      b.index = context.calldataload (UInt256.ofNat 132) ∧
      b.state.executionEnv = context.executionEnv ∧
      b.state.activeWords.toNat = 3 ∧
      Stored b.state 64 (UInt256.ofNat 128) ∧
      b.state.memory.size = 96 := by
  have henvp : (prologue context).executionEnv = context.executionEnv := prologue_environment context
  unfold beforeRoot at h
  obtain ⟨head, hh, h⟩ := bind_success h
  try dsimp only at h
  obtain ⟨branch, hbr, h⟩ := bind_success h
  have hbr' := map_success Error.abi _ _ hbr
  obtain ⟨slot, hs, h⟩ := bind_success h
  have hs' := map_success Error.abi _ _ hs
  obtain ⟨proposer, hp, h⟩ := bind_success h
  have hp' := map_success Error.abi _ _ hp
  obtain ⟨expected, hpair, h⟩ := bind_success h
  have hpair' := map_success Error.bls _ _ hpair
  obtain ⟨u, hsib, h⟩ := bind_success h
  cases u
  obtain ⟨ts, hts, h⟩ := bind_success h
  have hts' := map_success Error.abi _ _ hts
  change Except.ok _ = Except.ok b at h
  cases h
  have hts64 := (SszWitnessAbi.read64_success _ _ _ hts').2
  have hts_eq : ts = BitVec.ofNat 64 (expected.state.calldataload (UInt256.ofNat 4)).toNat := by
    apply BitVec.eq_of_toNat_eq
    rw [BitVec.toNat_ofNat, (SszWitnessAbi.read64_success _ _ _ hts').1]
    exact (Nat.mod_eq_of_lt ts.isLt).symm
  subst hts_eq
  have hdigest := SszShaCommitted.pair_success_digest fuel (prologue context) (chunk slot)
    (chunk proposer) expected hpair' (by rw [prologue_words]; omega)
  have hwords := SszShaCommitted.pair_success_words fuel (prologue context) (chunk slot)
    (chunk proposer) expected hpair'
  have henv := SszWitnessAbi.pair_environment fuel (prologue context) (chunk slot)
    (chunk proposer) expected hpair'
  have henv' : expected.state.executionEnv = context.executionEnv := henv.trans henvp
  have hsize := pair_memory_size fuel (prologue context) (chunk slot) (chunk proposer) expected hpair'
    (by rw [prologue_size]; omega)
  have hstored := SszCompiledMerkle.pair_stored fuel (prologue context) (chunk slot) (chunk proposer)
    expected 64 _ hpair' (prologue_stored context) (Nat.le_refl 64)
  unfold slotSibling at hsib
  try dsimp only at hsib
  split at hsib
  · cases hsib
  · rename_i hlen
    split at hsib
    · cases hsib
    · split at hsib
      · rename_i hsibeq
        refine ⟨slot, proposer, ?_, ?_, ?_, ?_, by change 2 ≤ branch.length; omega, ?_, ?_, ?_, hts64, ?_, henv', ?_, hstored, ?_⟩
        · rw [← header_env context (prologue context) henvp]
          exact hh
        · rw [← tail_env context (prologue context) henvp]
          exact hbr'
        · rw [← read64_env context (prologue context) henvp]
          exact hs'
        · rw [← read64_env context (prologue context) henvp]
          exact hp'
        · rw [← calldataload_env context expected.state henv', hsibeq, hdigest]
        · rw [← read64_env context expected.state henv', ← calldataload_env context expected.state henv']
          exact hts'
        · exact calldataload_env context expected.state henv' _
        · exact calldataload_env context (prologue context) henvp _
        · rw [hwords, prologue_words]
          try decide
        · rw [hsize, prologue_size]
      · cases hsib

/-! ## Phase 2: the root call -/

theorem payload_of_word (ts : UInt256) (hts : ts.toNat < 2 ^ 64) :
    liveBytes ts.toByteArray = SszRootCall.payload (BitVec.ofNat 64 ts.toNat) := by
  unfold liveBytes SszRootCall.payload SszRootCall.toBytes SszVerifierEntry.timestampPayload
  have hd : ((BitVec.ofNat 64 ts.toNat).zeroExtend 256).toNat = ts.toNat := by
    rw [BitVec.toNat_setWidth, BitVec.toNat_ofNat, Nat.mod_eq_of_lt hts]
    exact Nat.mod_eq_of_lt (by have := ts.val.isLt; unfold UInt256.size at this; omega)
  have hb := SszTypedFfiBridge.digest_bytes ((BitVec.ofNat 64 ts.toNat).zeroExtend 256)
  unfold SszTypedFfiBridge.bytes at hb
  rw [hd, ← SszWordBytes.actual_word_bytes] at hb
  rw [← hb, list_toByteArray_data]

theorem rootCall_success (external : StaticCall.External) (world : Live.World)
    (st st' : EVM.State) (ts : UInt256) (out : RootOutcome)
    (h : rootCall external world st ts = .ok (st', out))
    (hf : Stored st 64 (UInt256.ofNat 128)) (hsize : st.memory.size = 96)
    (hw : st.activeWords.toNat = 3) (hts : ts.toNat < 2 ^ 64) :
    out.attempts = (SszRootCall.call external (callerOf st) (BitVec.ofNat 64 ts.toNat) world).attempts ∧
    (out.success = true →
      ∃ data, (SszRootCall.call external (callerOf st) (BitVec.ofNat 64 ts.toNat) world).outcome = .ok data ∧
        st'.returnData = machineBytes data) ∧
    Stored st' 64 (UInt256.ofNat 192) ∧
    Stored st' 96 (UInt256.ofNat 0) ∧
    st'.activeWords.toNat < 2 ^ 64 ∧
    st'.executionEnv = st.executionEnv := by
  have e160 : (UInt256.ofNat 128 + UInt256.ofNat 32).toNat = 160 := by decide +kernel
  have e128 : (UInt256.ofNat 128).toNat = 128 := by decide +kernel
  have enext : UInt256.ofNat 128 + UInt256.ofNat 64 = UInt256.ofNat 192 := by decide +kernel
  have e192 : (UInt256.ofNat 192).toNat = 192 := by decide +kernel
  have e32 : (UInt256.ofNat 32).toNat = 32 := by decide +kernel
  have hw251 : st.activeWords.toNat < 2 ^ 251 := by omega
  unfold rootCall at h
  try dsimp only at h
  rw [stored_load st 64 _ hf (by decide) hw251] at h
  simp only [e160, e128, enext, e192] at h
  -- the three stores
  have wa : (load st 64).2.activeWords.toNat < 2 ^ 64 := load_bounded st 64 (by decide) (by omega)
  have wa3 : (load st 64).2.activeWords.toNat = 3 := by
    change (st.toMachineState.mload (UInt256.ofNat 64)).2.activeWords.toNat = 3
    rw [SszCompiledFrame.load_words _ _ (by decide), hw]
    decide +kernel
  have s160 : Stored (store (load st 64).2 160 ts) 160 ts :=
    stored_written _ 160 _ (by decide) (by show 160 ≤ st.memory.size + 576; omega)
  have z96 : Stored (store (load st 64).2 160 ts) 96 (UInt256.ofNat 0) :=
    stored_pad_zero _ 160 96 ts (by decide) (by show 160 ≤ st.memory.size + 576; omega)
      (by show st.memory.size ≤ 96; omega) (by decide)
  have wb : (store (load st 64).2 160 ts).activeWords.toNat = 6 := by
    change ((load st 64).2.toMachineState.mstore (UInt256.ofNat 160) ts).activeWords.toNat = 6
    rw [SszCompiledFrame.store_words _ _ _ (by decide), wa3]
    decide +kernel
  have s128 : Stored (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 128 (UInt256.ofNat 32) :=
    stored_written _ 128 _ (by decide) (by have := s160.1; omega)
  have s160' := stored_preserved _ 128 160 (UInt256.ofNat 32) ts s160 (by decide) (by omega)
  have z96' := stored_preserved _ 128 96 (UInt256.ofNat 32) _ z96 (by decide) (by omega)
  have wc : (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)).activeWords.toNat = 6 := by
    change ((store (load st 64).2 160 ts).toMachineState.mstore (UInt256.ofNat 128) _).activeWords.toNat = 6
    rw [SszCompiledFrame.store_words _ _ _ (by decide), wb]
    decide +kernel
  -- the guard
  split at h
  · cases h
  · rename_i hguard
    have s64 : Stored (store (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 64
        (UInt256.ofNat 192)) 64 (UInt256.ofNat 192) :=
      stored_written _ 64 _ (by decide) (by have := s128.1; omega)
    have s128' := stored_preserved _ 64 128 (UInt256.ofNat 192) _ s128 (by decide) (by omega)
    have s160'' := stored_preserved _ 64 160 (UInt256.ofNat 192) ts s160' (by decide) (by omega)
    have z96'' := stored_preserved _ 64 96 (UInt256.ofNat 192) _ z96' (by decide) (by omega)
    have wd : (store (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 64
        (UInt256.ofNat 192)).activeWords.toNat = 6 := by
      change ((store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)).toMachineState.mstore
        (UInt256.ofNat 64) _).activeWords.toNat = 6
      rw [SszCompiledFrame.store_words _ 64 _ (by decide), wc]
      try decide
    -- the length load
    rw [stored_load _ 128 _ s128' (by decide) (by omega), e32] at h
    have hread : (load (store (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 64
        (UInt256.ofNat 192)) 128).2.memory.readWithPadding 160 32 = ts.toByteArray := s160''.2.1
    rw [hread, payload_of_word ts hts] at h
    have we : (load (store (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 64
        (UInt256.ofNat 192)) 128).2.activeWords.toNat = 6 := by
      change ((store (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 64
        (UInt256.ofNat 192)).toMachineState.mload (UInt256.ofNat 128)).2.activeWords.toNat = 6
      rw [SszCompiledFrame.load_words _ 128 (by decide), wd]
      try decide
    have s64l := stored_after_load _ 128 64 _ s64 (by decide)
    have z96l := stored_after_load _ 128 96 _ z96'' (by decide)
    have hcall : audit.trio.consolidation.lowLevelStaticCall external
        (callerOf (load (store (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 64
          (UInt256.ofNat 192)) 128).2) SszRootCall.target
        (SszRootCall.payload (BitVec.ofNat 64 ts.toNat)) world =
        SszRootCall.call external (callerOf st) (BitVec.ofNat 64 ts.toNat) world := rfl
    rw [hcall] at h
    have hgrow : (load (store (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 64
        (UInt256.ofNat 192)) 128).2.activeWords.toNat ≤
        (UInt256.ofNat (MachineState.M (MachineState.M
          (load (store (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 64
            (UInt256.ofNat 192)) 128).2.activeWords.toNat 160 32) 0 0)).toNat := by
      rw [we]
      decide +kernel
    have hsmall : (UInt256.ofNat (MachineState.M (MachineState.M
          (load (store (store (store (load st 64).2 160 ts) 128 (UInt256.ofNat 32)) 64
            (UInt256.ofNat 192)) 128).2.activeWords.toNat 160 32) 0 0)).toNat < 2 ^ 64 := by
      rw [we]
      decide +kernel
    cases hc : (SszRootCall.call external (callerOf st) (BitVec.ofNat 64 ts.toNat) world).outcome with
    | ok data =>
      rw [hc] at h
      try dsimp only at h
      obtain ⟨hst, hout⟩ := Prod.mk.inj (Except.ok.inj h)
      subst hst
      subst hout
      refine ⟨rfl, fun _ => ⟨data, rfl, rfl⟩, ?_, ?_, hsmall, rfl⟩
      · exact stored_of_same_memory _ _ 64 _ s64l rfl hgrow
      · exact stored_of_same_memory _ _ 96 _ z96l rfl hgrow
    | error data =>
      rw [hc] at h
      try dsimp only at h
      obtain ⟨hst, hout⟩ := Prod.mk.inj (Except.ok.inj h)
      subst hst
      subst hout
      refine ⟨rfl, fun hfalse => absurd hfalse Bool.false_ne_true, ?_, ?_, hsmall, rfl⟩
      · exact stored_of_same_memory _ _ 64 _ s64l rfl hgrow
      · exact stored_of_same_memory _ _ 96 _ z96l rfl hgrow

/-! ## Phase 3: after the root call -/

theorem afterRoot_success (fuel : Nat) (cfg : Configuration) (st afterState : EVM.State)
    (head : UInt256) (success : Bool) (n : UInt256)
    (h : afterRoot fuel cfg st head success n = .ok afterState)
    (hf : Stored st 64 (UInt256.ofNat 192)) (hz : Stored st 96 (UInt256.ofNat 0))
    (hw : st.activeWords.toNat < 2 ^ 64) (hffi : SszProofCommitted.ShaWidth) :
    success = true ∧ 32 ≤ st.returnData.size ∧
    ∃ slot gi keySlice f branch,
      SszWitnessAbi.read64 st (UInt256.ofNat 36) = .ok slot ∧
      sourceWrapper cfg slot.toFin ⟨n.toNat, n.val.isLt⟩ = .ok gi ∧
      SszWitnessAbi.tail st head (UInt256.ofNat 36) 1 = .ok keySlice ∧ keySlice.length = 48 ∧
      SszWitnessAbi.FieldsMatch st head f ∧
      SszWitnessAbi.tail st head (UInt256.ofNat 4) 32 = .ok branch ∧ branch.length ≤ 2 ^ 64 - 1 ∧
      SszProofCommitted.proofWords branch.length st.executionEnv.calldata branch.offset
        (SszProofCommitted.endOffset branch.offset branch.length) ≠ [] ∧
      SszProofFold.Branch SszProofCalldataStep.ffiPair gi.index.val (validatorLeaf st keySlice.offset f)
        (SszProofCommitted.proofWords branch.length st.executionEnv.calldata branch.offset
          (SszProofCommitted.endOffset branch.offset branch.length))
        (UInt256.ofNat (fromByteArrayBigEndian (st.returnData.extract 0 32))) ∧
      afterState.executionEnv = st.executionEnv := by
  unfold afterRoot at h
  obtain ⟨pr, hpr, h⟩ := bind_success h
  rcases pr with ⟨data, st1⟩
  try dsimp only at h
  have hc := map_success Error.reply _ _ hpr
  obtain ⟨pr2, hpr2, h⟩ := bind_success h
  rcases pr2 with ⟨root, st2⟩
  try dsimp only at h
  have hd := map_success Error.reply _ _ hpr2
  obtain ⟨hsucc, h32, hsize, hF, hroot, hf2, hw2, henv2, hmem2⟩ :=
    reply_success st st1 st2 success data root hc hd hf hz hw
  subst hroot
  obtain ⟨slot, hslot, h⟩ := bind_success h
  have hslot' := map_success Error.abi _ _ hslot
  obtain ⟨raw, hraw, h⟩ := bind_success h
  have hraw' := map_success Error.gindex _ _ hraw
  try dsimp only at h
  obtain ⟨gi, hgi, hrawgi⟩ :=
    SszCompiledGIndex.wrapper_success cfg slot.toFin ⟨n.toNat, n.val.isLt⟩ raw hraw'
  obtain ⟨pr3, hpr3, h⟩ := bind_success h
  rcases pr3 with ⟨ptr, st3⟩
  try dsimp only at h
  have halloc := map_success Error.allocation _ _ hpr3
  have hw2' : st2.activeWords.toNat < 2 ^ 251 := by omega
  have free2 := stored_load st2 64 _ hf2 (by decide) hw2'
  obtain ⟨hptr, hbound, hf3, words3, hw3, henv3, hmono3, _⟩ :=
    allocate_frame st2 st3 ptr (192 + (st.returnData.size + 31) / 32 * 32 + 32) 256 halloc free2
      (by omega) (by omega) (by decide) (by decide) (by have := hf2.2.2; omega) hw2
  subst hptr
  obtain ⟨keySlice, hks, h⟩ := bind_success h
  have hks' := map_success Error.abi _ _ hks
  obtain ⟨key, hkey, h⟩ := bind_success h
  have hkey' := map_success Error.bls _ _ hkey
  try dsimp only at h
  have hkw := SszShaCommitted.pubkey_success_words fuel st3 keySlice.offset keySlice.length key hkey'
  have hkenv := SszWitnessAbi.pubkey_environment fuel st3 keySlice.offset keySlice.length key hkey'
  have hkmem := pubkey_memory fuel st3 keySlice.offset keySlice.length key hkey' (by have := hf3.1; omega)
  have hkdig := SszPubkeyBytes.pubkey_success_digest fuel st3 keySlice.offset keySlice.length key hkey'
    (by omega)
  have hkf : Stored key.state 64
      (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32 + 256)) :=
    ⟨Nat.le_trans hf3.1 hkmem.2, hkmem.1.trans hf3.2.1, by rw [hkw]; have := hf3.2.2; omega⟩
  have hkwb : key.state.activeWords.toNat < 2 ^ 64 := by rw [hkw]; omega
  have wnF : (UInt256.ofNat (192 + (st.returnData.size + 31) / 32 * 32 + 32)).toNat =
      192 + (st.returnData.size + 31) / 32 * 32 + 32 := word_nat _ (by omega)
  simp only [wnF] at h
  obtain ⟨st5, hfields, h⟩ := bind_success h
  have hfields' := map_success liftConsumer _ _ hfields
  have hkstored : Stored (store key.state (192 + (st.returnData.size + 31) / 32 * 32 + 32) key.digest)
      (192 + (st.returnData.size + 31) / 32 * 32 + 32) key.digest :=
    stored_written _ _ _ (by omega) (by have := hkmem.2; omega)
  have hkf' := stored_preserved key.state
    (192 + (st.returnData.size + 31) / 32 * 32 + 32) 64 key.digest _ hkf (by omega) (by omega)
  have hkwb' := store_bounded key.state (192 + (st.returnData.size + 31) / 32 * 32 + 32) key.digest (by omega) hkwb
  obtain ⟨f, fm, s64, sP, s32, s64', s96, s128, s160, s192, s224, hw5, henv5⟩ :=
    fields_effects (store key.state (192 + (st.returnData.size + 31) / 32 * 32 + 32) key.digest) st5
      head (192 + (st.returnData.size + 31) / 32 * 32 + 32) key.digest hfields' (by omega) (by omega)
      hkstored hkf' hkwb'
  obtain ⟨leaf, hleaf, h⟩ := bind_success h
  have hleaf' := map_success liftConsumer _ _ hleaf
  obtain ⟨hdigest, hwl, henvl⟩ :=
    merkle_effects fuel st5 (192 + (st.returnData.size + 31) / 32 * 32 + 32) key.digest _ _ _ _ _ _ _
      leaf hleaf' (by omega) (by omega) s64 hw5 sP s32 s64' s96 s128 s160 s192 s224
  obtain ⟨branch, hbr, h⟩ := bind_success h
  have hbr' := map_success Error.abi _ _ hbr
  have hverify := map_success Error.proof _ _ h
  have henvk : key.state.executionEnv = st.executionEnv := hkenv.trans (henv3.trans henv2)
  have henv5' : st5.executionEnv = st.executionEnv := henv5.trans henvk
  have henvl' : leaf.state.executionEnv = st.executionEnv := henvl.trans henv5'
  obtain ⟨nonempty, hbranch, henvA, _⟩ := SszProofCommitted.verify_success_branch fuel branch.length
    leaf.state afterState (UInt256.ofNat raw) leaf.digest _ branch.offset hverify hffi (by omega)
  rw [henvl'] at nonempty hbranch
  have hrawlt : raw < UInt256.size := by
    rw [hrawgi]
    exact SszCompiledGIndex.packWord_lt gi
  have hrn : (UInt256.ofNat raw).toNat = raw := Nat.mod_eq_of_lt hrawlt
  have hidx : (SszProofCalldataStep.decodeIndex (UInt256.ofNat raw)).toNat = gi.index.val := by
    rw [SszProofCalldataStep.decode_nat, hrn, hrawgi]
    exact SszCompiledGIndex.packWord_div gi
  rw [hidx] at hbranch
  have hwc : (store key.state (192 + (st.returnData.size + 31) / 32 * 32 + 32) key.digest).calldataload
      (UInt256.ofNat 164) = st.calldataload (UInt256.ofNat 164) :=
    calldataload_env st _ henvk _
  have hleafeq : leaf.digest = validatorLeaf st keySlice.offset f := by
    rw [hwc] at hdigest
    rw [hdigest, hkdig.1, pubkeyDigest_env st st3 (henv3.trans henv2)]
    change SszBlsComposition.merkleDigest (SszPubkeyBytes.pubkeyDigest st keySlice.offset)
      (st.calldataload (UInt256.ofNat 164)) _ _ _ _ _ _ = _
    exact SszPubkeyBytes.computed_leaf_typed st keySlice.offset _ f
  rw [hleafeq] at hbranch
  refine ⟨hsucc, h32, slot, gi, keySlice, f, branch, ?_, hgi, ?_, hkdig.2.2, ?_, ?_,
    SszWitnessAbi.tail_success_length _ _ _ _ _ hbr', nonempty, hbranch, henvA.trans henvl'⟩
  · rw [← read64_env st st2 henv2]
    exact hslot'
  · rw [← tail_env st st3 (henv3.trans henv2)]
    exact hks'
  · exact fieldsMatch_env st
      (store key.state (192 + (st.returnData.size + 31) / 32 * 32 + 32) key.digest) henvk head f fm
  · rw [← tail_env st leaf.state henvl']
    exact hbr'

/-! ## The whole entry -/

/-- Success of the selected compiled CL entry. Every operand of the final proof
loop is derived from the same execution: the branch root is the first word of
the bytes returned by the one STATICCALL whose 32-byte payload was read from
machine memory, the branch index is the typed `sourceWrapper` of the slot and
validator index read from this calldata on the constructor words, the leaf is
the typed validator tree of the key octets, decoded fields and calldata word
164, and the siblings are the words the cursor loop actually consumed. Slot
check and root call precede the index and leaf in source order. No index/root
equality, memory shape, stage success or size premise is supplied. -/
theorem run_success (fuel : Nat) (cfg : Configuration) (external : StaticCall.External)
    (world : Live.World) (context afterState : EVM.State)
    (h : (run fuel cfg external world context).outcome = .ok afterState)
    (hffi : SszProofCommitted.ShaWidth) :
    ∃ head branch slot proposer data gi keySlice f,
      header context = .ok head ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 4) 32 = .ok branch ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 36) = .ok slot ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 68) = .ok proposer ∧
      2 ≤ branch.length ∧ branch.length ≤ 2 ^ 64 - 1 ∧
      context.calldataload (branch.offset + UInt256.ofNat ((branch.length - 2) * 32)) =
        SszBlsComposition.pairDigest (chunk slot) (chunk proposer) ∧
      SszWitnessAbi.read64 context (UInt256.ofNat 4) =
        .ok (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat) ∧
      (SszRootCall.call external (callerOf context)
        (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat) world).outcome = .ok data ∧
      (world.core.codeSize SszRootCall.target.val).val ≠ 0 ∧
      external (SszRootCall.request (callerOf context)
        (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat)) world = .success data ∧
      32 ≤ data.length ∧
      (run fuel cfg external world context).attempts =
        [⟨SszRootCall.request (callerOf context)
          (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat), true, true, data, 1⟩] ∧
      sourceWrapper cfg slot.toFin
        ⟨(context.calldataload (UInt256.ofNat 132)).toNat,
          (context.calldataload (UInt256.ofNat 132)).val.isLt⟩ = .ok gi ∧
      SszWitnessAbi.tail context head (UInt256.ofNat 36) 1 = .ok keySlice ∧ keySlice.length = 48 ∧
      SszWitnessAbi.FieldsMatch context head f ∧
      SszProofCommitted.proofWords branch.length context.executionEnv.calldata branch.offset
        (SszProofCommitted.endOffset branch.offset branch.length) ≠ [] ∧
      SszProofFold.Branch SszProofCalldataStep.ffiPair gi.index.val
        (validatorLeaf context keySlice.offset f)
        (SszProofCommitted.proofWords branch.length context.executionEnv.calldata branch.offset
          (SszProofCommitted.endOffset branch.offset branch.length))
        (SszTypedFfiBridge.toWord (SszVerifierEntry.firstWord (SszRootCall.fromBytes data))) ∧
      afterState.executionEnv = context.executionEnv := by
  have hrun := h
  unfold run at hrun
  cases hb : beforeRoot fuel context with
  | error e =>
    rw [hb] at hrun
    try dsimp only at hrun
    cases hrun
  | ok b =>
    rw [hb] at hrun
    try dsimp only at hrun
    cases hr : rootCall external world b.state b.timestamp with
    | error e =>
      rw [hr] at hrun
      try dsimp only at hrun
      cases hrun
    | ok pr =>
      rcases pr with ⟨st, out⟩
      rw [hr] at hrun
      try dsimp only at hrun
      have hatt : (run fuel cfg external world context).attempts = out.attempts := by
        simp only [run, hb, hr]
      obtain ⟨slot, proposer, hhead, hbr, hs, hp, hlen2, hsib, hts, htsv, hts64, hidx, henvb, hwb,
        hfb, hsizeb⟩ := beforeRoot_success fuel context b hb
      obtain ⟨hattempts, hsuccess, hf, hz, hw, henv1⟩ :=
        rootCall_success external world b.state st b.timestamp out hr hfb hsizeb hwb hts64
      obtain ⟨hsucc, h32, slot', gi, keySlice, f, branch', hslot', hgi, hks, hk48, fm, hbr', hbl,
        hne, hbranch, henvA⟩ :=
        afterRoot_success fuel cfg st afterState b.head out.success b.index hrun hf hz hw hffi
      obtain ⟨data, hcall, hret⟩ := hsuccess hsucc
      have henvs : st.executionEnv = context.executionEnv := henv1.trans henvb
      rw [callerOf_env context b.state henvb, htsv] at hcall hattempts
      have hsz : st.returnData.size = data.length := by
        rw [hret]
        exact List.size_toArray
      have hlen : 32 ≤ data.length := by omega
      obtain ⟨hcode, hext, hatt1⟩ := SszRootCall.call_success external (callerOf context)
        (BitVec.ofNat 64 (context.calldataload (UInt256.ofNat 4)).toNat) world data hcall hlen
      rw [read64_env context st henvs] at hslot'
      have hslot_eq : slot' = slot := Except.ok.inj (hslot'.symm.trans hs)
      subst slot'
      rw [tail_env context st henvs] at hbr' hks
      have hbr_eq : branch' = b.branch := Except.ok.inj (hbr'.symm.trans hbr)
      subst hbr_eq
      rw [henvs, validatorLeaf_env context st henvs] at hbranch
      rw [henvs] at hne
      have hroot : UInt256.ofNat (fromByteArrayBigEndian (st.returnData.extract 0 32)) =
          SszTypedFfiBridge.toWord (SszVerifierEntry.firstWord (SszRootCall.fromBytes data)) := by
        rw [fromBytes_typed, root_word_typed (⟨data.toArray⟩ : ByteArray)
          (by show 32 ≤ data.toArray.size; rw [List.size_toArray]; exact hlen), hret]
        rfl
      rw [hroot] at hbranch
      rw [hidx] at hgi
      refine ⟨b.head, b.branch, slot, proposer, data, gi, keySlice, f, hhead, hbr, hs, hp, hlen2,
        hbl, hsib, hts, hcall, hcode, hext, hlen, ?_, hgi, hks, hk48,
        fieldsMatch_env context st henvs _ _ fm, hne, hbranch, henvA.trans henvs⟩
      rw [hatt, hattempts, hatt1]

#print axioms run_success
end LidoSRv3.Audit.Source.SszCompiledClEntry
