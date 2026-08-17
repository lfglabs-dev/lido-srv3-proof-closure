import LidoSRv3.Audit.StrategyProofs
import LidoSRv3.Audit.Source.MinFirstCorrespondence
import LidoSRv3.Audit.MinFirstAllocation
import LidoSRv3.Audit.Verity.MinFirstAmountTx
import LidoSRv3.Audit.Verity.MinFirstDistributionTx
import LidoSRv3.Audit.Guarantees.Registry

namespace LidoSRv3.Audit.Guarantees.PAlloc2

def guarantee : Guarantee := ⟨.pAlloc2, [.algorithm, .source, .verityTx]⟩

/-- Headline composed closure theorem for P-ALLOC-2. The executable
memory-array transaction scans, counts, bounds, divides, mutates and repeats
the pinned MinFirst loop, and its committed/reverted observables are exactly
the pinned-source loop observables. -/
theorem verity_tx_simulates_min_first_distribution
    (buckets capacities : List MinFirstAllocation.Source.Word)
    (allocationSize : MinFirstAllocation.Source.Word) (state : Verity.ContractState)
    (hBuckets : Verity.MinFirstDistributionTx.readArray state "buckets"
      Verity.MinFirstDistributionTx.bucketsBase buckets.length = some buckets)
    (hCapacities : Verity.MinFirstDistributionTx.readArray state "capacities"
      Verity.MinFirstDistributionTx.capacitiesBase capacities.length = some capacities) :
    Verity.MinFirstDistributionTx.observe buckets
        ((Verity.MinFirstDistributionTx.allocate buckets.length capacities.length
          allocationSize).run
        state) =
      Verity.MinFirstDistributionTx.sourceView buckets capacities allocationSize :=
  Verity.MinFirstDistributionTx.verity_tx_simulates_pinned_source
    buckets capacities allocationSize state hBuckets hCapacities

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

This theorem is selection-only; the proportional amount calculation and the
mutation at source lines 88--106 are covered separately by
`source_amount_correspondence` and `tx_step_matches_source` below.
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
audit's `Source.checkedAmount` distributes that subtraction over the `min`.
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

/-! ## Verity transaction plane -/

/--
Transaction-plane closure for the amounts slice.  Running the typed
`MinFirstAllocationTx.allocateToBestCandidate` contract under
`Verity.Contract.run`, fed the two source-plane words of lines 93 and 103,
commits and produces exactly the allocated word plus the three checked storage
mutations that `Source.checkedAmount` predicts: `buckets[bestCandidateIndex] +=
allocated` at line 106, and the outer `allocate` loop's `allocated +=
allocatedToBestCandidate` and `allocationSize - allocated` at lines 41 and 37.

The candidate search, the best-candidate count and `allocationSizeUpperBound`
stay on the source plane; generated Yul, runtime bytecode and the memory-array
layout of `buckets`/`capacities` remain open.
-/
theorem tx_step_matches_source
    (rs : List MinFirstAllocation.Source.Row)
    (allocationSize : MinFirstAllocation.Source.Word)
    (best : MinFirstAllocation.Source.Row)
    (total : MinFirstAllocation.Source.Word) (base : Verity.ContractState)
    (hSelected : MinFirstAllocation.Source.candidate? rs = some best)
    (hOpen : MinFirstAllocation.Source.hasFreeSpace best = true)
    (hLen : rs.length < Verity.Core.Uint256.modulus)
    (hTotal : total.val + allocationSize.val ≤ Verity.Core.MAX_UINT256) :
    Verity.MinFirstAmountTx.observe
        ((Verity.MinFirstAmountTx.MinFirstAllocationTx.allocateToBestCandidate
          (MinFirstAllocation.sourceShare rs allocationSize best)
          (MinFirstAllocation.upperBound rs best)).run
        (Verity.MinFirstAmountTx.stateFor best total allocationSize base)) =
      Verity.MinFirstAmountTx.sourceView rs allocationSize best total :=
  Verity.MinFirstAmountTx.tx_observes_source rs allocationSize best total base
    hSelected hOpen hLen hTotal

/-- Transaction-plane safety of one min-first step: it commits, allocates at
least one unit, never writes past the candidate's capacity, and decrements the
remaining demand by exactly the allocated amount. -/
theorem tx_step_is_safe
    (rs : List MinFirstAllocation.Source.Row)
    (allocationSize : MinFirstAllocation.Source.Word)
    (best : MinFirstAllocation.Source.Row)
    (total : MinFirstAllocation.Source.Word) (base : Verity.ContractState)
    (hSelected : MinFirstAllocation.Source.candidate? rs = some best)
    (hOpen : MinFirstAllocation.Source.hasFreeSpace best = true)
    (hLen : rs.length < Verity.Core.Uint256.modulus)
    (hSize : allocationSize.val ≠ 0)
    (hTotal : total.val + allocationSize.val ≤ Verity.Core.MAX_UINT256) :
    let tx := Verity.MinFirstAmountTx.observe
      ((Verity.MinFirstAmountTx.MinFirstAllocationTx.allocateToBestCandidate
        (MinFirstAllocation.sourceShare rs allocationSize best)
        (MinFirstAllocation.upperBound rs best)).run
      (Verity.MinFirstAmountTx.stateFor best total allocationSize base))
    tx.status = .committed ∧
      0 < tx.allocated.val ∧
      tx.allocated.val ≤ allocationSize.val ∧
      tx.bucket.val = best.allocation.val + tx.allocated.val ∧
      tx.bucket.val ≤ best.capacity.val ∧
      tx.total.val = total.val + tx.allocated.val ∧
      tx.remaining.val + tx.allocated.val = allocationSize.val :=
  Verity.MinFirstAmountTx.tx_step_is_safe rs allocationSize best total base
    hSelected hOpen hLen hSize hTotal

/-- Every revert of the amounts transaction rolls storage back to the exact
pre-call snapshot. -/
theorem tx_revert_restores_snapshot
    (share upperBound : MinFirstAllocation.Source.Word)
    (state rollback : Verity.ContractState) (reason : String)
    (h : (Verity.MinFirstAmountTx.MinFirstAllocationTx.allocateToBestCandidate
        share upperBound).run state = .revert reason rollback) :
    rollback = state :=
  Verity.MinFirstAmountTx.tx_revert_restores_snapshot share upperBound state rollback reason h

end LidoSRv3.Audit.Guarantees.PAlloc2
