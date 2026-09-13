import LidoSRv3.Audit.Model.EthConfinement

namespace LidoSRv3.Tests.ModelEthConfinementWitnessKillLines

open LidoSRv3.Audit.Model.EthConfinement
open LidoSRv3.Audit.Model.EthWorld

/-- Pin `route_confined`: every `ValueRoute` is either uncovered
(`primaryParent = none`) or lands on a registered covering
parent/destination pair. -/
theorem route_confined_restated (r : ValueRoute) : RouteConfined r :=
  route_confined r

/-- Pin `confined`: the trace-level confinement is universally quantified
over any `List GeneralFlow`. -/
theorem confined_restated (flows : List GeneralFlow) : Confined flows :=
  confined flows

/-- Concrete confinement witness: on a mixed list containing every
`ValueRoute` constructor, `Confined` holds. This exercises
`route_confined` on every case. -/
theorem confined_on_all_constructors :
    Confined
      [ .authorized ⟨.depositLidoPull, 1⟩
      , .authorized ⟨.depositBeaconDeposit, 1⟩
      , .authorized ⟨.topupLidoPull, 1⟩
      , .authorized ⟨.topupBeaconDeposit, 1⟩
      , .authorized ⟨.consolidationRefund, 1⟩
      , .authorized ⟨.busToGateway, 1⟩
      , .authorized ⟨.gatewayToVault, 1⟩
      , .authorized ⟨.vaultConsolidationCall, 1⟩
      , .authorized ⟨.vaultWithdrawalCall, 1⟩
      , .authorized ⟨.vaultToLido, 1⟩
      , .authorized ⟨.vaultToWithdrawalQueue, 1⟩ ] :=
  confined _

end LidoSRv3.Tests.ModelEthConfinementWitnessKillLines
