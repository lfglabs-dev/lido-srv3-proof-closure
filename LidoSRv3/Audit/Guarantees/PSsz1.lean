import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PSsz1

/-- Structural-only SSZ evidence; no full SSZ, crypto, EVM, or E2E claim. -/
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
