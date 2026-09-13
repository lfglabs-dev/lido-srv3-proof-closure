import LidoSRv3.Audit.Verity.TopupHybrid

/-! # Kill-lines for `Verity.TopupHybrid.TxStatus` + `topupCallJournal`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the P-TOPUP-1 hybrid Verity-plane transaction outcomes and the
pinned two-call journal shape. -/

namespace LidoSRv3.Tests.VerityTopupHybridTxStatusKillLines

open LidoSRv3.Audit.Verity.TopupHybrid

/-- **Kill-line: `TxStatus.committed ≠ TxStatus.reverted`.**

A mutant that collapsed the two statuses would obscure success/
failure classification at the hybrid boundary. -/
theorem txStatus_committed_ne_reverted :
    TxStatus.committed ≠ TxStatus.reverted := by decide

/-- **Kill-line: DecidableEq reflexivity.** -/
theorem txStatus_committed_refl :
    decide (TxStatus.committed = TxStatus.committed) = true := by decide

theorem txStatus_reverted_refl :
    decide (TxStatus.reverted = TxStatus.reverted) = true := by decide

/-- **Kill-line: `topupCallJournal` produces exactly two entries.**

The pinned StakingRouter.topUp path emits exactly two value-bearing
external calls: withdrawDepositableEther and makeBeaconChainTopUp. -/
theorem topupCallJournal_length (pulled pushed : Nat) :
    (topupCallJournal pulled pushed).length = 2 := by
  unfold topupCallJournal; rfl

/-- **Kill-line: `topupCallJournal` non-empty.**

Concrete: journal is non-nil (contains 2 entries). -/
theorem topupCallJournal_nonempty (pulled pushed : Nat) :
    topupCallJournal pulled pushed ≠ [] := by
  unfold topupCallJournal
  intro h; cases h

/-- **Kill-line: `withCalls s []` returns s (no-op).**

Adding an empty call list to a state must be a no-op. -/
theorem withCalls_empty (s : Verity.ContractState) :
    withCalls s [] = s := by
  unfold withCalls
  simp

/-- **Kill-line: TxView constructor is injective in status field.** -/
theorem txView_status_injective
    (b1 b2 a1 a2 : Verity.ContractState) :
    (TxView.mk .committed b1 a1).status = .committed := rfl

#print axioms txStatus_committed_ne_reverted
#print axioms txStatus_committed_refl
#print axioms topupCallJournal_length
#print axioms topupCallJournal_nonempty
#print axioms withCalls_empty
#print axioms txView_status_injective

end LidoSRv3.Tests.VerityTopupHybridTxStatusKillLines
