import LidoSRv3.Audit.Source.SszProofFold

namespace LidoSRv3.Tests.SszProofFoldMutants
open LidoSRv3.Audit.Source SszProofFold SszWrapperIndex

set_option maxRecDepth 8192
set_option maxHeartbeats 2000000

/-- A noncommutative arithmetic test hash; no SHA collision claim is made. -/
def pair (a b : Nat) : Nat := 1000 * a + b + 7
def hash : Hash Nat := fun a b => some (pair a b)
def failHash : Hash Nat := fun _ _ => none
def sumHash : Hash Nat := fun a b => some (a + b)
def gi (n : Nat) : Fin indexModulus := ⟨n % indexModulus, Nat.mod_lt _ (by decide)⟩

/-- Empty is invalid even when leaf=root, or SHA would fail. -/
example : sourceVerify hash (gi 1) 2 [] 2 = .error .invalidProof := by decide
example : sourceVerify failHash (gi 0) 2 [] 2 = .error .invalidProof := by decide

/-- Extra-item rejection precedes the hash at index zero or one. -/
example : sourceVerify failHash (gi 0) 2 [3] 2 = .error .extraItem := by decide
example : sourceVerify failHash (gi 1) 2 [3] 2 = .error .extraItem := by decide

/-- A genuine hash failure wins over a later extra/missing/root rejection. -/
example : sourceVerify failHash (gi 2) 2 [3, 4] 99 = .error .hashFailure := by decide
example : sourceVerify failHash (gi 4) 2 [3] 99 = .error .hashFailure := by decide

/-- Missing/extra checks win over the final root comparison. -/
example : sourceVerify hash (gi 4) 2 [3] 99 = .error .missingItem := by decide
example : sourceVerify hash (gi 4) 2 [3] 2010 = .error .missingItem := by decide
example : sourceVerify hash (gi 2) 2 [3, 4] 99 = .error .extraItem := by decide

/-- Correct parity is observed BEFORE shifting: left at 2, right at 3. -/
example : sourceVerify hash (gi 2) 2 [3] 2010 = .ok () := by decide
example : sourceVerify hash (gi 3) 2 [3] 3009 = .ok () := by decide
example : sourceVerify hash (gi 2) 2 [3] 3009 = .error .invalidProof := by decide
example : sourceVerify hash (gi 3) 2 [3] 2010 = .error .invalidProof := by decide

/-- Omitting accumulator updates cannot pass by reusing the input leaf. -/
example : sourceVerify hash (gi 2) 2 [3] 2 = .error .invalidProof := by decide

/-- Index 11 uses right/right/left. These numbers independently expand the
noncommutative pair; swapped proof order and shift-before-parity give other roots. -/
example : sourceVerify hash (gi 11) 2 [3, 5, 7] 8016014 = .ok () := by decide
example : sourceVerify hash (gi 11) 2 [7, 5, 3] 8016014 = .error .invalidProof := by decide
example : sourceVerify hash (gi 11) 2 [3, 5, 7] 3016019 = .error .invalidProof := by decide

/-- Full uint248 depth, not an artificial short-proof subdomain. Commutative
addition is used ONLY for these depth boundary tests, never operand-order tests. -/
example : sourceVerify sumHash (gi (2 ^ 247)) 0 (List.replicate 247 1) 247 = .ok () := by decide
example : sourceVerify sumHash (gi (2 ^ 248 - 1)) 0 (List.replicate 247 1) 247 = .ok () := by decide
example : sourceVerify sumHash (gi (2 ^ 247)) 0 (List.replicate 248 1) 248 = .error .extraItem := by decide
example : sourceVerify sumHash (gi (2 ^ 247)) 0 (List.replicate 246 1) 246 = .error .missingItem := by decide

/-- One independently constructed header supplies both its leaf and proof.
The same path/index then drives the digest-carrying verifier. -/
def header : Tree Nat := headerTree 1 2 3 4 0 (.leaf 5)
def headerProof : List Nat := [3, pair 1 2, pair (pair 4 0) (pair 0 0)]
example : treeIndex [false, true, true] = 11 := by decide
example : treeBranch pair header [false, true, true] = some headerProof := by decide
example : treeAt pair header [false, true, true] = some 5 := by decide
example : sourceVerify hash (gi 11) 5 headerProof (treeDigest pair header) = .ok () := by
  exact tree_verifies pair header [false, true, true] headerProof 5 (gi 11)
    (by decide) (by decide) (by decide) (by decide)
example : sourceVerify hash (gi 10) 5 headerProof (treeDigest pair header) = .error .invalidProof := by decide

end LidoSRv3.Tests.SszProofFoldMutants

#print axioms LidoSRv3.Audit.Source.SszProofFold.verify_success_iff
#print axioms LidoSRv3.Audit.Source.SszProofFold.verify_depth
#print axioms LidoSRv3.Audit.Source.SszProofFold.tree_branch_authenticates
#print axioms LidoSRv3.Audit.Source.SszProofFold.tree_verifies
#print axioms LidoSRv3.Audit.Source.SszProofFold.pinned_header_path_index
#print axioms LidoSRv3.Audit.Source.SszProofFold.pinned_encoded_header_verifies
