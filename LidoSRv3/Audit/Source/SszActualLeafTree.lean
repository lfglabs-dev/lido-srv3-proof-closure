import LidoSRv3.Audit.Source.SszRootCall

/-! Successful typed execution binds the actual SHA outputs to the independent
validator container tree. No globally successful SHA adapter is assumed. -/
namespace LidoSRv3.Audit.Source.SszActualLeafTree
open SszValidatorLeaf SszVerifierEntry SszWrapperIndex SszLittleEndianCorrespondence

/-- The digest carried by each actual interpreted reply. This does not assert
that a call succeeds, has width 32, or implements cryptographic SHA. -/
def outputSha (precompile : Precompile) : Sha := fun bytes => (precompile bytes).output

private theorem bind_success {ε α β : Type} {first : Except ε α}
    {next : α → Except ε β} {result : β} (h : (first >>= next) = .ok result) :
    ∃ value, first = .ok value ∧ next value = .ok result := by
  cases first with
  | error e => cases h
  | ok value => exact ⟨value,rfl,h⟩

theorem checked_sha_output (precompile : Precompile) (bytes : List Byte) (digest : Digest)
    (h : checkedSha precompile bytes = .ok digest) : outputSha precompile bytes = digest :=
  (checked_sha_success_iff precompile bytes digest).mp h |>.2.2

private theorem merkle_success
    (hash : Digest → Digest → Except SszValidatorLeaf.Error Digest) (pureHash : Digest → Digest → Digest)
    (sound : ∀ a b c, hash a b = .ok c → pureHash a b = c)
    (a b c d e f g k result : Digest)
    (h : sourceMerkle hash a b c d e f g k = .ok result) :
    pureHash (pureHash (pureHash a b) (pureHash c d))
      (pureHash (pureHash e f) (pureHash g k)) = result := by
  unfold sourceMerkle at h
  obtain ⟨ab,hab,h⟩ := bind_success h
  obtain ⟨cd,hcd,h⟩ := bind_success h
  obtain ⟨ef,hef,h⟩ := bind_success h
  obtain ⟨gk,hgk,h⟩ := bind_success h
  obtain ⟨abcd,habcd,h⟩ := bind_success h
  obtain ⟨efgk,hefgk,h⟩ := bind_success h
  rw [sound _ _ _ hab,sound _ _ _ hcd,sound _ _ _ hef,sound _ _ _ hgk,
    sound _ _ _ habcd,sound _ _ _ hefgk]
  exact sound _ _ _ h

/-- All eight leaf hashes consume their actual bytes and replies. Successful
execution suffices: failed/short replies elsewhere need not be ruled out. -/
theorem leaf_success_tree (precompile : Precompile) (scratch : Fin 32 → Byte)
    (w : Witness) (credentials leaf : Digest)
    (h : sourceLeaf precompile scratch w credentials = .ok leaf) :
    w.pubkey.length = 48 ∧
    treeDigest (pair (outputSha precompile))
      (validatorTree (outputSha precompile) w credentials) = leaf := by
  have hlen := leaf_success_length precompile scratch w credentials leaf h
  refine ⟨hlen,?_⟩
  unfold sourceLeaf at h
  obtain ⟨key,hkey,h⟩ := bind_success h
  have hkeyBytes : checkedSha precompile (pubkeyBlock w.pubkey) = .ok key := by
    simpa only [sourcePubkeyRoot,hlen,ne_eq,not_true_eq_false,↓reduceIte,
      source_pubkey_padding scratch w.pubkey hlen] using hkey
  have hkeyOutput := checked_sha_output precompile _ _ hkeyBytes
  have hpairs : ∀ a b c, sourcePair precompile a b = .ok c →
      pair (outputSha precompile) a b = c := by
    intro a b c hc
    exact checked_sha_output precompile _ _ hc
  have hm := merkle_success (sourcePair precompile) (pair (outputSha precompile))
    hpairs _ _ _ _ _ _ _ _ _ h
  simpa only [validatorTree,treeDigest,hkeyOutput,source_uint64_chunk,
    source_slashed_chunk] using hm

/-- Every successful proof edge also uses the actual reply's digest. It needs
only the source's CALL-success guard, not the BLS helper's width guard. -/
theorem branch_output_tree (precompile : Precompile) (index : Nat)
    (leaf root : Digest) (proof : List Digest)
    (h : SszProofFold.Branch (foldHash precompile) index leaf proof root) :
    SszProofFold.Branch (fun a b => some (pair (outputSha precompile) a b))
      index leaf proof root := by
  have edge : ∀ a b c, foldHash precompile a b = some c →
      some (pair (outputSha precompile) a b) = some c := by
    intro a b c hc
    unfold foldHash at hc
    dsimp only at hc
    split at hc
    · exact hc
    · cases hc
  induction h with
  | root digest => exact .root digest
  | left hashed above ih => exact .left (edge _ _ _ hashed) ih
  | right hashed above ih => exact .right (edge _ _ _ hashed) ih

#print axioms leaf_success_tree
#print axioms branch_output_tree
end LidoSRv3.Audit.Source.SszActualLeafTree
