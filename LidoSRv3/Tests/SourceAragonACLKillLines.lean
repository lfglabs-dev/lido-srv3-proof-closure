import LidoSRv3.Audit.Source.AragonACLSource

/-!
Kill-lines pinning `Source.AragonACLSource` — the Aragon ACL role
lookup surface used by P-RESERVE-1's authorizedRouter and P-TOPUP-1's
callerIsTopUpGateway.
-/

namespace LidoSRv3.Tests.SourceAragonACLKillLines

open LidoSRv3.Audit.Source.AragonACLSource

private def none_granted : ACLState :=
  { stakingRouterRole := false, topUpGatewayApp := false }

private def router_granted : ACLState :=
  { stakingRouterRole := true, topUpGatewayApp := false }

private def gateway_granted : ACLState :=
  { stakingRouterRole := false, topUpGatewayApp := true }

private def both_granted : ACLState :=
  { stakingRouterRole := true, topUpGatewayApp := true }

/-! ## `ACLState.hasRole` truth-table over the two named roles. -/

theorem hasRole_STAKING_ROUTER_ROLE_granted :
    router_granted.hasRole "STAKING_ROUTER_ROLE" = true := rfl

theorem hasRole_STAKING_ROUTER_ROLE_denied :
    none_granted.hasRole "STAKING_ROUTER_ROLE" = false := rfl

theorem hasRole_TOP_UP_GATEWAY_APP_granted :
    gateway_granted.hasRole "TOP_UP_GATEWAY_APP" = true := rfl

theorem hasRole_TOP_UP_GATEWAY_APP_denied :
    none_granted.hasRole "TOP_UP_GATEWAY_APP" = false := rfl

/-- Any role name outside the two named ones is false by the model. -/
theorem hasRole_unknown_role_false :
    both_granted.hasRole "OTHER_ROLE" = false := rfl

/-! ## `hasPermission` is `hasRole` (Aragon delegation identity). -/

theorem hasPermission_matches_hasRole (state : ACLState) (role : String) :
    hasPermission state role = state.hasRole role := rfl

/-! ## `isAuthorizedRouter` reduces to `stakingRouterRole`. -/

theorem isAuthorizedRouter_reduces (state : ACLState) :
    isAuthorizedRouter state = state.stakingRouterRole := rfl

/-! ## `isTopUpGatewayCaller` reduces to `topUpGatewayApp`. -/

theorem isTopUpGatewayCaller_reduces (state : ACLState) :
    isTopUpGatewayCaller state = state.topUpGatewayApp := rfl

/-! ## Kill-line restatement of the role-granted witnesses. -/

theorem isAuthorizedRouter_true_of_role_granted_restated
    {state : ACLState}
    (hRole : state.hasRole "STAKING_ROUTER_ROLE" = true) :
    isAuthorizedRouter state = true :=
  isAuthorizedRouter_true_of_role_granted hRole

theorem isTopUpGatewayCaller_true_of_app_registered_restated
    {state : ACLState}
    (hApp : state.hasRole "TOP_UP_GATEWAY_APP" = true) :
    isTopUpGatewayCaller state = true :=
  isTopUpGatewayCaller_true_of_app_registered hApp

/-! ## `roleKeyEncoding` is the opaque length encoding. -/

theorem roleKeyEncoding_staking :
    roleKeyEncoding "STAKING_ROUTER_ROLE" = 19 := rfl

theorem roleKeyEncoding_gateway :
    roleKeyEncoding "TOP_UP_GATEWAY_APP" = 18 := rfl

end LidoSRv3.Tests.SourceAragonACLKillLines
