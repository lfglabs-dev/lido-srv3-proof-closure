import LidoSRv3.Audit.Source.SszBlsComposition

/-! Raw witness access in the inspected solc0.8.25/viaIR/200/Cancun
BlsCompositionHarness. The source wrapper is the unmodified pinned validator
leaf followed by SSZ.verifyProof. Field decoding is lazy: key SHA precedes
uint64/Bool checks, and proof-tail access follows all seven pair calls.
Word arithmetic and signed relative-offset guards are retained, including
negative offsets which wrap into earlier calldata. This is an access/call
interpreter, not a proof of the surrounding opcode/memory/gas dispatcher.
-/
namespace LidoSRv3.Audit.Source.SszWitnessAbi
open EvmYul EvmYul.EVM SszBlsComposition SszTypedFfiBridge

inductive Error where
  | abi
  | bls (cause : SszBlsComposition.Error)
  | proof (cause : SszProofCalldataLoop.VerifyError)
  deriving DecidableEq, Repr

structure Slice where
  offset : UInt256
  length : Nat

abbrev abiWord (n : Nat) : UInt256 := UInt256.ofNat n

def header (st : EVM.State) : Except Error UInt256 := do
  let size := abiWord st.executionEnv.calldata.size
  if st.executionEnv.weiValue.toNat ≠ 0 then throw .abi
  if size.toNat < 4 then throw .abi
  if (st.calldataload (abiWord 0)).toNat / 2^224 ≠ 0x3bd227c1 then throw .abi
  if UInt256.sltBool (size - abiWord 4) (abiWord 128) then throw .abi
  let offset := st.calldataload (abiWord 4)
  if offset.toNat > 2^64-1 then throw .abi
  if UInt256.sltBool (size - offset - abiWord 4) (abiWord 256) then throw .abi
  pure offset

/-- Literal dynamic-tail guards. No canonical, positive or aligned relative
pointer is imposed. `scale=1` for pubkey and `scale=32` for proof words. -/
def tail (st : EVM.State) (headOffset fieldOffset : UInt256) (scale : Nat) : Except Error Slice := do
  let size := abiWord st.executionEnv.calldata.size
  let relative := st.calldataload (headOffset + fieldOffset)
  if !(UInt256.sltBool relative (size - headOffset - abiWord 35)) then throw .abi
  let base := headOffset + relative
  let length := st.calldataload (base + abiWord 4)
  if length.toNat > 2^64-1 then throw .abi
  let offset := base + abiWord 36
  if UInt256.sgtBool offset (size - abiWord (scale * length.toNat)) then throw .abi
  pure ⟨offset,length.toNat⟩

def read64 (st : EVM.State) (offset : UInt256) : Except Error (BitVec 64) :=
  let value := st.calldataload offset
  if value.toNat < 2^64 then .ok (BitVec.ofNat 64 value.toNat) else .error .abi

def readBool (st : EVM.State) (offset : UInt256) : Except Error Bool :=
  let value := (st.calldataload offset).toNat
  if value = 0 then .ok false else if value = 1 then .ok true else .error .abi

/-- Source evaluation order, after the raw pubkey SHA has returned. -/
def fields (st : EVM.State) (headOffset : UInt256) : Except Error Fields := do
  let effectiveBalance ← read64 st (headOffset + abiWord 68)
  let slashed ← readBool st (headOffset + abiWord 228)
  let activationEligibilityEpoch ← read64 st (headOffset + abiWord 100)
  let activationEpoch ← read64 st (headOffset + abiWord 132)
  let exitEpoch ← read64 st (headOffset + abiWord 164)
  let withdrawableEpoch ← read64 st (headOffset + abiWord 196)
  pure {effectiveBalance,slashed,activationEligibilityEpoch,activationEpoch,exitEpoch,withdrawableEpoch}

/-- The decoder's fields and raw slices are actually consumed by the existing
BLS primitive and proof loop. No decoded field, key/proof length or leaf digest
is a caller argument. The proof tail is accessed on the state after all BLS
calls, preserving the compiler's competing-failure order. -/
def run (fuel : Nat) (st : EVM.State) : Except Error EVM.State := do
  let h ← header st
  let keySlice ← tail st h (abiWord 36) 1
  let key ← (pubkeyRun fuel st keySlice.offset keySlice.length).mapError Error.bls
  let f ← fields key.state h
  let leaf ← (merkleRun fuel key.state key.digest (key.state.calldataload (abiWord 36))
    (chunk f.effectiveBalance) (chunk (if f.slashed then 1 else 0))
    (chunk f.activationEligibilityEpoch) (chunk f.activationEpoch)
    (chunk f.exitEpoch) (chunk f.withdrawableEpoch)).mapError Error.bls
  let branch ← tail leaf.state h (abiWord 4) 32
  (SszProofCalldataLoop.verify fuel leaf.state
    (leaf.state.calldataload (abiWord 100)) leaf.digest
    (leaf.state.calldataload (abiWord 68)) branch.offset branch.length).mapError Error.proof

