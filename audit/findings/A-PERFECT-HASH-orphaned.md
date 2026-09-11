# Finding: A-PERFECT-HASH is orphaned from the registered P-SSZ-1 parents

**Category:** Assumption discharge — outcome (a) per the goal loop.
**Severity:** N/A (bookkeeping — no runtime risk change).
**Scope:** Only P-SSZ-1 declares `A-PERFECT-HASH`; no other guarantee references it.
**Status:** Proof of orphanage merged. Retirement of the assumption from
`audit/assumptions.yaml` and from `P-SSZ-1`'s assumption list in
`audit/guarantees.yaml` is a **policy decision** (advances the R1 review basis)
and is left explicit for Thomas.

## Claim

The two registered P-SSZ-1 parents,
`LidoSRv3.Audit.Guarantees.PSsz1.deposit_root_iff`
and
`LidoSRv3.Audit.Guarantees.PSsz1.verity_tx_simulates_ssz_encoding`,
do **not** consume the caller-supplied premise
`LidoSRv3.Audit.SszDepositEquivalence.PerfectDepositEncoding`.
`A-PERFECT-HASH` is a stale registry identifier for these parents; the
registry text already records that `PerfectDepositEncoding` "is used only
by the unregistered uniqueness child" (`deposit_unique_of_perfect`).

## Proof (see `LidoSRv3/Audit/Provenance/SszPerfectHashOrphaned.lean`)

Three theorems exhibit the orphanage:

1. `abstract_parent_ignores_perfect_deposit_encoding` — for **any**
   well-formed source input, the registered abstract parent
   `PSsz1.deposit_root_iff` still yields the witness correspondence
   `Spec.SszWitness.Correspondence depositSszWitness src`. The proof
   ignores `_hPerfect : PerfectDepositEncoding` and re-applies the
   parent.
2. `abstract_parent_applies_universally` — the same statement without
   the ignored premise: the parent applies to every well-formed input.
3. `verity_parent_ignores_perfect_deposit_encoding` — for **any**
   encoding input and state, the registered Verity parent
   `PSsz1.verity_tx_simulates_ssz_encoding` still yields its
   five-conjunct conclusion
   (`ObservesSourceView ∧ CommitPersistsWitnessObservables ∧
   ConcatMatchesSpec ∧ DigestChainIsExact ∧ RevertRestoresSnapshot`).
   The proof ignores `_hPerfect` and re-applies the parent.

Each theorem depends only on the accepted Lean foundations
(`propext`, `Classical.choice`, `Quot.sound`); `#print axioms` is
registered in `LidoSRv3.Audit.Trust`.

## Reproduction

```bash
lake build LidoSRv3.Audit.Provenance.SszPerfectHashOrphaned
lake build LidoSRv3.Audit.Trust
python3 scripts/check_trust_axioms.py
```

The last command reports `trust-axiom check ok` and includes the three
new registered theorems inside `{propext, Classical.choice, Quot.sound}`.

## Structural evidence

Inspection of the registered parent bodies confirms:

- `PSsz1.deposit_root_iff` (delegates to
  `SszDepositEquivalence.deposit_root_iff`) takes only `src`,
  `hWellFormed` and yields `Spec.SszWitness.Correspondence` via
  `wellFormed_deposit_binds_sourceWitness` and
  `deposit_verified_witness_eq_sourceWitness`. Neither of these consumes
  `PerfectDepositEncoding`.
- `PSsz1.verity_tx_simulates_ssz_encoding` takes only `input`, `state`
  and yields the five-conjunct bundle via
  `verity_tx_simulates_pinned_source`,
  `encoding_commits_structural_witness`,
  `encoding_uses_source_concat`, `encoding_uses_exact_digest`,
  `revert_restores_snapshot`. None consume `PerfectDepositEncoding`.

The premise is consumed only by the **unregistered** uniqueness child
`SszDepositEquivalence.deposit_unique_of_perfect`, which explicitly
takes `hPerfect : PerfectDepositEncoding` and yields
`sourceNode src' = sourceNode src → src' = src`. That child is a
supplemental result about deposit uniqueness, not a registered parent
of P-SSZ-1.

## Policy note

Removing `A-PERFECT-HASH` from `audit/assumptions.yaml` and from
`P-SSZ-1.assumptions` in `audit/guarantees.yaml` advances the R1 review
basis and is a policy decision under Thomas's "décision de fond"
clause. This finding delivers the mechanical evidence needed for that
decision.

Note: `A-SHA256-FFI` (the separate opaque-SHA256 assumption) is *not*
orphaned by this finding and remains a genuine premise of the SSZ
guarantee's downstream cryptographic-correctness reading.
