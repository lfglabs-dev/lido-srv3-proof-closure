import LidoSRv3.Audit.Source.SszValidatorLeaf

namespace LidoSRv3.Tests.SszValidatorLeafMutants
open LidoSRv3.Audit.Source SszValidatorLeaf SszLittleEndianCorrespondence SszWrapperIndex

set_option maxRecDepth 8192
set_option maxHeartbeats 2000000

def oldScratch : Fin 32 → Byte := fun _ => 255
def pubkey : List Byte := List.replicate 32 1 ++ List.replicate 16 2

def witness : Witness := ⟨pubkey, 3, true, 4, 5, 6, 7⟩
def credentials : Digest := 9 <<< (248 : Nat)

/-- Cheap noncommutative test hash. It observes high field bytes, low digest
bytes and pubkey byte47. No assertion about SHA collision resistance is made. -/
def octet (bytes : List Byte) (n : Nat) : Nat := (bytes[n]?.getD 0).toNat
def half (bytes : List Byte) (start : Nat) : Nat :=
  octet bytes start + 256 * octet bytes (start + 1) +
    65536 * octet bytes (start + 29) + 256 * octet bytes (start + 30) + octet bytes (start + 31)
def testSha (bytes : List Byte) : Digest :=
  BitVec.ofNat 256 (2 * half bytes 0 + 3 * half bytes 32 + 7 * octet bytes 47 + 17)

def failedSha : Precompile := fun _ => ⟨false, 32, 123⟩
def shortSha : Precompile := fun _ => ⟨true, 31, 123⟩

/-- Real48byte domain, arbitrary dirty scratch, preserved pubkey tail and zero padding. -/
example : sourcePubkeyBytes oldScratch pubkey = pubkeyBlock pubkey := by decide
example : (sourcePubkeyBytes oldScratch pubkey).length = 64 := by decide
example : (sourcePubkeyBytes oldScratch pubkey).drop 32 =
    List.replicate 16 2 ++ List.replicate 16 0 := by decide
example : sourcePubkeyBytes oldScratch pubkey ≠ pubkey := by decide
example : sourcePubkeyBytes oldScratch pubkey ≠ pubkey ++ List.replicate 16 255 := by decide

/-- The length guard precedes any SHA failure/size check, including oversized input. -/
example : sourcePubkeyRoot failedSha oldScratch [] = .error .invalidPubkeyLength := by decide
example : sourcePubkeyRoot shortSha oldScratch (List.replicate 47 0) = .error .invalidPubkeyLength := by decide
example : sourceLeaf failedSha oldScratch {witness with pubkey := List.replicate 49 0} credentials =
    .error .invalidPubkeyLength := by decide
example : sourceLeaf shortSha oldScratch {witness with pubkey := List.replicate 256 0} credentials =
    .error .invalidPubkeyLength := by decide

/-- Successful CALL alone is insufficient; exact32returndata is load-bearing. -/
example : sourceLeaf failedSha oldScratch witness credentials = .error .sha256PrecompileFailed := by decide
example : sourceLeaf shortSha oldScratch witness credentials = .error .sha256PrecompileFailed := by decide
example : checkedSha (fun _ => ⟨true, 33, 123⟩) [] = .error .sha256PrecompileFailed := by decide
example : checkedSha (fun _ => ⟨true, 0, 123⟩) [] = .error .sha256PrecompileFailed := by decide
example : checkedSha (fun _ => ⟨true, 32, 123⟩) [] = .ok 123 := by decide

/-- BLS pair memory interpretation carries exactly two ordered32byte words. -/
example : (digestBytes credentials ++ digestBytes 1).length = 64 := by decide
example : (digestBytes credentials ++ digestBytes 1)[0]? = some 9 ∧
    (digestBytes credentials ++ digestBytes 1)[63]? = some 1 := by decide

/-- slashed follows the actual uint64 integer cast, and epochs are little endian. -/
example : sourceSlashed true = (1 : Digest) <<< (248 : Nat) ∧ sourceSlashed false = 0 := by decide
example : sourceSlashed true ≠ (1 : Digest) := by decide
example : digestBytes (sourceUint256 ((0x0102 : BitVec 64).zeroExtend 256)) =
    [2, 1] ++ List.replicate 30 0 := by decide

/-- Fields are independently selected in the eight-leaf semantic tree. -/
example : subtreeAt (validatorTree testSha witness credentials) [false, false, true] =
    some (.leaf credentials) := by rfl
example : subtreeAt (validatorTree testSha witness credentials) [true, false, false] =
    some (.leaf (uint64Chunk 4)) := by rfl
example : subtreeAt (validatorTree testSha witness credentials) [true, false, true] =
    some (.leaf (uint64Chunk 5)) := by rfl

/-- Full source execution consumes raw witness fields and the expected-WC argument. -/
example : sourceLeaf (standardSha testSha) oldScratch witness credentials =
    .ok (treeDigest (pair testSha) (validatorTree testSha witness credentials)) := by
  rw [source_leaf_eq_tree, if_pos (by decide)]

example : treeDigest (pair testSha) (validatorTree testSha witness credentials) ≠
    treeDigest (pair testSha) (validatorTree testSha witness 0) := by decide
example : treeDigest (pair testSha) (validatorTree testSha witness credentials) ≠
    treeDigest (pair testSha) (validatorTree testSha {witness with slashed := false} credentials) := by decide
example : treeDigest (pair testSha) (validatorTree testSha witness credentials) ≠
    treeDigest (pair testSha) (validatorTree testSha
      {witness with activationEligibilityEpoch := 5, activationEpoch := 4} credentials) := by decide

end LidoSRv3.Tests.SszValidatorLeafMutants

#print axioms LidoSRv3.Audit.Source.SszValidatorLeaf.source_pubkey_padding
#print axioms LidoSRv3.Audit.Source.SszValidatorLeaf.checked_sha_success_iff
#print axioms LidoSRv3.Audit.Source.SszValidatorLeaf.leaf_success_length
#print axioms LidoSRv3.Audit.Source.SszValidatorLeaf.source_slashed_chunk
#print axioms LidoSRv3.Audit.Source.SszValidatorLeaf.source_leaf_eq_tree
#print axioms LidoSRv3.Audit.Source.SszValidatorLeaf.validator_header_consumer
