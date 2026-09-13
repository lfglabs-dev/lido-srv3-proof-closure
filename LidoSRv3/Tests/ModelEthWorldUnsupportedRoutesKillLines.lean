import LidoSRv3.Audit.Model.EthWorld

/-!
Kill-lines pinning `Model.EthWorld` `UnsupportedRoute` enum
distinctness and `AuthorizedValueFrame.isPositive` decidable
witness.
-/

namespace LidoSRv3.Tests.ModelEthWorldUnsupportedRoutesKillLines

open LidoSRv3.Audit.Model.EthWorld

/-! ## `UnsupportedRoute` seven-arm enum: pairwise distinctness. -/

theorem unsupported_owner_ne_stVault :
    UnsupportedRoute.ownerWithdrawal ≠ UnsupportedRoute.stVaultInternal := by
  decide

theorem unsupported_stVault_ne_valueBounded :
    UnsupportedRoute.stVaultInternal ≠ UnsupportedRoute.valueBoundedExit := by
  decide

theorem unsupported_valueBounded_ne_governance :
    UnsupportedRoute.valueBoundedExit ≠ UnsupportedRoute.governanceLifecycle := by
  decide

theorem unsupported_governance_ne_fallback :
    UnsupportedRoute.governanceLifecycle ≠ UnsupportedRoute.fallbackReceive := by
  decide

theorem unsupported_fallback_ne_treasury :
    UnsupportedRoute.fallbackReceive ≠ UnsupportedRoute.treasuryMint := by
  decide

theorem unsupported_treasury_ne_ops :
    UnsupportedRoute.treasuryMint ≠ UnsupportedRoute.opsTransfer := by
  decide

/-! ## `AuthorizedValueFrame.isPositive` — zero rejects, positive accepts. -/

theorem isPositive_zero :
    ¬ AuthorizedValueFrame.isPositive
        { route := .depositLidoPull, value := 0 } := by
  decide

theorem isPositive_one :
    AuthorizedValueFrame.isPositive
        { route := .depositLidoPull, value := 1 } := by
  decide

/-! ## `AuthorizedValueFrame` field extraction. -/

theorem authorizedFrame_route :
    ({ route := .topupBeaconDeposit, value := 100 }
       : AuthorizedValueFrame).route = .topupBeaconDeposit := rfl

theorem authorizedFrame_value :
    ({ route := .topupBeaconDeposit, value := 100 }
       : AuthorizedValueFrame).value = 100 := rfl

/-! ## `inventory_count` + `unsupported_count` restated. -/

theorem inventory_count_restated : allRoutes.length = 11 := rfl

theorem unsupported_count_restated : allUnsupportedRoutes.length = 7 := rfl

end LidoSRv3.Tests.ModelEthWorldUnsupportedRoutesKillLines
