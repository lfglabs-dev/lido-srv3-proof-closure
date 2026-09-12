# Finding: A-HANDWRITTEN-MINFIRST orphaned from all registered consumers

**Category:** Assumption discharge — outcome (a) per the goal loop.
**Severity:** N/A (bookkeeping — accepted assumption boundary tightened; assumption fully retired).
**Scope:** `A-HANDWRITTEN-MINFIRST` was declared by `P-ALLOC-2` and `P-ALLOC-1.eugene-bound`. Both consumers retired; registry entry removed.
**Status:** Assumption retired from `audit/assumptions.yaml`; retired from `P-ALLOC-2.assumptions` and `P-ALLOC-1.eugene-bound.assumptions` in `audit/guarantees.yaml`. Registry now lists 9 assumptions.

## Discharge

The `A-HANDWRITTEN-MINFIRST` assumption records the observation that
the project ships a handwritten +1 `Nat` MinFirst model
(`LidoSRv3.Audit.MinFirst`, in `LidoSRv3/Audit/Strategy.lean`) whose
correspondence with the pinned Solidity
`MinFirstAllocationStrategy.allocateToBestCandidate` (a proportional
one-shot step) is not established. The concern is that a P-ALLOC-2 or
P-ALLOC-1.eugene-bound conclusion appealing to that handwritten +1
model would inherit the modelling gap.

This finding shows the concern is misapplied to the registered parents.
**None of them consume the handwritten +1 `MinFirst` model in their
statement or in their proof term.**

## Registered surfaces

- **`LidoSRv3.Audit.Guarantees.PAlloc2.step_correspondence_and_full_loop_conservation`**
  is `StepMatchesModel ∧ FullLoopConserves ∧ LoopStaysInCorrespondence`,
  where every predicate is stated over
  `LidoSRv3.Audit.MinFirstAllocation.Model.Bucket` (the **proportional
  Nat model**) and
  `LidoSRv3.Audit.MinFirstAllocation.Source.Row` (the source-shaped
  rows). These proportional Model/Source planes have their own
  independent correspondence lemmas
  (`MinFirstAllocation.candidate_correspondence`,
  `MinFirstAllocation.amount_correspondence`,
  `Verity.MinFirstDistributionTx.sourceAllocateLoop_model_correspondence`).
  The handwritten `LidoSRv3.Audit.MinFirst.Bucket` type never appears
  in the statement or its supporting lemmas.

- **`LidoSRv3.Audit.Guarantees.PAlloc2.verity_tx_simulates_min_first_distribution`**
  is the Verity-transaction plane theorem over
  `MinFirstAllocation.Source.Word` and
  `Verity.MinFirstDistributionTx.sourceAllocateLoop`. Its own
  documentation (`PAlloc2.lean:16`) reads: "Not the +1
  `selects_least_open_bucket` model." The registered proof forwards to
  `Verity.MinFirstDistributionTx.verity_tx_simulates_pinned_source`,
  which operates on the proportional source loop directly.

- **`LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound.checked_amount_le_bond`**
  is stated over `MinFirstAllocation.Source.Row` /
  `Source.checkedAmount` and proves the checked amount is bounded by
  the row's checked capacity headroom. Its proof term uses
  `Source.checkedAmount` case analysis and word-monotonicity of
  `Source.minWord`; no handwritten +1 model appears.

The unregistered helper `PAlloc2.selects_least_open_bucket` (which
does mention `MinFirst.candidate?`) is exactly what the
`A-HANDWRITTEN-MINFIRST` original registry entry pointed at, and its
own documentation ("This is not the proportional `allocateToBestCandidate`
transaction and not Solidity equivalence (`A-HANDWRITTEN-MINFIRST`)")
carries the caveat. Since this theorem is NOT part of any registered
guarantee's parent chain, the assumption isn't load-bearing anywhere
in the audit.

## Lean proof

`LidoSRv3/Audit/Provenance/HandwrittenMinFirstOrphaned.lean` provides
four theorems, all clean under `{propext, Classical.choice, Quot.sound}`:

1. `alloc2_source_parent_ignores_handwritten_minfirst` — for any
   caller-supplied `HandwrittenMinFirstFaithful : Prop`, the
   `step_correspondence_and_full_loop_conservation` conclusion still
   holds. The premise is ignored.
2. `alloc2_source_parent_applies_universally` — same statement without
   the ignored premise; the P-ALLOC-2 abstract parent applies
   universally.
3. `alloc2_verity_parent_ignores_handwritten_minfirst` — analogous
   statement for the Verity-transaction parent
   `verity_tx_simulates_min_first_distribution`.
4. `eugene_bound_parent_ignores_handwritten_minfirst` — analogous
   statement for the P-ALLOC-1.eugene-bound registered theorem
   `checked_amount_le_bond`.

All four are registered in `LidoSRv3/Audit/Trust.lean` via
`#print axioms`; each depends only on the accepted foundational
axioms.

## Boundary preserved

- The handwritten +1 `LidoSRv3.Audit.MinFirst` model is still shipped
  (`LidoSRv3/Audit/Strategy.lean`, `LidoSRv3/Audit/StrategyProofs.lean`)
  as unregistered structural evidence for step-level reasoning.
  Retirement does not delete it; it just declares that no registered
  guarantee depends on Model↔Solidity equivalence for the +1 model.
- No claims silently weakened. Registered parent statements and proofs
  are byte-for-byte unchanged. The trust envelope grows by four
  orphelinat theorems (all axiom-clean), unchanged 3-axiom envelope
  for production parents.
- The +1 vs. proportional model gap (the +1 model iterates one unit at
  a time, Solidity does a proportional one-shot with `ceilDiv`) is
  simply not a registered claim: the audit relies on the proportional
  Model/Source correspondence which is proved independently.

## Actions taken in this commit

- Added `LidoSRv3/Audit/Provenance/HandwrittenMinFirstOrphaned.lean`
  with the four orphelinat theorems above.
- Registered the four theorems in `LidoSRv3/Audit/Trust.lean` via
  `#print axioms`.
- Removed `A-HANDWRITTEN-MINFIRST` from `audit/assumptions.yaml` (9
  assumptions remaining).
- Removed `A-HANDWRITTEN-MINFIRST` from `P-ALLOC-2.assumptions` and
  `P-ALLOC-1.eugene-bound.assumptions` in `audit/guarantees.yaml`.
- Updated `EXPECTED_CANONICAL_CLAIMS["P-ALLOC-2"]` in
  `scripts/audit_metadata.py`.
- Regenerated `audit/STATUS.md`, `audit/ROADMAP.md`,
  `audit/R1-FINAL-AUDITOR-REPORT.md`.
- Advanced `R1_REVIEW_BASE` and refreshed
  `R1_REPORT_INPUT_SHA256["audit/guarantees.yaml"]` (follow-up commit).
