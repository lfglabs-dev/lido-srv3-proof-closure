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

/-! ## Kill-line mutants for the registered parent
`PAlloc2.forall_proportional_step_correspondence_and_bounded` (the explicit-∀
closure re-registered by human PR #134; the wave-4 implicit-binder
`PAlloc2.proportional_step_correspondence_and_bounded` is retained as the
helper the registered parent forwards to). -/

/-- Kill-line mutant: a MODEL-side candidate scan that picks the first open
bucket regardless of minimality, instead of the least-allocation bucket with
earliest-index tie-break that `Model.candidate?` (and the registered parent's
first conjunct) selects. -/
private def mutantFirstOpenCandidate? : List Model.Bucket → Option Model.Bucket
  | [] => none
  | b :: bs => if Model.isOpen b then some b else mutantFirstOpenCandidate? bs

/-- Selection kill-line against the registered parent
`PAlloc2.forall_proportional_step_correspondence_and_bounded`: the negation of
the parent's FULL predicate shape — explicit `∀` binders
`(model) (source) (best) (allocationSize w)` exactly matching the registered
parent's spine, all six premises retained and discharged, whole conclusion
conjunction negated — with the first-open mutant scan
`mutantFirstOpenCandidate?` substituted for `Model.candidate?`.  The witness
keeps every premise true on concrete data: on the `RowsCorrespond` pair
`[(5, 10), (0, 10)]` the real source scan selects the NON-first row
`⟨w 0, w 10⟩` (index 1, the strictly least allocation), that row is open,
`2 < 2^256`, the demand `w 10` is nonzero, and `Source.checkedAmount`
succeeds with `some (w 5)`; yet the mutant scan maps to `some (5, 10)`, so
the pinned-selection conjunct — and hence the whole conclusion conjunction —
is false on the mutant model. -/
theorem selection_kill_line_refutes_parent :
    ¬ (∀ (model : List Model.Bucket) (source : List Source.Row)
        (best : Source.Row) (allocationSize w : Source.Word),
        RowsCorrespond model source →
        Source.candidate? source = some best →
        Source.hasFreeSpace best = true →
        source.length < Verity.Core.Uint256.modulus →
        allocationSize.val ≠ 0 →
        Source.checkedAmount source allocationSize best = some w →
        (Option.map (fun b => (b.allocation, b.capacity))
            (mutantFirstOpenCandidate? model) =
          some (best.allocation.val, best.capacity.val)) ∧
        0 < w.val ∧ w.val ≤ allocationSize.val ∧
          best.allocation.val + w.val ≤ best.capacity.val) := by
  intro h
  exact absurd
    ((h [⟨5, 10⟩, ⟨0, 10⟩] [⟨w 5, w 10⟩, ⟨w 0, w 10⟩] ⟨w 0, w 10⟩
      (w 10) (w 5)
      (List.Forall₂.cons ⟨rfl, rfl⟩
        (List.Forall₂.cons ⟨rfl, rfl⟩ List.Forall₂.nil))
      rfl rfl (by decide) (by decide) rfl).1)
    (by decide)

/-- Kill-line mutant: `checkedAmount` without the final capacity-headroom
clamp (dropping `capacityHeadroom` from the three-way `min`). Skipping that
clamp lets the allocated amount push a candidate's allocation past its
capacity. -/
def checkedAmountNoCapacityCap (rs : List Source.Row)
    (allocationSize : Source.Word) (best : Source.Row) : Option Source.Word := do
  let count := Source.countBest rs best.allocation
  let share := if 1 < count then
    Verity.Stdlib.Math.ceilDiv allocationSize (Verity.Core.Uint256.ofNat count)
  else allocationSize
  let levelHeadroom ← match Source.nextLevel? rs best.allocation with
    | none => some share
    | some next => Verity.Stdlib.Math.safeSub next best.allocation
  pure (Source.minWord share levelHeadroom)

/-- Computational evidence for the headroom kill-line (not itself a kill-line
theorem): a single open row `(0, 3)` with demand `10` — the mutant (no
capacity cap) allocates the full `10`, so `best.allocation + allocated =
10 > 3 = best.capacity`. The load-bearing parent-shaped refutation is the
named theorem `headroom_clamp_kill_line_refutes_parent` below; this anonymous
`example` only evaluates the mutant on the same witness. -/
example :
    let best : Source.Row := ⟨w 0, w 3⟩
    checkedAmountNoCapacityCap [best] (w 10) best = some (w 10) ∧
      ¬ (best.allocation.val + (w 10 : Source.Word).val ≤ best.capacity.val) := by
  native_decide

