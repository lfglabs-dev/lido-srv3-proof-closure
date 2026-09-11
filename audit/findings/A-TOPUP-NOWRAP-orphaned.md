# Finding: A-TOPUP-NOWRAP is orphaned from the registered P-TOPUP-1 parents

**Category:** Assumption discharge — outcome (a) per the goal loop.  
**Severity:** N/A (bookkeeping — no runtime risk change).  
**Scope:** Only P-TOPUP-1 declares `A-TOPUP-NOWRAP`; no other guarantee references it.  
**Status:** Proof of orphanage merged. Retirement of the assumption from
`audit/assumptions.yaml` and from `P-TOPUP-1`'s assumption list in
`audit/guarantees.yaml` is a **policy decision** (advances the R1 review basis)
and is left explicit for Thomas.

## Claim

The two registered P-TOPUP-1 parents,
`LidoSRv3.Audit.Guarantees.PTopup1.source_topup_conserves_and_rolls_back`
and
`LidoSRv3.Audit.Guarantees.PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close`,
do **not** consume the caller-supplied premise
`LidoSRv3.Audit.SolidityTopup.NoUncheckedWrap`. `A-TOPUP-NOWRAP` is a stale
registry identifier for these parents — its risk text already records
"the current P-TOPUP-1 parent explicitly models wrapping and does not
require a general no-wrap premise", and its `removal_path` in
`audit/assumptions.yaml` is "Review each consuming theorem before removing
this registry identifier."

## Proof (see `LidoSRv3/Audit/Provenance/TopupNoWrapOrphaned.lean`)

Three theorems exhibit the orphanage:

1. `source_parent_ignores_no_unchecked_wrap` — for **any** input violating
   `NoUncheckedWrap`, the registered parent's five-conjunct conclusion
   (`ConservesAndRollsBack ∧ UnregisteredModuleReverts ∧ WrapMovesNoValue ∧
   WrongWcTypeReverts ∧ RunFollowsAllocationLoop`) still holds. The proof
   term ignores the `_hWrap : ¬ NoUncheckedWrap inp` premise and re-applies
   `PTopup1.source_topup_conserves_and_rolls_back`.
2. `source_parent_applies_universally` — the same statement without the
   ignored `_hWrap` premise, making it obvious that the parent applies to
   every input, wrapping or not.
3. `verity_parent_ignores_no_unchecked_wrap` — for **any** input violating
   `NoUncheckedWrap`, provided the source-call correspondence
   `SourceTopupCallCorresponds cfg inp call` holds, the registered Verity
   parent's conclusion
   (`VerityGuardedReturndataSimulation cfg call state`) still holds. The
   proof term ignores `_hWrap` and re-applies
   `PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close`.

Each theorem depends only on the accepted Lean foundations
(`propext`, `Classical.choice`, `Quot.sound`); `#print axioms` is registered
in `LidoSRv3.Audit.Trust`.

## Reproduction

```bash
lake build LidoSRv3.Audit.Provenance.TopupNoWrapOrphaned
lake build LidoSRv3.Audit.Trust
python3 scripts/check_trust_axioms.py
```

The last command reports `trust-axiom check ok` and includes the three new
registered theorems inside `{propext, Classical.choice, Quot.sound}`.

## Structural evidence

Inspection of the registered parent bodies (see
`LidoSRv3/Audit/Guarantees/PTopup1.lean:444-462` and
`LidoSRv3/Audit/Guarantees/PTopup1.lean:815-831`) confirms:

- `source_topup_conserves_and_rolls_back` takes `cfg`, `inp`,
  `before`, `after`, `attempts`, `trace` and closes via
  `run_conserves`, `reverting_outcome_rolls_back`,
  `source_module_guard_required`,
  `source_wrap_precludes_value_moving_commit`,
  `source_wc_type2_guard_required`,
  `source_allocation_guards_required`,
  `source_over_target_guard_required`. None of these are premised on
  `NoUncheckedWrap`.
- `verity_tx_simulates_source_with_nonzero_wrap_close` takes `cfg`,
  `inp`, `call`, `state`, and `hCall : SourceTopupCallCorresponds`. Its
  proof term goes through
  `Verity.TopupTx.executeGuarded_binds_returndata` and the
  `executeGuarded_reverts_on_*` family. None of these are premised on
  `NoUncheckedWrap`.

The premise appears only in unregistered mutant tests
(`LidoSRv3/Tests/TopupTxMutants.lean`,
`LidoSRv3/Tests/TopupHybridMutants.lean`) that explicitly exhibit
wrapping-versus-non-wrapping witnesses; those consume `NoUncheckedWrap`
as a **hypothesis to negate** on a mutant plane, not as a premise for
the registered parent.

## Policy note

Removing `A-TOPUP-NOWRAP` from `audit/assumptions.yaml` and from
`P-TOPUP-1.assumptions` in `audit/guarantees.yaml` would advance the R1
review basis (the canonical assurance-detail digest for P-TOPUP-1
changes; the yaml SHA in `scripts/audit_metadata.py` and
`R1_REVIEW_BASE` both need to advance). That is a policy decision under
Thomas's "décision de fond" clause; this finding delivers the evidence
needed for that decision.
