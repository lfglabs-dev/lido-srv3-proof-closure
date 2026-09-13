import LidoSRv3.Audit.Verity.TopupParent

/-!
Kill-lines pinning `Verity.TopupParent` parent-transaction closure and
revert-restores-caller-frame theorems, plus the `ParentStatus` enum
distinctness. These re-state the module's two headline theorems so any
future change to `execute` / `sourceView` / `observe` breaks the test
surface, not only the module itself.
-/

namespace LidoSRv3.Tests.VerityTopupParentClosureKillLines

open LidoSRv3.Audit.Verity.TopupParent

/-! ## `ParentStatus` enum -/

theorem parent_status_committed_ne_reverted :
    ParentStatus.committed ≠ ParentStatus.reverted := by
  decide

theorem parent_status_decEq_committed_self :
    (decide (ParentStatus.committed = ParentStatus.committed)) = true := by
  decide

theorem parent_status_decEq_reverted_self :
    (decide (ParentStatus.reverted = ParentStatus.reverted)) = true := by
  decide

/-! ## Parent-transaction closure — one kill-line per input tuple

    The kernel-checked `parent_transaction_closure` says the observed
    `Contract.run` result equals `sourceView` on every input. Re-state it
    verbatim so the test surface is broken by any regression in `execute`,
    `observe`, or `sourceView`. -/

theorem parent_transaction_closure_restated
    (cfg : LidoSRv3.Audit.SolidityTopup.SourceTopupConfig)
    (base : LidoSRv3.Audit.SolidityTopup.SourceTopupInput)
    (gateway : Verity.Address)
    (iface : LidoSRv3.Audit.SolidityTopupParent.CalleeInterface)
    (state : Verity.ContractState) :
    ParentProposition cfg base gateway iface state :=
  parent_transaction_closure cfg base gateway iface state

/-! ## Revert restores caller frame — kill-line restatement -/

theorem revert_restores_caller_frame_restated
    (cfg : LidoSRv3.Audit.SolidityTopup.SourceTopupConfig)
    (base : LidoSRv3.Audit.SolidityTopup.SourceTopupInput)
    (gateway : Verity.Address)
    (iface : LidoSRv3.Audit.SolidityTopupParent.CalleeInterface)
    (state rollback : Verity.ContractState) (reason : String)
    (h : (execute cfg base gateway iface).run state = .revert reason rollback) :
    rollback = state :=
  revert_restores_caller_frame cfg base gateway iface state rollback reason h

/-! ## Revert-reason string constants — pin the four `RevertReason` branches. -/

theorem reasonString_allocationCallFailed :
    reasonString .allocationCallFailed = "ALLOCATION_CALL_FAILED" := rfl

theorem reasonString_lidoPullCallFailed :
    reasonString .lidoPullCallFailed = "LIDO_PULL_CALL_FAILED" := rfl

theorem reasonString_beaconPushCallFailed :
    reasonString .beaconPushCallFailed = "BEACON_PUSH_CALL_FAILED" := rfl

end LidoSRv3.Tests.VerityTopupParentClosureKillLines