/-- Headroom-clamp kill-line against the registered parent
`PAlloc2.forall_proportional_step_correspondence_and_bounded`: the negation of
the parent's FULL predicate shape — explicit `∀` binders
`(model) (source) (best) (allocationSize w)` exactly matching the registered
parent's spine, all six premises retained and discharged, whole conclusion
conjunction negated — with the capacity-cap mutant
`checkedAmountNoCapacityCap` substituted at the `checkedAmount` premise ONLY
(the conclusion speaks only of `w`, so the first conclusion conjunct keeps the
honest `Model.candidate?` scan).  The witness keeps every premise true on
concrete data: model `[⟨0, 3⟩]`, source `[⟨w 0, w 3⟩]`, best `⟨w 0, w 3⟩`,
demand `w 10`, and the mutant amount check returns `some (w 10)`; the honest
scan conjunct holds (`some (0, 3)`), as do `0 < 10` and `10 ≤ 10`, but the
final conjunct is `0 + 10 ≤ 3`, which is false — exactly the over-headroom
execution the registered parent's capacity conjunct excludes. -/
theorem headroom_clamp_kill_line_refutes_parent :
    ¬ (∀ (model : List Model.Bucket) (source : List Source.Row)
        (best : Source.Row) (allocationSize w : Source.Word),
        RowsCorrespond model source →
        Source.candidate? source = some best →
        Source.hasFreeSpace best = true →
        source.length < Verity.Core.Uint256.modulus →
        allocationSize.val ≠ 0 →
        checkedAmountNoCapacityCap source allocationSize best = some w →
        (Option.map (fun b => (b.allocation, b.capacity))
            (Model.candidate? model) =
          some (best.allocation.val, best.capacity.val)) ∧
        0 < w.val ∧ w.val ≤ allocationSize.val ∧
          best.allocation.val + w.val ≤ best.capacity.val) := by
  intro h
  exact absurd
    ((h [⟨0, 3⟩] [⟨w 0, w 3⟩] ⟨w 0, w 3⟩ (w 10) (w 10)
      (List.Forall₂.cons ⟨rfl, rfl⟩ List.Forall₂.nil)
      rfl rfl (by decide) (by decide) rfl).2.2.2)
    (by decide)

/-! ## TX-observe computational evidence for the headroom kill-line: the
capacity-cap mutant executed through the `MinFirstDistributionTx` loop.  The
parent-shaped refutation of the registered parent
`PAlloc2.forall_proportional_step_correspondence_and_bounded` is the named
theorem `headroom_clamp_kill_line_refutes_parent` above; this section only
observes the mutant through the full TX observe path. -/

/-- TX-level mutant observe: the `MinFirstDistributionTx.allocate` loop
using `checkedAmountNoCapacityCap` instead of `checkedAmount` for one step.
This mutates the Verity TX's `execute` (the `allocateToBestCandidate`
amount) and its `observe` (committed buckets). -/
private def mutantAllocateToBestCandidate (rows : List Source.Row) (remaining : Source.Word) :
    Option (List Source.Row × Source.Word) :=
  match Source.candidate? rows with
  | none => some (rows, 0)
  | some best => do
      let amount ← checkedAmountNoCapacityCap rows remaining best
      if amount = 0 then some (rows, 0) else
      let updated ← Verity.Stdlib.Math.safeAdd best.allocation amount
      match rows.idxOf? best with
      | none => none
      | some i => some (rows.set i { best with allocation := updated }, amount)

/-- Full-loop mutant: `while (allocated < allocationSize)` over the
capacity-unclamped mutant step. -/
private def mutantAllocateLoop : Nat → List Source.Row → Source.Word → Source.Word →
    Option (List Source.Row × Source.Word × Source.Word)
  | 0, rows, remaining, total => if remaining = 0 then some (rows, total, remaining) else none
  | fuel + 1, rows, remaining, total =>
      if remaining = 0 then some (rows, total, remaining) else
      match mutantAllocateToBestCandidate rows remaining with
      | none => none
      | some (after, amount) =>
          if amount = 0 then some (rows, total, remaining) else do
            let newTotal ← Verity.Stdlib.Math.safeAdd total amount
            let newRemaining ← Verity.Stdlib.Math.safeSub remaining amount
            mutantAllocateLoop fuel after newRemaining newTotal

private def mutantSourceView (buckets capacities : List Source.Word) (allocationSize : Source.Word) : View :=
  if buckets.length != capacities.length then ⟨.reverted, buckets, 0, 0⟩ else
  let rows := (buckets.zip capacities).map fun p => Source.Row.mk p.1 p.2
  match mutantAllocateLoop allocationSize.val rows allocationSize 0 with
  | none => ⟨.reverted, buckets, 0, 0⟩
  | some (after, total, remaining) =>
      ⟨.committed, after.map Source.Row.allocation, total, remaining⟩

/-- TX-observe computational evidence (not itself a kill-line theorem):
witness `buckets=[0], capacities=[3], allocationSize=10`: real TX commits
`[3]` (capped by headroom), mutant TX commits `[10]` and breaches
`best.allocation + w ≤ best.capacity`. The explicit `∀` registered parent
`PAlloc2.forall_proportional_step_correspondence_and_bounded`
proves for the real `checkedAmount` that `best.allocation + w ≤
best.capacity`; the mutant's `checkedAmountNoCapacityCap` yields `w=10`
with `0+10=10 > 3`, so the mutant's `observe` would persist an
over-capacity bucket. The load-bearing refutation of the registered parent
on this mutant is the named theorem `headroom_clamp_kill_line_refutes_parent`
above; this anonymous `example` only records, computationally, that the same
witness executes to an over-capacity committed bucket through the full
`MinFirstDistributionTx` observe path. -/
example :
    let buckets := words [0]
    let capacities := words [3]
    let allocationSize := w 10
    runView buckets capacities allocationSize = ⟨.committed, words [3], 3, 7⟩ ∧
    mutantSourceView buckets capacities allocationSize = ⟨.committed, words [10], 10, 0⟩ ∧
    (let best : Source.Row := ⟨w 0, w 3⟩
     checkedAmountNoCapacityCap [best] allocationSize best = some (w 10) ∧
     ¬ (best.allocation.val + (w 10 : Source.Word).val ≤ best.capacity.val) ∧
     Source.checkedAmount [best] allocationSize best = some (w 3)) := by
  native_decide

end LidoSRv3.Tests.MinFirstDistributionTxMutants
