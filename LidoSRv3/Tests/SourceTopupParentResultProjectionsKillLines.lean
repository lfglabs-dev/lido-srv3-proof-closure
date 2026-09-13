import LidoSRv3.Audit.Source.TopupParentCorrespondence

/-!
Kill-lines pinning `Source.TopupParentCorrespondence`
`ParentResult.reverts` / `.pulled` / `.pushed` truth-tables and the
`committed_conserves` witness theorem.
-/

namespace LidoSRv3.Tests.SourceTopupParentResultProjectionsKillLines

open LidoSRv3.Audit.SolidityTopupParent

/-! ## `ParentResult.reverts` truth-table across all 5 constructors. -/

theorem reverts_committedNoTopUp :
    ParentResult.reverts .committedNoTopUp = false := rfl

theorem reverts_committedTopUp (amount : Nat) :
    ParentResult.reverts (.committedTopUp amount) = false := rfl

theorem reverts_reverted (reason : RevertReason) :
    ParentResult.reverts (.reverted reason) = true := rfl

/-! ## `ParentResult.pulled` on the three constructors. -/

theorem pulled_committedNoTopUp :
    ParentResult.pulled .committedNoTopUp = 0 := rfl

theorem pulled_committedTopUp (amount : Nat) :
    ParentResult.pulled (.committedTopUp amount) = amount := rfl

theorem pulled_reverted (reason : RevertReason) :
    ParentResult.pulled (.reverted reason) = 0 := rfl

/-! ## `ParentResult.pushed` mirrors pulled on the three constructors. -/

theorem pushed_committedNoTopUp :
    ParentResult.pushed .committedNoTopUp = 0 := rfl

theorem pushed_committedTopUp (amount : Nat) :
    ParentResult.pushed (.committedTopUp amount) = amount := rfl

theorem pushed_reverted (reason : RevertReason) :
    ParentResult.pushed (.reverted reason) = 0 := rfl

/-! ## `committed_conserves` — restated: pulled = pushed on non-revert. -/

theorem committed_conserves_restated (execution : ParentExecution)
    (h : execution.result.reverts = false) :
    execution.result.pulled = execution.result.pushed :=
  committed_conserves execution h

/-! ## `RevertReason` distinctness for the four constructors. -/

theorem revertReason_allocation_ne_lidoPull :
    RevertReason.allocationCallFailed ≠ RevertReason.lidoPullCallFailed := by
  decide

theorem revertReason_lidoPull_ne_beaconPush :
    RevertReason.lidoPullCallFailed ≠ RevertReason.beaconPushCallFailed := by
  decide

theorem revertReason_allocation_ne_beacon :
    RevertReason.allocationCallFailed ≠ RevertReason.beaconPushCallFailed := by
  decide

end LidoSRv3.Tests.SourceTopupParentResultProjectionsKillLines
