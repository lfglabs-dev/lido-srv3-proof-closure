import LidoSRv3.Audit.Source.SszProofLoopResources
/-! Iterated SSZ calldata, scratch and SHA primitives at core17005714.
The loop follows sourceStep's actual next offset and continuation flag. The
natural round bound is interpreter fuel, supplied as the decoded proof length
in the refinement theorem; it does not replace the source continuation check.
A conservative initial budget derives each CALL's resource admission. Surrounding
memory/control opcodes are not charged by these primitive semantics.
-/
namespace LidoSRv3.Audit.Source.SszProofCalldataLoop
open EvmYul EvmYul.EVM
open SszProofCalldataStep SszProofLoopResources SszShaCallMemory

def loop : Nat → Nat → EVM.State → UInt256 → UInt256 → UInt256 → UInt256 → Except StepError StepResult
  | 0, _, _, _, _, _, _ => .error .engineFailure
  | rounds+1, fuel, st, index, leaf, offset, endOffset => do
      let result ← sourceStep fuel st index leaf offset endOffset
      if result.continues then
        loop rounds fuel result.state result.index result.leaf result.offset endOffset
      else .ok result

def budget (rounds : Nat) : Nat := 2684 * rounds + 1

theorem word_ext {a b : UInt256} (h : a.toNat = b.toNat) : a = b :=
  congrArg UInt256.mk (Fin.ext h)

theorem ofNat_nat (w : UInt256) : UInt256.ofNat w.toNat = w := by
  apply word_ext
  exact Nat.mod_eq_of_lt w.val.isLt

theorem layout_shift (prebytes suffix : ByteArray) (before rest : List UInt256) (a b : UInt256) :
    layout prebytes suffix before a (b::rest) = layout prebytes suffix (before++[a]) b rest := by
  simp [layout,List.append_assoc]

theorem end_shift (prebytes : ByteArray) (before rest : List UInt256) (a b : UInt256) :
    sourceEnd prebytes (before++a::b::rest).length =
      sourceEnd prebytes ((before++[a])++b::rest).length := by
  simp [List.append_assoc]

