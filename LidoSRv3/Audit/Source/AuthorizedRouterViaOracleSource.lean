import LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource

/-! # P-RESERVE-1 authorizedRouter via KeccakOracle real derivation

**General rule (Thomas 2026-09-13, real derivation of the
P-RESERVE-1 `authorizedRouter` free boolean via the shared ACL-
mapping oracle chain — closing item (c) of the general-rule
follow-up in audit/STATUS.md.)**

`P-RESERVE-1`'s registered parent uses `inputs.authorizedRouter` as
a free `Bool`. Item (c) of the general-rule follow-up disclosed
that this should be derived via `Aragon-ACL
hasPermission(msg.sender, address(this), STAKING_ROUTER_ROLE)`,
reached from `Lido.sol:872`.

This composition names the pinned `STAKING_ROUTER_ROLE` string
constant and derives the caller-role check via the shared oracle-
backed `hasRoleFromOracle`. Downstream P-RESERVE-1 consumers can
now replace their free `authorizedRouter` with
`isAuthorizedRouterFromOracle` on a live ACL storage.

**Status:** first oracle-backed derivation of the P-RESERVE-1
`authorizedRouter` past its `AuthorizedRouterFromACL` naming
scaffold. -/

namespace LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource

/-- Pinned Aragon ACL role string for the STAKING_ROUTER_ROLE. -/
def stakingRouterRoleName : String := "STAKING_ROUTER_ROLE"

/-- Real derivation of the pinned
`Lido.sol:872` `hasPermission(msg.sender, address(this),
STAKING_ROUTER_ROLE)` check via the shared oracle. -/
def isAuthorizedRouterFromOracle
    (oracle : KeccakOracle) (aclBaseSlot : Nat) : Bool :=
  hasRoleFromOracle oracle aclBaseSlot stakingRouterRoleName

/-- Under the pinned nonzero role-slot premise, the oracle-backed
authorized-router check passes. Real derivation. -/
theorem isAuthorizedRouterFromOracle_true_of_nonzero
    {oracle : KeccakOracle}
    {aclBaseSlot : Nat}
    (hNonzero : (LidoSRv3.Audit.Source.MappingSlotViaOracleSource.realMappingStorage
                    oracle aclBaseSlot).slotAt
                    (LidoSRv3.Audit.Source.AragonACLSource.roleKeyEncoding
                       stakingRouterRoleName) ≠ 0) :
    isAuthorizedRouterFromOracle oracle aclBaseSlot = true := by
  unfold isAuthorizedRouterFromOracle
  exact hasRoleFromOracle_true_of_nonzero hNonzero

end LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource
