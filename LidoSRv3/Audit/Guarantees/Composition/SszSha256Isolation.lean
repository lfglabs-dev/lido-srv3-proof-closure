import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Guarantees.PSszLive1
import LidoSRv3.Audit.Verity.SszAbstractDigest
import LidoSRv3.Audit.Verity.SszTxSimulation
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence

/-! # Structural SSZ lemmas: no SHA-256 discharge

These wrappers restate structural facts of the chosen model. They do not bind
its digest oracle to SHA-256 or the deployed precompile. A-SHA256-FFI remains
an explicit assumption of the affected guarantees even when their kernel
axiom lists contain only Lean's foundational axioms. The abstract
`deposit_root_iff` result is a definitional model-shape restatement, not a
correspondence proof for CLValidatorVerifier._verifyValidator.
-/

namespace LidoSRv3.Audit.Provenance.SszSha256Isolation

open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Source.DepositDataRootCorrespondence
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.Verity.SszTxSimulation

/-- Structural model fact; no SHA-256 implementation correspondence is proved. -/
theorem ssz1_abstract_parent_ignores_sha256_correctness
    (src : SourceDepositDataRootInput)
    (hWellFormed : PSsz1.wellFormedDeposit src) :
    _root_.LidoSRv3.Audit.Spec.SszWitness.Correspondence
      PSsz1.depositSszWitness src :=
  PSsz1.deposit_root_iff src hWellFormed

/-- Structural model fact; no SHA-256 implementation correspondence is proved. -/
theorem ssz1_abstract_parent_applies_universally
    (src : SourceDepositDataRootInput)
    (hWellFormed : PSsz1.wellFormedDeposit src) :
    _root_.LidoSRv3.Audit.Spec.SszWitness.Correspondence
      PSsz1.depositSszWitness src :=
  PSsz1.deposit_root_iff src hWellFormed

/-- Structural model fact; no SHA-256 implementation correspondence is proved. -/
theorem ssz1_verity_parent_ignores_sha256_correctness
    (input : _root_.LidoSRv3.Audit.Verity.SszEncodingTx.EncodingInput)
    (state : _root_.Verity.ContractState) :
    PSsz1.ObservesSourceView input state ∧
      PSsz1.CommitPersistsWitnessObservables input state ∧
      PSsz1.ConcatMatchesSpec input ∧
      PSsz1.DigestChainIsExact input ∧
      PSsz1.RevertRestoresSnapshot input state :=
  PSsz1.verity_tx_simulates_ssz_encoding input state

/-- Structural model fact; no SHA-256 implementation correspondence is proved. -/
theorem deposit_data_root_parent_ignores_sha256_correctness
    (input : SourceDepositDataRootInput)
    (hPublicKey : input.publicKey.length = PUBKEY_LENGTH pinnedConfig)
    (hWithdrawalCredentials : input.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig)
    (hSignature : input.signature.length = SIGNATURE_LENGTH pinnedConfig) :
    SHA256_DIGEST_LENGTH pinnedConfig = 32 :=
  (source_pinned_config_discharges_deposit_data_root
      input hPublicKey hWithdrawalCredentials hSignature).1

/-- Structural model fact; no SHA-256 implementation correspondence is proved. -/
theorem abstract_digest_parent_ignores_sha256_correctness
    :
    (_root_.Compiler.CompilationModel.compile
        _root_.LidoSRv3.Audit.Verity.SszAbstractDigest.spec
        [_root_.LidoSRv3.Audit.Verity.SszAbstractDigest.selector]).isOk = true ∧
      ∀ input : _root_.LidoSRv3.Audit.Verity.SszAbstractDigest.Inputs,
        _root_.LidoSRv3.Audit.Verity.SszAbstractDigest.ExactDigestComposition input :=
  abstract_digest_refinement

/-- Structural model fact; no SHA-256 implementation correspondence is proved. -/
theorem tx_execution_simulation_parent_ignores_sha256_correctness
    (input : _root_.LidoSRv3.Audit.Verity.SszAbstractDigest.Inputs) :
    (digestPreimages input).length = 7 :=
  digest_preimages_length input

end LidoSRv3.Audit.Provenance.SszSha256Isolation
