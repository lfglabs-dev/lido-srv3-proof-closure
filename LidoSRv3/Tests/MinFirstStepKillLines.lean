import LidoSRv3.Audit.Strategy

/-! # Kill-lines for `MinFirst.Bucket.open` and `step` semantics

**Chantier 3 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned MinFirstAllocationStrategy step semantics: active &&
free-space open test, one-validator-per-step increment, and no-op
when no candidate. -/

namespace LidoSRv3.Tests.MinFirstStepKillLines

open LidoSRv3.Audit
open LidoSRv3.Audit.MinFirst

/-- Active + open bucket. -/
def liveBucket : Bucket :=
  { moduleId := 1, active := true, credentialType := .wc01,
    allocation := 1, capacity := 5 }

/-- Active but full bucket. -/
def liveFull : Bucket :=
  { moduleId := 2, active := true, credentialType := .wc01,
    allocation := 5, capacity := 5 }

/-- Inactive bucket. -/
def deadBucket : Bucket :=
  { moduleId := 3, active := false, credentialType := .wc01,
    allocation := 1, capacity := 5 }

/-- **Kill-line: `Bucket.open` requires both `active` and free space.**

A mutant that dropped either conjunct would refute. -/
theorem open_composition (b : Bucket) :
    b.open = (b.active && decide (b.allocation < b.capacity)) := rfl

/-- **Kill-line: active + free-space bucket is open.** -/
theorem liveBucket_open : liveBucket.open = true := by decide

/-- **Kill-line: full bucket is closed.** -/
theorem liveFull_closed : liveFull.open = false := by decide

/-- **Kill-line: inactive bucket is closed.** -/
theorem deadBucket_closed : deadBucket.open = false := by decide

/-- **Kill-line: `step` on empty rows yields empty rows.** -/
theorem step_empty : step [] = [] := rfl

/-- **Kill-line: `step` on no-candidate rows (all full) returns unchanged.** -/
theorem step_no_candidate :
    step [liveFull] = [liveFull] := by decide

/-- **Kill-line: `step` on singleton open bucket increments its allocation by 1.** -/
theorem step_single_open :
    step [liveBucket] = [{ liveBucket with allocation := 2 }] := by decide

#print axioms open_composition
#print axioms liveBucket_open
#print axioms liveFull_closed
#print axioms deadBucket_closed
#print axioms step_empty
#print axioms step_no_candidate
#print axioms step_single_open

end LidoSRv3.Tests.MinFirstStepKillLines
