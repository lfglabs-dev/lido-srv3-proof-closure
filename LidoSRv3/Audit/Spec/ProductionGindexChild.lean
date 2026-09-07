import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.GIndexConcatCorrespondence

/-!
# Wave 2 W2-GINDEX: toy operationIndex slots and constructor-pin GI

`Ssz.operationIndex` still uses toy slots 2, 3, 4 (`Ssz.lean` 111–114).
Those remain leftover record, not a deployed GI.

`ProductionGindexBinding` is now the constructor-pin decode: the packed
word recorded in `audit/p-topup-2-runtime-provenance.json`
`build.constructor_args.g_index_first_validator_curr` (TopUpGateway at
lidofinance/core@17005714) equals `(index << 8) | pow` for
`GI_FIRST_VALIDATOR_CURR` (`150 * 2^40`, pow `40`). That is an in-repo
constructor literal, not a live-deployment identity discharge and not a
claim that EIP-4788, SHA, or Yul are modeled.
-/

namespace LidoSRv3.Audit.Spec.ProductionGindexChild

open LidoSRv3.Audit
open LidoSRv3.Audit.Source.GIndexConcatCorrespondence

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

/-- Constructor-arg pin from
`audit/p-topup-2-runtime-provenance.json`
`build.constructor_args.g_index_first_validator_curr`. In-repo constructor
literal; not a live-deployment identity discharge. -/
def pinnedCoreGiFirstValidatorCurr : Nat :=
  0x0000000000000000000000000000000000000000000000000096000000000028

/-- The constructor-pin packed word decodes as `GIndex.sol`
`(index << 8) | pow` for `GI_FIRST_VALIDATOR_CURR`. -/
def ProductionGindexBinding : Prop :=
  pinnedCoreGiFirstValidatorCurr = (150 * 2 ^ 40 <<< 8) ||| 40

/-- Named discharge: the constructor pin equals the GIndex pack of
index `150 * 2^40` and pow `40`. -/
theorem production_gindex_binding : ProductionGindexBinding := by
  unfold ProductionGindexBinding pinnedCoreGiFirstValidatorCurr
  decide

/-- Concrete SOURCE concat pair used by `GIndexConcatMutants` (index 2
pow 7 and index 3 pow 11). Toy operands, not production `GI_*`. -/
def toyConcatLhs : GIndex :=
  ⟨2, 7, by decide, by decide⟩

def toyConcatRhs : GIndex :=
  ⟨3, 11, by decide, by decide⟩

/-- Existing `source_concat_matches_spec`, instantiated on that concrete
pair. Import of the SOURCE child; not a live verifier claim. -/
theorem source_concat_matches_spec :
    sourceConcat toyConcatLhs toyConcatRhs =
      specConcat toyConcatLhs toyConcatRhs :=
  LidoSRv3.Audit.Source.GIndexConcatCorrespondence.source_concat_matches_spec
    toyConcatLhs toyConcatRhs

end LidoSRv3.Audit.Spec.ProductionGindexChild
