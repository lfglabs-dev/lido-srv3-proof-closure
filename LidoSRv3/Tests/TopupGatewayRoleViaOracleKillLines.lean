import LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource

/-! # Kill-lines for `TopupGatewayRoleViaOracleSource`

**Chantier 1 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned top-up-gateway ACL oracle name and derivation.** -/

namespace LidoSRv3.Tests.TopupGatewayRoleViaOracleKillLines

open LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource

/-- **Kill-line: the pinned role name is exactly "TOP_UP_GATEWAY_APP".** -/
theorem topUpGatewayRoleName_pinned :
    topUpGatewayRoleName = "TOP_UP_GATEWAY_APP" := rfl

/-- **Kill-line: `isTopUpGatewayFromOracle` uses the pinned role name in
its call to `hasRoleFromOracle`.**

Definitionally, `isTopUpGatewayFromOracle oracle aclBaseSlot =
hasRoleFromOracle oracle aclBaseSlot "TOP_UP_GATEWAY_APP"`.  A mutant
that swapped the role name would produce a different value. -/
theorem isTopUpGatewayFromOracle_uses_pinned_role
    (oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle)
    (aclBaseSlot : Nat) :
    isTopUpGatewayFromOracle oracle aclBaseSlot =
      LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource.hasRoleFromOracle
        oracle aclBaseSlot "TOP_UP_GATEWAY_APP" := rfl

/-- **Kill-line: role name does NOT equal common alternatives.** -/
theorem topUpGatewayRoleName_distinct :
    topUpGatewayRoleName ≠ "STAKING_ROUTER_ROLE" ∧
    topUpGatewayRoleName ≠ "TOP_UP_ORCHESTRATOR" ∧
    topUpGatewayRoleName ≠ "" := by
  refine ⟨?_, ?_, ?_⟩ <;> decide

#print axioms topUpGatewayRoleName_pinned
#print axioms isTopUpGatewayFromOracle_uses_pinned_role
#print axioms topUpGatewayRoleName_distinct

end LidoSRv3.Tests.TopupGatewayRoleViaOracleKillLines
