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

/-- One-object composition input. The four P-SSZ-1 children are gathered on a
single record instead of four independently typed parameters: `src` is the
one deposit whose derived witness (`sourceWitness src`) and root
(`sourceNode src`) the structural-bind hypothesis below must name, `lhs`/`rhs`
feed the `GIndex.concat` child, and `digestInput`/`txInput` feed the
seven-call digest / root-match child. -/
structure ComposedSszInput where
  src : SourceDepositDataRootInput
  lhs : GIndex
  rhs : GIndex
  digestInput : Inputs
  txInput : TxInputs

/-- Composed on one object, not an independent `And` of four unrelated
arguments: the structural-bind hypothesis names `sourceWitness input.src` and
`sourceNode input.src` directly, so a witness bound for one deposit can no
longer be paired with the pinned deposit-data-root layout of a *different*
deposit (report issue #4's "witness for validator 1, root for validator 2"
counterexample). `GIndexConcatCorrespondence.encoding_uses_source_concat` and
the seven-call digest / root-match control flow remain their own children.
Still not `SSZ.verifyProof` on production gindices; SHA-256 functional
correctness remains `A-SHA256-FFI`. -/
theorem composed_ssz_encoding
    {operation : Ssz.Operation} {combine : Ssz.Node → Ssz.Node → Ssz.Node}
    (input : ComposedSszInput)
    (hPublicKey : input.src.publicKey.length = PUBKEY_LENGTH pinnedConfig)
    (hWithdrawalCredentials : input.src.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig)
    (hSignature : input.src.signature.length = SIGNATURE_LENGTH pinnedConfig)
    (hTxWidths : exactTxWidths input.txInput)
    (hBind : Ssz.bindOperation operation combine (sourceWitness input.src)
      (sourceNode input.src) = true) :
    -- Child: structural witness binding, on the SAME witness/root that the
    -- deposit-data-root child below discharges for `input.src` -- one shared
    -- object, not an independently supplied witness/expectedRoot pair.
    ((sourceWitness input.src).operation = operation ∧
      (sourceWitness input.src).index = Ssz.operationIndex operation ∧
      Ssz.HasGeneralizedIndex (sourceWitness input.src).index
        (sourceWitness input.src).pivotBoundary (sourceWitness input.src).path ∧
      (sourceWitness input.src).branch.length = (sourceWitness input.src).path.length ∧
      Ssz.traverseBranch combine
        (Ssz.validatorRoot combine (sourceWitness input.src).validator)
        (sourceWitness input.src).path (sourceWitness input.src).branch =
        sourceNode input.src) ∧
    -- Child: pinned deposit-data-root source layout and witness, for the
    -- same `input.src`.
    (SHA256_DIGEST_LENGTH pinnedConfig = 32 ∧
      PUBKEY_LENGTH pinnedConfig = 48 ∧
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig = 32 ∧
      SIGNATURE_LENGTH pinnedConfig = 96 ∧
      DEPOSIT_DATA_LENGTH pinnedConfig = 184 ∧
      input.src.publicKey.length = 48 ∧
      input.src.withdrawalCredentials.length = 32 ∧
      input.src.signature.length = 96 ∧
      (∀ byte ∈ input.src.withdrawalCredentials, byte < 256) ∧
      (∀ byte ∈ input.src.publicKey, byte < 256) ∧
      (∀ byte ∈ input.src.signature, byte < 256) ∧
      input.src.amountGwei < 2 ^ 256 ∧
      signatureRoot input.src = computeSignatureRoot input.src.signature ∧
      Ssz.HasGeneralizedIndex (sourceWitness input.src).index
        (sourceWitness input.src).pivotBoundary (sourceWitness input.src).path ∧
      Ssz.traverseBranch (sourceCombine input.src)
        (Ssz.validatorRoot (sourceCombine input.src) (sourceWitness input.src).validator)
        (sourceWitness input.src).path (sourceWitness input.src).branch =
        sourceNode input.src) ∧
    -- Child: GIndex.concat source transcription.
    sourceConcat input.lhs input.rhs = specConcat input.lhs input.rhs ∧
    -- Child: seven-call digest composition and root-match control flow.
    (ExactDigestComposition input.digestInput ∧
      (digestPreimages input.txInput.toInputs).length = 7 ∧
      (runVerification input.txInput = .accept ↔
        computedRoot input.txInput = input.txInput.expectedDepositDataRoot) ∧
      exactTxWidths input.txInput) := by
  refine ⟨Ssz.structural_witness_binding_sound hBind,
    source_pinned_config_discharges_deposit_data_root input.src
      hPublicKey hWithdrawalCredentials hSignature,
    encoding_uses_source_concat input.lhs input.rhs,
    ⟨digest_composition input.digestInput,
      digest_preimages_length input.txInput.toInputs,
      accepted_iff_root_matches input.txInput, hTxWidths⟩⟩

