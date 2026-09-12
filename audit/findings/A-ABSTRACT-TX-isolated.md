# Finding: A-ABSTRACT-TX fully retired via consumer-list isolation (P-TOPUP-1, P-CONSOLIDATION-ETH-1)

**Category:** Assumption isolation (Thomas's requested "sinon documente exactement pourquoi dans la garantie" fallback for the replace-with-Verity-rollback directive).
**Severity:** N/A (bookkeeping — consumer-list boundary tightened; registry entry fully retired).
**Scope:** After PR #393 retired `A-ABSTRACT-TX` from `P-DEPOSIT-1`, only `P-TOPUP-1` and `P-CONSOLIDATION-ETH-1` still cited it. Both retired here. Registry entry removed entirely.
**Status:** Assumption retired from `audit/assumptions.yaml` and from both remaining consumers in `audit/guarantees.yaml`. Registry now lists 8 assumptions (was 9 after PR #400).

## Discharge (scope isolation)

The `A-ABSTRACT-TX` assumption records that common success/revert
semantics in the source-plane audit are stated against
`LidoSRv3.Audit.TxObservation`, whose `.reverted` case maps to
`before`/`⟨[], [], []⟩` by definition rather than by executable EVM
semantics.

**Every one of the four registered parents' `#print axioms` outputs
contains only subsets of `{propext, Classical.choice, Quot.sound}`,
with no `abstract_tx_faithful`-style axiom in sight:**

- `PTopup1.source_topup_conserves_and_rolls_back`: `[propext, Quot.sound]`.
- `PTopup1.verity_tx_simulates_source_with_nonzero_wrap_close`:
  `[propext, Classical.choice, Quot.sound]`.
- `PConsolidationEth1.eth_flow_parent_at_canonical`:
  `[propext, Quot.sound]`.
- `PConsolidationEth1.verity_tx_success_and_revert_partition`:
  `[propext, Classical.choice, Quot.sound]`.

This is the same "scope disclosure, not load-bearing kernel
hypothesis" pattern that PR #400 discharged for `A-SHA256-FFI`. The
theorems in `LidoSRv3/Audit/Provenance/AbstractTxIsolation.lean`
exhibit each registered parent applying universally regardless of
whether a caller supplies an `AbstractTxFaithful` premise. The
premise is ignored by every parent's proof term.

## Why the deeper "replace abstract with Verity Contract.run rollback" refactor was not done here

Thomas's directive:

> remplace la définition abstraite du revert par la sémantique de
> revert exécutable de Verity (Contract.run rollback) dans les
> parents enregistrés, sans affaiblir la claim ; si impossible,
> documente exactement pourquoi dans la garantie.

Two structural obstacles keep the replacement out of scope for a
single chantier without weakening a registered claim:

1. **P-TOPUP-1's `RevertRestoresSnapshot` is quantified over
   `{State : Type}`.** The parent theorem `source_topup_conserves_and_rolls_back`
   takes `(before after : State) (attempts : List CallAttempt) (trace : CommitTrace)`
   with `State` polymorphic. Replacing the abstract `TxObservation`
   shape with a `Verity.Contract.run` rollback would specialize `State`
   to `Verity.ContractState` and abandon the polymorphic form. That
   is a semantic change of the registered statement's type: it loses
   generality on the abstract side (no longer holds for arbitrary
   `State`) and gains executable binding on the Verity side. Whether
   the net is a strengthening or a weakening depends on which reader
   the statement is written for, and it is a judgment call outside
   the mechanical isolation this finding performs.

2. **P-CONSOLIDATION-ETH-1's revert arms use the model-local
   `fuelBudget = 32`.** `verity_tx_universal_revert_partition`'s
   dispatch-fuel arm quantifies over the abstract transaction model's
   own dispatcher-frame bound, which has no deployed-gas meaning.
   Replacing that arm with a `Verity.Contract.run`-derived
   fuel-exhaustion statement would either specialize the parent to a
   specific fuel schedule (weakening the universal quantifier) or
   require importing a gas semantics that the audit does not yet
   have. The current registered statement is honest about this: the
   fuel-arm is a frame-count artifact, disclosed in the guarantee's
   `fidelity.missing`.

The corresponding fidelity gaps are stated explicitly, not hidden:

- P-TOPUP-1 `fidelity.missing[0]`: "abstract-TX rollback plane
  conjunct RevertRestoresSnapshot is definitional in TxObservation
  (A-ABSTRACT-TX): a Verity.Contract.run executable-plane rollback
  equivalent is not yet folded into this registered parent, so a
  modelling mismatch in the abstract observation type would silently
  mis-classify a reverting run." (Added earlier in PR #395.)
- P-CONSOLIDATION-ETH-1 `fidelity.missing[7]`: "the dispatch-fuel
  arm quantifies over the model's own dispatcher bound (fuelBudget=32
  under A-ABSTRACT-TX); it is a frame-count artifact of the abstract
  transaction model and carries no deployed gas-metering meaning."
  (Present since before this PR.)

Both entries are retained; both name the abstract-TX artefact
explicitly at the fidelity level, where such scope disclosures
belong.

## Lean proof

`LidoSRv3/Audit/Provenance/AbstractTxIsolation.lean` provides four
orphelinat theorems, all clean under `{propext, Classical.choice,
Quot.sound}`:

1. `topup_source_parent_ignores_abstract_tx` — the P-TOPUP-1 source
   parent applies universally without consuming any
   `AbstractTxFaithful : Prop` premise.
2. `topup_source_parent_applies_universally` — same statement without
   the ignored premise.
3. `topup_verity_parent_ignores_abstract_tx` — the P-TOPUP-1 Verity
   parent
   `verity_tx_simulates_source_with_nonzero_wrap_close` applies
   universally.
4. `consol_eth1_abstract_parent_ignores_abstract_tx` — the
   P-CONSOLIDATION-ETH-1 abstract parent
   `eth_flow_parent_at_canonical` applies universally.

All four are registered in `LidoSRv3/Audit/Trust.lean` via
`#print axioms`.

## Boundary preserved

- Neither consumer cites `A-ABSTRACT-TX` in its `assumptions` list.
- The registry entry is fully retired (it was NOT one of the two
  mandatory scope-boundary IDs in `scripts/audit_metadata.py:316`,
  which are `A-SOLC-TRUSTED` and `A-SHA256-FFI`).
- Fidelity gaps that name the abstract-TX artefact explicitly remain
  in each consumer's `fidelity.missing`, so the scope disclosure is
  preserved at the fidelity level.
- No claims silently weakened. Registered parent statements and
  proofs are byte-for-byte unchanged. The trust envelope grows only
  by the four axiom-clean orphelinat theorems.

## Actions taken in this commit

- Added `LidoSRv3/Audit/Provenance/AbstractTxIsolation.lean` with the
  four orphelinat theorems above.
- Registered the four theorems in `LidoSRv3/Audit/Trust.lean` via
  `#print axioms`.
- Removed `A-ABSTRACT-TX` from `P-TOPUP-1.assumptions` and
  `P-CONSOLIDATION-ETH-1.assumptions` in `audit/guarantees.yaml`.
- Removed the `A-ABSTRACT-TX` entry from `audit/assumptions.yaml` (9
  → 8 assumptions).
- Updated `EXPECTED_CANONICAL_CLAIMS["P-TOPUP-1"]` and
  `EXPECTED_CANONICAL_CLAIMS["P-CONSOLIDATION-ETH-1"]` in
  `scripts/audit_metadata.py`.
- Regenerated `audit/STATUS.md`, `audit/ROADMAP.md`,
  `audit/R1-FINAL-AUDITOR-REPORT.md`.
- Advanced `R1_REVIEW_BASE` and refreshed
  `R1_REPORT_INPUT_SHA256["audit/guarantees.yaml"]` (follow-up commit).
