import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Spec.ProductionGindexChild

/-!
# Wave 2 W2-GINDEX fail-closed vectors

`Ssz.operationIndex .clValidatorVerifier` is the toy slot 2. A claim that
it equals `⟨10, _⟩` is false. There is no in-repo production `GI_*`
binding to mutate toward.
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

/-- The named production binding is uninhabited here: no deployed GI
literal exists in-repo to close it. -/
theorem production_binding_uninhabited :
    ¬ ProductionGindexBinding :=
  id

end LidoSRv3.Tests.PackW2GindexMutants
