import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence
import LidoSRv3.Audit.Guarantees.PSsz1

namespace LidoSRv3.Tests.SszRegression

open LidoSRv3.Audit.Ssz

/-- Executable non-cryptographic mixer used only for structural regression vectors. -/
def mix (left right : Node) : Node := left * 131 + right

def validator : Validator := {
  pubkey := 1, withdrawalCredentials := 2, effectiveBalance := 3, slashed := 4,
  activationEligibilityEpoch := 5, activationEpoch := 6, exitEpoch := 7,
  withdrawableEpoch := 8 }

def index : GeneralizedIndex := ⟨2, by decide⟩

def indexThree : GeneralizedIndex := ⟨3, by decide⟩

def indexFour : GeneralizedIndex := ⟨4, by decide⟩

def indexTen : GeneralizedIndex := ⟨10, by decide⟩

def rootIndex : GeneralizedIndex := ⟨1, by decide⟩

def witness : ValidatorWitness :=
  ⟨.clValidatorVerifier, validator, index, pivot index, branchPath index, [17]⟩

def expectedRoot : Node := mix (validatorRoot mix validator) 17

def adversarialPath : List SiblingSide := [.left, .left, .right]

def adversarialBranch : List Node := [17, 18, 19]

def adversarialRoot : Node :=
  traverseBranch mix (validatorRoot mix validator) adversarialPath adversarialBranch

def relabelledWitness : ValidatorWitness := { witness with operation := .clProofVerifier }

/-- Regression: generalized index 2 selects one right sibling on leaf-to-root traversal. -/
example : branchPath index = [.right] := by decide

/-- Regression: the generalized-index pivot is retained as the structural root boundary. -/
example : pivot index = 2 := by decide

/-- Regression family: pivot and path rebuild generalized indices at several depths. -/
example : indexFromPivotPath (pivot index) (branchPath index) = index.value := by decide

example : indexFromPivotPath (pivot indexThree) (branchPath indexThree) = indexThree.value := by decide

example : indexFromPivotPath (pivot indexFour) (branchPath indexFour) = indexFour.value := by decide

example : indexFromPivotPath (pivot indexTen) (branchPath indexTen) = indexTen.value := by decide

/-- Boundary regression: the root index has its pivot but no traversed branch. -/
example : pivot rootIndex = 1 ∧ branchPath rootIndex = [] ∧
    indexFromPivotPath (pivot rootIndex) (branchPath rootIndex) = rootIndex.value := by decide

/-- Negative regression: a path with the wrong low-bit direction misses the index. -/
example : indexFromPivotPath (pivot indexTen) adversarialPath ≠ indexTen.value := by decide

/--
Adversarial regression: even with the correct boundary, depth, arity, and root
for the supplied path, its wrong low bits make the verifier reject the witness.
-/
example : verifyProof mix (validatorRoot mix validator) indexTen (pivot indexTen)
    adversarialPath adversarialBranch adversarialRoot = false := by decide

/-- Regression: named wrappers occupy distinct generalized-index structures. -/
example : operationIndex .clValidatorVerifier ≠ operationIndex .clProofVerifier := by decide

example : operationIndex .clProofVerifier ≠ operationIndex .consolidationGateway := by decide

/-- Regression: a bound operation accepts a correctly shaped structural branch. -/
example : bindOperation .clValidatorVerifier mix witness expectedRoot = true := by decide

/-- Regression: a missing branch is rejected structurally. -/
example : verifyProof mix (validatorRoot mix validator) index (pivot index) (branchPath index)
    [] expectedRoot = false := by decide

/-- Regression: a witness cannot be relabeled as a different named operation. -/
example : bindOperation .clProofVerifier mix witness expectedRoot = false := by decide

/-- Regression: changing the witness tag alone cannot move it to another wrapper slot. -/
example : bindOperation .clProofVerifier mix relabelledWitness expectedRoot = false := by decide

open LidoSRv3.Audit.Source.DepositDataRootCorrespondence

def depositInput : SourceDepositDataRootInput := {
  withdrawalCredentials := [1, 2], publicKey := [3, 4], signature := List.replicate 96 9,
  amountGwei := 32_000_000_000
  withdrawalCredentialsBounded := by
    intro byte h; simp at h; omega
  publicKeyBounded := by
    intro byte h; simp at h; omega
  signatureBounded := by
    intro byte h
    simpa using (List.eq_of_mem_replicate h) ▸ (by decide : (9 : Nat) < 256)
  amountGweiBounded := by decide }

/-- Negative regression: the deposit-data-root structural combiner is not constant. -/
example : sourceCombine depositInput 7 11 = Nat.pair 7 11 := by rfl

/-- Negative regression: incrementing the leaf the witness branch actually carries
changes the reconstructed root, so a mutated deposit-data-root cannot replay it. -/
example : traverseBranch (sourceCombine depositInput)
    (validatorRoot (sourceCombine depositInput) (sourceWitness depositInput).validator)
    (sourceWitness depositInput).path [sourceLeaf depositInput + 1] ≠ sourceNode depositInput := by
  show structuralRoot (sourceAnchor depositInput) (sourceSignatureNode depositInput)
      (sourceLeaf depositInput + 1) ≠ sourceNode depositInput
  rw [structuralRoot_eq]
  simp only [sourceNode]
  simp [structuralEncoding]

