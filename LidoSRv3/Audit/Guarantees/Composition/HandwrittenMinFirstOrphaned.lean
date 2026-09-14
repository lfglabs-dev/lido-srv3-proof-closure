import LidoSRv3.Audit.Guarantees.PAlloc2
import LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound

/-!
# A-HANDWRITTEN-MINFIRST is orphaned from the registered P-ALLOC-2 and
P-ALLOC-1.eugene-bound parents

The `A-HANDWRITTEN-MINFIRST` assumption records the observation that
the project ships a handwritten +1 `Nat` MinFirst model
(`LidoSRv3.Audit.MinFirst`, in `LidoSRv3/Audit/Strategy.lean`) whose
correspondence with the pinned Solidity
`MinFirstAllocationStrategy.allocateToBestCandidate` (a proportional
one-shot step) is not established. The concern is that a P-ALLOC-2 or
P-ALLOC-1.eugene-bound conclusion appealing to that handwritten +1
model would inherit the modelling gap.

This module proves the concern is misapplied to the registered
parents: **none of them consume the handwritten +1 `MinFirst` model in
their statement or in their proof term.**

Registered surfaces on P-ALLOC-2:
- `LidoSRv3.Audit.Guarantees.PAlloc2.step_correspondence_and_full_loop_conservation`
  is `StepMatchesModel ∧ FullLoopConserves ∧ LoopStaysInCorrespondence`,
  where every predicate is stated over
  `LidoSRv3.Audit.MinFirstAllocation.Model.Bucket` (the **proportional
  Nat model**) and `LidoSRv3.Audit.MinFirstAllocation.Source.Row` (the
  source-shaped rows).  These proportional Model/Source planes have
  their own independent correspondence lemmas
  (`MinFirstAllocation.candidate_correspondence`,
  `amount_correspondence`, `sourceAllocateLoop_model_correspondence`).
  The handwritten `LidoSRv3.Audit.MinFirst.Bucket` type never appears.
- `LidoSRv3.Audit.Guarantees.PAlloc2.verity_tx_simulates_min_first_distribution`
  is a Verity-transaction plane theorem over the same
  `MinFirstAllocation.Source.Word` and
  `Verity.MinFirstDistributionTx.sourceAllocateLoop`; its own
  documentation reads "Not the +1 `selects_least_open_bucket` model."

Registered surface on P-ALLOC-1.eugene-bound:
- `LidoSRv3.Audit.Guarantees.PAlloc1EugeneBound.checked_amount_le_bond`
  is stated over `MinFirstAllocation.Source.Row` /
  `Source.checkedAmount` and proves the checked amount is bounded by
  the row's checked capacity headroom. Its proof term uses
  `Source.checkedAmount` case analysis and word-monotonicity of
  `Source.minWord`; no handwritten +1 model appears.

The theorems below make this documentation load-bearing by exhibiting
the registered parents applying universally in the presence of an
arbitrary caller-supplied `HandwrittenMinFirstFaithful` hypothesis --
the hypothesis is ignored by every parent's proof term.

Consequently `A-HANDWRITTEN-MINFIRST` is retired from both
`P-ALLOC-2.assumptions` and `P-ALLOC-1.eugene-bound.assumptions` in
`audit/guarantees.yaml`, and the registry entry itself is removed from
`audit/assumptions.yaml`. The handwritten +1 model is still shipped
(`LidoSRv3/Audit/Strategy.lean`, `LidoSRv3/Audit/StrategyProofs.lean`)
and remains available as unregistered structural evidence, but it does
not carry any registered guarantee.
-/

namespace LidoSRv3.Audit.Provenance.HandwrittenMinFirstOrphaned

open LidoSRv3.Audit.MinFirstAllocation
open LidoSRv3.Audit.Guarantees

/-- The registered P-ALLOC-2 abstract parent applies universally without
consuming any hypothesis representing "the handwritten +1 `MinFirst`
model corresponds to Solidity `MinFirstAllocationStrategy`". The
`_hHandwrittenMinFirstFaithful` premise is introduced only to make the
orphanage explicit and is ignored by the parent's proof term. -/
theorem alloc2_source_parent_ignores_handwritten_minfirst
    (HandwrittenMinFirstFaithful : Prop)
    (_hHandwrittenMinFirstFaithful : HandwrittenMinFirstFaithful) :
    PAlloc2.StepMatchesModel ∧
      PAlloc2.FullLoopConserves ∧
      PAlloc2.LoopStaysInCorrespondence :=
  PAlloc2.step_correspondence_and_full_loop_conservation

/-- Same statement without the ignored hypothesis: the P-ALLOC-2
abstract parent applies universally, so its correctness does not depend
on the faithfulness of the handwritten +1 `MinFirst` model. -/
theorem alloc2_source_parent_applies_universally :
    PAlloc2.StepMatchesModel ∧
      PAlloc2.FullLoopConserves ∧
      PAlloc2.LoopStaysInCorrespondence :=
  PAlloc2.step_correspondence_and_full_loop_conservation

/-- The registered P-ALLOC-2 Verity-transaction parent applies
universally without consuming any hypothesis representing the
handwritten +1 `MinFirst` model. -/
theorem alloc2_verity_parent_ignores_handwritten_minfirst
    (HandwrittenMinFirstFaithful : Prop)
    (_hHandwrittenMinFirstFaithful : HandwrittenMinFirstFaithful)
    (buckets capacities : List Source.Word)
    (allocationSize : Source.Word) (state : _root_.Verity.ContractState)
    (hBuckets : LidoSRv3.Audit.Verity.MinFirstDistributionTx.readArray state "buckets"
      LidoSRv3.Audit.Verity.MinFirstDistributionTx.bucketsBase buckets.length = some buckets)
    (hCapacities : LidoSRv3.Audit.Verity.MinFirstDistributionTx.readArray state "capacities"
      LidoSRv3.Audit.Verity.MinFirstDistributionTx.capacitiesBase capacities.length = some capacities) :
    LidoSRv3.Audit.Verity.MinFirstDistributionTx.observe buckets
        ((LidoSRv3.Audit.Verity.MinFirstDistributionTx.allocate buckets.length capacities.length
          allocationSize).run state) =
      LidoSRv3.Audit.Verity.MinFirstDistributionTx.sourceView buckets capacities allocationSize :=
  PAlloc2.verity_tx_simulates_min_first_distribution
    buckets capacities allocationSize state hBuckets hCapacities

/-- The registered P-ALLOC-1.eugene-bound subordinate parent
`checked_amount_le_bond` applies universally without consuming any
hypothesis representing the handwritten +1 `MinFirst` model. -/
theorem eugene_bound_parent_ignores_handwritten_minfirst
    (HandwrittenMinFirstFaithful : Prop)
    (_hHandwrittenMinFirstFaithful : HandwrittenMinFirstFaithful)
    (rows : List Source.Row) (allocationSize : Source.Word)
    (best : Source.Row) (bond allocated : Source.Word)
    (hBond : _root_.Verity.Stdlib.Math.safeSub best.capacity best.allocation = some bond)
    (hAmount : Source.checkedAmount rows allocationSize best = some allocated) :
    allocated ≤ bond :=
  PAlloc1EugeneBound.checked_amount_le_bond
    rows allocationSize best bond allocated hBond hAmount

end LidoSRv3.Audit.Provenance.HandwrittenMinFirstOrphaned
