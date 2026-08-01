import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PSsz1

/-- Structural-only SSZ evidence; no full SSZ, crypto, EVM, or E2E claim. -/
def guarantee : Guarantee := ⟨.pSsz1, [.model, .source]⟩

theorem source_pinned_config_discharges_deposit_data_root
    (input : LidoSRv3.Audit.Source.DepositDataRootCorrespondence.SourceDepositDataRootInput) :
    LidoSRv3.Audit.Source.DepositDataRootCorrespondence.SHA256_DIGEST_LENGTH
      LidoSRv3.Audit.Source.DepositDataRootCorrespondence.pinnedConfig = 32 ∧
    LidoSRv3.Audit.Source.DepositDataRootCorrespondence.PUBKEY_LENGTH
      LidoSRv3.Audit.Source.DepositDataRootCorrespondence.pinnedConfig = 48 ∧
    LidoSRv3.Audit.Source.DepositDataRootCorrespondence.WITHDRAWAL_CREDENTIALS_LENGTH
      LidoSRv3.Audit.Source.DepositDataRootCorrespondence.pinnedConfig = 32 ∧
    LidoSRv3.Audit.Source.DepositDataRootCorrespondence.SIGNATURE_LENGTH
      LidoSRv3.Audit.Source.DepositDataRootCorrespondence.pinnedConfig = 96 ∧
    LidoSRv3.Audit.Source.DepositDataRootCorrespondence.DEPOSIT_DATA_LENGTH
      LidoSRv3.Audit.Source.DepositDataRootCorrespondence.pinnedConfig = 184 ∧
    LidoSRv3.Audit.Ssz.HasGeneralizedIndex
      (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.sourceWitness input).index
      (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.sourceWitness input).pivotBoundary
      (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.sourceWitness input).path ∧
    LidoSRv3.Audit.Ssz.traverseBranch
      (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.sourceCombine input)
      (LidoSRv3.Audit.Ssz.validatorRoot
        (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.sourceCombine input)
        (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.sourceWitness input).validator)
      (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.sourceWitness input).path
      (LidoSRv3.Audit.Source.DepositDataRootCorrespondence.sourceWitness input).branch =
        LidoSRv3.Audit.Source.DepositDataRootCorrespondence.sourceNode input :=
  LidoSRv3.Audit.Source.DepositDataRootCorrespondence.source_pinned_config_discharges_deposit_data_root
    input

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
