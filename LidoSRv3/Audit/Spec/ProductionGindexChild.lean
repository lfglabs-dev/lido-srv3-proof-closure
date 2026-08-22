import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.GIndexConcatCorrespondence

/-!
# Wave 2 W2-GINDEX: toy operationIndex slots

Unregistered child. There are no production `GI_*` literals in-repo.
`Ssz.operationIndex` uses toy slots 2, 3, 4 (`Ssz.lean` 111–114). This
module records those definitional facts and names that a deployed GI
equality cannot be closed here. It does not invent mainnet gindices,
claim EIP-4788, SHA, or Yul, or register a new guarantee.
-/

namespace LidoSRv3.Audit.Spec.ProductionGindexChild

open LidoSRv3.Audit
open LidoSRv3.Audit.Source (GIndexConcatCorrespondence)

/-- The CL validator wrapper binds the toy slot 2, not a production
`GI_FIRST_VALIDATOR_*` literal. -/
theorem cl_validator_index_is_toy :
    (Ssz.operationIndex .clValidatorVerifier).value = 2 :=
  rfl

/-- The CL proof wrapper binds the toy slot 3. -/
theorem cl_proof_index_is_toy :
    (Ssz.operationIndex .clProofVerifier).value = 3 :=
  rfl

/-- The consolidation gateway wrapper binds the toy slot 4. -/
theorem consolidation_index_is_toy :
    (Ssz.operationIndex .consolidationGateway).value = 4 :=
  rfl

/-- Named undischarged: no in-repo production literal, so a deployed-GI
equality hyp cannot be closed here. `False` is the honest inhabitant —
we do not have deployed GI equality. This is not a refutation of a
mainnet constant (none is in-repo). -/
def ProductionGindexBinding : Prop := False

/-- The production binding remains open. Toy slots 2/3/4 are not a
deployed GI equality, and this pack does not invent mainnet gindices. -/
theorem production_gindex_binding_remains_open : True := trivial

/-- Concrete SOURCE concat pair used by `GIndexConcatMutants` (index 2
pow 7 and index 3 pow 11). Toy operands, not production `GI_*`. -/
def toyConcatLhs : GIndexConcatCorrespondence.GIndex :=
  ⟨2, 7, by decide, by decide⟩

def toyConcatRhs : GIndexConcatCorrespondence.GIndex :=
  ⟨3, 11, by decide, by decide⟩

/-- Existing `source_concat_matches_spec`, instantiated on that concrete
pair. Import of the SOURCE child; not a live verifier claim. -/
theorem source_concat_matches_spec :
    GIndexConcatCorrespondence.sourceConcat toyConcatLhs toyConcatRhs =
      GIndexConcatCorrespondence.specConcat toyConcatLhs toyConcatRhs :=
  GIndexConcatCorrespondence.source_concat_matches_spec
    toyConcatLhs toyConcatRhs

end LidoSRv3.Audit.Spec.ProductionGindexChild
