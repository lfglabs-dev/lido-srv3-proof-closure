import LidoSRv3.Audit.Source.TopupParentCorrespondence

/-! # Kill-lines for `TopupParentCorrespondence.ParentResult` + CallKind trichotomy

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-TOPUP-1 parent-execute result enum (committedNoTopUp /
committedTopUp / reverted) and the CallKind trichotomy
(allocation / lidoPull / beaconPush). -/

namespace LidoSRv3.Tests.TopupParentResultKillLines

open LidoSRv3.Audit.SolidityTopupParent

/-- **Kill-line: `ParentResult.committedNoTopUp` ≠ `ParentResult.reverted _`.** -/
theorem parentResult_committedNoTopUp_ne_reverted (reason : RevertReason) :
    ParentResult.committedNoTopUp ≠ ParentResult.reverted reason := by
  intro h; cases h

/-- **Kill-line: `ParentResult.committedTopUp n` ≠ `ParentResult.committedNoTopUp`.** -/
theorem parentResult_committedTopUp_ne_committedNoTopUp (n : Nat) :
    ParentResult.committedTopUp n ≠ ParentResult.committedNoTopUp := by
  intro h; cases h

/-- **Kill-line: `ParentResult.committedTopUp n` ≠ `ParentResult.reverted _`.** -/
theorem parentResult_committedTopUp_ne_reverted (n : Nat) (reason : RevertReason) :
    ParentResult.committedTopUp n ≠ ParentResult.reverted reason := by
  intro h; cases h

/-- **Kill-line: `ParentResult.committedTopUp` is injective in the amount.** -/
theorem parentResult_committedTopUp_injective (n m : Nat) (h : n ≠ m) :
    ParentResult.committedTopUp n ≠ ParentResult.committedTopUp m := by
  intro hEq; apply h; cases hEq; rfl

/-- **Kill-line: `CallKind` has three distinct constructors.** -/
theorem callKind_allocation_ne_lidoPull :
    CallKind.allocation ≠ CallKind.lidoPull := by decide
theorem callKind_allocation_ne_beaconPush :
    CallKind.allocation ≠ CallKind.beaconPush := by decide
theorem callKind_lidoPull_ne_beaconPush :
    CallKind.lidoPull ≠ CallKind.beaconPush := by decide

/-- **Kill-line: `RevertReason` distinct constructors for
allocation/lidoPull/beaconPush call failures.** -/
theorem revertReason_allocation_ne_lidoPull :
    RevertReason.allocationCallFailed ≠ RevertReason.lidoPullCallFailed := by decide
theorem revertReason_lidoPull_ne_beaconPush :
    RevertReason.lidoPullCallFailed ≠ RevertReason.beaconPushCallFailed := by decide

#print axioms parentResult_committedNoTopUp_ne_reverted
#print axioms parentResult_committedTopUp_ne_committedNoTopUp
#print axioms parentResult_committedTopUp_injective
#print axioms callKind_allocation_ne_lidoPull
#print axioms callKind_lidoPull_ne_beaconPush
#print axioms revertReason_allocation_ne_lidoPull

end LidoSRv3.Tests.TopupParentResultKillLines
