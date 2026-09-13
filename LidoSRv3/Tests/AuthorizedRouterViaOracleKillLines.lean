import LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource

/-! # Kill-lines for `AuthorizedRouterViaOracleSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned Lido.sol:872 authorized-router check via oracle.** -/

namespace LidoSRv3.Tests.AuthorizedRouterViaOracleKillLines

open LidoSRv3.Audit.Source.AuthorizedRouterViaOracleSource

/-- **Kill-line: pinned role name is exactly "STAKING_ROUTER_ROLE".** -/
theorem stakingRouterRoleName_pinned :
    stakingRouterRoleName = "STAKING_ROUTER_ROLE" := rfl

/-- **Kill-line: role name distinct from alternatives.** -/
theorem stakingRouterRoleName_distinct :
    stakingRouterRoleName ≠ "TOP_UP_GATEWAY_APP" ∧
    stakingRouterRoleName ≠ "ADMIN" ∧
    stakingRouterRoleName ≠ "" := by
  refine ⟨?_, ?_, ?_⟩ <;> decide

/-- **Kill-line: isAuthorizedRouterFromOracle uses the pinned role
name.** -/
theorem isAuthorizedRouterFromOracle_uses_pinned_role
    (oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle)
    (aclBaseSlot : Nat) :
    isAuthorizedRouterFromOracle oracle aclBaseSlot =
      LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource.hasRoleFromOracle
        oracle aclBaseSlot "STAKING_ROUTER_ROLE" := rfl

#print axioms stakingRouterRoleName_pinned
#print axioms stakingRouterRoleName_distinct
#print axioms isAuthorizedRouterFromOracle_uses_pinned_role

end LidoSRv3.Tests.AuthorizedRouterViaOracleKillLines
