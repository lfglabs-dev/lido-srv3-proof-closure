import LidoSRv3.Audit.Model.EthWorld

/-! # Kill-lines for `Model.EthWorld.allRoutes` and `allUnsupportedRoutes`

**Chantier (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the E1 ETH-world inventory enumeration counts and membership. -/

namespace LidoSRv3.Tests.ModelEthWorldInventoryCountKillLines

open LidoSRv3.Audit.Model.EthWorld

/-- **Kill-line: exactly 11 modeled value routes.**

A mutant that added or dropped a route would refute the pinned
inventory size. -/
theorem allRoutes_count : allRoutes.length = 11 := rfl

/-- **Kill-line: exactly 7 unsupported routes.** -/
theorem allUnsupportedRoutes_count : allUnsupportedRoutes.length = 7 := rfl

/-- **Kill-line: `topupLidoPull` is in the inventory.** -/
theorem topupLidoPull_in_inventory :
    ValueRoute.topupLidoPull ∈ allRoutes := by decide

/-- **Kill-line: `topupBeaconDeposit` is in the inventory.** -/
theorem topupBeaconDeposit_in_inventory :
    ValueRoute.topupBeaconDeposit ∈ allRoutes := by decide

/-- **Kill-line: `vaultToLido` is in the inventory.** -/
theorem vaultToLido_in_inventory :
    ValueRoute.vaultToLido ∈ allRoutes := by decide

/-- **Kill-line: `vaultToWithdrawalQueue` is in the inventory.** -/
theorem vaultToWithdrawalQueue_in_inventory :
    ValueRoute.vaultToWithdrawalQueue ∈ allRoutes := by decide

/-- **Kill-line: unsupported route `ownerWithdrawal` is in the unsupported list.** -/
theorem ownerWithdrawal_unsupported :
    UnsupportedRoute.ownerWithdrawal ∈ allUnsupportedRoutes := by decide

/-- **Kill-line: unsupported route `governanceLifecycle` is in the list.** -/
theorem governanceLifecycle_unsupported :
    UnsupportedRoute.governanceLifecycle ∈ allUnsupportedRoutes := by decide

/-- **Kill-line: `fallbackReceive` is in the unsupported list.** -/
theorem fallbackReceive_unsupported :
    UnsupportedRoute.fallbackReceive ∈ allUnsupportedRoutes := by decide

/-- **Kill-line: `treasuryMint` is in the unsupported list.** -/
theorem treasuryMint_unsupported :
    UnsupportedRoute.treasuryMint ∈ allUnsupportedRoutes := by decide

#print axioms allRoutes_count
#print axioms allUnsupportedRoutes_count
#print axioms topupLidoPull_in_inventory
#print axioms ownerWithdrawal_unsupported
#print axioms treasuryMint_unsupported

end LidoSRv3.Tests.ModelEthWorldInventoryCountKillLines
