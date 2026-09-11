# Finding: A-ABSTRACT-TX orphaned from P-DEPOSIT-1

**Category:** Assumption discharge -- outcome (a) per the goal loop.
**Severity:** N/A (bookkeeping -- accepted assumption boundary tightened for one guarantee).
**Scope:** Partial retirement. `A-ABSTRACT-TX` was declared by `P-DEPOSIT-1`, `P-TOPUP-1`, and `P-CONSOLIDATION-ETH-1`. This finding retires it from `P-DEPOSIT-1` only; `P-TOPUP-1` and `P-CONSOLIDATION-ETH-1` still cite it because their registered parents fold `RevertRestoresSnapshot` / abstract-TX conjuncts in explicitly (`PTopup1.lean:255-268, 447-...`).
**Status:** `A-ABSTRACT-TX` removed from `P-DEPOSIT-1.assumptions` in `audit/guarantees.yaml`. Registry entry retained in `audit/assumptions.yaml`.

## Discharge

The `A-ABSTRACT-TX` assumption records that common success/revert
semantics are stated against `LidoSRv3.Audit.TxObservation`, whose
`.reverted` case maps to `before` / `⟨[], [], []⟩` by definition rather
than by executable EVM semantics.

`LidoSRv3.Audit.Guarantees.PDeposit1.lean:108-114` already records
that P-DEPOSIT-1's registered parent explicitly does not fold the
abstract-TX rollback conjunct in:

> The abstract-transaction rollback fact used in earlier revisions --
> `observation` maps a reverting outcome to `.reverted`, whose
> `committedState`/`committedTrace` are `before`/`⟨[], [], []⟩` by
> definition (`A-ABSTRACT-TX`) -- is definitional in this model and is
> therefore *not* a conjunct of this registered parent. It remains
> available as the unregistered child
> `revert_restores_state_value_and_logs`.

This finding makes that documentation load-bearing by proving in Lean
that both registered P-DEPOSIT-1 parents ignore any caller-supplied
A-ABSTRACT-TX hypothesis.

## Registered parents

- `LidoSRv3.Audit.Guarantees.PDeposit1.source_deposit_conserves_and_rolls_back`
  is quantified only over source-plane data (`SourceDepositConfig`,
  `SourceDepositInput`, and the source `run` outcome via
  `SolidityDeposit.Outcome`). Its conclusion
  `CommittedPushConserves cfg inp ∧ NonConservingDeploymentReverts cfg inp`
  never mentions `TxObservation`, `.reverted`, `.committedState`, or
  `.committedTrace`.

- `LidoSRv3.Audit.Guarantees.PDeposit1.NFrame.verity_tx_composes_nframe_deposit`
  is quantified over the same source-plane data plus Verity's
  executable `Verity.ContractState`. Its conclusion likewise never
  mentions `TxObservation` or its accessors; the executable half runs
  against `Verity.Contract.run`, not the abstract observation model.

## Lean proof

`LidoSRv3/Audit/Provenance/DepositAbstractTxOrphaned.lean` provides
four theorems, all clean under `{propext, Classical.choice, Quot.sound}`:

1. `source_parent_ignores_abstract_tx` -- for any caller-supplied
   `AbstractTxFaithful : Prop` and any `(cfg, inp)`, the registered
   source parent's conclusion holds. The `_hAbstractTxFaithful`
   premise is introduced only to make the orphanage explicit and is
   ignored by the parent's proof term.
2. `source_parent_applies_universally` -- same statement without the
   ignored premise; the source parent applies universally, so its
   correctness does not depend on the faithfulness of the abstract
   `TxObservation` model.
3. `verity_parent_ignores_abstract_tx` -- analogous statement for the
   Verity-executable parent
   `verity_tx_composes_nframe_deposit`, showing the same premise is
   ignored.
4. `verity_parent_applies_universally` -- Verity parent applies
   universally, no A-ABSTRACT-TX-shaped premise required.

All four are registered in `LidoSRv3/Audit/Trust.lean` via
`#print axioms`; each depends only on the accepted foundational
axioms.

## Boundary preserved

- The `A-ABSTRACT-TX` **registry entry stays** in
  `audit/assumptions.yaml` because the assumption is still
  load-bearing for two other guarantees:
  - `P-TOPUP-1`: its registered parent
    `source_topup_conserves_and_rolls_back` folds
    `RevertRestoresSnapshot` (an abstract-TX conjunct) explicitly into
    its conclusion (`PTopup1.lean:255-268, 444-...`).
  - `P-CONSOLIDATION-ETH-1`: uses abstract-TX-flavored predicates in
    its registered parent for the same reasons.
- **No claims are silently weakened.** The registered P-DEPOSIT-1
  parents' statements and proofs are byte-for-byte unchanged; only
  the assumption footprint in the audit registry is narrowed.
- **No new axioms** enter the trust envelope.

## Actions taken in this commit

- Added `LidoSRv3/Audit/Provenance/DepositAbstractTxOrphaned.lean`
  with the four orphelinat theorems above.
- Registered the four theorems in `LidoSRv3/Audit/Trust.lean` via
  `#print axioms`.
- Removed `A-ABSTRACT-TX` from `P-DEPOSIT-1.assumptions` in
  `audit/guarantees.yaml`.
- Updated `EXPECTED_CANONICAL_CLAIMS["P-DEPOSIT-1"]` in
  `scripts/audit_metadata.py`.
- Regenerated `audit/STATUS.md`, `audit/ROADMAP.md`,
  `audit/R1-FINAL-AUDITOR-REPORT.md`.
- Advanced `R1_REVIEW_BASE` and updated
  `R1_REPORT_INPUT_SHA256["audit/guarantees.yaml"]` (follow-up commit).
