import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PSsz1

/-- Structural-only SSZ evidence; no full SSZ, crypto, EVM, or E2E claim. -/
def guarantee : Guarantee := ⟨.pSsz1, [.model]⟩

/--
The structural helper accepts only witnesses whose branch arity matches the
generalized-index path, whose path reconstructs the index from its pivot
boundary, and whose traversal reconstructs the supplied root. This is not a
SHA-256, Solidity, EVM, or end-to-end theorem.
-/
theorem structural_witness_binding_sound
    (h : LidoSRv3.Audit.Ssz.bindOperation operation combine witness expectedRoot = true) :
    witness.operation = operation ∧
      witness.index = LidoSRv3.Audit.Ssz.operationIndex operation ∧
      LidoSRv3.Audit.Ssz.indexFromPivotPath witness.index = witness.index.value ∧
      witness.branch.length = (LidoSRv3.Audit.Ssz.branchPath witness.index).length ∧
      LidoSRv3.Audit.Ssz.traverseBranch combine
        (LidoSRv3.Audit.Ssz.validatorRoot combine witness.validator)
        (LidoSRv3.Audit.Ssz.branchPath witness.index) witness.branch = expectedRoot :=
  LidoSRv3.Audit.Ssz.structural_witness_binding_sound h

end LidoSRv3.Audit.Guarantees.PSsz1