/-- The guarded width is derived from the raw word, not supplied as an ABI
premise. Returned uint64 preserves that entire word, including the upper edge. -/
theorem read64_success (st : EVM.State) (offset : UInt256) (value : BitVec 64)
    (h : read64 st offset = .ok value) :
    (st.calldataload offset).toNat = value.toNat ∧ (st.calldataload offset).toNat < 2^64 := by
  unfold read64 at h
  dsimp only at h
  split at h
  · rename_i fit
    cases h
    exact ⟨(Nat.mod_eq_of_lt fit).symm,fit⟩
  · cases h

theorem readBool_success (st : EVM.State) (offset : UInt256) (value : Bool)
    (h : readBool st offset = .ok value) :
    (st.calldataload offset).toNat = if value then 1 else 0 := by
  unfold readBool at h
  dsimp only at h
  split at h
  · rename_i hz
    cases h
    exact hz
  · split at h
    · rename_i ho
      cases h
      exact ho
    · cases h

/-- Successful dynamic access derives the compiler's actual length cap,
without assuming canonical relative offsets or an independent slice extent. -/
theorem tail_success_length (st : EVM.State) (h f : UInt256) (scale : Nat) (s : Slice)
    (ok : tail st h f scale = .ok s) : s.length ≤ 2^64-1 := by
  unfold tail at ok
  dsimp only at ok
  split at ok
  · cases ok
  · simp only [bind,Except.bind,pure,Except.pure] at ok
    split at ok
    · cases ok
    · rename_i hn
      split at ok
      · cases ok
      · cases ok
        exact Nat.le_of_not_gt hn

private theorem bind_success {ε α β : Type} {step : Except ε α}
    {next : α → Except ε β} {value : β} (h : (step >>= next) = .ok value) :
    ∃ x, step = .ok x ∧ next x = .ok value := by
  cases step with
  | error e => cases h
  | ok x => exact ⟨x,rfl,h⟩

private theorem mapped_success {ε α : Type} (f : ε → Error) (step : Except ε α)
    (value : α) (h : step.mapError f = .ok value) : step = .ok value := by
  cases step with
  | error e => cases h
  | ok x => cases h; rfl

/-- CALL restores the caller execution environment even when the callee's
account/substate result is arbitrary. No gas, depth or SHA-output premise. -/
theorem call_environment (fuel gasCost : Nat) (source gas : UInt256)
    (st afterState : EVM.State) (flag : UInt256)
    (h : SszShaCallMemory.callSha (fuel+2) gasCost source gas st = .ok (flag,afterState)) :
    afterState.executionEnv = st.executionEnv := by
  unfold SszShaCallMemory.callSha at h
  rw [EVM.call] at h
  dsimp only at h
  split at h
  · simp only [Bind.bind,Except.bind,Pure.pure,Except.pure] at h
    split at h
    · cases h
    · cases h
      rfl
  · cases h
    rfl

private theorem finish_origin (called : Except EVM.ExecutionException (UInt256 × EVM.State))
    (result : SszBlsComposition.Result) (h : finish called = .ok result) :
    ∃ flag st, called = .ok (flag,st) ∧ result.state.executionEnv = st.executionEnv := by
  cases called with
  | error e => cases h
  | ok pair =>
    rcases pair with ⟨flag,st⟩
    by_cases bad : flag = UInt256.ofNat 0 ∨ st.returnData.size ≠ 32
    · simp only [finish,bad,if_true] at h
      cases h
    · simp only [finish,bad,if_false] at h
      cases h
      exact ⟨flag,st,rfl,rfl⟩

/-- Successful pubkey execution preserves calldata, sender, value and depth
from the actual EVM CALL return rule, not from an arbitrary-callee frame. -/
theorem pubkey_environment (fuel : Nat) (st : EVM.State) (offset : UInt256)
    (length : Nat) (result : SszBlsComposition.Result)
    (h : pubkeyRun fuel st offset length = .ok result) :
    result.state.executionEnv = st.executionEnv := by
  unfold pubkeyRun at h
  split at h
  · cases h
  · obtain ⟨flag,called,hc,he⟩ := finish_origin _ _ h
    let prep := SszShaCallMemory.prepared st offset
    have hec := call_environment fuel
      (Ccall SszShaCallMemory.shaAddress SszShaCallMemory.shaAddress (UInt256.ofNat 0)
        prep.gasAvailable prep.accountMap prep.toMachineState prep.substate)
      (UInt256.ofNat prep.executionEnv.codeOwner.val) prep.gasAvailable prep called flag hc
    exact he.trans hec

