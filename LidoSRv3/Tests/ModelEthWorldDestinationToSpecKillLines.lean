import LidoSRv3.Audit.Model.EthWorld

/-! # Kill-lines for `Model.EthWorld.Destination.toSpec`

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Piste-A Destination→ApprovedDestination projection table and
route→destination mapping. -/

namespace LidoSRv3.Tests.ModelEthWorldDestinationToSpecKillLines

open LidoSRv3.Audit.Model.EthWorld
open LidoSRv3.Audit.Spec

/-- **Kill-line: `topupLidoPull` targets the Lido pull destination.**

A mutant that swapped the destination for a Piste-A route would
break the P-TOPUP-1 confinement narrative. -/
theorem topupLidoPull_destination :
    ValueRoute.destination .topupLidoPull = .lidoPull := rfl

/-- **Kill-line: `topupBeaconDeposit` targets the beacon deposit contract.** -/
theorem topupBeaconDeposit_destination :
    ValueRoute.destination .topupBeaconDeposit = .beaconDeposit := rfl

/-- **Kill-line: `vaultToLido` destination.** -/
theorem vaultToLido_destination :
    ValueRoute.destination .vaultToLido = .vaultToLido := rfl

/-- **Kill-line: `vaultToWithdrawalQueue` destination.** -/
theorem vaultToWithdrawalQueue_destination :
    ValueRoute.destination .vaultToWithdrawalQueue = .vaultToWithdrawalQueue := rfl

/-- **Kill-line: `Destination.lidoPull` → `Spec.ApprovedDestination.lidoPull`.** -/
theorem lidoPull_toSpec :
    (Destination.lidoPull).toSpec = some .lidoPull := rfl

/-- **Kill-line: `Destination.beaconDeposit` → `Spec.ApprovedDestination.beaconDeposit`.** -/
theorem beaconDeposit_toSpec :
    (Destination.beaconDeposit).toSpec = some .beaconDeposit := rfl

/-- **Kill-line: `Destination.withdrawalPredeploy` toSpec is none.**

The withdrawal-request predeploy (EIP-7002) has no constructor in
`Spec.ApprovedDestination`; a mutant that added one would refute. -/
theorem withdrawalPredeploy_toSpec :
    (Destination.withdrawalPredeploy).toSpec = none := rfl

/-- **Kill-line: `Destination.consolidationGateway` toSpec is none.**

Intermediate Bus→Gateway hop has no destination in Spec. -/
theorem consolidationGateway_toSpec :
    (Destination.consolidationGateway).toSpec = none := rfl

/-- **Kill-line: `Destination.withdrawalVault` toSpec is none.**

Intermediate Gateway→Vault hop has no destination in Spec. -/
theorem withdrawalVault_toSpec :
    (Destination.withdrawalVault).toSpec = none := rfl

/-- **Kill-line: `Destination.vaultToLido` and `Destination.vaultToWithdrawalQueue`
have Spec constructors.** -/
theorem vaultToLido_toSpec :
    (Destination.vaultToLido).toSpec = some .vaultToLido := rfl
theorem vaultToWithdrawalQueue_toSpec :
    (Destination.vaultToWithdrawalQueue).toSpec = some .vaultToWithdrawalQueue := rfl

#print axioms topupLidoPull_destination
#print axioms topupBeaconDeposit_destination
#print axioms lidoPull_toSpec
#print axioms beaconDeposit_toSpec
#print axioms withdrawalPredeploy_toSpec
#print axioms vaultToLido_toSpec

end LidoSRv3.Tests.ModelEthWorldDestinationToSpecKillLines