/-- Kill-line: an inconsistent witness across children is rejected. Binding
`sourceWitness srcA` (child 1) against `sourceNode srcB` (child 2's root for a
*different* deposit) fails `bindOperation`, whenever the two deposits'
public-key anchors differ. This is exactly the cross-child mismatch
`composed_ssz_encoding`'s single shared `input.src` now rules out: the parent
hypothesis `hBind` can only be discharged when the structural witness and the
pinned deposit-data-root come from the same object. -/
theorem inconsistent_witness_kill_line
    (srcA srcB : SourceDepositDataRootInput)
    (hMismatch : sourceAnchor srcA ≠ sourceAnchor srcB) :
    Ssz.bindOperation .clValidatorVerifier (sourceCombine srcA) (sourceWitness srcA)
        (sourceNode srcB) = false := by
  have hRootNe :
      Ssz.traverseBranch (sourceCombine srcA)
          (Ssz.validatorRoot (sourceCombine srcA) (sourceWitness srcA).validator)
          (sourceWitness srcA).path (sourceWitness srcA).branch ≠ sourceNode srcB := by
    intro hEq
    have hStructural :
        structuralRoot (sourceAnchor srcA) (sourceSignatureNode srcA) (sourceLeaf srcA) =
          sourceNode srcB := by
      simpa [structuralRoot, sourceWitness, sourceCombine] using hEq
    exact hMismatch
      (sourceNode_components_injective srcB (sourceAnchor srcA) (sourceSignatureNode srcA)
        (sourceLeaf srcA) hStructural).1
  -- Restate against `sourceNode`'s unfolding, `structuralEncoding`, so this matches the
  -- shape `simp` leaves the goal in below (`sourceNode` is itself `@[simp]`).
  have hRootNe' :
      Ssz.traverseBranch (sourceCombine srcA)
          (Ssz.validatorRoot (sourceCombine srcA) (sourceWitness srcA).validator)
          (sourceWitness srcA).path (sourceWitness srcA).branch ≠
        structuralEncoding (sourceAnchor srcB) (sourceSignatureNode srcB) (sourceLeaf srcB) :=
    hRootNe
  have hBeqFalse :
      (Ssz.traverseBranch (sourceCombine srcA)
          (Ssz.validatorRoot (sourceCombine srcA) (sourceWitness srcA).validator)
          (sourceWitness srcA).path (sourceWitness srcA).branch ==
        structuralEncoding (sourceAnchor srcB) (sourceSignatureNode srcB)
          (sourceLeaf srcB)) = false := by
    simp [hRootNe']
  simp [Ssz.bindOperation, Ssz.verifyValidatorWitness, Ssz.verifyProof, hBeqFalse]

/-- `observe` of the handwritten `encode` transaction equals `sourceView`.
A commit also re-exports the structural-witness conjunct. This is not
`SSZ.verifyProof` and does not prove SHA-256. -/
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
            nodeWord (traversedRoot input) ∧
          (observe ((encode input).run state)).observables.pathLength =
            input.witness.path.length ∧
          (observe ((encode input).run state)).observables.branchLength =
            input.witness.branch.length ∧
          (observe ((encode input).run state)).observables.path =
            twoWords (input.witness.path.map siblingWord) ∧
          (observe ((encode input).run state)).observables.branch =
            twoWords (input.witness.branch.map nodeWord)) ∧
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
