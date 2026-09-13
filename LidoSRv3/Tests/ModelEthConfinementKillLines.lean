import LidoSRv3.Audit.Model.EthConfinement

/-!
Kill-lines pinning `Model.EthConfinement` residual list, coverage
agreement, and per-route confinement predicate.
-/

namespace LidoSRv3.Tests.ModelEthConfinementKillLines

open LidoSRv3.Audit.Model.EthWorld
open LidoSRv3.Audit.Model.EthConfinement

/-! ## Residual list contents (three uncovered hops) -/

theorem residualRoutes_length : residualRoutes.length = 3 := rfl

theorem residualRoutes_contains_busToGateway :
    ValueRoute.busToGateway ∈ residualRoutes := by
  decide

theorem residualRoutes_contains_gatewayToVault :
    ValueRoute.gatewayToVault ∈ residualRoutes := by
  decide

theorem residualRoutes_contains_vaultWithdrawalCall :
    ValueRoute.vaultWithdrawalCall ∈ residualRoutes := by
  decide

/-- Covered routes are absent from the residual list. -/
theorem residualRoutes_omits_depositLidoPull :
    ValueRoute.depositLidoPull ∉ residualRoutes := by
  decide

theorem residualRoutes_omits_vaultToLido :
    ValueRoute.vaultToLido ∉ residualRoutes := by
  decide

/-! ## Conclusion conjuncts — kernel-checked lemmas restated
    verbatim as kill-lines. -/

theorem coverage_agrees_with_spec_approval :
    CoverageAgreesWithSpecApproval :=
  coverageAgreesWithSpecApproval

theorem residual_is_exactly_uncovered :
    ResidualIsExactlyTheUncoveredInventory :=
  residualIsExactlyTheUncoveredInventory

theorem residual_hops_are_unclassified :
    ResidualHopsAreUnclassified :=
  residualHopsAreUnclassified

/-! ## Per-route confinement witnesses -/

theorem depositLidoPull_confined :
    RouteConfined ValueRoute.depositLidoPull :=
  route_confined _

theorem topupBeaconDeposit_confined :
    RouteConfined ValueRoute.topupBeaconDeposit :=
  route_confined _

theorem vaultToLido_confined :
    RouteConfined ValueRoute.vaultToLido :=
  route_confined _

theorem busToGateway_confined :
    RouteConfined ValueRoute.busToGateway :=
  route_confined _

end LidoSRv3.Tests.ModelEthConfinementKillLines
