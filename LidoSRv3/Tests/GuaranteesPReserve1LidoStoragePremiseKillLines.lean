import LidoSRv3.Audit.Guarantees.PReserve1LidoStoragePremise

/-!
Kill-lines pinning `Guarantees.PReserve1LidoStoragePremise`
straight-line and real-derivation compositions for the two
`WithdrawInputs` booleans (`canDeposit`, `authorizedRouter`).
-/

namespace LidoSRv3.Tests.GuaranteesPReserve1LidoStoragePremiseKillLines

open LidoSRv3.Audit.Guarantees.PReserve1LidoStoragePremise
open LidoSRv3.Audit.SolidityReserve

/-! ## Straight-line scaffold theorems restated. -/

theorem canDeposit_derived_under_pinned_lido_shape_restated
    {inputs : WithdrawInputs}
    (hPinned : PinnedLidoReserveCallShape inputs) :
    inputs.canDeposit = true :=
  canDeposit_derived_under_pinned_lido_shape hPinned

theorem authorizedRouter_derived_under_pinned_lido_shape_restated
    {inputs : WithdrawInputs}
    (hPinned : PinnedLidoReserveCallShape inputs) :
    inputs.authorizedRouter = true :=
  authorizedRouter_derived_under_pinned_lido_shape hPinned

/-! ## Real-derivation composition via `LidoStakingState`. -/

theorem canDeposit_derived_from_lido_state_restated
    {inputs : WithdrawInputs}
    {state : LidoSRv3.Audit.Source.LidoStakingStateStorage.LidoStakingState}
    (hLink : CanDepositFromLidoState inputs state)
    (hStakingNotPaused : state.isStakingPaused = false)
    (hBunkerNotActive : state.isBunkerActive = false) :
    inputs.canDeposit = true :=
  canDeposit_derived_from_lido_state hLink hStakingNotPaused hBunkerNotActive

/-! ## Real-derivation composition via Aragon `ACLState`. -/

theorem authorizedRouter_derived_from_acl_restated
    {inputs : WithdrawInputs}
    {acl : LidoSRv3.Audit.Source.AragonACLSource.ACLState}
    (hLink : AuthorizedRouterFromACL inputs acl)
    (hRole : acl.hasRole "STAKING_ROUTER_ROLE" = true) :
    inputs.authorizedRouter = true :=
  authorizedRouter_derived_from_acl hLink hRole

/-! ## Premise-shape passthroughs. -/

theorem pinnedLidoReserveCallShape_canDeposit
    {inputs : WithdrawInputs} (hPinned : PinnedLidoReserveCallShape inputs) :
    inputs.canDeposit = true := hPinned.canDepositBecausePinned

theorem pinnedLidoReserveCallShape_authorizedRouter
    {inputs : WithdrawInputs} (hPinned : PinnedLidoReserveCallShape inputs) :
    inputs.authorizedRouter = true := hPinned.authorizedRouterBecausePinned

theorem canDepositFromLidoState_match
    {inputs : WithdrawInputs}
    {state : LidoSRv3.Audit.Source.LidoStakingStateStorage.LidoStakingState}
    (hLink : CanDepositFromLidoState inputs state) :
    inputs.canDeposit =
      LidoSRv3.Audit.Source.LidoStakingStateStorage.canDepositFromStorage state :=
  hLink.canDepositMatchesSource

theorem authorizedRouterFromACL_match
    {inputs : WithdrawInputs}
    {acl : LidoSRv3.Audit.Source.AragonACLSource.ACLState}
    (hLink : AuthorizedRouterFromACL inputs acl) :
    inputs.authorizedRouter =
      LidoSRv3.Audit.Source.AragonACLSource.isAuthorizedRouter acl :=
  hLink.authorizedRouterMatchesACL

end LidoSRv3.Tests.GuaranteesPReserve1LidoStoragePremiseKillLines
