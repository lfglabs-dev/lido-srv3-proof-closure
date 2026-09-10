import LidoSRv3.Audit.Source.SszTypedFfiBridge

/-! BLS.sol:516–561 and CLValidatorVerifier.sol:60–85, core17005714.
Actual primitive calls with their success-and-size guard, carried state and
computed outputs. CALL/precompile resources only; raw ABI/compiled execution,
full World framing, cryptography and initial-domain reachability remain open.
-/
namespace LidoSRv3.Audit.Source.SszBlsComposition
open EvmYul EvmYul.EVM SszWordBytes SszScratchByteArray SszShaCallBytes
open SszShaCallMemory SszProofLoopResources SszTypedFfiBridge

inductive Error where
  | invalidPubkeyLength | sha256PrecompileFailed | engineFailure
  deriving DecidableEq, Repr

structure Result where
  state : EVM.State
  digest : UInt256

/-- The BLS guard consumes the actual call flag and actual returndata size.
The returned state includes the actual mload memory-extent update. -/
def finish (called : Except EVM.ExecutionException (UInt256 × EVM.State)) : Except Error Result :=
  match called with
  | .error _ => .error .engineFailure
  | .ok (flag, st) =>
    if flag = UInt256.ofNat 0 ∨ st.returnData.size ≠ 32 then
      .error .sha256PrecompileFailed
    else
      let (digest, machine) := st.toMachineState.mload (UInt256.ofNat 0)
      .ok ⟨{ st with toSharedState := { st.toSharedState with toMachineState := machine } }, digest⟩

def preparePair (st : EVM.State) (left right : UInt256) : EVM.State :=
  let first : EVM.State := {st with toSharedState :=
    {st.toSharedState with toMachineState := st.toMachineState.mstore (UInt256.ofNat 0) left}}
  let machine := first.toMachineState.mstore (UInt256.ofNat 32) right
  {first with toSharedState := {first.toSharedState with toMachineState := machine}}

def pairCall (fuel : Nat) (st : EVM.State) (left right : UInt256) :=
  let prep := preparePair st left right
  callSha (fuel+2)
    (Ccall shaAddress shaAddress (UInt256.ofNat 0) prep.gasAvailable
      prep.accountMap prep.toMachineState prep.substate)
    (UInt256.ofNat prep.executionEnv.codeOwner.val) prep.gasAvailable prep

def pairRun (fuel : Nat) (st : EVM.State) (left right : UInt256) : Except Error Result :=
  finish (pairCall fuel st left right)

def pubkeyRun (fuel : Nat) (st : EVM.State) (offset : UInt256) (length : Nat) : Except Error Result :=
  if length ≠ 48 then .error .invalidPubkeyLength else finish (blsCall fuel st offset)

theorem prepared_memory (st : EVM.State) (left right : UInt256) :
    (preparePair st left right).memory =
      fixedBE 32 left.toNat ++ fixedBE 32 right.toNat ++ st.memory.extract 64 st.memory.size := by
  change right.toByteArray.write 0 (left.toByteArray.write 0 st.memory 0 32) 32 32 = _
  rw [SszProofCalldataStep.writes_left _ _ _ (actual_word_size left) (actual_word_size right)]
  simp only [actual_word_bytes]

theorem prepared_words (st : EVM.State) (left right : UInt256) :
    (preparePair st left right).activeWords.toNat = max st.activeWords.toNat 2 := by
  have hs : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
  simp only [preparePair, MachineState.mstore, MachineState.M]
  change (max ((max st.activeWords.toNat 1) % UInt256.size) 2) % UInt256.size = _
  rw [Nat.mod_eq_of_lt (show max st.activeWords.toNat 1 < UInt256.size by unfold UInt256.size at *; omega)]
  have hm : max (max st.activeWords.toNat 1) 2 = max st.activeWords.toNat 2 := by omega
  rw [hm, Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)]

theorem prepared_read (st : EVM.State) (left right : UInt256) :
    (preparePair st left right).memory.readWithPadding 0 64 =
      fixedBE 32 left.toNat ++ fixedBE 32 right.toNat := by
  rw [prepared_memory]
  exact read_prefix _ _ (by simp [fixedBE])

theorem finish_failed_flag (st : EVM.State) :
    finish (.ok (UInt256.ofNat 0, st)) = .error .sha256PrecompileFailed := by
  simp [finish]

