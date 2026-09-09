import LidoSRv3.Audit.Source.SszProofCalldataLoop
import LidoSRv3.Audit.Source.SszVerifierEntry
/-! Representation bridge from the accepted typed SSZ digest interface to the
real EvmYul word codec and opaque SHA FFI, at core17005714. This module proves
byte equality, pair/path transport and final verifier success correspondence.
It does not prove SHA cryptography, raw full entry execution or ABI extraction.
The primitive loop's initial resource/layout domains remain explicit. -/
namespace LidoSRv3.Audit.Source.SszTypedFfiBridge
open EvmYul LidoSRv3.Audit.Source SszWordBytes SszValidatorLeaf SszShaCallMemory SszProofCalldataStep

def toWord (d : Digest) : UInt256 := ⟨d.toFin⟩
def toDigest (w : UInt256) : Digest := ⟨w.val⟩
def bytes (xs : List Byte) : ByteArray := (xs.map fun b => UInt8.ofNat b.toNat).toByteArray

theorem digest_word (d : Digest) : toDigest (toWord d) = d := rfl
theorem word_digest (w : UInt256) : toWord (toDigest w) = w := rfl

theorem fixedLE_get (k n i : Nat) (hi : i < k) :
    (fixedLE k n)[i]'(by rw [fixedLE_length];exact hi) = UInt8.ofNat (n / 256^i) := by
  induction k generalizing n i with
  | zero => omega
  | succ k ih =>
    cases i with
    | zero => simp [fixedLE]
    | succ i =>
      simp only [fixedLE,List.getElem_cons_succ]
      rw [ih (n/256) i (by omega)]
      congr 1
      rw [Nat.div_div_eq_div_mul,Nat.pow_succ]
      rw [Nat.mul_comm]


theorem digest_bytes (d : Digest) : bytes (digestBytes d) = fixedBE 32 d.toNat := by
  unfold bytes fixedBE
  apply congrArg List.toByteArray
  apply List.ext_getElem
  · simp only [digestBytes,List.length_map,List.length_ofFn,List.length_reverse,fixedLE_length]
  · intro i h₁ h₂
    have hi : i < 32 := by simpa only [List.length_map,digestBytes,List.length_ofFn] using h₁
    simp only [List.getElem_map,digestBytes,List.getElem_ofFn]
    rw [List.getElem_reverse]
    simp only [fixedLE_length]
    rw [fixedLE_get _ _ _ (by omega)]
    apply UInt8.toNat_inj.mp
    simp only [UInt8.toNat_ofNat',BitVec.extractLsb'_toNat,Nat.shiftRight_eq_div_pow]
    have hp : 2^(8*(31-i)) = 256^(31-i) := by rw [Nat.pow_mul]
    rw [hp]
    simp only [Nat.mod_mod]


theorem bytes_append (xs ys : List Byte) : bytes (xs++ys) = bytes xs ++ bytes ys := by
  simp [bytes,List.map_append]

/-- Instantiate the earlier abstract byte-level hash with the actual opaque
engine FFI and its big-endian word decoder. This is not an independent SHA
implementation or a proof that the external binary computes standard SHA. -/
def ffiSha : Sha := fun xs => toDigest (UInt256.ofNat (fromByteArrayBigEndian (shaOutput (bytes xs))))

theorem pair_transport (left right : Digest) :
    ffiPair (toWord left) (toWord right) = some (toWord (pair ffiSha left right)) := by
  simp only [ffiPair,pair,ffiSha,bytes_append,digest_bytes]
  rfl

theorem digest_actual_word (w : UInt256) : bytes (digestBytes (toDigest w)) = w.toByteArray := by
  rw [digest_bytes,actual_word_bytes]
  rfl


