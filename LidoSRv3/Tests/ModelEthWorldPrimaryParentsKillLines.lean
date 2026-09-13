import LidoSRv3.Audit.Model.EthWorld

/-! # Kill-lines for `Model.EthWorld.ValueRoute.primaryParent`

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Piste-A value-route coverage in the E1 inventory (topupLidoPull
and topupBeaconDeposit are covered by P-TOPUP-1). -/

namespace LidoSRv3.Tests.ModelEthWorldPrimaryParentsKillLines

open LidoSRv3.Audit.Model.EthWorld

/-- **Kill-line: `topupLidoPull` is primarily covered by P-TOPUP-1.**

A mutant that swapped the covering parent (e.g. to P-DEPOSIT-1)
would collapse the two chantiers. -/
theorem topupLidoPull_primary :
    ValueRoute.primaryParent .topupLidoPull =
      some .pTopupOne := rfl

/-- **Kill-line: `topupBeaconDeposit` is primarily covered by P-TOPUP-1.** -/
theorem topupBeaconDeposit_primary :
    ValueRoute.primaryParent .topupBeaconDeposit =
      some .pTopupOne := rfl

/-- **Kill-line: `vaultToLido` covered by P-VAULT-ETH-1.**

Reserve/vault route lives at the P-VAULT-ETH-1 parent; a mutant
that dropped it would leave the reserve-refund route uncovered. -/
theorem vaultToLido_primary :
    ValueRoute.primaryParent .vaultToLido =
      some .pVaultEthOne := rfl

/-- **Kill-line: `vaultToWithdrawalQueue` covered by P-VAULT-ETH-1.** -/
theorem vaultToWithdrawalQueue_primary :
    ValueRoute.primaryParent .vaultToWithdrawalQueue =
      some .pVaultEthOne := rfl

/-- **Kill-line: unsupported route `busToGateway` has no primary parent.** -/
theorem busToGateway_no_primary :
    ValueRoute.primaryParent .busToGateway = none := rfl

/-- **Kill-line: unsupported route `gatewayToVault` has no primary parent.** -/
theorem gatewayToVault_no_primary :
    ValueRoute.primaryParent .gatewayToVault = none := rfl

/-- **Kill-line: unsupported route `vaultWithdrawalCall` has no primary parent.** -/
theorem vaultWithdrawalCall_no_primary :
    ValueRoute.primaryParent .vaultWithdrawalCall = none := rfl

/-- **Kill-line: `topupLidoPull` composition contains P-ETH-JOURNAL-1.** -/
theorem topupLidoPull_composition :
    ValueRoute.compositionParents .topupLidoPull =
      [.pEthJournalOne] := rfl

/-- **Kill-line: `topupBeaconDeposit` composition contains P-ETH-JOURNAL-1.** -/
theorem topupBeaconDeposit_composition :
    ValueRoute.compositionParents .topupBeaconDeposit =
      [.pEthJournalOne] := rfl

#print axioms topupLidoPull_primary
#print axioms topupBeaconDeposit_primary
#print axioms vaultToLido_primary
#print axioms busToGateway_no_primary
#print axioms topupLidoPull_composition

end LidoSRv3.Tests.ModelEthWorldPrimaryParentsKillLines
