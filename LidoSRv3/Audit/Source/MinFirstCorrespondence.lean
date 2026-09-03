import LidoSRv3.Audit.Strategy

/-!
Pinned source correspondence for `MinFirstAllocationStrategy` at
`lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
`contracts/common/lib/MinFirstAllocationStrategy.sol`.

`allocateToBestCandidate`, lines 76--86, scans buckets in ascending index
order, skips a bucket when `buckets[i] >= capacities[i]`, and replaces the
saved candidate only when `bestCandidateAllocation > buckets[i]`.  Thus an
equal-valued later bucket does not replace the first one.  The definition below
is the extensionally equivalent recursive presentation of that candidate-search
loop: it selects the first least open row.

This module deliberately models only the selected target.  Lines 92--106
compute and apply a proportional allocation amount; no amount/refinement claim
is made here because `MinFirst.step` uses one `Nat` unit.
-/

namespace LidoSRv3.Audit.SolidityMinFirst

open LidoSRv3.Audit

/-- Solidity's free-space condition at source lines 76--79 and 94--97. -/
def hasFreeSpace (b : MinFirst.Bucket) : Bool :=
  decide (b.allocation < b.capacity)

/--
Functional presentation of the candidate-search loop at source lines 76--86.
The `≤` branch is the first-index tie behavior induced by Solidity's strict
replacement test `bestCandidateAllocation > buckets[i]` at line 79.
-/
def candidate? : List MinFirst.Bucket → Option MinFirst.Bucket
  | [] => none
  | b :: bs =>
      match candidate? bs with
      | none => if hasFreeSpace b then some b else none
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
about the proportional allocation amount computed at source lines 92--106.
-/
theorem selects_same_next_target
    (hRows : RowsCorrespond rows) :
    candidate? rows = MinFirst.candidate? rows :=
  candidate?_eq_minFirst_candidate? hRows

end LidoSRv3.Audit.SolidityMinFirst
