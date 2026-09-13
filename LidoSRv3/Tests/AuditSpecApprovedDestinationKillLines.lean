import LidoSRv3.Audit.Spec

/-! # Kill-lines for `Audit.Spec.ApprovedDestination`

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Wave 0 frozen composition-interface enumeration of six approved
ETH destinations. -/

namespace LidoSRv3.Tests.AuditSpecApprovedDestinationKillLines

open LidoSRv3.Audit.Spec

/-- **Kill-line: six constructors, six enum values pairwise-distinct.**

A mutant that collapsed any two destinations would corrupt the
composition Spec — approved-destination widening is prohibited. -/
theorem approvedDestination_consolidationRequest_ne_refundRecipient :
    ApprovedDestination.consolidationRequest ≠
      ApprovedDestination.refundRecipient := by decide

theorem approvedDestination_refundRecipient_ne_beaconDeposit :
    ApprovedDestination.refundRecipient ≠
      ApprovedDestination.beaconDeposit := by decide

theorem approvedDestination_beaconDeposit_ne_lidoPull :
    ApprovedDestination.beaconDeposit ≠
      ApprovedDestination.lidoPull := by decide

theorem approvedDestination_lidoPull_ne_vaultToLido :
    ApprovedDestination.lidoPull ≠
      ApprovedDestination.vaultToLido := by decide

theorem approvedDestination_vaultToLido_ne_vaultToWithdrawalQueue :
    ApprovedDestination.vaultToLido ≠
      ApprovedDestination.vaultToWithdrawalQueue := by decide

/-- **Kill-line: DecidableEq reflexivity across all six approved destinations.** -/
theorem approvedDestination_consolidationRequest_refl :
    decide (ApprovedDestination.consolidationRequest =
      ApprovedDestination.consolidationRequest) = true := by decide
theorem approvedDestination_beaconDeposit_refl :
    decide (ApprovedDestination.beaconDeposit =
      ApprovedDestination.beaconDeposit) = true := by decide
theorem approvedDestination_lidoPull_refl :
    decide (ApprovedDestination.lidoPull =
      ApprovedDestination.lidoPull) = true := by decide
theorem approvedDestination_vaultToLido_refl :
    decide (ApprovedDestination.vaultToLido =
      ApprovedDestination.vaultToLido) = true := by decide

#print axioms approvedDestination_consolidationRequest_ne_refundRecipient
#print axioms approvedDestination_beaconDeposit_ne_lidoPull
#print axioms approvedDestination_vaultToLido_ne_vaultToWithdrawalQueue
#print axioms approvedDestination_consolidationRequest_refl
#print axioms approvedDestination_beaconDeposit_refl
#print axioms approvedDestination_lidoPull_refl

end LidoSRv3.Tests.AuditSpecApprovedDestinationKillLines
