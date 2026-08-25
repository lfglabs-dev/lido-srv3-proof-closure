import LidoSRv3.Audit.Model.EthWorld

/-!
# ETH-world inventory mutant tests

Concrete witnesses demonstrating:
1. The owner/treasury/ops mutant is non-trivial: the zeroed list differs,
   total value decreases, but modeled inventory value is preserved.
2. Primary-parent mutants: zeroing routes of each primary covering parent
   reduces inventory value, proving every primary parent is load-bearing.
3. Composition-parent mutants: zeroing routes of each composition parent
   reduces inventory value, including the terminal consolidation-fee leg.
4. Every route is inhabited by a positive-value frame witness.
-/

namespace LidoSRv3.Tests.EthWorldMutants

open LidoSRv3.Audit.Model.EthWorld

/-! ## Witness flow list — all 11 value routes plus unmodeled flows -/

private def witnessFlows : List GeneralFlow :=
  [ .authorized ⟨.depositLidoPull, 32⟩
  , .authorized ⟨.depositBeaconDeposit, 32⟩
  , .authorized ⟨.topupLidoPull, 1⟩
  , .authorized ⟨.topupBeaconDeposit, 1⟩
  , .authorized ⟨.consolidationRefund, 7⟩
  , .authorized ⟨.busToGateway, 10⟩
  , .authorized ⟨.gatewayToVault, 5⟩
  , .authorized ⟨.vaultConsolidationCall, 5⟩
  , .authorized ⟨.vaultWithdrawalCall, 2⟩
  , .authorized ⟨.vaultToLido, 7⟩
  , .authorized ⟨.vaultToWithdrawalQueue, 4⟩
  , .ownerWithdrawal 42 100
  , .treasuryMint 50
  , .opsTransfer 25 ]

/-! ## Non-vacuity: all 11 authorized frames are present -/

theorem witness_has_authorized_frames :
    (authorizedFrames witnessFlows).length = 11 := by native_decide

/-! ## Owner/treasury/ops mutant: non-trivial yet inventory-preserving -/

theorem witness_mutation_nontrivial :
    witnessFlows.map zeroUnmodeled ≠ witnessFlows := by native_decide

theorem witness_has_unmodeled_value :
    (witnessFlows.filter fun g => match g with
      | .ownerWithdrawal _ v | .treasuryMint v | .opsTransfer v => v > 0
      | _ => false).length = 3 := by native_decide

theorem witness_inventory_value :
    inventoryValue witnessFlows = 106 := by native_decide

theorem witness_mutant_inventory_value :
    inventoryValue (witnessFlows.map zeroUnmodeled) = 106 := by native_decide

theorem witness_total_value :
    totalValue witnessFlows = 281 := by native_decide

theorem witness_mutant_total_value :
    totalValue (witnessFlows.map zeroUnmodeled) = 106 := by native_decide

theorem witness_mutant_reduces_total :
    totalValue (witnessFlows.map zeroUnmodeled) <
    totalValue witnessFlows := by native_decide

/-! ## Primary-parent mutants: each primary covering parent is load-bearing -/

theorem parent_deposit_load_bearing :
    inventoryValue (witnessFlows.map (zeroParentRoutes .pDepositOne)) <
    inventoryValue witnessFlows := by native_decide

theorem parent_topup_load_bearing :
    inventoryValue (witnessFlows.map (zeroParentRoutes .pTopupOne)) <
    inventoryValue witnessFlows := by native_decide

theorem parent_consolidation_eth_load_bearing :
    inventoryValue (witnessFlows.map (zeroParentRoutes .pConsolidationEthOne)) <
    inventoryValue witnessFlows := by native_decide

theorem parent_consolidation_value_load_bearing :
    inventoryValue (witnessFlows.map (zeroParentRoutes .pConsolidationValueOne)) <
    inventoryValue witnessFlows := by native_decide

theorem parent_vault_eth_load_bearing :
    inventoryValue (witnessFlows.map (zeroParentRoutes .pVaultEthOne)) <
    inventoryValue witnessFlows := by native_decide

