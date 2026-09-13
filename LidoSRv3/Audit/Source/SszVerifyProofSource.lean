import LidoSRv3.Audit.Source.SszGindexSource
import LidoSRv3.Audit.Source.Sha256OpacitySource

/-! # SSZ Merkle-proof verification source model

**General rule (Thomas 2026-09-13, chantier 3 SSZ derivation
prerequisite): the pinned CLValidatorVerifier verifies a Merkle
proof by folding SHA-256 over the sibling path from the leaf up to
the root, then comparing with the beacon block root. This
composition names the pinned verifyProof semantics.**

**Status:** first real source-level naming of the SSZ Merkle-proof
verification path folded through the shared SHA-256 oracle. -/

namespace LidoSRv3.Audit.Source.SszVerifyProofSource

open LidoSRv3.Audit.Source.SszGindexSource
open LidoSRv3.Audit.Source.Sha256OpacitySource

/-- Concatenate two 32-byte hashes to form the 64-byte input for the
next SHA-256 iteration. -/
def concatHashes (left right : List Nat) : List Nat := left ++ right

/-- SSZ Merkle-proof-step: given a current-node hash, a sibling
hash, and the current gindex's parity (0 = left, 1 = right),
compute the parent-node hash. -/
def stepUp (oracle : Sha256Oracle) (current sibling : List Nat)
    (parity : Nat) : List Nat :=
  if parity = 0 then oracle.hash (concatHashes current sibling)
  else oracle.hash (concatHashes sibling current)

/-- Recursive fold over a sibling path. -/
def foldPath (oracle : Sha256Oracle) (leaf : List Nat)
    (siblings : List (List Nat × Nat)) : List Nat :=
  siblings.foldl
    (fun acc (sibParity : List Nat × Nat) =>
      stepUp oracle acc sibParity.1 sibParity.2)
    leaf

/-- Empty proof: the root equals the leaf. -/
theorem foldPath_nil (oracle : Sha256Oracle) (leaf : List Nat) :
    foldPath oracle leaf [] = leaf := by
  simp [foldPath]

/-- Single-step fold. -/
theorem foldPath_singleton
    (oracle : Sha256Oracle) (leaf sib : List Nat) (parity : Nat) :
    foldPath oracle leaf [(sib, parity)]
      = stepUp oracle leaf sib parity := by
  simp [foldPath]

/-- verifyProof: check whether folding the sibling path from the
leaf reproduces the claimed root. -/
def verifyProof
    (oracle : Sha256Oracle) (leaf : List Nat)
    (siblings : List (List Nat × Nat)) (root : List Nat) : Bool :=
  decide (foldPath oracle leaf siblings = root)

/-- Under the pinned equality premise (folded path equals root),
verifyProof returns true. -/
theorem verifyProof_true_of_folded_eq
    {oracle : Sha256Oracle} {leaf : List Nat}
    {siblings : List (List Nat × Nat)} {root : List Nat}
    (hEq : foldPath oracle leaf siblings = root) :
    verifyProof oracle leaf siblings root = true := by
  simp [verifyProof, hEq]

end LidoSRv3.Audit.Source.SszVerifyProofSource
