import LidoSRv3.Audit.Spec.EthJournalConfinement

/-!
# P-ETH-JOURNAL-1 composition parent

This parent composes the three existing Spec projections without widening
`ApprovedDestination`: conserving two-batch deposit, value-moving top-up, and
consolidation fee/refund.  It is not a claim about all SRv3 ETH.
-/

namespace LidoSRv3.Audit.Guarantees.PEthJournal1

open LidoSRv3.Audit.Guarantees.PConsolidationEth1
open LidoSRv3.Audit.SolidityTopup
open LidoSRv3.Audit.Spec.EthJournalConfinement
open LidoSRv3.Audit.Spec.EthJournalCorrespondence

/-- Composition parent: every leg of each premise-satisfying modeled success
journal has a frozen `ApprovedDestination`.

The deposit premise is the executable two-batch conserving boundary.  The
top-up premise selects the value-moving schedule rather than the empty
wrap-to-zero schedule.  The consolidation equation selects the successful
fee/refund arm.  The final named conjunct keeps the former Vault-to-Lido and
WithdrawalQueue protocol-return paths outside this parent. -/
theorem every_modeled_success_journal_approved
    (depositInputs : LidoSRv3.Audit.Verity.DepositParentTx.Inputs)
    (depositEntry : _root_.Verity.ContractState)
    (topupAllocations : List Nat)
    (approved : ApprovedSet)
    (msgValue batchSize fee : Nat)
    (consolidationMoves : List EthMove)
    (_hDeposit :
      LidoSRv3.Audit.Verity.DepositParentTx.Preconditions depositInputs depositEntry)
    (_hTopupValueMoving : allocSumUnchecked topupAllocations ≠ 0)
    (hDistinct : approved.refundRecipient ≠ approved.consolidationContract)
    (hConsolidation :
      gatewayExecute approved msgValue batchSize fee = .success consolidationMoves) :
    EveryModeledSuccessJournalApproved
        (depositCandidate depositInputs)
        (topupCandidate topupAllocations)
        (consolidationCandidate consolidationMoves) ∧
      ProtocolReturnPathsExcluded consolidationMoves := by
  have hProjection :=
    success_journal_projects_to_spec
      approved hDistinct msgValue batchSize fee
  rw [hConsolidation] at hProjection
  exact
    ⟨⟨depositCandidate_approved depositInputs,
       topupCandidate_approved topupAllocations,
       consolidationCandidate_approved_of_projected
         consolidationMoves hProjection.1⟩,
     protocolReturnPathsExcluded_of_projected
       consolidationMoves hProjection.1⟩

end LidoSRv3.Audit.Guarantees.PEthJournal1
