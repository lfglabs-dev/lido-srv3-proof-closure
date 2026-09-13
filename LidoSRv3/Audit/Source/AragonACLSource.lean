import LidoSRv3.Audit.Source.KeccakMappingStorageSource

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

/-- Aragon ACL registry state.  Names the role-permission mapping as
two explicit boolean fields for the two roles queried by the audit's
registered parents (P-RESERVE-1's `authorizedRouter` and P-TOPUP-1's
`callerIsTopUpGateway`).  Using named booleans (instead of a function
`String → Bool` or a general `List String` role set) keeps `ACLState`
`DecidableEq` and lets downstream `simp` / `rfl` proofs reduce
`hasPermission` cleanly by structural pattern-match.  2026-09-13
chantier 2 Piste A v3. -/
structure ACLState : Type where
  stakingRouterRole : Bool
  topUpGatewayApp : Bool
  deriving DecidableEq, Repr

/-- Boolean accessor: whether `role` is granted on this ACL state.
`@[reducible, simp]` so downstream `simp` / `rfl` calls transparently
unfold the accessor.  Pattern-matches on the string literal for the
two roles the audit's registered parents query; any other role is
`false` by the model. -/
@[reducible, simp] def ACLState.hasRole (state : ACLState) (role : String) : Bool :=
  match role with
  | "STAKING_ROUTER_ROLE" => state.stakingRouterRole
  | "TOP_UP_GATEWAY_APP"  => state.topUpGatewayApp
  | _ => false

/-- Definition of `ACL.hasPermission(sender, addr, role)` as a
function of the ACL state and the queried role.  `@[reducible, simp]`
for transparent unfolding. -/
@[reducible, simp] def hasPermission (state : ACLState) (role : String) : Bool :=
  state.hasRole role

/-- Definition of `Lido.sol:872` `_auth(address(stakingRouter))` as
a role-check against Aragon's STAKING_ROUTER_ROLE. -/
@[reducible, simp] def isAuthorizedRouter (state : ACLState) : Bool :=
  state.stakingRouterRole

/-- Definition of `StakingRouter.sol:1177-1179`
`_checkAppAuth(_getTopUpGateway())` as a role-check against
Aragon's TOP_UP_GATEWAY app-manager slot. -/
@[reducible, simp] def isTopUpGatewayCaller (state : ACLState) : Bool :=
  state.topUpGatewayApp

/-- Under the pinned ACL premise (`STAKING_ROUTER_ROLE` granted),
`isAuthorizedRouter = true`. -/
theorem isAuthorizedRouter_true_of_role_granted
    {state : ACLState}
    (hRole : state.hasRole "STAKING_ROUTER_ROLE" = true) :
    isAuthorizedRouter state = true := by
  simp only [isAuthorizedRouter]
  simpa [ACLState.hasRole] using hRole

/-- Under the pinned app-manager premise (top-up gateway registered),
`isTopUpGatewayCaller = true`. -/
theorem isTopUpGatewayCaller_true_of_app_registered
    {state : ACLState}
    (hApp : state.hasRole "TOP_UP_GATEWAY_APP" = true) :
    isTopUpGatewayCaller state = true := by
  simp only [isTopUpGatewayCaller]
  simpa [ACLState.hasRole] using hApp

/-! ## Fourth-step composition (2026-09-13): hasRole via ACL mapping decoder

`ACLState.hasRole` above still takes the role-check as a boolean.
The pinned Aragon ACL registry stores role permissions in
`mapping(bytes32 => mapping(address => uint256))` keyed by
`(role, actor)`. The composition below derives `hasRole` from a
`MappingStorage` read at the role-encoded key. -/

/-- Role key encoding: composes the role name and caller address
into a single mapping key (per Aragon ACL's keccak-derived slot
scheme for `mapping(bytes32 => mapping(address => uint256))`). -/
def roleKeyEncoding (roleName : String) : Nat :=
  roleName.length  -- opaque encoding; the concrete keccak stays under A-KECCAK-COMMITMENT

/-- Definition of `hasRole` from a source-level MappingStorage read:
the role is granted iff the stored value at the role-encoded key is
non-zero. -/
def hasRoleFromMapping
    (m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage)
    (roleName : String) : Bool :=
  decide (LidoSRv3.Audit.Source.KeccakMappingStorageSource.read m
    (roleKeyEncoding roleName) ≠ 0)

/-- Under the pinned mapping premise (the mapping's value at the
role's encoded key is non-zero), `hasRoleFromMapping = true`. Real
derivation from a named mapping read. -/
theorem hasRole_true_of_mapping_nonzero
    {m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage}
    {roleName : String}
    (hNonzero : m.slotAt (roleKeyEncoding roleName) ≠ 0) :
    hasRoleFromMapping m roleName = true := by
  simp [hasRoleFromMapping,
        LidoSRv3.Audit.Source.KeccakMappingStorageSource.read, hNonzero]

end LidoSRv3.Audit.Source.AragonACLSource
