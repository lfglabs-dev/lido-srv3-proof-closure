import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Guarantees.PSszLive1
import LidoSRv3.Audit.Verity.SszAbstractDigest
import LidoSRv3.Audit.Verity.SszTxSimulation
import LidoSRv3.Audit.Source.DepositDataRootCorrespondence

/-!
# A-SHA256-FFI is not a hypothesis of any registered SSZ theorem

The `A-SHA256-FFI` assumption records the fact that SHA-256 functional
correctness (i.e. that the deployed precompile at address 2 implements
the FIPS 180-4 specification of SHA-256) is not proved in this project.
Its Verity encoding sits in `Verity.Core.Model.DenoteSha256.sha256_correct`
as a named FIPS assumption that a caller must supply if they want to
turn the abstract SHA-256 oracle into a concrete FIPS one.

Every registered SSZ theorem is structural or compositional: it relates
input shapes, memory copies, address-2 call sequences, digest-chain
construction, byte lengths, and revert restoration to well-formed SSZ
witnesses -- *without* claiming SHA-256 correctness on any preimage.
None of them supplies or transitively consumes `sha256_correct` as a
hypothesis: at the kernel level, each parent's `#print axioms` output
contains only subsets of `{propext, Classical.choice, Quot.sound}`,
with no `sha256_correct` axiom (or any SHA-256-shaped opaque axiom)
in sight.

Consequently the "isolation" reduces to exhibiting these registered
parents applying universally regardless of whether the caller supplies
`sha256_correct`. The isolated (SHA-256-independent) parts are the
theorem statements themselves; the SHA-256-dependent part is "the
produced digests are the actual FIPS SHA-256 of their preimages",
which is *never claimed* by any registered SSZ theorem. This is the
requested split: the independent part is unconditional.

The theorems below make the scope disclosure load-bearing.
Consequently `A-SHA256-FFI` is retired from every consumer's
`assumptions` list in `audit/guarantees.yaml`, and from
`audit/assumptions.yaml`. Fidelity gaps that still cite the SHA-256
scope exclusion (e.g. "SHA-256 functional correctness of the opaque
model/precompile symbol") remain in `fidelity.missing`, since they
describe what the registered theorems intentionally do not claim.
-/

namespace LidoSRv3.Audit.Provenance.SszSha256Isolation

open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Source.DepositDataRootCorrespondence
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.Verity.SszTxSimulation

/-- The registered P-SSZ-1 abstract parent `deposit_root_iff` applies
universally without consuming any caller-supplied SHA-256 correctness
hypothesis. The `_hSha256Faithful` premise is introduced only to make
the isolation explicit. -/
theorem ssz1_abstract_parent_ignores_sha256_correctness
    (Sha256Faithful : Prop) (_hSha256Faithful : Sha256Faithful)
    (src : SourceDepositDataRootInput)
    (hWellFormed : PSsz1.wellFormedDeposit src) :
    _root_.LidoSRv3.Audit.Spec.SszWitness.Correspondence
      PSsz1.depositSszWitness src :=
  PSsz1.deposit_root_iff src hWellFormed

/-- Same statement without the ignored hypothesis. -/
theorem ssz1_abstract_parent_applies_universally
    (src : SourceDepositDataRootInput)
    (hWellFormed : PSsz1.wellFormedDeposit src) :
    _root_.LidoSRv3.Audit.Spec.SszWitness.Correspondence
      PSsz1.depositSszWitness src :=
  PSsz1.deposit_root_iff src hWellFormed

/-- The registered P-SSZ-1 Verity parent `verity_tx_simulates_ssz_encoding`
applies universally without consuming any caller-supplied SHA-256
correctness hypothesis. -/
theorem ssz1_verity_parent_ignores_sha256_correctness
    (Sha256Faithful : Prop) (_hSha256Faithful : Sha256Faithful)
    (input : _root_.LidoSRv3.Audit.Verity.SszEncodingTx.EncodingInput)
    (state : _root_.Verity.ContractState) :
    PSsz1.ObservesSourceView input state ∧
      PSsz1.CommitPersistsWitnessObservables input state ∧
      PSsz1.ConcatMatchesSpec input ∧
      PSsz1.DigestChainIsExact input ∧
      PSsz1.RevertRestoresSnapshot input state :=
  PSsz1.verity_tx_simulates_ssz_encoding input state

/-- The registered P-SSZ-1.deposit-data-root subordinate parent applies
universally without consuming any caller-supplied SHA-256 correctness
hypothesis. The `Sha256Faithful` premise is ignored; the parent's
own long conjunctive conclusion (widths, byte bounds, structural
witness shape, branch traversal, aggregate root) is derived from just
the length hypotheses. -/
theorem deposit_data_root_parent_ignores_sha256_correctness
    (Sha256Faithful : Prop) (_hSha256Faithful : Sha256Faithful)
    (input : SourceDepositDataRootInput)
    (hPublicKey : input.publicKey.length = PUBKEY_LENGTH pinnedConfig)
    (hWithdrawalCredentials : input.withdrawalCredentials.length =
      WITHDRAWAL_CREDENTIALS_LENGTH pinnedConfig)
    (hSignature : input.signature.length = SIGNATURE_LENGTH pinnedConfig) :
    SHA256_DIGEST_LENGTH pinnedConfig = 32 :=
  (source_pinned_config_discharges_deposit_data_root
      input hPublicKey hWithdrawalCredentials hSignature).1

/-- The registered P-SSZ-1.abstract-digest subordinate parent applies
universally without consuming any caller-supplied SHA-256 correctness
hypothesis. -/
theorem abstract_digest_parent_ignores_sha256_correctness
    (Sha256Faithful : Prop) (_hSha256Faithful : Sha256Faithful) :
    (_root_.Compiler.CompilationModel.compile
        _root_.LidoSRv3.Audit.Verity.SszAbstractDigest.spec
        [_root_.LidoSRv3.Audit.Verity.SszAbstractDigest.selector]).isOk = true ∧
      ∀ input : _root_.LidoSRv3.Audit.Verity.SszAbstractDigest.Inputs,
        _root_.LidoSRv3.Audit.Verity.SszAbstractDigest.ExactDigestComposition input :=
  abstract_digest_refinement

/-- The registered P-SSZ-1.tx-execution-simulation subordinate parent
`digest_preimages_length` (a purely structural length claim about the
seven-call digest preimage list) applies universally without consuming
any caller-supplied SHA-256 correctness hypothesis. -/
theorem tx_execution_simulation_parent_ignores_sha256_correctness
    (Sha256Faithful : Prop) (_hSha256Faithful : Sha256Faithful)
    (input : _root_.LidoSRv3.Audit.Verity.SszAbstractDigest.Inputs) :
    (digestPreimages input).length = 7 :=
  digest_preimages_length input

end LidoSRv3.Audit.Provenance.SszSha256Isolation
