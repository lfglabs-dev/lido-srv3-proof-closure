import LidoSRv3.Audit.Source.MinFirstAmountCorrespondence

/-!
# P-ALLOC-2 proportional step, lowered to the source layer

These are the candidate/amount step facts behind P-ALLOC-2's registered
step theorem, stated entirely over `LidoSRv3.Audit.MinFirstAllocation`
(production layer) and `LidoSRv3.Audit.Source.MinFirstAmountCorrespondence`
(source layer).  They were moved here from
`LidoSRv3.Audit.Guarantees.PAlloc2` so source-plane consumers (for example
`LidoSRv3.Audit.Source.TrioComposition.AllocSeam`) can cite the
proportional-step facts without a Source → Guarantees import edge.
`PAlloc2` re-states each theorem with an identical statement, forwarding
to the proofs in this module; no registered content changed.

Pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`MinFirstAllocationStrategy.allocateToBestCandidate` lines 76--106.
-/

namespace LidoSRv3.Audit.Source.MinFirstProportionalStep

/-- Full pinned-source candidate scan correspondence for the independent
MODEL/SOURCE representations used by the proportional mutation slice.
Together with `source_amount_correspondence` below this is registered parent
evidence; the remaining OPEN step is folding amount equality into the
registered parent's conclusion and lifting it to a full-loop theorem. -/
theorem full_candidate_correspondence
    (hRows : MinFirstAllocation.RowsCorrespond model source) :
    Option.map (fun b => (b.allocation, b.capacity))
        (MinFirstAllocation.Model.candidate? model) =
      Option.map (fun r => (r.allocation.val, r.capacity.val))
        (MinFirstAllocation.Source.candidate? source) :=
  MinFirstAllocation.candidate_correspondence hRows

/-! ## Proportional amount, pinned source lines 88--106 -/

/--
The proportional allocation amount at source lines 102--105 is the value of the
unbounded model amount, whenever the checked `uint256` arithmetic succeeds.  The
array-length premise is what reflects a Solidity candidate count back into
`Nat`; an EVM memory array cannot hold `2^256` entries.
-/
theorem source_amount_correspondence
    {model : List MinFirstAllocation.Model.Bucket}
    {source : List MinFirstAllocation.Source.Row}
    {mbest : MinFirstAllocation.Model.Bucket}
    {sbest : MinFirstAllocation.Source.Row}
    {allocationSize w : MinFirstAllocation.Source.Word}
    (hRows : MinFirstAllocation.RowsCorrespond model source)
    (hLen : source.length < Verity.Core.Uint256.modulus)
    (hAlloc : mbest.allocation = sbest.allocation.val)
    (hCap : mbest.capacity = sbest.capacity.val)
    (hAmount : MinFirstAllocation.Source.checkedAmount source allocationSize sbest = some w) :
    MinFirstAllocation.Model.amount model allocationSize.val mbest = w.val :=
  MinFirstAllocation.amount_correspondence hRows hLen hAlloc hCap hAmount

/--
The pinned source subtracts once, after the inner `Math256.min`, whereas the
audit `Source.checkedAmount` distributes that subtraction over the `min`.
This discharges the difference rather than assuming it: for any best candidate
with free space the two expressions are the same `Option`.
-/
theorem source_pinned_expression_shape
    {rs : List MinFirstAllocation.Source.Row}
    {allocationSize : MinFirstAllocation.Source.Word}
    {best : MinFirstAllocation.Source.Row}
    (hOpen : MinFirstAllocation.Source.hasFreeSpace best = true) :
    MinFirstAllocation.pinnedAmount rs allocationSize best =
      MinFirstAllocation.Source.checkedAmount rs allocationSize best :=
  MinFirstAllocation.pinnedAmount_eq_checkedAmount hOpen

/--
The pinned checked arithmetic of lines 102--106 never reverts for an open best
candidate, and the resulting word makes strict progress without breaching the
candidate's capacity or underflowing the remaining demand.  These are exactly
the premises `Source.Execute.mutate` carries as hypotheses.
-/
theorem source_amount_totality
    {rs : List MinFirstAllocation.Source.Row}
    {allocationSize : MinFirstAllocation.Source.Word}
    {best : MinFirstAllocation.Source.Row} {w : MinFirstAllocation.Source.Word}
    (hOpen : MinFirstAllocation.Source.hasFreeSpace best = true)
    (hLen : rs.length < Verity.Core.Uint256.modulus)
    (hSize : allocationSize.val ≠ 0)
    (hAmount : MinFirstAllocation.Source.checkedAmount rs allocationSize best = some w) :
    0 < w.val ∧ w.val ≤ allocationSize.val ∧
      best.allocation.val + w.val ≤ best.capacity.val :=
  ⟨MinFirstAllocation.checkedAmount_pos hOpen hLen hSize hAmount,
   MinFirstAllocation.checkedAmount_le_size hOpen hLen hAmount,
   MinFirstAllocation.checkedAmount_le_headroom hOpen hAmount⟩

