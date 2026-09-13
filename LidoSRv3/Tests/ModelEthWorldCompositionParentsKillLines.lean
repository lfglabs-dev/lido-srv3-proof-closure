import LidoSRv3.Audit.Model.EthWorld

/-!
Kill-lines pinning `Model.EthWorld.ValueRoute.compositionParents` and
Spec-coverage theorems (`spec_destination_surjective`,
`withdrawal_predeploy_outside_spec`, `intermediate_hops_outside_spec`,
`terminal_destinations_in_spec`).
-/

namespace LidoSRv3.Tests.ModelEthWorldCompositionParentsKillLines

open LidoSRv3.Audit.Model.EthWorld
open LidoSRv3.Audit.Spec

/-! ## `compositionParents` — one witness per route. -/

theorem composition_deposit_lido_pull :
    ValueRoute.compositionParents .depositLidoPull =
      [CoveringParent.pEthJournalOne] := rfl

theorem composition_topup_beacon_deposit :
    ValueRoute.compositionParents .topupBeaconDeposit =
      [CoveringParent.pEthJournalOne] := rfl

theorem composition_consolidation_refund :
    ValueRoute.compositionParents .consolidationRefund =
      [CoveringParent.pEthJournalOne] := rfl

theorem composition_vault_consolidation_call :
    ValueRoute.compositionParents .vaultConsolidationCall =
      [CoveringParent.pEthJournalOne, CoveringParent.pConsolidationOne] := rfl

theorem composition_bus_to_gateway_empty :
    ValueRoute.compositionParents .busToGateway = [] := rfl

theorem composition_gateway_to_vault_empty :
    ValueRoute.compositionParents .gatewayToVault = [] := rfl

theorem composition_vault_withdrawal_call_empty :
    ValueRoute.compositionParents .vaultWithdrawalCall = [] := rfl

theorem composition_vault_to_lido_empty :
    ValueRoute.compositionParents .vaultToLido = [] := rfl

theorem composition_vault_to_withdrawal_queue_empty :
    ValueRoute.compositionParents .vaultToWithdrawalQueue = [] := rfl

/-! ## Spec surjectivity, restated. -/

theorem spec_destination_surjective_restated (d : ApprovedDestination) :
    ∃ r : ValueRoute, r.destination.toSpec = some d :=
  spec_destination_surjective d

/-! ## Non-Spec destinations. -/

theorem withdrawal_predeploy_outside_spec_restated :
    Destination.toSpec .withdrawalPredeploy = none :=
  withdrawal_predeploy_outside_spec

theorem intermediate_hops_outside_spec_restated :
    Destination.toSpec .consolidationGateway = none ∧
      Destination.toSpec .withdrawalVault = none :=
  intermediate_hops_outside_spec

/-! ## Terminal destinations project into Spec. -/

theorem terminal_destinations_in_spec_restated (d : Destination)
    (h1 : d ≠ .withdrawalPredeploy)
    (h2 : d ≠ .consolidationGateway)
    (h3 : d ≠ .withdrawalVault) :
    (Destination.toSpec d).isSome = true :=
  terminal_destinations_in_spec d h1 h2 h3

end LidoSRv3.Tests.ModelEthWorldCompositionParentsKillLines