theorem finish_wrong_size (flag : UInt256) (st : EVM.State) (h : st.returnData.size ≠ 32) :
    finish (.ok (flag, st)) = .error .sha256PrecompileFailed := by
  simp [finish, h]

theorem pubkey_wrong_length (fuel : Nat) (st : EVM.State) (offset : UInt256) (length : Nat)
    (h : length ≠ 48) : pubkeyRun fuel st offset length = .error .invalidPubkeyLength := by
  simp [pubkeyRun, h]

def pairDigest (left right : UInt256) : UInt256 :=
  UInt256.ofNat (fromByteArrayBigEndian
    (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)))

theorem pair_digest_typed (left right : SszValidatorLeaf.Digest) :
    pairDigest (toWord left) (toWord right) = toWord (SszValidatorLeaf.pair ffiSha left right) :=
  Option.some.inj (pair_transport left right)

/-- One actual pair consumes the two operands, checks its own return and
derives the next state's resources. No successful reply or decoded digest is
an input. The initial bound covers only CALL/precompile charges. -/
theorem pair_success (fuel : Nat) (st : EVM.State) (left right : UInt256)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : 2685 ≤ st.gasAvailable.toNat)
    (hout : (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ result : Result,
      pairRun fuel st left right = .ok result ∧
      result.digest = pairDigest left right ∧
      result.state.executionEnv = st.executionEnv ∧
      result.state.gasAvailable.toNat + Caccess shaAddress st.substate + 84 = st.gasAvailable.toNat ∧
      st.gasAvailable.toNat ≤ result.state.gasAvailable.toNat + 2684 ∧
      result.state.activeWords.toNat = max st.activeWords.toNat 2 := by
  let prep := preparePair st left right
  have hgas : 2685 ≤ prep.gasAvailable.toNat := hg
  obtain ⟨hcgas, _⟩ := call_admitted prep hgas
  have hr := prepared_read st left right
  obtain ⟨called,hcall,hret,hmem,hwords,henv,hgasWord⟩ := call_observations fuel
    (Ccall shaAddress shaAddress (UInt256.ofNat 0) prep.gasAvailable prep.accountMap prep.toMachineState prep.substate)
    (UInt256.ofNat prep.executionEnv.codeOwner.val) prep.gasAvailable prep
    hdepth hcgas (by rw [hr]; simp [fixedBE]) (by rw [hr]; exact hout)
  have hc : pairCall fuel st left right = .ok (UInt256.ofNat 1,called) := hcall
  rw [hr] at hret hmem
  have hnat : called.activeWords.toNat = max st.activeWords.toNat 2 := by
    rw [hwords]
    change (max prep.activeWords.toNat 2) % UInt256.size = _
    rw [prepared_words]
    have hs : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    rw [max_eq_left (by omega), Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)]
  have hm := mload32 called.toMachineState _ _ hmem hout
    (by rw [hnat]; omega) (by rw [hnat]; omega)
  let result : Result := ⟨{called with toSharedState := {called.toSharedState with
    toMachineState := (called.toMachineState.mload (UInt256.ofNat 0)).2}},
    (called.toMachineState.mload (UInt256.ofNat 0)).1⟩
  have hcost : result.state.gasAvailable.toNat + Caccess shaAddress st.substate + 84 = st.gasAvailable.toNat := by
    change called.gasAvailable.toNat + Caccess shaAddress prep.substate + 84 = prep.gasAvailable.toNat
    rw [hgasWord]
    exact returned_gas prep hgas
  refine ⟨result, ?_, hm, henv, hcost, ?_, ?_⟩
  · simp only [pairRun, hc, finish, hret, hout]
    have hn : UInt256.ofNat 1 ≠ UInt256.ofNat 0 := by decide +kernel
    simp only [hn, ne_eq, not_true_eq_false, or_self, ↓reduceIte]
    rfl
  · have ha := access_le st
    omega
  · change (max called.activeWords.toNat 1) % UInt256.size = _
    rw [hnat, max_eq_left (by omega), Nat.mod_eq_of_lt (by
      have hs : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
      unfold UInt256.size at *; omega)]

def budget (calls : Nat) : Nat := 2684 * calls + 1

theorem pair_budget (fuel remaining : Nat) (st : EVM.State) (left right : UInt256)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : budget (remaining+1) ≤ st.gasAvailable.toNat)
    (hout : (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ result : Result,
      pairRun fuel st left right = .ok result ∧
      result.digest = pairDigest left right ∧
      result.state.executionEnv = st.executionEnv ∧
      budget remaining ≤ result.state.gasAvailable.toNat ∧
      result.state.activeWords.toNat < 2^251 := by
  obtain ⟨result, hc, hd, he, _, hg', hw⟩ := pair_success fuel st left right hdepth
    (by unfold budget at hg; omega) hout hwidth
  refine ⟨result, hc, hd, he, ?_, ?_⟩
  · unfold budget at *
    omega
  · rw [hw]
    omega

/-- The seven literal BLS pair calls in CLValidatorVerifier. Every next call
receives the preceding call's state, including its actual gas and memory. -/
def merkleRun (fuel : Nat) (st : EVM.State) (a b c d e f g h : UInt256) : Except Error Result := do
  let l10 ← pairRun fuel st a b
  let l11 ← pairRun fuel l10.state c d
  let l12 ← pairRun fuel l11.state e f
  let l13 ← pairRun fuel l12.state g h
  let l20 ← pairRun fuel l13.state l10.digest l11.digest
  let l21 ← pairRun fuel l20.state l12.digest l13.digest
  pairRun fuel l21.state l20.digest l21.digest

def merkleDigest (a b c d e f g h : UInt256) : UInt256 :=
  pairDigest (pairDigest (pairDigest a b) (pairDigest c d))
    (pairDigest (pairDigest e f) (pairDigest g h))

/-- Initial resources derive every call's admission. The computed root is an
output, not a supplied equality or a field in the input. -/
theorem merkle_success (fuel remaining : Nat) (st : EVM.State) (a b c d e f g h : UInt256)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : budget (remaining+7) ≤ st.gasAvailable.toNat)
    (hffi : ∀ left right : UInt256,
      (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ result : Result,
      merkleRun fuel st a b c d e f g h = .ok result ∧
      result.digest = merkleDigest a b c d e f g h ∧
      result.state.executionEnv = st.executionEnv ∧
      budget remaining ≤ result.state.gasAvailable.toNat ∧
      result.state.activeWords.toNat < 2^251 := by
  obtain ⟨r0,c0,d0,e0,g0,w0⟩ := pair_budget fuel (remaining+6) st a b hdepth hg (hffi _ _) hwidth
  obtain ⟨r1,c1,d1,e1,g1,w1⟩ := pair_budget fuel (remaining+5) r0.state c d
    (by rw [e0]; exact hdepth) g0 (hffi _ _) w0
  obtain ⟨r2,c2,d2,e2,g2,w2⟩ := pair_budget fuel (remaining+4) r1.state e f
    (by rw [e1,e0]; exact hdepth) g1 (hffi _ _) w1
  obtain ⟨r3,c3,d3,e3,g3,w3⟩ := pair_budget fuel (remaining+3) r2.state g h
    (by rw [e2,e1,e0]; exact hdepth) g2 (hffi _ _) w2
  obtain ⟨r4,c4,d4,e4,g4,w4⟩ := pair_budget fuel (remaining+2) r3.state r0.digest r1.digest
    (by rw [e3,e2,e1,e0]; exact hdepth) g3 (hffi _ _) w3
  obtain ⟨r5,c5,d5,e5,g5,w5⟩ := pair_budget fuel (remaining+1) r4.state r2.digest r3.digest
    (by rw [e4,e3,e2,e1,e0]; exact hdepth) g4 (hffi _ _) w4
  obtain ⟨r6,c6,d6,e6,g6,w6⟩ := pair_budget fuel remaining r5.state r4.digest r5.digest
    (by rw [e5,e4,e3,e2,e1,e0]; exact hdepth) g5 (hffi _ _) w5
  refine ⟨r6, ?_, ?_, ?_, g6, w6⟩
  · simp only [merkleRun,c0,c1,c2,c3,c4,c5,c6,bind,Except.bind]
  · rw [d6,d4,d5,d0,d1,d2,d3]
    rfl
  · exact e6.trans (e5.trans (e4.trans (e3.trans (e2.trans (e1.trans e0)))))

theorem merkle_digest_typed (a b c d e f g h : SszValidatorLeaf.Digest) :
    merkleDigest (toWord a) (toWord b) (toWord c) (toWord d)
      (toWord e) (toWord f) (toWord g) (toWord h) =
      toWord (SszValidatorLeaf.pair ffiSha
        (SszValidatorLeaf.pair ffiSha (SszValidatorLeaf.pair ffiSha a b) (SszValidatorLeaf.pair ffiSha c d))
        (SszValidatorLeaf.pair ffiSha (SszValidatorLeaf.pair ffiSha e f) (SszValidatorLeaf.pair ffiSha g h))) := by
  simp only [merkleDigest,pair_digest_typed]

def pubkeyDigest (st : EVM.State) (offset : UInt256) : UInt256 :=
  UInt256.ofNat (fromByteArrayBigEndian
    (shaOutput (SszScratchEvmMemory.rawBlock st.executionEnv.calldata offset.toNat)))

/-- Actual calldata pubkey preparation and call, with derived admission and carried state. -/
theorem pubkey_success (fuel : Nat) (st : EVM.State) (offset : UInt256)
    (hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : 2685 ≤ st.gasAvailable.toNat)
    (hout : (shaOutput (SszScratchEvmMemory.rawBlock st.executionEnv.calldata offset.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ result : Result,
      pubkeyRun fuel st offset 48 = .ok result ∧
      result.digest = pubkeyDigest st offset ∧
      result.state.executionEnv = st.executionEnv ∧
      result.state.gasAvailable.toNat + Caccess shaAddress st.substate + 84 = st.gasAvailable.toNat ∧
      st.gasAvailable.toNat ≤ result.state.gasAvailable.toNat + 2684 ∧
      result.state.activeWords.toNat = max st.activeWords.toNat 2 := by
  let prep := SszShaCallMemory.prepared st offset
  have hgas : 2685 ≤ prep.gasAvailable.toNat := hg
  obtain ⟨hcgas, _⟩ := call_admitted prep hgas
  have hr : prep.memory.readWithPadding 0 64 =
      SszScratchEvmMemory.rawBlock st.executionEnv.calldata offset.toNat :=
    SszScratchEvmMemory.read_exact st.toSharedState offset hfit
  obtain ⟨called,hcall,hret,hmem,hwords,henv,hgasWord⟩ := call_observations fuel
    (Ccall shaAddress shaAddress (UInt256.ofNat 0) prep.gasAvailable prep.accountMap prep.toMachineState prep.substate)
    (UInt256.ofNat prep.executionEnv.codeOwner.val) prep.gasAvailable prep
    hdepth hcgas (by rw [hr]; exact SszScratchEvmMemory.rawBlock_size _ _ hfit) (by rw [hr]; exact hout)
  have hc : blsCall fuel st offset = .ok (UInt256.ofNat 1,called) := hcall
  rw [hr] at hret hmem
  have hnat : called.activeWords.toNat = max st.activeWords.toNat 2 := by
    rw [hwords]
    change (max prep.activeWords.toNat 2) % UInt256.size = _
    rw [SszShaCallMemory.prepared_words]
    have hs : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
    rw [max_eq_left (by omega), Nat.mod_eq_of_lt (by unfold UInt256.size at *; omega)]
  have hm := mload32 called.toMachineState _ _ hmem hout
    (by rw [hnat]; omega) (by rw [hnat]; omega)
  let result : Result := ⟨{called with toSharedState := {called.toSharedState with
    toMachineState := (called.toMachineState.mload (UInt256.ofNat 0)).2}},
    (called.toMachineState.mload (UInt256.ofNat 0)).1⟩
  have hcost : result.state.gasAvailable.toNat + Caccess shaAddress st.substate + 84 = st.gasAvailable.toNat := by
    change called.gasAvailable.toNat + Caccess shaAddress prep.substate + 84 = prep.gasAvailable.toNat
    rw [hgasWord]
    exact returned_gas prep hgas
  refine ⟨result, ?_, hm, henv, hcost, ?_, ?_⟩
  · simp only [pubkeyRun, ne_eq, not_true_eq_false, ↓reduceIte, hc, finish, hret, hout]
    have hn : UInt256.ofNat 1 ≠ UInt256.ofNat 0 := by decide +kernel
    simp only [hn, or_self, ↓reduceIte]
    rfl
  · have ha := access_le st
    omega
  · change (max called.activeWords.toNat 1) % UInt256.size = _
    rw [hnat, max_eq_left (by omega), Nat.mod_eq_of_lt (by
      have hs : st.activeWords.toNat < UInt256.size := st.activeWords.val.isLt
      unfold UInt256.size at *; omega)]

structure Fields where
  effectiveBalance : BitVec 64
  slashed : Bool
  activationEligibilityEpoch : BitVec 64
  activationEpoch : BitVec 64
  exitEpoch : BitVec 64
  withdrawableEpoch : BitVec 64

/-- Witness pubkey octets are read from the same calldata that the primitive
consumes. Typed ABI fields and the admitted offset/extent remain explicit. -/
def witnessAt (st : EVM.State) (offset : UInt256) (fields : Fields) : SszValidatorLeaf.Witness :=
  {pubkey := SszScratchEvmMemory.typedBytes
      (st.executionEnv.calldata.extract offset.toNat (offset.toNat+48)),
    effectiveBalance := fields.effectiveBalance, slashed := fields.slashed,
    activationEligibilityEpoch := fields.activationEligibilityEpoch,
    activationEpoch := fields.activationEpoch, exitEpoch := fields.exitEpoch,
    withdrawableEpoch := fields.withdrawableEpoch}

theorem bytes_typed (raw : ByteArray) : bytes (SszScratchEvmMemory.typedBytes raw) = raw := by
  unfold bytes SszScratchEvmMemory.typedBytes
  apply ByteArray.ext
  simp [Function.comp_def]

theorem pubkey_digest_typed (st : EVM.State) (offset : UInt256) (fields : Fields) :
    pubkeyDigest st offset = toWord (ffiSha
      (SszValidatorLeaf.pubkeyBlock (witnessAt st offset fields).pubkey)) := by
  have hblock : bytes (SszValidatorLeaf.pubkeyBlock (witnessAt st offset fields).pubkey) =
      SszScratchEvmMemory.rawBlock st.executionEnv.calldata offset.toNat := by
    simp only [witnessAt, SszValidatorLeaf.pubkeyBlock, bytes_append, bytes_typed]
    rfl
  simp only [ffiSha, hblock, word_digest]
  rfl

def chunk (x : BitVec 64) : UInt256 :=
  toWord (SszLittleEndianCorrespondence.sourceUint256 (x.zeroExtend 256))

/-- Actual raw pubkey call followed by the seven actual pair calls. Expected
credentials come from the separate caller argument, as in the Solidity body. -/
def leafRun (fuel : Nat) (st : EVM.State) (offset : UInt256) (length : Nat)
    (fields : Fields) (expectedCredentials : SszValidatorLeaf.Digest) : Except Error Result := do
  let key ← pubkeyRun fuel st offset length
  merkleRun fuel key.state key.digest (toWord expectedCredentials)
    (chunk fields.effectiveBalance) (chunk (if fields.slashed then 1 else 0))
    (chunk fields.activationEligibilityEpoch) (chunk fields.activationEpoch)
    (chunk fields.exitEpoch) (chunk fields.withdrawableEpoch)

theorem leaf_success (fuel remaining : Nat) (st : EVM.State) (offset : UInt256)
    (fields : Fields) (expectedCredentials : SszValidatorLeaf.Digest)
    (hfit : offset.toNat + 48 ≤ st.executionEnv.calldata.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : budget (remaining+8) ≤ st.gasAvailable.toNat)
    (hkey : (shaOutput (SszScratchEvmMemory.rawBlock st.executionEnv.calldata offset.toNat)).size = 32)
    (hffi : ∀ left right : UInt256,
      (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ result : Result,
      leafRun fuel st offset 48 fields expectedCredentials = .ok result ∧
      result.digest = toWord (SszWrapperIndex.treeDigest (SszValidatorLeaf.pair ffiSha)
        (SszValidatorLeaf.validatorTree ffiSha (witnessAt st offset fields) expectedCredentials)) ∧
      result.state.executionEnv = st.executionEnv ∧
      budget remaining ≤ result.state.gasAvailable.toNat ∧
      result.state.activeWords.toNat < 2^251 := by
  obtain ⟨key,hcall,hdigest,henv,_,hgas,hwords⟩ := pubkey_success fuel st offset hfit hdepth
    (by unfold budget at hg; omega) hkey hwidth
  have hg' : budget (remaining+7) ≤ key.state.gasAvailable.toNat := by
    unfold budget at *
    omega
  have hw' : key.state.activeWords.toNat < 2^251 := by rw [hwords]; omega
  obtain ⟨result,hmerkle,hd,he,hg'',hw⟩ := merkle_success fuel remaining key.state key.digest
    (toWord expectedCredentials) (chunk fields.effectiveBalance) (chunk (if fields.slashed then 1 else 0))
    (chunk fields.activationEligibilityEpoch) (chunk fields.activationEpoch)
    (chunk fields.exitEpoch) (chunk fields.withdrawableEpoch)
    (by rw [henv]; exact hdepth) hg' hffi hw'
  refine ⟨result, ?_, ?_, he.trans henv, hg'', hw⟩
  · simp only [leafRun,hcall,bind,Except.bind,hmerkle]
  · rw [hd,hdigest,pubkey_digest_typed st offset fields]
    unfold chunk
    rw [merkle_digest_typed]
    simp only [SszValidatorLeaf.validatorTree, SszWrapperIndex.treeDigest,
      SszLittleEndianCorrespondence.source_uint64_chunk]
    cases hs : fields.slashed <;>
      simp only [witnessAt, hs, Bool.false_eq_true, ↓reduceIte]
    all_goals rfl

inductive VerifyError where
  | bls (cause : Error)
  | proof (cause : SszProofCalldataLoop.VerifyError)
  deriving DecidableEq, Repr

/-- The actual leaf result and carried state enter the actual primitive proof
verifier. The root/GIndex are inputs from the still-separate wrapper prefix. -/
def verifyLeaf (fuel : Nat) (st : EVM.State) (keyOffset : UInt256) (keyLength : Nat)
    (fields : Fields) (expectedCredentials : SszValidatorLeaf.Digest)
    (rawIndex root proofOffset : UInt256) (proofLength : Nat) : Except VerifyError EVM.State := do
  let leaf ← (leafRun fuel st keyOffset keyLength fields expectedCredentials).mapError VerifyError.bls
  (SszProofCalldataLoop.verify fuel leaf.state rawIndex leaf.digest root proofOffset proofLength).mapError VerifyError.proof

/-- Composed raw pubkey/pair execution and final verification agree on success
with an independently calculated validator tree and typed branch verifier.
No separately supplied leaf digest or per-call success is a premise. -/
theorem verify_leaf_success (proof : List SszValidatorLeaf.Digest) (fuel : Nat) (st : EVM.State)
    (keyOffset : UInt256) (fields : Fields) (expectedCredentials root : SszValidatorLeaf.Digest)
    (rawIndex : UInt256) (prebytes suffix : ByteArray)
    (hlayout : st.executionEnv.calldata = prebytes ++ bytes (proof.flatMap SszValidatorLeaf.digestBytes) ++ suffix)
    (hfit : keyOffset.toNat + 48 ≤ st.executionEnv.calldata.size)
    (hsize : st.executionEnv.calldata.size < UInt256.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : budget (proof.length+8) ≤ st.gasAvailable.toNat)
    (hkey : (shaOutput (SszScratchEvmMemory.rawBlock st.executionEnv.calldata keyOffset.toNat)).size = 32)
    (hffi : ∀ left right : UInt256,
      (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    (∃ afterState, verifyLeaf fuel st keyOffset 48 fields expectedCredentials rawIndex (toWord root)
      (UInt256.ofNat prebytes.size) proof.length = .ok afterState) ↔
    SszProofFold.sourceVerify (SszVerifierEntry.foldHash (SszValidatorLeaf.standardSha ffiSha))
      (typedIndex rawIndex)
      (SszWrapperIndex.treeDigest (SszValidatorLeaf.pair ffiSha)
        (SszValidatorLeaf.validatorTree ffiSha (witnessAt st keyOffset fields) expectedCredentials))
      proof root = .ok () := by
  obtain ⟨leaf,hcall,hd,he,hg',hw⟩ := leaf_success fuel proof.length st keyOffset fields expectedCredentials
    hfit hdepth hg hkey hffi hwidth
  have h := primitive_typed_success proof fuel leaf.state rawIndex
    (SszWrapperIndex.treeDigest (SszValidatorLeaf.pair ffiSha)
      (SszValidatorLeaf.validatorTree ffiSha (witnessAt st keyOffset fields) expectedCredentials))
    root prebytes suffix (by rw [he]; exact hlayout) (by rw [he]; exact hsize)
    (by rw [he]; exact hdepth) hg' hffi hw
  rw [← h]
  simp only [verifyLeaf,hcall,Except.mapError,bind,Except.bind,hd]
  cases SszProofCalldataLoop.verify fuel leaf.state rawIndex
    (toWord (SszWrapperIndex.treeDigest (SszValidatorLeaf.pair ffiSha)
      (SszValidatorLeaf.validatorTree ffiSha (witnessAt st keyOffset fields) expectedCredentials)))
    (toWord root) (UInt256.ofNat prebytes.size) proof.length <;> simp

end LidoSRv3.Audit.Source.SszBlsComposition
