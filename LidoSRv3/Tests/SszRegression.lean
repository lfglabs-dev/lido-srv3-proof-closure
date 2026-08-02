import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence

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
  amountGwei := 32_000_000_000 }

/-- Negative regression: the deposit-data-root structural combiner is not constant. -/
example : sourceCombine depositInput 7 11 = 1810 := by decide

/-- Negative regression: replacing the computed-root branch with a wrong root is rejected. -/
example : traverseBranch (sourceCombine depositInput)
    (validatorRoot (sourceCombine depositInput) (sourceWitness depositInput).validator)
    (sourceWitness depositInput).path [sourceNode depositInput + 1] ≠ sourceNode depositInput := by
  simp [sourceWitness, structuralWitness, sourceCombine, structuralCombine,
    traverseBranch, validatorRoot]

end LidoSRv3.Tests.SszRegression
