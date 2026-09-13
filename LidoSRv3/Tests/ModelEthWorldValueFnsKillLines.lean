import LidoSRv3.Audit.Model.EthWorld

/-!
Kill-lines pinning `Model.EthWorld` value functions:
`inventoryValue`, `totalValue`, `zeroUnmodeled_preserves_value`, and
the mutant zero-routing helpers `zeroParentRoutes`,
`zeroCompositionParentRoutes`.
-/

namespace LidoSRv3.Tests.ModelEthWorldValueFnsKillLines

open LidoSRv3.Audit.Model.EthWorld

private def frame_vaultToLido : AuthorizedValueFrame :=
  ⟨ValueRoute.vaultToLido, 42⟩

private def frame_deposit : AuthorizedValueFrame :=
  ⟨ValueRoute.depositBeaconDeposit, 7⟩

private def owner_flow : GeneralFlow :=
  GeneralFlow.ownerWithdrawal 9 100

/-! ## `totalValue` on the four constructors. -/

theorem totalValue_empty : totalValue [] = 0 := rfl

theorem totalValue_ownerWithdrawal :
    totalValue [owner_flow] = 100 := rfl

theorem totalValue_treasuryMint :
    totalValue [GeneralFlow.treasuryMint 25] = 25 := rfl

theorem totalValue_opsTransfer :
    totalValue [GeneralFlow.opsTransfer 30] = 30 := rfl

theorem totalValue_authorized :
    totalValue [GeneralFlow.authorized frame_deposit] = 7 := rfl

theorem totalValue_composition :
    totalValue
      [GeneralFlow.authorized frame_deposit,
       GeneralFlow.treasuryMint 3] = 10 := rfl

/-! ## `inventoryValue` filters unmodeled flows before summing. -/

theorem inventoryValue_empty :
    inventoryValue [] = 0 := rfl

theorem inventoryValue_owner_only :
    inventoryValue [owner_flow] = 0 := rfl

theorem inventoryValue_authorized :
    inventoryValue [GeneralFlow.authorized frame_deposit] = 7 := rfl

/-! ## `zeroUnmodeled_preserves_value` — kill-line restatement. -/

theorem zeroUnmodeled_preserves_value_restated (flows : List GeneralFlow) :
    inventoryValue (flows.map zeroUnmodeled) = inventoryValue flows :=
  zeroUnmodeled_preserves_value flows

/-! ## `zeroParentRoutes` — one witness per constructor. -/

theorem zeroParentRoutes_owner :
    zeroParentRoutes CoveringParent.pTopupOne owner_flow = owner_flow := rfl

theorem zeroParentRoutes_treasury :
    zeroParentRoutes CoveringParent.pTopupOne (GeneralFlow.treasuryMint 5) =
      GeneralFlow.treasuryMint 5 := rfl

theorem zeroParentRoutes_ops :
    zeroParentRoutes CoveringParent.pTopupOne (GeneralFlow.opsTransfer 5) =
      GeneralFlow.opsTransfer 5 := rfl

/-! ## `zeroCompositionParentRoutes` — leaves non-authorized alone. -/

theorem zeroCompositionParentRoutes_owner :
    zeroCompositionParentRoutes CoveringParent.pTopupOne owner_flow =
      owner_flow := rfl

theorem zeroCompositionParentRoutes_treasury :
    zeroCompositionParentRoutes CoveringParent.pTopupOne
      (GeneralFlow.treasuryMint 5) = GeneralFlow.treasuryMint 5 := rfl

end LidoSRv3.Tests.ModelEthWorldValueFnsKillLines
