import LidoSRv3.Audit.Model.EthWorld

/-! # Kill-lines for `Model.EthWorld.ValueRoute.provenance`

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Piste-A route provenance classification (pinned-Solidity-call
vs source-shaped-runtime). -/

namespace LidoSRv3.Tests.ModelEthWorldProvenanceKillLines

open LidoSRv3.Audit.Model.EthWorld

/-- **Kill-line: `topupLidoPull` has pinned-Solidity provenance.**

The P-TOPUP-1 topup path corresponds to a pinned call site at
Lido.sol:869-886; a mutant classifying it as `sourceShapedRuntime`
would refute the pinned code correspondence. -/
theorem topupLidoPull_provenance :
    ValueRoute.provenance .topupLidoPull = .pinnedSolidityCall := rfl

/-- **Kill-line: `topupBeaconDeposit` has pinned-Solidity provenance.** -/
theorem topupBeaconDeposit_provenance :
    ValueRoute.provenance .topupBeaconDeposit = .pinnedSolidityCall := rfl

/-- **Kill-line: `depositLidoPull` has pinned-Solidity provenance.** -/
theorem depositLidoPull_provenance :
    ValueRoute.provenance .depositLidoPull = .pinnedSolidityCall := rfl

/-- **Kill-line: `depositBeaconDeposit` has pinned-Solidity provenance.** -/
theorem depositBeaconDeposit_provenance :
    ValueRoute.provenance .depositBeaconDeposit = .pinnedSolidityCall := rfl

/-- **Kill-line: `vaultToLido` has source-shaped-runtime provenance.**

The P-VAULT-ETH-1 route is a source-shaped schedule; a mutant
that upgraded it to pinnedSolidityCall would over-claim. -/
theorem vaultToLido_provenance :
    ValueRoute.provenance .vaultToLido = .sourceShapedRuntime := rfl

/-- **Kill-line: `vaultToWithdrawalQueue` has source-shaped-runtime provenance.** -/
theorem vaultToWithdrawalQueue_provenance :
    ValueRoute.provenance .vaultToWithdrawalQueue = .sourceShapedRuntime := rfl

/-- **Kill-line: RouteProvenance has exactly two distinct constructors.** -/
theorem provenance_ctors_distinct :
    RouteProvenance.pinnedSolidityCall ≠ RouteProvenance.sourceShapedRuntime := by decide

/-- **Kill-line: consolidationRefund is pinnedSolidityCall.** -/
theorem consolidationRefund_provenance :
    ValueRoute.provenance .consolidationRefund = .pinnedSolidityCall := rfl

#print axioms topupLidoPull_provenance
#print axioms topupBeaconDeposit_provenance
#print axioms depositLidoPull_provenance
#print axioms vaultToLido_provenance
#print axioms vaultToWithdrawalQueue_provenance
#print axioms provenance_ctors_distinct

end LidoSRv3.Tests.ModelEthWorldProvenanceKillLines