theorem branch_map {α β : Type} {ha : SszProofFold.Hash α} {hb : SszProofFold.Hash β}
    (f : α → β) (hf : ∀ a b, hb (f a) (f b) = (ha a b).map f)
    {index : Nat} {leaf root : α} {proof : List α}
    (h : SszProofFold.Branch ha index leaf proof root) :
    SszProofFold.Branch hb index (f leaf) (proof.map f) (f root) := by
  induction h with
  | root => exact .root _
  | left hh ha ih => exact .left (by rw [hf,hh];rfl) ih
  | right hh ha ih => exact .right (by rw [hf,hh];rfl) ih

theorem pair_transport_back (left right : UInt256) :
    (some (pair ffiSha (toDigest left) (toDigest right)) : Option Digest) =
      (ffiPair left right).map toDigest := by
  rw [← word_digest left,← word_digest right,pair_transport]
  rfl

theorem branch_transport (index : Nat) (leaf root : Digest) (proof : List Digest) :
    SszProofFold.Branch ffiPair index (toWord leaf) (proof.map toWord) (toWord root) ↔
      SszProofFold.Branch (fun a b => some (pair ffiSha a b)) index leaf proof root := by
  constructor
  · intro h
    have hm := branch_map (hb := fun a b => some (pair ffiSha a b)) toDigest pair_transport_back h
    have hmap : (proof.map toWord).map toDigest = proof := by
      clear h hm
      induction proof with
      | nil => rfl
      | cons a rest ih => simp only [List.map_cons,digest_word,ih]
    rw [hmap,digest_word,digest_word] at hm
    exact hm
  · exact branch_map toWord (fun a b => pair_transport a b)


open SszProofCalldataLoop

def typedIndex (raw : UInt256) : Fin SszWrapperIndex.indexModulus :=
  ⟨(decodeIndex raw).toNat, decode_width raw⟩

theorem proof_bytes (proof : List Digest) :
    wordStream (proof.map toWord) = bytes (proof.flatMap digestBytes) := by
  induction proof with
  | nil => rfl
  | cons d rest ih =>
    rw [List.map_cons,wordStream,List.flatMap_cons,bytes_append,digest_bytes,ih]
    rfl

/-- The raw primitive helper and the earlier typed verifier have the same
success criterion on independently serialized typed proof bytes. The actual
FFI is shared, not replaced by a successful digest assumption. Only the final
verifier is transported: raw leaf/slot/root lookup execution remains open. -/
theorem primitive_typed_success (proof : List Digest) (fuel : Nat) (st : EVM.State)
    (rawIndex : UInt256) (leaf root : Digest) (prebytes suffix : ByteArray)
    (hlayout : st.executionEnv.calldata = prebytes ++ bytes (proof.flatMap digestBytes) ++ suffix)
    (hsize : st.executionEnv.calldata.size < UInt256.size)
    (hdepth : st.executionEnv.depth < 1024)
    (hg : budget proof.length ≤ st.gasAvailable.toNat)
    (hffi : ∀ left right : UInt256,
      (shaOutput (fixedBE 32 left.toNat ++ fixedBE 32 right.toNat)).size = 32)
    (hwidth : st.activeWords.toNat < 2^251) :
    (∃ afterState, verify fuel st rawIndex (toWord leaf) (toWord root)
      (UInt256.ofNat prebytes.size) proof.length = .ok afterState) ↔
    SszProofFold.sourceVerify (SszVerifierEntry.foldHash (standardSha ffiSha))
      (typedIndex rawIndex) leaf proof root = .ok () := by
  have h := SszProofCalldataLoop.verify_success_iff (proof.map toWord) fuel st rawIndex
    (toWord leaf) (toWord root) prebytes suffix (by rw [proof_bytes];exact hlayout) hsize hdepth
    (by simpa only [List.length_map] using hg) hffi hwidth
  simp only [List.length_map,branch_transport] at h
  rw [h,SszProofFold.verify_success_iff,SszVerifierEntry.fold_hash_standard]
  simp only [ne_eq,List.map_eq_nil_iff,typedIndex]

end LidoSRv3.Audit.Source.SszTypedFfiBridge
