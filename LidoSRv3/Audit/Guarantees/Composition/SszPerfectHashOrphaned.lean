import LidoSRv3.Audit.Guarantees.PSsz1

/-!
# A-PERFECT-HASH is orphaned from the registered P-SSZ-1 parents

The registered P-SSZ-1 theorems
`LidoSRv3.Audit.Guarantees.PSsz1.deposit_root_iff`
and
`LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_simulates_ssz_encoding`
do **not** consume the caller-supplied premise `PerfectDepositEncoding`.

- `deposit_root_iff` takes only `src : SourceDepositDataRootInput` and
  `hWellFormed : wellFormedDeposit src` and yields
  `Spec.SszWitness.Correspondence depositSszWitness src`. The proof term
  goes through `wellFormed_deposit_binds_sourceWitness` and
  `deposit_verified_witness_eq_sourceWitness`, both of which are
  witness-equality theorems, not deposit-uniqueness theorems. No
  injectivity premise is consumed.
- `verity_tx_simulates_ssz_encoding` takes only `input : EncodingInput`
  and `state : Verity.ContractState` and yields the five-conjunct
  observe/commit/concat/digest/rollback bundle. Each conjunct is
  discharged by an executable lemma
  (`verity_tx_simulates_pinned_source`,
  `encoding_commits_structural_witness`, `encoding_uses_source_concat`,
  `encoding_uses_exact_digest`, `revert_restores_snapshot`). No
  `PerfectDepositEncoding` premise is consumed.

The `A-PERFECT-HASH` registry text explicitly agrees: "`PerfectDepositEncoding`
… is used only by the unregistered uniqueness child; removal requires a
proved injectivity theorem or a narrower deposit model." The unregistered
child is `deposit_unique_of_perfect` in `LidoSRv3.Audit.SszDepositEquivalence`,
which takes the premise explicitly.

This file documents that `A-PERFECT-HASH` is orphaned from the two
registered P-SSZ-1 parents. The theorems below exhibit the proof: for
**any** encoding input and state, the parents apply without any injectivity
premise. Formal retirement from `audit/assumptions.yaml` and from
`P-SSZ-1`'s assumption list in `audit/guarantees.yaml` requires the R1
review basis to advance (policy decision under Thomas's "décision de
fond" clause; see `audit/findings/A-PERFECT-HASH-orphaned.md`).
-/

namespace LidoSRv3.Audit.Provenance.SszPerfectHashOrphaned

open LidoSRv3.Audit
open LidoSRv3.Audit.Source.DepositDataRootCorrespondence
open LidoSRv3.Audit.Guarantees
open LidoSRv3.Audit.Guarantees.PSsz1

/-- The registered abstract parent applies to **any** well-formed source
input, without any `PerfectDepositEncoding` premise. The `hPerfect`
hypothesis is introduced only to make the orphanage explicit — the
parent's proof term ignores it. -/
theorem abstract_parent_ignores_perfect_deposit_encoding
    (src : SourceDepositDataRootInput)
    (hWellFormed : wellFormedDeposit src)
    (_hPerfect : PerfectDepositEncoding) :
    Spec.SszWitness.Correspondence depositSszWitness src :=
  PSsz1.deposit_root_iff src hWellFormed

/-- Same statement without the ignored `hPerfect` hypothesis: the
registered abstract parent applies universally on well-formed inputs. -/
theorem abstract_parent_applies_universally
    (src : SourceDepositDataRootInput)
    (hWellFormed : wellFormedDeposit src) :
    Spec.SszWitness.Correspondence depositSszWitness src :=
  PSsz1.deposit_root_iff src hWellFormed

/-- The registered Verity-side parent yields its five-conjunct
conclusion on **any** encoding input and state without any
`PerfectDepositEncoding` premise. -/
theorem verity_parent_ignores_perfect_deposit_encoding
    (input : Verity.SszEncodingTx.EncodingInput) (state : Verity.ContractState)
    (_hPerfect : PerfectDepositEncoding) :
    ObservesSourceView input state ∧
      CommitPersistsWitnessObservables input state ∧
      ConcatMatchesSpec input ∧
      DigestChainIsExact input ∧
      RevertRestoresSnapshot input state :=
  PSsz1.verity_tx_simulates_ssz_encoding input state

end LidoSRv3.Audit.Provenance.SszPerfectHashOrphaned
