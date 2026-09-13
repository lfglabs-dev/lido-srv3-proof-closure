import LidoSRv3.Audit.Model.EthConfinement

namespace LidoSRv3.Tests.ModelEthConfinementAgreementsKillLines

open LidoSRv3.Audit.Model.EthConfinement
open LidoSRv3.Audit.Model.EthWorld

/-- Pin `routeAssignmentsMatch`: the three routing tables agree on every
`ValueRoute`. Any drift in `primaryParent`, `destination`, or
`Destination.toSpec` breaks this before it can silently rot the
confinement inventory. -/
theorem routeAssignmentsMatch_restated :
    RouteAssignmentsMatch ValueRoute.primaryParent ValueRoute.destination Destination.toSpec :=
  routeAssignmentsMatch

/-- Pin `coverageAgreesWithSpecApproval`: the covered-vs-approved
inventory tables agree route-by-route. -/
theorem coverageAgreesWithSpecApproval_restated :
    CoverageAgreesWithSpecApproval :=
  coverageAgreesWithSpecApproval

/-- Pin `residualIsExactlyTheUncoveredInventory`: the residual-route list
is exactly the complement of the covered inventory. -/
theorem residualIsExactlyTheUncoveredInventory_restated :
    ResidualIsExactlyTheUncoveredInventory :=
  residualIsExactlyTheUncoveredInventory

/-- Pin `residualHopsAreUnclassified`: every residual hop is unclassified,
never a covered destination. -/
theorem residualHopsAreUnclassified_restated :
    ResidualHopsAreUnclassified :=
  residualHopsAreUnclassified

end LidoSRv3.Tests.ModelEthConfinementAgreementsKillLines
