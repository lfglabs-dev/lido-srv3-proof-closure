import LidoSRv3.Audit.Source.MinFirstCorrespondence

/-! # Kill-lines for `SolidityMinFirst.hasFreeSpace` and `candidate?`

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned `MinFirstAllocationStrategy.allocateToBestCandidate`
candidate-scan free-space test semantics. -/

namespace LidoSRv3.Tests.MinFirstCorrespondenceHasFreeSpaceKillLines

open LidoSRv3.Audit.SolidityMinFirst
open LidoSRv3.Audit
open LidoSRv3.Audit.MinFirst

/-- A concrete bucket at allocation < capacity is open. -/
def openBucket : Bucket :=
  { moduleId := 0, active := true, credentialType := .wc01,
    allocation := 1, capacity := 5 }

/-- A concrete bucket at allocation = capacity (full). -/
def fullBucket : Bucket :=
  { moduleId := 0, active := true, credentialType := .wc01,
    allocation := 5, capacity := 5 }

/-- A concrete bucket at allocation > capacity (over-full). -/
def overfullBucket : Bucket :=
  { moduleId := 0, active := true, credentialType := .wc01,
    allocation := 6, capacity := 5 }

/-- **Kill-line: `hasFreeSpace` = decide (allocation < capacity).**

A mutant that swapped `<` for `≤` or `≥` would refute the pinned
Solidity `if (buckets[i] >= capacities[i]) { continue; }`
condition (negated). -/
theorem hasFreeSpace_composition (b : Bucket) :
    hasFreeSpace b = decide (b.allocation < b.capacity) := rfl

/-- **Kill-line: open bucket has free space.** -/
theorem openBucket_hasFreeSpace :
    hasFreeSpace openBucket = true := by decide

/-- **Kill-line: full bucket has no free space (allocation = capacity).** -/
theorem fullBucket_no_freeSpace :
    hasFreeSpace fullBucket = false := by decide

/-- **Kill-line: over-full bucket has no free space.** -/
theorem overfullBucket_no_freeSpace :
    hasFreeSpace overfullBucket = false := by decide

/-- **Kill-line: `candidate?` on empty list returns none.** -/
theorem candidate_empty :
    SolidityMinFirst.candidate? [] = none := rfl

/-- **Kill-line: `candidate?` on singleton with free space returns it.** -/
theorem candidate_singleton_open :
    SolidityMinFirst.candidate? [openBucket] = some openBucket := rfl

/-- **Kill-line: `candidate?` on singleton with no free space returns none.** -/
theorem candidate_singleton_full :
    SolidityMinFirst.candidate? [fullBucket] = none := by decide

#print axioms hasFreeSpace_composition
#print axioms openBucket_hasFreeSpace
#print axioms fullBucket_no_freeSpace
#print axioms overfullBucket_no_freeSpace
#print axioms candidate_empty
#print axioms candidate_singleton_open
#print axioms candidate_singleton_full

end LidoSRv3.Tests.MinFirstCorrespondenceHasFreeSpaceKillLines
