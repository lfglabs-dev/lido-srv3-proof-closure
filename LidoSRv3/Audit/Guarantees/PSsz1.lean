import LidoSRv3.Audit.Ssz
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence
import LidoSRv3.Audit.Source.GIndexConcatCorrespondence
import LidoSRv3.Audit.Verity.SszAbstractDigest
import LidoSRv3.Audit.Verity.SszTxSimulation
import LidoSRv3.Audit.Verity.SszEncodingTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PSsz1

open LidoSRv3.Audit
open LidoSRv3.Audit.Source.DepositDataRootCorrespondence
open LidoSRv3.Audit.Source.GIndexConcatCorrespondence
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.Verity.SszTxSimulation
open LidoSRv3.Audit.Verity.SszEncodingTx

def guarantee : Guarantee := ⟨.pSsz1, [.model, .source, .verityTx]⟩

/--
Parent abstract composition of the four P-SSZ-1 children.  Each conjunct is
the existing child theorem; none is weakened.

1. structural witness binding (`Audit.Ssz`)
2. pinned deposit-data-root source layout (`DepositDataRootCorrespondence`)
3. `GIndex.concat` source transcription (`GIndexConcatCorrespondence`)
4. seven-call SHA-256 digest composition (`SszAbstractDigest`) plus the
   root-match verification control flow (`SszTxSimulation`)
-/
theorem composed_ssz_encoding
    {operation : Ssz.Operation} {combine : Ssz.Node → Ssz.Node → Ssz.Node}
    {witness : Ssz.ValidatorWitness} {expectedRoot : Ssz.Node}
    (hBind : Ssz.bindOperation operation combine witness expectedRoot = true)
    (src : SourceDepositDataRootInput)
    (hPublicKey : src.publicKey.length = PUBKEY_LENGTH pinnedConfig)
    (hWithdrawalCredentials : src.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig)
    (hSignature : src.signature.length = SIGNATURE_LENGTH pinnedConfig)
    (lhs rhs : GIndex)
    (digestInput : Inputs)
    (txInput : TxInputs)
    (hTxWidths : exactTxWidths txInput) :
    -- Child: structural witness binding.
    (witness.operation = operation ∧
      witness.index = Ssz.operationIndex operation ∧
      Ssz.HasGeneralizedIndex witness.index witness.pivotBoundary witness.path ∧
      witness.branch.length = witness.path.length ∧
      Ssz.traverseBranch combine (Ssz.validatorRoot combine witness.validator)
        witness.path witness.branch = expectedRoot) ∧
    -- Child: pinned deposit-data-root source layout and witness.
    (SHA256_DIGEST_LENGTH pinnedConfig = 32 ∧
      PUBKEY_LENGTH pinnedConfig = 48 ∧
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig = 32 ∧
      SIGNATURE_LENGTH pinnedConfig = 96 ∧
      DEPOSIT_DATA_LENGTH pinnedConfig = 184 ∧
      src.publicKey.length = 48 ∧
      src.withdrawalCredentials.length = 32 ∧
      src.signature.length = 96 ∧
      (∀ byte ∈ src.withdrawalCredentials, byte < 256) ∧
      (∀ byte ∈ src.publicKey, byte < 256) ∧
      (∀ byte ∈ src.signature, byte < 256) ∧
      src.amountGwei < 2 ^ 256 ∧
      signatureRoot src = computeSignatureRoot src.signature ∧
      Ssz.HasGeneralizedIndex (sourceWitness src).index
        (sourceWitness src).pivotBoundary (sourceWitness src).path ∧
      Ssz.traverseBranch (sourceCombine src)
        (Ssz.validatorRoot (sourceCombine src) (sourceWitness src).validator)
        (sourceWitness src).path (sourceWitness src).branch = sourceNode src) ∧
    -- Child: GIndex.concat source transcription.
    sourceConcat lhs rhs = specConcat lhs rhs ∧
    -- Child: seven-call digest composition and root-match control flow.
    (ExactDigestComposition digestInput ∧
      (digestPreimages txInput.toInputs).length = 7 ∧
      (runVerification txInput = .accept ↔
        computedRoot txInput = txInput.expectedDepositDataRoot) ∧
      exactTxWidths txInput) := by
  refine ⟨Ssz.structural_witness_binding_sound hBind,
    source_pinned_config_discharges_deposit_data_root src
      hPublicKey hWithdrawalCredentials hSignature,
    encoding_uses_source_concat lhs rhs,
    ⟨digest_composition digestInput,
      digest_preimages_length txInput.toInputs,
      accepted_iff_root_matches txInput, hTxWidths⟩⟩

/--
Faithful VERITY_TX closure for P-SSZ-1. One `Contract.run` transaction
computes the four children simultaneously — structural witness binding,
pinned deposit-data-root, `GIndex.concat`, and the seven-call
digest/root-match — persists every child through `writeSlot`/`writeMapUint`,
and matches the independently stated source view.

This is not a lift of `verity_tx_simulates_pinned_source` alone: a commit
implies the same structural-witness conjunct the parent abstract proves from
`bindOperation`, and the concat and digest children are composed in the
same statement. Reverts after intermediate writes restore the pre-call
snapshot.
-/
theorem verity_tx_simulates_ssz_encoding
    (input : EncodingInput) (state : Verity.ContractState) :
    observe ((encode input).run state) = sourceView input ∧
      ((observe ((encode input).run state)).status = .committed →
        structuralOk input = true ∧
          structuralWitnessConjunct input ∧
          (observe ((encode input).run state)).observables.bound = 1 ∧
          (observe ((encode input).run state)).observables.operation =
            operationWord input.operation ∧
          (observe ((encode input).run state)).observables.index =
            indexWord input.witness.index ∧
          (observe ((encode input).run state)).observables.pivotBoundary =
            nodeWord input.witness.pivotBoundary ∧
          (observe ((encode input).run state)).observables.traversedRoot =
            nodeWord (traversedRoot input)) ∧
      sourceConcat input.lhs input.rhs = specConcat input.lhs input.rhs ∧
      (ExactDigestComposition input.deposit ∧
        (digestChain input.deposit).length = 7) ∧
      ∀ reason rollback,
        (encode input).run state = .revert reason rollback →
          rollback = state :=
  ⟨verity_tx_simulates_pinned_source input state,
    encoding_commits_structural_witness input state,
    encoding_uses_source_concat input.lhs input.rhs,
    encoding_uses_exact_digest input.deposit,
    fun reason rollback h =>
      revert_restores_snapshot input false state rollback reason h⟩

theorem verity_tx_two_batch_rolls_back
    (first second : EncodingInput) (state rollback : Verity.ContractState)
    (reason : String)
    (h : (encodeTwo first second true).run state = .revert reason rollback) :
    rollback = state :=
  revert_restores_snapshot_two first second true state rollback reason h

end LidoSRv3.Audit.Guarantees.PSsz1
