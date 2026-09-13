import LidoSRv3.Audit.Source.Sha256OpacitySource

/-! # SSZ Validator hash-tree-root layout source model

**General rule (Thomas 2026-09-13, chantier 3 SSZ derivation
prerequisite): the pinned CLValidatorVerifier._validatorHashTreeRoot
computes the SSZ hash-tree-root of a BeaconState Validator
container. The eight fields (pubkey, withdrawalCredentials,
effectiveBalance, slashed, activationEligibilityEpoch,
activationEpoch, exitEpoch, withdrawableEpoch) are merkleized
pairwise via SHA-256. This composition names the layout.**

**Status:** first real source-level naming of the pinned Validator
SSZ hash-tree-root layout. -/

namespace LidoSRv3.Audit.Source.SszValidatorHashTreeRootSource

open LidoSRv3.Audit.Source.Sha256OpacitySource

/-- Source-level SSZ Validator container: eight fields per pinned
BeaconState schema. All fields are byte-list encoded. -/
structure Validator : Type where
  pubkey : List Nat
  withdrawalCredentials : List Nat
  effectiveBalance : List Nat
  slashed : List Nat
  activationEligibilityEpoch : List Nat
  activationEpoch : List Nat
  exitEpoch : List Nat
  withdrawableEpoch : List Nat

/-- Concatenate two 32-byte hashes into a 64-byte input. -/
def concatHashes (l r : List Nat) : List Nat := l ++ r

/-- Pairwise merkleize: hash two adjacent leaves into their parent. -/
def merkleizePair (oracle : Sha256Oracle) (l r : List Nat) : List Nat :=
  oracle.hash (concatHashes l r)

/-- SSZ Validator hash-tree-root: pairwise merkleize the 8 fields
then reduce the 4-leaf level, then the 2-leaf level, then the root.
Real derivation of the pinned CLValidatorVerifier layout. -/
def validatorHashTreeRoot (oracle : Sha256Oracle) (v : Validator) : List Nat :=
  let level0_01 := merkleizePair oracle v.pubkey v.withdrawalCredentials
  let level0_23 := merkleizePair oracle v.effectiveBalance v.slashed
  let level0_45 := merkleizePair oracle v.activationEligibilityEpoch
                                        v.activationEpoch
  let level0_67 := merkleizePair oracle v.exitEpoch v.withdrawableEpoch
  let level1_01 := merkleizePair oracle level0_01 level0_23
  let level1_23 := merkleizePair oracle level0_45 level0_67
  merkleizePair oracle level1_01 level1_23

/-- Definitionally computes to the pinned merkleization schedule. -/
theorem validatorHashTreeRoot_eq
    (oracle : Sha256Oracle) (v : Validator) :
    validatorHashTreeRoot oracle v =
      merkleizePair oracle
        (merkleizePair oracle
          (merkleizePair oracle v.pubkey v.withdrawalCredentials)
          (merkleizePair oracle v.effectiveBalance v.slashed))
        (merkleizePair oracle
          (merkleizePair oracle v.activationEligibilityEpoch
                                 v.activationEpoch)
          (merkleizePair oracle v.exitEpoch v.withdrawableEpoch)) :=
  rfl

end LidoSRv3.Audit.Source.SszValidatorHashTreeRootSource
