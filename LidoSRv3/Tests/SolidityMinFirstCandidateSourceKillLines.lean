import LidoSRv3.Audit.Source.MinFirstCorrespondence

namespace LidoSRv3.Tests.SolidityMinFirstCandidateSourceKillLines

open LidoSRv3.Audit
open LidoSRv3.Audit.SolidityMinFirst

/-- Pin `candidate?_eq_minFirst_candidate?`: under row correspondence, the
pinned-source recursive candidate scan agrees with the handwritten Lean
`MinFirst.candidate?` model — the discharge of the
`allocateToBestCandidate` loop shape (Lido core `17005714`,
MinFirstAllocationStrategy.sol lines 76-86). -/
theorem candidate?_eq_minFirst_candidate?_restated
    {rows : List MinFirst.Bucket} (hRows : RowsCorrespond rows) :
    candidate? rows = MinFirst.candidate? rows :=
  candidate?_eq_minFirst_candidate? hRows

/-- Pin `selects_same_next_target`: the aliased version stating that the
source loop and the model pick the same next target, intentionally not
claiming anything about the proportional allocation amount. -/
theorem selects_same_next_target_restated
    {rows : List MinFirst.Bucket} (hRows : RowsCorrespond rows) :
    candidate? rows = MinFirst.candidate? rows :=
  selects_same_next_target hRows

/-- Pin `hasFreeSpace`: the pinned-source predicate is the strict
`allocation < capacity` inequality (negation of the `continue` test at
line 77 / line 95). -/
theorem hasFreeSpace_restated (b : MinFirst.Bucket) :
    hasFreeSpace b = decide (b.allocation < b.capacity) := rfl

/-- Pin `candidate?` empty-list base case: the loop exit at line 76
returns `none`. -/
theorem candidate?_nil : candidate? ([] : List MinFirst.Bucket) = none := rfl

end LidoSRv3.Tests.SolidityMinFirstCandidateSourceKillLines
