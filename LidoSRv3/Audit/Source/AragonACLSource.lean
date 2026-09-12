/-! # Aragon ACL role-check source model (P-RESERVE-1 authorizedRouter, P-TOPUP-1 gateway)

**General rule (Thomas 2026-09-13, second real-derivation step for
P-RESERVE-1 authorizedRouter and P-TOPUP-1 callerIsTopUpGateway).**

Names the Aragon ACL role-check as an audit-source model. Under this
model, the authorizedRouter and gateway booleans become DEFINED
functions of a source-level `ACLState`, not anonymous free `Bool` fields.

Pinned Solidity (17005714):

- `contracts/0.4.24/apps/Aragon.sol` `ACL.hasPermission(who, where, role)`
  — the Aragon ACL registry lookup.
- `contracts/0.4.24/Lido.sol:872` `_auth(address(stakingRouter))` calls
  through Aragon's `_auth` modifier which delegates to
  `ACL.hasPermission(msg.sender, address(this), STAKING_ROUTER_ROLE)`.
- `contracts/0.8.25/sr/StakingRouter.sol:1177-1179` `_checkAppAuth(app)`
  calls `_getKernel().getApp(APP_MANAGER_APP_BASES_NAMESPACE, app)` and
  compares to `msg.sender`. `_getTopUpGateway()` at
  `StakingRouter.sol:1169-1171` returns the top-up gateway address
  from the app manager.

The model deliberately does not model the ACL registry's mapping
storage or the full Aragon app-manager lookup — this scaffold names
the boolean result of `hasPermission` and `_checkAppAuth` as
source-level functions of a named `ACLState`.

**Status:** first-step real derivation. The two boolean fields
(authorizedRouter, callerIsTopUpGateway) are no longer anonymous —
each IS a source-level function of a named `ACLState` querying a
specific role or app-address.

Residual: the `ACLState` role-registry mapping storage remains
input; live keyed-storage derivation of role assignments and
app-manager lookups is the follow-up. -/

namespace LidoSRv3.Audit.Source.AragonACLSource

/-- Aragon ACL registry state. Names the role-permission mapping as
a boolean lookup on (caller, role) tuples. -/
structure ACLState : Type where
  hasRole : String → Bool

/-- Definition of `ACL.hasPermission(sender, addr, role)` as a
function of the ACL state and the queried role. -/
def hasPermission (state : ACLState) (role : String) : Bool :=
  state.hasRole role

/-- Definition of `Lido.sol:872` `_auth(address(stakingRouter))` as
a role-check against Aragon's STAKING_ROUTER_ROLE. -/
def isAuthorizedRouter (state : ACLState) : Bool :=
  hasPermission state "STAKING_ROUTER_ROLE"

/-- Definition of `StakingRouter.sol:1177-1179`
`_checkAppAuth(_getTopUpGateway())` as a role-check against
Aragon's TOP_UP_GATEWAY app-manager slot. -/
def isTopUpGatewayCaller (state : ACLState) : Bool :=
  hasPermission state "TOP_UP_GATEWAY_APP"

/-- Under the pinned ACL premise (`STAKING_ROUTER_ROLE` granted),
`isAuthorizedRouter = true`. -/
theorem isAuthorizedRouter_true_of_role_granted
    {state : ACLState}
    (hRole : state.hasRole "STAKING_ROUTER_ROLE" = true) :
    isAuthorizedRouter state = true := by
  simp [isAuthorizedRouter, hasPermission, hRole]

/-- Under the pinned app-manager premise (top-up gateway registered),
`isTopUpGatewayCaller = true`. -/
theorem isTopUpGatewayCaller_true_of_app_registered
    {state : ACLState}
    (hApp : state.hasRole "TOP_UP_GATEWAY_APP" = true) :
    isTopUpGatewayCaller state = true := by
  simp [isTopUpGatewayCaller, hasPermission, hApp]

end LidoSRv3.Audit.Source.AragonACLSource
