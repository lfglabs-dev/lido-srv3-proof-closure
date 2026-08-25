import LidoSRv3.Audit.Model.EthWorld

/-!
# ETH-world inventory mutant tests

Concrete witnesses demonstrating:
1. The owner/treasury/ops mutant is non-trivial (the zeroed list differs)
   but preserves inventory value (non-load-bearing).
2. Parent-shaped mutants: zeroing routes of each covering parent reduces
   inventory value, proving every parent is load-bearing.
3. Every route is inhabited by a positive-value frame witness.
-/

namespace LidoSRv3.Tests.EthWorldMutants

open LidoSRv3.Audit.Model.EthWorld

/-! ## Witness flow list -/

private def witnessFlows : List GeneralFlow :=
  [ .authorized ⟨.depositBeaconDeposit, 32⟩
  , .authorized ⟨.topupBeaconDeposit, 1⟩
  , .authorized ⟨.consolidationFee, 3⟩
  , .authorized ⟨.busToGateway, 10⟩
  , .authorized ⟨.vaultConsolidationCall, 5⟩
  , .authorized ⟨.vaultWithdrawalCall, 2⟩
  , .authorized ⟨.vaultToLido, 7⟩
  , .ownerWithdrawal 42 100
  , .treasuryMint 50
  , .opsTransfer 25 ]

/-! ## Non-vacuity: authorized frames are present -/

theorem witness_has_authorized_frames :
    (authorizedFrames witnessFlows).length = 7 := by native_decide

/-! ## Owner/treasury/ops mutant: non-trivial yet value-preserving -/

theorem witness_mutation_nontrivial :
    witnessFlows.map zeroUnmodeled ≠ witnessFlows := by native_decide

theorem witness_has_unmodeled_value :
    (witnessFlows.filter fun g => match g with
      | .ownerWithdrawal _ v | .treasuryMint v | .opsTransfer v => v > 0
      | _ => false).length = 3 := by native_decide

theorem witness_inventory_value :
    inventoryValue witnessFlows = 60 := by native_decide

theorem witness_mutant_inventory_value :
    inventoryValue (witnessFlows.map zeroUnmodeled) = 60 := by native_decide

/-! ## Parent-shaped mutants: each covering parent is load-bearing -/

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

/-! ## EIP-7002 withdrawal predeploy is uncovered -/

theorem vaultWithdrawalCall_uncovered :
    ValueRoute.vaultWithdrawalCall.primaryParent = none := rfl

theorem every_covered_route_has_parent :
    ∀ r : ValueRoute, r ≠ .vaultWithdrawalCall →
    (r.primaryParent).isSome = true := by
  intro r h; cases r <;> simp_all [ValueRoute.primaryParent]

/-! ## Route coverage: every route is inhabited by a positive-value frame -/

private def routeWitness : ValueRoute → AuthorizedValueFrame
  | .depositLidoPull        => ⟨.depositLidoPull, 32⟩
  | .depositBeaconDeposit   => ⟨.depositBeaconDeposit, 32⟩
  | .topupLidoPull          => ⟨.topupLidoPull, 1⟩
  | .topupBeaconDeposit     => ⟨.topupBeaconDeposit, 1⟩
  | .consolidationFee       => ⟨.consolidationFee, 3⟩
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