/-! ## Composition-parent mutants: each composition parent is load-bearing -/

theorem composition_eth_journal_load_bearing :
    inventoryValue (witnessFlows.map (zeroCompositionParentRoutes .pEthJournalOne)) <
    inventoryValue witnessFlows := by native_decide

theorem composition_consolidation_load_bearing :
    inventoryValue (witnessFlows.map (zeroCompositionParentRoutes .pConsolidationOne)) <
    inventoryValue witnessFlows := by native_decide

/-- The terminal fee route has both advertised composition parents. -/
theorem vault_consolidation_composition_parents :
    ValueRoute.vaultConsolidationCall.compositionParents =
      [.pEthJournalOne, .pConsolidationOne] := rfl

/-- A fee-only witness ensures the ETH-journal composition mutant exercises
the terminal consolidation fee, not only its refund leg. -/
theorem composition_eth_journal_fee_leg_load_bearing :
    inventoryValue
      ([.authorized ⟨.vaultConsolidationCall, 5⟩].map
        (zeroCompositionParentRoutes .pEthJournalOne)) <
    inventoryValue [.authorized ⟨.vaultConsolidationCall, 5⟩] := by native_decide

/-! ## Uncovered routes -/

theorem vaultWithdrawalCall_uncovered :
    ValueRoute.vaultWithdrawalCall.primaryParent = none := rfl

theorem busToGateway_uncovered :
    ValueRoute.busToGateway.primaryParent = none := rfl

theorem gatewayToVault_uncovered :
    ValueRoute.gatewayToVault.primaryParent = none := rfl

/-! ## Provenance and unsupported-route inventory -/

theorem vault_routes_are_source_shaped_runtime :
    ValueRoute.vaultToLido.provenance = .sourceShapedRuntime ∧
    ValueRoute.vaultToWithdrawalQueue.provenance = .sourceShapedRuntime := by
  exact ⟨rfl, rfl⟩

theorem ops_transfer_is_explicitly_unsupported :
    allUnsupportedRoutes.contains .opsTransfer = true := by native_decide

theorem covered_routes_have_primary_parent :
    ∀ r : ValueRoute,
      r ≠ .busToGateway → r ≠ .gatewayToVault → r ≠ .vaultWithdrawalCall →
      (r.primaryParent).isSome = true := by
  intro r h1 h2 h3; cases r <;> simp_all [ValueRoute.primaryParent]

/-! ## Route coverage: every route is inhabited by a positive-value frame -/

private def routeWitness : ValueRoute → AuthorizedValueFrame
  | .depositLidoPull        => ⟨.depositLidoPull, 32⟩
  | .depositBeaconDeposit   => ⟨.depositBeaconDeposit, 32⟩
  | .topupLidoPull          => ⟨.topupLidoPull, 1⟩
  | .topupBeaconDeposit     => ⟨.topupBeaconDeposit, 1⟩
  | .consolidationRefund    => ⟨.consolidationRefund, 7⟩
  | .busToGateway           => ⟨.busToGateway, 10⟩
  | .gatewayToVault         => ⟨.gatewayToVault, 5⟩
  | .vaultConsolidationCall => ⟨.vaultConsolidationCall, 1⟩
  | .vaultWithdrawalCall    => ⟨.vaultWithdrawalCall, 1⟩
  | .vaultToLido            => ⟨.vaultToLido, 10⟩
  | .vaultToWithdrawalQueue => ⟨.vaultToWithdrawalQueue, 5⟩

theorem every_route_positive :
    ∀ r : ValueRoute, (routeWitness r).isPositive := by
  intro r; cases r <;> decide

theorem every_route_witness_matches :
    ∀ r : ValueRoute, (routeWitness r).route = r := by
  intro r; cases r <;> rfl

/-! ## Destination classification is total -/

theorem every_route_has_destination :
    ∀ r : ValueRoute, ∃ d : Destination, r.destination = d := by
  intro r; exact ⟨r.destination, rfl⟩

end LidoSRv3.Tests.EthWorldMutants