/-- **Helper (wave-1 parent with implicit binders; the registered parent is
now the explicit-∀ `forall_proportional_step_correspondence_and_bounded`
below, re-registered by human PR #134 — this theorem is the retained helper
the parent's proof forwards to).**  For the pinned-source *proportional* step
(not the +1-per-iteration `MinFirst` model demoted in `PAlloc2`): given
`RowsCorrespond` between the handwritten `Model` rows and the word-typed
`Source` rows, and given that the source scan selected `best` (`hSelected`),
the independently-defined model scan selects that same bucket — the first
conjunct pins the model scan's result to the *selected* row, so `hSelected`
is load-bearing; and whenever the checked `uint256` amount for the selected
candidate succeeds, it is positive, does not exceed the remaining demand, and
keeps the candidate within its capacity (`best.allocation + w ≤
best.capacity`, i.e. the allocation never runs over headroom). -/
theorem proportional_step_correspondence_and_bounded
    {model : List MinFirstAllocation.Model.Bucket}
    {source : List MinFirstAllocation.Source.Row}
    {best : MinFirstAllocation.Source.Row}
    {allocationSize w : MinFirstAllocation.Source.Word}
    (hRows : MinFirstAllocation.RowsCorrespond model source)
    (hSelected : MinFirstAllocation.Source.candidate? source = some best)
    (hOpen : MinFirstAllocation.Source.hasFreeSpace best = true)
    (hLen : source.length < Verity.Core.Uint256.modulus)
    (hSize : allocationSize.val ≠ 0)
    (hAmount : MinFirstAllocation.Source.checkedAmount source allocationSize best = some w) :
    (Option.map (fun b => (b.allocation, b.capacity)) (MinFirstAllocation.Model.candidate? model) =
      some (best.allocation.val, best.capacity.val)) ∧
    MinFirstAllocation.Model.amount model allocationSize.val
      ⟨best.allocation.val, best.capacity.val⟩ = w.val ∧
    0 < w.val ∧ w.val ≤ allocationSize.val ∧
      best.allocation.val + w.val ≤ best.capacity.val :=
  ⟨by rw [full_candidate_correspondence hRows, hSelected]; rfl,
   source_amount_correspondence hRows hLen rfl rfl hAmount,
   source_amount_totality hOpen hLen hSize hAmount⟩

/-- **Explicit ∀ registered parent (P-ALLOC-2).** Universal closure over
valid model/source rows and `allocationSize`: for every model/source pair
with `RowsCorrespond`, every selected open best candidate, every non-zero
remaining demand and every successful checked amount, the candidate
correspondence holds and the amount is positive, bounded by the remaining
 demand, and capacity-safe. It also identifies the checked source word with
the independent unbounded `Model.amount`, making the proportional `ceilDiv`
and both model clamps load-bearing parent content. The `∀` is explicit so the bound is not an
existential witness over one allocationSize. -/
theorem forall_proportional_step_correspondence_and_bounded :
    ∀ (model : List MinFirstAllocation.Model.Bucket)
      (source : List MinFirstAllocation.Source.Row)
      (best : MinFirstAllocation.Source.Row)
      (allocationSize w : MinFirstAllocation.Source.Word),
      MinFirstAllocation.RowsCorrespond model source →
      MinFirstAllocation.Source.candidate? source = some best →
      MinFirstAllocation.Source.hasFreeSpace best = true →
      source.length < Verity.Core.Uint256.modulus →
      allocationSize.val ≠ 0 →
      MinFirstAllocation.Source.checkedAmount source allocationSize best = some w →
      (Option.map (fun b => (b.allocation, b.capacity)) (MinFirstAllocation.Model.candidate? model) =
        some (best.allocation.val, best.capacity.val)) ∧
      MinFirstAllocation.Model.amount model allocationSize.val
        ⟨best.allocation.val, best.capacity.val⟩ = w.val ∧
      0 < w.val ∧ w.val ≤ allocationSize.val ∧
        best.allocation.val + w.val ≤ best.capacity.val :=
  fun _ _ _ _ _ hRows hSelected hOpen hLen hSize hAmount =>
    proportional_step_correspondence_and_bounded hRows hSelected hOpen hLen hSize hAmount

end LidoSRv3.Audit.Source.MinFirstProportionalStep
