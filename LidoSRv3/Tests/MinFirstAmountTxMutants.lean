import LidoSRv3.Audit.Verity.MinFirstAmountTx

/-!
# P-ALLOC-2 amounts: transaction-plane mutants

Each mutant below drops exactly one operation of pinned source lines 102--106
(or of the outer `allocate` loop at lines 37/41) and is rejected on a concrete
state by the transaction-plane observation.  The last mutant is a source-plane
one: it replaces `ceilDiv` at line 103 by floor division, which silently
destroys the min-first loop's strict progress.
-/

namespace LidoSRv3.Tests.MinFirstAmountTxMutants

open _root_.Verity
open _root_.Contracts
open _root_.Verity.Stdlib.Math
open LidoSRv3.Audit.MinFirstAllocation
open LidoSRv3.Audit.Verity.MinFirstAmountTx

/-- Best candidate holding 2 of a capacity of 5, next allocation level 4,
remaining demand 10, nothing allocated yet. -/
def row : Source.Row := ⟨2, 5⟩

def state : ContractState := stateFor row 0 10 _root_.Verity.defaultState

/-- Reference behaviour: `min(10, min(4,5) - 2) = 2`. -/
theorem reference_step :
    observe ((MinFirstAllocationTx.allocateToBestCandidate 10 4).run state) =
      ⟨.committed, 2, 4, 2, 8⟩ := by
  native_decide

/-- Mutant: the outer `Math256.min` against the headroom is dropped, so the
whole demand share is written. -/
def dropHeadroomMin (share upperBound : Uint256) : Contract Uint256 := do
  let b ← getStorage MinFirstAllocationTx.bucket
  let c ← getStorage MinFirstAllocationTx.capacity
  let _headroom ← subPanic (Contracts.min upperBound c) b
  let newBucket ← addPanic b share
  setStorage MinFirstAllocationTx.bucket newBucket
  let total ← getStorage MinFirstAllocationTx.allocatedActual
  let newTotal ← addPanic total share
  setStorage MinFirstAllocationTx.allocatedActual newTotal
  let size ← getStorage MinFirstAllocationTx.remaining
  let newRemaining ← subPanic size share
  setStorage MinFirstAllocationTx.remaining newRemaining
  _root_.Verity.pure share

/-- Mutant: the headroom subtraction at line 104 is omitted, so the bound
itself is used as available room. -/
def dropAllocationSubtraction (share upperBound : Uint256) : Contract Uint256 := do
  let b ← getStorage MinFirstAllocationTx.bucket
  let c ← getStorage MinFirstAllocationTx.capacity
  let headroom := Contracts.min upperBound c
  let amount := Contracts.min share headroom
  let newBucket ← addPanic b amount
  setStorage MinFirstAllocationTx.bucket newBucket
  let total ← getStorage MinFirstAllocationTx.allocatedActual
  let newTotal ← addPanic total amount
  setStorage MinFirstAllocationTx.allocatedActual newTotal
  let size ← getStorage MinFirstAllocationTx.remaining
  let newRemaining ← subPanic size amount
  setStorage MinFirstAllocationTx.remaining newRemaining
  _root_.Verity.pure amount

/-- Mutant: the outer loop's `allocationSize - allocated` at line 37 is omitted,
so the remaining demand never shrinks and the loop would never terminate. -/
def dropRemainingUpdate (share upperBound : Uint256) : Contract Uint256 := do
  let b ← getStorage MinFirstAllocationTx.bucket
  let c ← getStorage MinFirstAllocationTx.capacity
  let headroom ← subPanic (Contracts.min upperBound c) b
  let amount := Contracts.min share headroom
  let newBucket ← addPanic b amount
  setStorage MinFirstAllocationTx.bucket newBucket
  let total ← getStorage MinFirstAllocationTx.allocatedActual
  let newTotal ← addPanic total amount
  setStorage MinFirstAllocationTx.allocatedActual newTotal
  _root_.Verity.pure amount

/-- Dropping the headroom `min` breaches the candidate's capacity: the bucket
is written past `capacities[bestCandidateIndex]`. -/
theorem dropHeadroomMin_is_detected :
    observe ((dropHeadroomMin 10 4).run state) ≠
      observe ((MinFirstAllocationTx.allocateToBestCandidate 10 4).run state) ∧
    row.capacity.val < (observe ((dropHeadroomMin 10 4).run state)).bucket.val := by
  native_decide

/-- Dropping the `- bestCandidateAllocation` also breaches capacity. -/
theorem dropAllocationSubtraction_is_detected :
    observe ((dropAllocationSubtraction 10 4).run state) ≠
      observe ((MinFirstAllocationTx.allocateToBestCandidate 10 4).run state) ∧
    row.capacity.val < (observe ((dropAllocationSubtraction 10 4).run state)).bucket.val := by
  native_decide

/-- Dropping the remaining-demand decrement leaves `allocationSize` unchanged,
so the mutant makes no progress on the outer loop. -/
theorem dropRemainingUpdate_is_detected :
    observe ((dropRemainingUpdate 10 4).run state) ≠
      observe ((MinFirstAllocationTx.allocateToBestCandidate 10 4).run state) ∧
    (observe ((dropRemainingUpdate 10 4).run state)).remaining.val = 10 := by
  native_decide

/-- Source-plane mutant of line 103: floor division instead of
`Math256.ceilDiv`. -/
def floorShare (rs : List Source.Row) (allocationSize : Source.Word)
    (best : Source.Row) : Source.Word :=
  if 1 < Source.countBest rs best.allocation then
    allocationSize / Core.Uint256.ofNat (Source.countBest rs best.allocation)
  else allocationSize

/-- Two open candidates tied at allocation 0 and one unit of demand left. -/
def tiedRows : List Source.Row := [⟨0, 5⟩, ⟨0, 5⟩]

/-- `ceilDiv` allocates the last unit; floor division allocates nothing, and the
min-first outer loop would spin forever. -/
theorem floorShare_loses_progress :
    (sourceShare tiedRows 1 ⟨0, 5⟩).val = 1 ∧
      (floorShare tiedRows 1 ⟨0, 5⟩).val = 0 := by
  native_decide

/-- The same divergence observed at the transaction plane: the honest share
commits one unit, the floor-division share commits nothing. -/
theorem floorShare_is_detected_in_tx :
    observe ((MinFirstAllocationTx.allocateToBestCandidate
        (sourceShare tiedRows 1 ⟨0, 5⟩) 5).run
      (stateFor ⟨0, 5⟩ 0 1 _root_.Verity.defaultState)) ≠
      observe ((MinFirstAllocationTx.allocateToBestCandidate
        (floorShare tiedRows 1 ⟨0, 5⟩) 5).run
      (stateFor ⟨0, 5⟩ 0 1 _root_.Verity.defaultState)) := by
  native_decide

end LidoSRv3.Tests.MinFirstAmountTxMutants
