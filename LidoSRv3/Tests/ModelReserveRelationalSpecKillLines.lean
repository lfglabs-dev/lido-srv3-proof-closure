import LidoSRv3.Audit.Model.ReserveRelational

/-! # Kill-lines for `Model.ReserveRelational.spec` short-circuit behavior

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the abstract-plane `spec` short-circuit guards: paused-queue
revert, empty-batchEnds revert, buffer-shortfall revert, and
happy-path commit. -/

namespace LidoSRv3.Tests.ModelReserveRelationalSpecKillLines

open LidoSRv3.Audit.ReserveRelational

/-- Empty state fixture. -/
def emptyState : State := ⟨0, 0⟩

/-- **Kill-line: paused queue always reverts.**

A mutant dropping the paused guard would allow finalization while
the queue is paused. -/
theorem spec_paused_reverts :
    spec ⟨⟨[3], false⟩, ⟨0, [], true⟩, 100⟩ emptyState = .reverted emptyState := rfl

/-- **Kill-line: empty batchEnds always reverts.**

A mutant dropping the empty-check would try to finalize with no
requested batches. -/
theorem spec_empty_batchEnds_reverts :
    spec ⟨⟨[], false⟩, ⟨0, [], false⟩, 100⟩ emptyState = .reverted emptyState := rfl

/-- **Kill-line: buffer shortfall reverts.**

Requested finalization (100 eth) exceeds buffer (50); a mutant that
skipped this check would over-lock. -/
theorem spec_buffer_shortfall_reverts :
    spec ⟨⟨[5], false⟩, ⟨0, [⟨5, 100, 90, 5⟩], false⟩, 50⟩ emptyState =
      .reverted emptyState := by decide

/-- **Kill-line: happy path commits with locked = before.locked + eth.**

Buffer 100 covers requested 100 eth; the after-state's lockedEth
becomes 0 + 100 = 100. -/
theorem spec_happy_path_commits :
    spec ⟨⟨[5], false⟩, ⟨0, [⟨5, 100, 90, 5⟩], false⟩, 100⟩ emptyState =
      .committed ⟨0, 100⟩
        ⟨[(1, 5)], 100, 5, some (1, 5), 100⟩ := by decide

/-- **Kill-line: happy path with discount uses discountedEth (90).** -/
theorem spec_happy_path_discount :
    spec ⟨⟨[5], true⟩, ⟨0, [⟨5, 100, 90, 5⟩], false⟩, 100⟩ emptyState =
      .committed ⟨0, 90⟩
        ⟨[(1, 5)], 90, 5, some (1, 5), 90⟩ := by decide

#print axioms spec_paused_reverts
#print axioms spec_empty_batchEnds_reverts
#print axioms spec_buffer_shortfall_reverts
#print axioms spec_happy_path_commits
#print axioms spec_happy_path_discount

end LidoSRv3.Tests.ModelReserveRelationalSpecKillLines
