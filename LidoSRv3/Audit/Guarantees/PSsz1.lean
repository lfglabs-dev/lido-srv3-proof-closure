import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PSsz1

/--
P-SSZ-1 guarantee facade.  Structural-only SSZ evidence.

The single theorem exposed here is `structural_witness_binding_sound`.

What this facade does **not** claim: full SSZ serialization or `hashTreeRoot`
correctness, SHA-256 cryptographic correctness, deployed-precompile
equivalence, Solidity or EVM execution semantics, transaction-level behavior,
runtime/codehash provenance, and end-to-end validator provenance.

The pinned-source deposit-data-root correspondence is deliberately **not**
re-exported through this facade.  It is stated and proved next to the source
shape it constrains, as
`Source.DepositDataRootCorrespondence.source_pinned_config_discharges_deposit_data_root`,
and it is reported from that module by `LidoSRv3.Audit.Trust`.
-/
def guarantee : Guarantee := ⟨.pSsz1, [.model]⟩

/--
The structural helper accepts only witnesses whose independently supplied
pivot/path data has the claimed generalized-index meaning, whose branch arity
matches that supplied path, and whose traversal reconstructs the supplied root.
This is not an SSZ, SHA-256, Solidity, EVM, transaction, source, or end-to-end
theorem.
-/
theorem structural_witness_binding_sound
    (h : LidoSRv3.Audit.Ssz.bindOperation operation combine witness expectedRoot = true) :
      witness.operation = operation ∧
      witness.index = LidoSRv3.Audit.Ssz.operationIndex operation ∧
      LidoSRv3.Audit.Ssz.HasGeneralizedIndex witness.index witness.pivotBoundary
        witness.path ∧
      witness.branch.length = witness.path.length ∧
      LidoSRv3.Audit.Ssz.traverseBranch combine
        (LidoSRv3.Audit.Ssz.validatorRoot combine witness.validator)
        witness.path witness.branch = expectedRoot :=
  LidoSRv3.Audit.Ssz.structural_witness_binding_sound h

end LidoSRv3.Audit.Guarantees.PSsz1
