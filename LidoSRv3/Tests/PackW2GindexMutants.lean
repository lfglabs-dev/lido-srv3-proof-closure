import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Spec.ProductionGindexChild

/-!
# Wave 2 W2-GINDEX fail-closed vectors

`Ssz.operationIndex .clValidatorVerifier` is the toy slot 2. A claim that
it equals `⟨10, _⟩` is false. The constructor-pin
`ProductionGindexBinding` is inhabited; the kill-line is a wrong packed
word, not uninhabited-False.
-/

namespace LidoSRv3.Tests.PackW2GindexMutants

open LidoSRv3.Audit
open LidoSRv3.Audit.Spec.ProductionGindexChild

/-- Kill-line: claiming `operationIndex .clValidatorVerifier = ⟨10, _⟩`
is false. The in-repo slot is the toy index 2. -/
theorem claimed_cl_validator_index_ten_is_false :
    Ssz.operationIndex .clValidatorVerifier ≠ ⟨10, by decide⟩ := by
  intro h
  have hToy : (Ssz.operationIndex .clValidatorVerifier).value = 2 :=
    cl_validator_index_is_toy
  have hTen : (Ssz.operationIndex .clValidatorVerifier).value = 10 :=
    congrArg Ssz.GeneralizedIndex.value h
  exact (by decide : (2 : Nat) ≠ 10) (hToy.symm.trans hTen)

/-- Mutant packed word: only the pow byte, missing the index field. -/
def mutantPackedWord : Nat := 0x28

/-- Parent-shaped kill-line: a wrong packed word is not the constructor-pin
`ProductionGindexBinding` decode `(150 * 2^40 << 8) | 40`. -/
theorem wrong_packed_word_is_not_production_binding :
    ¬ (mutantPackedWord = (150 * 2 ^ 40 <<< 8) ||| 40) := by
  decide

/-- Positive control: the constructor pin satisfies the binding. -/
theorem production_binding_holds : ProductionGindexBinding :=
  production_gindex_binding

end LidoSRv3.Tests.PackW2GindexMutants