/-! ### Digest-binding mutant regressions

These vectors fail under the two mutants the pinned wrapper and the
value-bearing projection rule out: a constant length projection for the witness
leaf, and an unconstrained-width hash-chain result. -/

/-- A pinned-width digest whose leading byte carries the mutation. -/
def markedDigest (b : Nat) (hb : b < 256) : Sha256Digest where
  bytes := b :: List.replicate 31 0
  widthPinned := by simp [SHA256_DIGEST_LENGTH, pinnedConfig]
  bytesBounded := by
    intro x hx
    rcases List.mem_cons.mp hx with rfl | hx
    · exact hb
    · simp [List.eq_of_mem_replicate hx]

/--
Mutant regression (constant projection): the two digests are indistinguishable
under the digest *length*, which is what `sourceNode` used to project.
-/
example : (markedDigest 1 (by decide)).bytes.length =
    (markedDigest 2 (by decide)).bytes.length := by decide

/--
Mutant regression (constant projection): the value-bearing `digestNode` that
`sourceNode` now uses separates exactly those two digests, so a mutated
deposit-data-root can no longer reuse the witness leaf.
-/
example : digestNode (markedDigest 1 (by decide)) ≠ digestNode (markedDigest 2 (by decide)) := by
  decide

/-- Regression: the value-bearing projection is injective on pinned digests. -/
example (left right : Sha256Digest) (h : digestNode left = digestNode right) :
    left.bytes = right.bytes := digestNode_injective left right h

/-- The unconstrained-width hash-chain result that the pinned wrapper rules out. -/
def unconstrainedSha256 (_ : Bytes) : Bytes := List.replicate 20 0

/--
Mutant regression (unconstrained width): an opaque `Bytes → Bytes` result lets
the source's `abi.encodePacked(bytes32, bytes32)` preimage take a layout that is
not the pinned 64-byte one.
-/
example : (unconstrainedSha256 [] ++ unconstrainedSha256 []).length ≠
    2 * SHA256_DIGEST_LENGTH pinnedConfig := by decide

/-- Mutant regression (unconstrained width): every digest carries the pinned width. -/
example (digest : Sha256Digest) :
    digest.bytes.length = SHA256_DIGEST_LENGTH pinnedConfig := digest.widthPinned

/-- With the pinned wrapper the same preimage is forced to the source layout. -/
example (left right : Sha256Digest) :
    (concatDigests left right).length = 2 * SHA256_DIGEST_LENGTH pinnedConfig :=
  concatDigests_length left right

/-- Regression: the pinned constant width stays a separate computation from the leaf. -/
example : sourceNodeWidth depositInput = SHA256_DIGEST_LENGTH pinnedConfig :=
  sourceNodeWidth_pinned depositInput

/-! ### P-SSZ-1 one-object composition smoke test

`composedExample` has the pinned 48/32/96-byte widths every other
`depositInput` above deliberately lacks, so it can actually discharge
`PSsz1.composed_ssz_encoding`'s hypotheses. This shows the four-child
one-object coupling (`ComposedSszInput.rhs`/`digestInput`/`txInput` all
derived from `composedExample.src`) is satisfiable, not vacuously closed. -/

open LidoSRv3.Audit.Guarantees.PSsz1
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.Source.GIndexConcatCorrespondence

def compositionSrc : SourceDepositDataRootInput := {
  withdrawalCredentials := List.replicate 32 1, publicKey := List.replicate 48 2,
  signature := List.replicate 96 3, amountGwei := 32_000_000_000
  withdrawalCredentialsBounded := by
    intro byte h
    simpa using (List.eq_of_mem_replicate h) ▸ (by decide : (1 : Nat) < 256)
  publicKeyBounded := by
    intro byte h
    simpa using (List.eq_of_mem_replicate h) ▸ (by decide : (2 : Nat) < 256)
  signatureBounded := by
    intro byte h
    simpa using (List.eq_of_mem_replicate h) ▸ (by decide : (3 : Nat) < 256)
  amountGweiBounded := by decide }

def composedExample : ComposedSszInput :=
  { src := compositionSrc
    lhs := ⟨2, 7, by decide, by decide⟩
    rhsPow := 11
    rhsPowFits := by decide
    forkVersion := zeros 4
    expectedDepositDataRoot := zeros digestBytes }

/-- Non-vacuity witness: `composed_ssz_encoding` is genuinely invokable on a
pinned-width deposit, its own derived witness/root, and the derived
`rhs`/`digestInput`/`txInput` -- the tightened one-object hypotheses are
jointly satisfiable, not vacuously closed. The type is inferred from the term
so it stays in lockstep with `composed_ssz_encoding`'s conclusion. -/
def composedExample_satisfies_composed_ssz_encoding :=
  composed_ssz_encoding (operation := .clValidatorVerifier)
    (combine := sourceCombine composedExample.src) composedExample
    (by decide) (by decide) (by decide) (by decide) (by decide)
    (LidoSRv3.Audit.Guarantees.PSsz1.sourceWitness_binds_sourceNode compositionSrc
      (by decide) (by decide) (by decide))

end LidoSRv3.Tests.SszRegression
