import LidoSRv3.Audit.Verity.MinFirstDistributionTx

/-! P-ALLOC-2 faithful-plane fail-closed vectors. -/

namespace LidoSRv3.Tests.MinFirstDistributionTxMutants

open Verity
open LidoSRv3.Audit.MinFirstAllocation
open LidoSRv3.Audit.Verity.MinFirstDistributionTx

private def words (xs : List Nat) : List Source.Word :=
  xs.map Verity.Core.Uint256.ofNat

private def w (n : Nat) : Source.Word := Verity.Core.Uint256.ofNat n

private def runView (buckets capacities : List Source.Word)
    (allocationSize : Source.Word) : View :=
  let before := stateFor buckets capacities defaultState
  observe buckets ((allocate buckets.length capacities.length allocationSize).run before)

/-- Odd demand must use ceil division: the first tied bucket receives three,
not the floor mutant's two. -/
example :
    runView (words [0, 0]) (words [100, 100]) 5 =
      ⟨.committed, words [3, 2], 5, 0⟩ := by native_decide

example :
    runView (words [0, 0]) (words [100, 100]) 5 ≠
      ⟨.committed, words [2, 3], 5, 0⟩ := by native_decide

/-- The next-level upper bound prevents the least bucket jumping past ten. -/
example :
    runView (words [0, 10]) (words [100, 100]) 20 =
      ⟨.committed, words [15, 15], 20, 0⟩ := by native_decide

example :
    runView (words [0, 10]) (words [100, 100]) 20 ≠
      ⟨.committed, words [20, 10], 20, 0⟩ := by native_decide

/-- Amount inflation is rejected by both conservation observables. -/
example :
    runView (words [0, 0]) (words [100, 100]) 5 ≠
      ⟨.committed, words [4, 2], 6, 0⟩ := by native_decide

/-- A second batch starts from the first batch's buckets and preserves the
same min-first flow. -/
example :
    let first := runView (words [0, 0]) (words [100, 100]) 5
    first = ⟨.committed, words [3, 2], 5, 0⟩ ∧
      runView first.buckets (words [100, 100]) 3 =
        ⟨.committed, words [4, 4], 3, 0⟩ := by native_decide

/-- Failure after bucket and accumulator writes is rolled back by
`Contract.run`, not merely hidden by the observation. -/
example :
    let before := stateFor (words [0, 0]) (words [100, 100]) defaultState
    (allocate 2 2 5 true).run before =
      .revert "INJECTED_AFTER_WRITES" before := by rfl

/-! ## Wave 1 kill-line mutants for the registered parent
`PAlloc2.proportional_step_correspondence_and_bounded`. -/

/-- Kill-line mutant: a MODEL-side candidate scan that picks the first open
bucket regardless of minimality, instead of the least-allocation bucket with
earliest-index tie-break that `Model.candidate?` (and the registered parent's
first conjunct) selects. -/
private def mutantFirstOpenCandidate? : List Model.Bucket → Option Model.Bucket
  | [] => none
  | b :: bs => if Model.isOpen b then some b else mutantFirstOpenCandidate? bs

/-- Selection kill-line against the registered parent
`PAlloc2.proportional_step_correspondence_and_bounded`.  On the concrete
`RowsCorrespond` pair `[(5, 10), (0, 10)]` the real source scan selects the
NON-first row `⟨w 0, w 10⟩` (index 1, the strictly least allocation), so the
parent premises `hRows` and `hSelected` both hold here; but the first-open
mutant model scan maps to `some (5, 10)` — the negation of the parent's first
conjunct `Option.map (fun b => (b.allocation, b.capacity))
(Model.candidate? model) = some (best.allocation.val, best.capacity.val)`
with the mutant scan in place of `Model.candidate?`. -/
theorem selection_kill_line_refutes_parent :
    ∃ model : List Model.Bucket, ∃ source : List Source.Row,
      ∃ best : Source.Row,
        RowsCorrespond model source ∧
        Source.candidate? source = some best ∧
        Option.map (fun b => (b.allocation, b.capacity))
            (mutantFirstOpenCandidate? model) ≠
          some (best.allocation.val, best.capacity.val) := by
  refine ⟨[⟨5, 10⟩, ⟨0, 10⟩], [⟨w 5, w 10⟩, ⟨w 0, w 10⟩], ⟨w 0, w 10⟩,
    ?_, ?_, ?_⟩
  · exact List.Forall₂.cons ⟨rfl, rfl⟩
      (List.Forall₂.cons ⟨rfl, rfl⟩ List.Forall₂.nil)
  · rfl
  · decide

/-- Kill-line mutant: `checkedAmount` without the final capacity-headroom
clamp (dropping `capacityHeadroom` from the three-way `min`). Skipping that
clamp lets the allocated amount push a candidate's allocation past its
capacity. -/
private def checkedAmountNoCapacityCap (rs : List Source.Row)
    (allocationSize : Source.Word) (best : Source.Row) : Option Source.Word := do
  let count := Source.countBest rs best.allocation
  let share := if 1 < count then
    Verity.Stdlib.Math.ceilDiv allocationSize (Verity.Core.Uint256.ofNat count)
  else allocationSize
  let levelHeadroom ← match Source.nextLevel? rs best.allocation with
    | none => some share
    | some next => Verity.Stdlib.Math.safeSub next best.allocation
  pure (Source.minWord share levelHeadroom)

/-- A single open row `(0, 3)` with demand `10`: the mutant (no capacity cap)
allocates the full `10`, so `best.allocation + allocated = 10 > 3 =
best.capacity`. This is exactly the over-headroom failure that the parent's
`source_amount_totality` conjunct (`best.allocation.val + w.val ≤
best.capacity.val`) rules out for the real `checkedAmount`. -/
example :
    let best : Source.Row := ⟨w 0, w 3⟩
    checkedAmountNoCapacityCap [best] (w 10) best = some (w 10) ∧
      ¬ (best.allocation.val + (w 10 : Source.Word).val ≤ best.capacity.val) := by
  native_decide

end LidoSRv3.Tests.MinFirstDistributionTxMutants