theorem step_complete (fuel : Nat) (st : EVM.State) (index leaf : UInt256)
    (prebytes suffix : ByteArray) (before after : List UInt256) (sibling : UInt256)
    (hlayout : st.executionEnv.calldata = layout prebytes suffix before sibling after)
    (hsize : st.executionEnv.calldata.size < UInt256.size)
    (hindex : 1 < index.toNat)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : 2685 ≤ st.gasAvailable.toNat)
    (hout : (shaOutput (pairInput index leaf sibling)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    ∃ result : StepResult,
      sourceStep fuel st index leaf (proofOffset prebytes before)
        (sourceEnd prebytes (before ++ sibling :: after).length) = .ok result ∧
      SszProofFold.sourceFold ffiPair index.toNat leaf [sibling] = .ok (result.index.toNat,result.leaf) ∧
      result.offset = proofOffset prebytes (before++[sibling]) ∧
      result.continues = decide (after ≠ []) ∧
      result.state.executionEnv = st.executionEnv ∧
      st.gasAvailable.toNat ≤ result.state.gasAvailable.toNat + 2684 ∧
      result.state.activeWords.toNat < 2^251 := by
  have hgp : 2685 ≤ (preparedStep st index leaf (proofOffset prebytes before)).gasAvailable.toNat := hg
  obtain ⟨hgas,hpaid⟩ := call_admitted (preparedStep st index leaf (proofOffset prebytes before)) hgp
  obtain ⟨result,hstep,hfold,hoff,hcont,_⟩ := sourceStep_success fuel st index leaf prebytes suffix before after sibling
    hlayout hsize hindex hdepth hgas hpaid hout hwidth
  obtain ⟨other,hother,henv,hgasEq,hwords⟩ := step_resources fuel st index leaf prebytes suffix before after sibling
    hlayout hsize hindex hdepth hg hout
  have heq : result = other := Except.ok.inj (hstep.symm.trans hother)
  subst other
  have hcursor : cursor prebytes (before++[sibling]) = cursor prebytes before + 32 := by
    simp [cursor,List.length_append,Nat.mul_add,Nat.add_assoc]
  have hOffset : result.offset = proofOffset prebytes (before++[sibling]) := by
    rw [proofOffset,hcursor,← hoff,ofNat_nat]
  refine ⟨result,hstep,hfold,hOffset,hcont,henv,?_,?_⟩
  · have haccess := access_le st
    omega
  · rw [hwords]
    omega


def observe (out : Except StepError StepResult) : Except StepError (Nat × UInt256) :=
  out.map fun result => (result.index.toNat,result.leaf)

def foldProjection (out : Except SszProofFold.Error (Nat × UInt256)) : Except StepError (Nat × UInt256) :=
  out.mapError fun e => match e with
    | .extraItem => .extraItem
    | .hashFailure => .hashFailure
    | .invalidProof | .missingItem => .engineFailure

theorem fold_cons_of_step {α : Type} (hash : SszProofFold.Hash α) (index next : Nat)
    (leaf sibling digest : α) (rest : List α)
    (h : SszProofFold.sourceFold hash index leaf [sibling] = .ok (next,digest)) :
    SszProofFold.sourceFold hash index leaf (sibling::rest) =
      SszProofFold.sourceFold hash next digest rest := by
  simp only [SszProofFold.sourceFold] at h ⊢
  split at h
  · cases h
  · split at h
    · cases h
    · cases Except.ok.inj h
      simp_all



theorem loop_extra (rounds fuel : Nat) (st : EVM.State) (index leaf offset ending : UInt256)
    (hi : index.toNat ≤ 1) : loop (rounds+1) fuel st index leaf offset ending = .error .extraItem := by
  simp only [loop,sourceStep_extra fuel st index leaf offset ending hi]
  rfl

theorem fold_extra (index leaf sibling : UInt256) (rest : List UInt256)
    (hi : index.toNat ≤ 1) :
    SszProofFold.sourceFold ffiPair index.toNat leaf (sibling::rest) = .error .extraItem := by
  have hp : index.toNat / 2 = 0 := by omega
  simp [SszProofFold.sourceFold,Nat.shiftRight_eq_div_pow,hp]

open SszWordBytes

/-- All observed outcomes of the nonempty primitive loop match the existing
FFI-backed word fold. Layout, initial representation/depth and opaque hash
output length remain explicit; per-iteration gas is derived, not supplied.
This does not assert standardSha, cryptography or compiled opcode execution. -/
theorem loop_refines (rest : List UInt256) (fuel : Nat) (st : EVM.State)
    (index leaf sibling : UInt256) (prebytes suffix : ByteArray) (before : List UInt256)
    (hlayout : st.executionEnv.calldata = layout prebytes suffix before sibling rest)
    (hsize : st.executionEnv.calldata.size < UInt256.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : budget (rest.length+1) ≤ st.gasAvailable.toNat)
    (hffi : ∀ left right : UInt256,
      (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    observe (loop (rest.length+1) fuel st index leaf (proofOffset prebytes before)
      (sourceEnd prebytes (before++sibling::rest).length)) =
      foldProjection (SszProofFold.sourceFold ffiPair index.toNat leaf (sibling::rest)) := by
  induction rest generalizing st index leaf sibling before with
  | nil =>
    by_cases hi : index.toNat ≤ 1
    · rw [loop_extra _ _ _ _ _ _ _ hi,fold_extra _ _ _ _ hi]
      rfl
    · have hout : (shaOutput (pairInput index leaf sibling)).size = 32 := by
        unfold pairInput
        split <;> apply hffi
      obtain ⟨result,hstep,hfold,hoff,hcont,henv,hcost,hwords⟩ := step_complete fuel st index leaf
        prebytes suffix before [] sibling hlayout hsize (by omega) hdepth (by simpa [budget] using hg) hout hwidth
      change observe (loop 1 fuel st index leaf (proofOffset prebytes before)
        (sourceEnd prebytes (before++[sibling]).length)) = _
      rw [loop,hstep]
      have hc : result.continues = false := by simpa using hcont
      simp only [bind,Except.bind,hc,hfold]
      rfl
  | cons second rest ih =>
    by_cases hi : index.toNat ≤ 1
    · rw [loop_extra _ _ _ _ _ _ _ hi,fold_extra _ _ _ _ hi]
      rfl
    · have hout : (shaOutput (pairInput index leaf sibling)).size = 32 := by
        unfold pairInput
        split <;> apply hffi
      have hgas : 2685 ≤ st.gasAvailable.toNat := by
        simp only [budget,List.length_cons,Nat.mul_add,Nat.mul_one] at hg
        omega
      obtain ⟨result,hstep,hfold,hoff,hcont,henv,hcost,hwords⟩ := step_complete fuel st index leaf
        prebytes suffix before (second::rest) sibling hlayout hsize (by omega) hdepth hgas hout hwidth
      have hnextlayout : result.state.executionEnv.calldata = layout prebytes suffix (before++[sibling]) second rest := by
        rw [henv,hlayout,layout_shift]
      have hnsize : result.state.executionEnv.calldata.size < UInt256.size := by rwa [henv]
      have hndepth : result.state.executionEnv.depth < 1024 := by rwa [henv]
      have hngas : budget (rest.length+1) ≤ result.state.gasAvailable.toNat := by
        simp only [budget,List.length_cons,Nat.mul_add,Nat.mul_one] at hg ⊢
        omega
      have hn := ih result.state result.index result.leaf second (before++[sibling])
        hnextlayout hnsize hndepth hngas hwords
      rw [fold_cons_of_step ffiPair index.toNat result.index.toNat leaf sibling result.leaf (second::rest) hfold]
      change observe (loop ((rest.length+1)+1) fuel st index leaf (proofOffset prebytes before)
        (sourceEnd prebytes (before++sibling::second::rest).length)) = _
      rw [loop,hstep]
      have hc : result.continues = true := by simpa using hcont
      simp only [bind,Except.bind,hc,↓reduceIte]
      rw [hoff,end_shift]
      exact hn


inductive VerifyError where
  | invalidProof | extraItem | hashFailure | missingItem | engineFailure
  deriving DecidableEq, Repr

def liftError : StepError → VerifyError
  | .extraItem => .extraItem
  | .hashFailure => .hashFailure
  | .engineFailure => .engineFailure

def finish (root : UInt256) (r : StepResult) : Except VerifyError EVM.State :=
  if r.index = UInt256.ofNat 1 then
    if r.leaf = root then .ok r.state else .error .invalidProof
  else .error .missingItem

def verify (fuel : Nat) (st : EVM.State) (rawIndex leaf root offset : UInt256) (count : Nat) :
    Except VerifyError EVM.State :=
  let index := decodeIndex rawIndex
  if count = 0 then .error .invalidProof
  else match loop count fuel st index leaf offset (offset + (UInt256.ofNat count <<< UInt256.ofNat 5)) with
    | .error e => .error (liftError e)
    | .ok r => finish root r

theorem word_one (w : UInt256) : w = UInt256.ofNat 1 ↔ w.toNat = 1 := by
  constructor
  · intro h;rw [h];rfl
  · intro h;exact word_ext h

theorem finish_success (root : UInt256) (r : StepResult) :
    (∃ afterState, finish root r = .ok afterState) ↔ r.index.toNat = 1 ∧ r.leaf = root := by
  by_cases hi : r.index.toNat = 1 <;> by_cases hl : r.leaf = root <;>
    simp [finish,word_one,hi,hl]

theorem observe_success (out : Except StepError StepResult) (index : Nat) (leaf : UInt256) :
    observe out = .ok (index,leaf) ↔
      ∃ r, out = .ok r ∧ r.index.toNat = index ∧ r.leaf = leaf := by
  cases out with
  | error e => simp [observe,Except.map]
  | ok r => simp [observe,Except.map]

theorem projection_success (out : Except SszProofFold.Error (Nat × UInt256)) (value : Nat × UInt256) :
    foldProjection out = .ok value ↔ out = .ok value := by
  cases out with
  | error e => cases e <;> simp [foldProjection,Except.mapError]
  | ok v => simp [foldProjection,Except.mapError]

/-- Exact success criterion of the full primitive-based helper. The supplied
calldata layout, initial CALL budget/depth/memory domain and opaque FFI32
condition do not supply a successful execution, expected digest or root match.
The independent Branch is over the same FFI word pair, not standardSha or an
authenticated consensus tree. Error selectors/rollback/ABI/X remain outside
this interpreter's correspondence claim. -/
theorem verify_success_iff (proof : List UInt256) (fuel : Nat) (st : EVM.State)
    (rawIndex leaf root : UInt256) (prebytes suffix : ByteArray)
    (hlayout : st.executionEnv.calldata = prebytes ++ wordStream proof ++ suffix)
    (hsize : st.executionEnv.calldata.size < UInt256.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : budget proof.length ≤ st.gasAvailable.toNat)
    (hffi : ∀ left right : UInt256,
      (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    (∃ afterState, verify fuel st rawIndex leaf root (UInt256.ofNat prebytes.size) proof.length = .ok afterState) ↔
      proof ≠ [] ∧ SszProofFold.Branch ffiPair (decodeIndex rawIndex).toNat leaf proof root := by
  cases proof with
  | nil => simp [verify]
  | cons sibling rest =>
    have hr := loop_refines rest fuel st (decodeIndex rawIndex) leaf sibling prebytes suffix []
      hlayout hsize hdepth hg hffi hwidth
    have hoff : proofOffset prebytes [] = UInt256.ofNat prebytes.size := by simp [proofOffset,cursor]
    rw [hoff] at hr
    simp only [List.nil_append,List.length_cons] at hr
    have hloop :
        (∃ r, loop (rest.length+1) fuel st (decodeIndex rawIndex) leaf (UInt256.ofNat prebytes.size)
          (sourceEnd prebytes (rest.length+1)) = .ok r ∧ r.index.toNat = 1 ∧ r.leaf = root) ↔
        SszProofFold.Branch ffiPair (decodeIndex rawIndex).toNat leaf (sibling::rest) root := by
      rw [← observe_success,hr,projection_success,SszProofFold.fold_root_iff]
    have hnon : (sibling::rest) ≠ [] := by simp
    rw [and_iff_right hnon]
    rw [← hloop]
    unfold verify
    simp only [List.length_cons,Nat.add_eq_zero_iff,one_ne_zero,and_false,↓reduceIte]
    change (∃ afterState : EVM.State,
      (match loop (rest.length+1) fuel st (decodeIndex rawIndex) leaf (UInt256.ofNat prebytes.size)
        (sourceEnd prebytes (rest.length+1)) with
        | .error e => (Except.error (liftError e) : Except VerifyError EVM.State)
        | .ok r => finish root r) = .ok afterState) ↔ _
    generalize ho : loop (rest.length+1) fuel st (decodeIndex rawIndex) leaf (UInt256.ofNat prebytes.size)
      (sourceEnd prebytes (rest.length+1)) = out
    change (∃ afterState : EVM.State, (match out with | .error e => (Except.error (liftError e) : Except VerifyError EVM.State) | .ok r => finish root r) = .ok afterState) ↔ _
    cases out with
    | error e => simp
    | ok r => simpa using finish_success root r


/-- Structural branch depth bounds the conservative CALL-only budget. This is
not a total Solidity transaction gas estimate. -/
theorem decoded_branch_budget (raw leaf root : UInt256) (proof : List UInt256)
    (h : SszProofFold.Branch ffiPair (decodeIndex raw).toNat leaf proof root) :
    proof.length ≤ 247 ∧ budget proof.length ≤ 662949 := by
  have interval := SszProofFold.branch_interval h
  have hi := decode_width raw
  have hp : 2 ^ proof.length < 2 ^ 248 := lt_of_le_of_lt interval.1 hi
  have hn : proof.length < 248 := (Nat.pow_lt_pow_iff_right (by decide)).mp hp
  simp only [budget]
  omega

theorem verify_empty (fuel : Nat) (st : EVM.State) (raw leaf root offset : UInt256) :
    verify fuel st raw leaf root offset 0 = .error .invalidProof := by rfl

theorem finish_missing (root : UInt256) (r : StepResult) (hi : r.index ≠ UInt256.ofNat 1) :
    finish root r = .error .missingItem := by simp [finish,hi]

theorem finish_mismatch (root : UInt256) (r : StepResult)
    (hi : r.index = UInt256.ofNat 1) (hr : r.leaf ≠ root) :
    finish root r = .error .invalidProof := by simp [finish,hi,hr]

end LidoSRv3.Audit.Source.SszProofCalldataLoop
