import LidoSRv3.Audit.Strategy

/-!
Pinned source correspondence for `MinFirstAllocationStrategy` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`contracts/common/lib/MinFirstAllocationStrategy.sol`.

`allocateToBestCandidate`, `MinFirstAllocationStrategy.sol:76-86`, scans buckets in ascending index
order, skips a bucket when `buckets[i] >= capacities[i]`, and replaces the
saved candidate only when `bestCandidateAllocation > buckets[i]`.  Thus an
equal-valued later bucket does not replace the first one.  The definition below
is the extensionally equivalent recursive presentation of that candidate-search
loop: it selects the first least open row.

This module deliberately models only the selected target.
`MinFirstAllocationStrategy.sol:92-106` compute and apply a proportional
allocation amount; no amount/refinement claim is made here because
`MinFirst.step` uses one `Nat` unit.  The proportional amount, including
`bestCandidatesCount` (lines 81-84), is transcribed by
`LidoSRv3.Audit.MinFirstAllocation.Source.checkedAmount` and consumed by
`Verity.MinFirstDistributionTx`.
-/

namespace LidoSRv3.Audit.SolidityMinFirst

open LidoSRv3.Audit

/-! ## MinFirstAllocationStrategy.allocateToBestCandidate, candidate scan (MinFirstAllocationStrategy.sol:76-86) -/

/-- Solidity's free-space condition at `MinFirstAllocationStrategy.sol:77` and
`:95` (negation of the `continue` test). -/
def hasFreeSpace (b : MinFirst.Bucket) : Bool :=
  -- MinFirstAllocationStrategy.sol:77  if (buckets[i] >= capacities[i]) { continue; }  (negated)
  decide (b.allocation < b.capacity)

/--
Functional presentation of the candidate-search loop at
`MinFirstAllocationStrategy.sol:76-86`.
The `≤` branch is the first-index tie behavior induced by Solidity's strict
replacement test `bestCandidateAllocation > buckets[i]` at line 79.

Not transcribed: `bestCandidatesCount` (lines 81 and 84) is not carried by this
selection-only presentation; it lives in
`LidoSRv3.Audit.MinFirstAllocation.Source.checkedAmount` (via `countBest`).
`none` is the `bestCandidatesCount == 0` exit of lines 88-90.
-/
def candidate? : List MinFirst.Bucket → Option MinFirst.Bucket
  -- MinFirstAllocationStrategy.sol:76  for (uint256 i = 0; i < buckets.length; ++i) {  (loop exit)
  | [] => none
  | b :: bs =>
      match candidate? bs with
      -- MinFirstAllocationStrategy.sol:77-78  if (buckets[i] >= capacities[i]) { continue; }
      | none => if hasFreeSpace b then some b else none
      -- MinFirstAllocationStrategy.sol:79-82  else if (bestCandidateAllocation > buckets[i]) { bestCandidateIndex = i; ... }
      -- The recursion visits later indices first, so `b` wins on `≤`: exactly the strict `>` of a forward scan.
      | some later =>
          if hasFreeSpace b && decide (b.allocation ≤ later.allocation)
          then some b else some later

/-- Row correspondence for this selection-only slice: the lists are in the
same router order and each Solidity free-space test agrees with Lean's model
open predicate. -/
def RowsCorrespond (rows : List MinFirst.Bucket) : Prop :=
  ∀ b, b ∈ rows → hasFreeSpace b = b.open

theorem candidate?_eq_minFirst_candidate?
    (hRows : RowsCorrespond rows) :
    candidate? rows = MinFirst.candidate? rows := by
  induction rows with
  | nil => rfl
  | cons b bs ih =>
      have hb : hasFreeSpace b = b.open := hRows b (by simp)
      have hbs : RowsCorrespond bs := by
        intro other hOther
        exact hRows other (by simp [hOther])
      rw [candidate?, MinFirst.candidate?, ih hbs]
      cases MinFirst.candidate? bs <;> simp [hb]

/--
Under row correspondence, the source-shaped loop and the handwritten Lean
model select exactly the same next target.  This is intentionally not a claim
about the proportional allocation amount computed at
`MinFirstAllocationStrategy.sol:92-106`.
-/
theorem selects_same_next_target
    (hRows : RowsCorrespond rows) :
    candidate? rows = MinFirst.candidate? rows :=
  candidate?_eq_minFirst_candidate? hRows

end LidoSRv3.Audit.SolidityMinFirst