theorem pair_environment (fuel : Nat) (st : EVM.State) (left right : UInt256)
    (result : SszBlsComposition.Result) (h : pairRun fuel st left right = .ok result) :
    result.state.executionEnv = st.executionEnv := by
  obtain ⟨flag,called,hc,he⟩ := finish_origin _ _ h
  let prep := preparePair st left right
  have hec := call_environment fuel
    (Ccall SszShaCallMemory.shaAddress SszShaCallMemory.shaAddress (UInt256.ofNat 0)
      prep.gasAvailable prep.accountMap prep.toMachineState prep.substate)
    (UInt256.ofNat prep.executionEnv.codeOwner.val) prep.gasAvailable prep called flag hc
  exact he.trans hec

/-- All seven pairs carry the original caller environment through their
actual intermediate states, including failure-free execution at any resources. -/
theorem merkle_environment (fuel : Nat) (st : EVM.State) (a b c d e f g h : UInt256)
    (result : SszBlsComposition.Result)
    (ok : merkleRun fuel st a b c d e f g h = .ok result) :
    result.state.executionEnv = st.executionEnv := by
  unfold merkleRun at ok
  obtain ⟨r0,c0,ok⟩ := bind_success ok
  obtain ⟨r1,c1,ok⟩ := bind_success ok
  obtain ⟨r2,c2,ok⟩ := bind_success ok
  obtain ⟨r3,c3,ok⟩ := bind_success ok
  obtain ⟨r4,c4,ok⟩ := bind_success ok
  obtain ⟨r5,c5,ok⟩ := bind_success ok
  exact (pair_environment _ _ _ _ _ ok).trans
    ((pair_environment _ _ _ _ _ c5).trans
      ((pair_environment _ _ _ _ _ c4).trans
        ((pair_environment _ _ _ _ _ c3).trans
          ((pair_environment _ _ _ _ _ c2).trans
            ((pair_environment _ _ _ _ _ c1).trans (pair_environment _ _ _ _ _ c0))))))

/-- Independent raw-word interpretation of all six decoded witness fields.
The offsets include the selector base, as in the inspected compiler. -/
structure FieldsMatch (st : EVM.State) (h : UInt256) (f : Fields) : Prop where
  effective : (st.calldataload (h + abiWord 68)).toNat = f.effectiveBalance.toNat
  slashed : (st.calldataload (h + abiWord 228)).toNat = if f.slashed then 1 else 0
  eligible : (st.calldataload (h + abiWord 100)).toNat = f.activationEligibilityEpoch.toNat
  active : (st.calldataload (h + abiWord 132)).toNat = f.activationEpoch.toNat
  exited : (st.calldataload (h + abiWord 164)).toNat = f.exitEpoch.toNat
  withdrawable : (st.calldataload (h + abiWord 196)).toNat = f.withdrawableEpoch.toNat

theorem fields_success (st : EVM.State) (offset : UInt256) (f : Fields)
    (h : fields st offset = .ok f) : FieldsMatch st offset f := by
  unfold fields at h
  obtain ⟨balance,hb,h⟩ := bind_success h
  obtain ⟨slashed,hs,h⟩ := bind_success h
  obtain ⟨eligible,he,h⟩ := bind_success h
  obtain ⟨active,ha,h⟩ := bind_success h
  obtain ⟨exited,hx,h⟩ := bind_success h
  obtain ⟨withdrawable,hw,h⟩ := bind_success h
  cases h
  exact ⟨(read64_success _ _ _ hb).1,readBool_success _ _ _ hs,
    (read64_success _ _ _ he).1,(read64_success _ _ _ ha).1,
    (read64_success _ _ _ hx).1,(read64_success _ _ _ hw).1⟩

