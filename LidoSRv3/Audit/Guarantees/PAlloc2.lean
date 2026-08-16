import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Source.MinFirstCorrespondence
import LidoSRv3.Audit.MinFirstAllocation
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc2

def guarantee : Guarantee := ⟨.pAlloc2, [.algorithm, .source]⟩

/--
The executable MinFirst control rule selects an open bucket with no larger
allocation than any other open input bucket. This is an ALG theorem for the
handwritten `Nat` model; Solidity and EVM refinement remain open.
-/
theorem selects_least_open_bucket
    (h : MinFirst.candidate? rows = some selected)
    (hOther : other ∈ rows) (hOpen : other.open = true) :
    selected.allocation ≤ other.allocation := by
  exact MinFirst.candidate_minimal h hOther hOpen

/--
Pinned-source selection correspondence for
`MinFirstAllocationStrategy.allocateToBestCandidate` at
`lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`, lines 76--86.
Given router-order and free-space-predicate correspondence, the source-shaped
candidate loop selects the same next bucket as `MinFirst.candidate?`.

This theorem is deliberately selection-only: it excludes the proportional
allocation amount calculation and mutation at source lines 92--106.
-/
theorem source_selects_same_next_target
    (hRows : SolidityMinFirst.RowsCorrespond rows) :
    SolidityMinFirst.candidate? rows = MinFirst.candidate? rows :=
  SolidityMinFirst.selects_same_next_target hRows

/-- Full pinned-source candidate scan correspondence for the independent
MODEL/SOURCE representations used by the proportional mutation slice. -/
theorem full_candidate_correspondence
    (hRows : MinFirstAllocation.RowsCorrespond model source) :
    Option.map (fun b => (b.allocation, b.capacity))
        (MinFirstAllocation.Model.candidate? model) =
      Option.map (fun r => (r.allocation.val, r.capacity.val))
        (MinFirstAllocation.Source.candidate? source) :=
  MinFirstAllocation.candidate_correspondence hRows

end LidoSRv3.Audit.Guarantees.PAlloc2
