import LidoSRv3.Audit.Verity.TopupHybrid

/-!
Kill-lines pinning `Verity.TopupHybrid` `withCalls` state extension
and `topupCallJournal` two-entry shape.
-/

namespace LidoSRv3.Tests.VerityTopupHybridExecuteSourceKillLines

open LidoSRv3.Audit.Verity.TopupHybrid

/-! ## `withCalls` extends the call journal via list append. -/

theorem withCalls_empty (s : Verity.ContractState) :
    withCalls s [] = s := by
  simp [withCalls]

/-! ## `topupCallJournal` has exactly two entries. -/

theorem topupCallJournal_length (pulled pushed : Nat) :
    (topupCallJournal pulled pushed).length = 2 := rfl

/-! ## `topupCallJournal` first entry name. -/

theorem topupCallJournal_first_name (pulled pushed : Nat) :
    (topupCallJournal pulled pushed).head?.map (·.name) =
      some "withdrawDepositableEther" := rfl

/-! ## `TxStatus` two-arm enum decidable distinctness. -/

theorem txStatus_committed_ne_reverted :
    TxStatus.committed ≠ TxStatus.reverted := by decide

theorem txStatus_decEq_self :
    (decide (TxStatus.committed = TxStatus.committed)) = true := by decide

end LidoSRv3.Tests.VerityTopupHybridExecuteSourceKillLines
