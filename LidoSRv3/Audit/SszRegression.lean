import LidoSRv3.Audit.Ssz

namespace LidoSRv3.Audit.SszRegression

open LidoSRv3.Audit.Ssz

/-- Executable non-cryptographic mixer used only for structural regression vectors. -/
def mix (left right : Node) : Node := left * 131 + right

def validator : Validator := {
  pubkey := 1, withdrawalCredentials := 2, effectiveBalance := 3, slashed := 4,
  activationEligibilityEpoch := 5, activationEpoch := 6, exitEpoch := 7,
  withdrawableEpoch := 8 }

def index : GeneralizedIndex := ⟨2, by decide⟩

def witness : ValidatorWitness := ⟨validator, index, [17]⟩

def expectedRoot : Node := mix (validatorRoot mix validator) 17

/-- Regression: generalized index 2 selects one right sibling on leaf-to-root traversal. -/
example : branchPath index = [.right] := by decide

/-- Regression: the generalized-index pivot is retained as the structural root boundary. -/
example : pivot index = 2 := by decide

/-- Regression: a bound operation accepts a correctly shaped structural branch. -/
example : bindOperation .clValidatorVerifier mix witness expectedRoot = true := by decide

/-- Regression: a missing branch is rejected structurally. -/
example : verifyProof mix (validatorRoot mix validator) index [] expectedRoot = false := by decide

end LidoSRv3.Audit.SszRegression