/-- The actual raw-data consumer supplies every decoded field and slice to
its BLS/proof calls. The bounds below follow from executed guards. There is no
supplied decoded witness, field-width admission, proof length or leaf digest.
This does not yet establish a full raw-byte/typed-tree success equivalence. -/
theorem run_success_origin (fuel : Nat) (st afterState : EVM.State)
    (h : run fuel st = .ok afterState) :
    ∃ offset keySlice key f leaf branch,
      header st = .ok offset ∧
      tail st offset (abiWord 36) 1 = .ok keySlice ∧
      pubkeyRun fuel st keySlice.offset keySlice.length = .ok key ∧
      fields key.state offset = .ok f ∧
      FieldsMatch key.state offset f ∧
      merkleRun fuel key.state key.digest (key.state.calldataload (abiWord 36))
        (chunk f.effectiveBalance) (chunk (if f.slashed then 1 else 0))
        (chunk f.activationEligibilityEpoch) (chunk f.activationEpoch)
        (chunk f.exitEpoch) (chunk f.withdrawableEpoch) = .ok leaf ∧
      tail leaf.state offset (abiWord 4) 32 = .ok branch ∧
      SszProofCalldataLoop.verify fuel leaf.state
        (leaf.state.calldataload (abiWord 100)) leaf.digest
        (leaf.state.calldataload (abiWord 68)) branch.offset branch.length = .ok afterState ∧
      keySlice.length = 48 ∧ branch.length ≤ 2^64-1 := by
  unfold run at h
  obtain ⟨offset,ho,h⟩ := bind_success h
  obtain ⟨keySlice,hks,h⟩ := bind_success h
  obtain ⟨key,hk,h⟩ := bind_success h
  obtain ⟨f,hf,h⟩ := bind_success h
  obtain ⟨leaf,hl,h⟩ := bind_success h
  obtain ⟨branch,hp,h⟩ := bind_success h
  have hk' := mapped_success _ _ _ hk
  have hl' := mapped_success _ _ _ hl
  have hv := mapped_success _ _ _ h
  have hlen : keySlice.length = 48 := by
    by_contra hn
    rw [pubkey_wrong_length _ _ _ _ hn] at hk'
    cases hk'
  exact ⟨offset,keySlice,key,f,leaf,branch,ho,hks,hk',hf,fields_success _ _ _ hf,
    hl',hp,hv,hlen,tail_success_length _ _ _ _ _ hp⟩

/-- The decoded witness and proof slice are bound to the original raw input.
The pubkey and seven pair calls derive environment preservation; callers do not
supply a decoded witness or a calldata/frame premise for intermediate states. -/
theorem run_success_input_binding (fuel : Nat) (st afterState : EVM.State)
    (h : run fuel st = .ok afterState) :
    ∃ offset keySlice key f leaf branch,
      header st = .ok offset ∧
      tail st offset (abiWord 36) 1 = .ok keySlice ∧
      pubkeyRun fuel st keySlice.offset keySlice.length = .ok key ∧
      key.state.executionEnv = st.executionEnv ∧
      FieldsMatch st offset f ∧
      merkleRun fuel key.state key.digest (st.calldataload (abiWord 36))
        (chunk f.effectiveBalance) (chunk (if f.slashed then 1 else 0))
        (chunk f.activationEligibilityEpoch) (chunk f.activationEpoch)
        (chunk f.exitEpoch) (chunk f.withdrawableEpoch) = .ok leaf ∧
      leaf.state.executionEnv = st.executionEnv ∧
      tail st offset (abiWord 4) 32 = .ok branch ∧
      SszProofCalldataLoop.verify fuel leaf.state
        (st.calldataload (abiWord 100)) leaf.digest
        (st.calldataload (abiWord 68)) branch.offset branch.length = .ok afterState ∧
      keySlice.length = 48 ∧ branch.length ≤ 2^64-1 := by
  obtain ⟨offset,keySlice,key,f,leaf,branch,ho,hks,hk,hf,fm,hl,hp,hv,hkl,hpl⟩ :=
    run_success_origin fuel st afterState h
  have he := pubkey_environment _ _ _ _ _ hk
  have hle := (merkle_environment _ _ _ _ _ _ _ _ _ _ _ hl).trans he
  have fm0 : FieldsMatch st offset f := by
    rcases fm with ⟨hb,hs,hepoch,ha,hx,hw⟩
    constructor
    · simpa only [EvmYul.State.calldataload,he] using hb
    · simpa only [EvmYul.State.calldataload,he] using hs
    · simpa only [EvmYul.State.calldataload,he] using hepoch
    · simpa only [EvmYul.State.calldataload,he] using ha
    · simpa only [EvmYul.State.calldataload,he] using hx
    · simpa only [EvmYul.State.calldataload,he] using hw
  refine ⟨offset,keySlice,key,f,leaf,branch,ho,hks,hk,he,
    fm0,?_,hle,?_,?_,hkl,hpl⟩
  · simpa only [EvmYul.State.calldataload,he] using hl
  · simpa only [tail,EvmYul.State.calldataload,hle] using hp
  · simpa only [EvmYul.State.calldataload,hle] using hv

#print axioms run_success_input_binding
#print axioms pubkey_environment
#print axioms pair_environment
#print axioms merkle_environment
#print axioms call_environment
#print axioms fields_success
#print axioms run_success_origin

#print axioms read64_success
#print axioms readBool_success
#print axioms tail_success_length
end LidoSRv3.Audit.Source.SszWitnessAbi
