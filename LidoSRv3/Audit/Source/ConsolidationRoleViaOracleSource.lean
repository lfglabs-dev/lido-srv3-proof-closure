import LidoSRv3.Audit.Source.ConsolidationRoleGuardSource
import LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource

/-! # ConsolidationGateway ADD_CONSOLIDATION_REQUESTS_ROLE via KeccakOracle

**General rule (Thomas 2026-09-13, chain the P-CONSOLIDATION-ETH-1
role guard through the shared oracle-backed hasRoleFromOracle.)**

`ConsolidationRoleGuardSource.hasAddConsolidationRequestsRole`
consumes an `AragonACLSource.ACLState` (naming scaffold). This
composition swaps in `ACLRoleMappingViaOracleSource.hasRoleFromOracle`,
which reads through `realMappingStorage` — the ACL role slot is
now a function of `(oracle, aclBaseSlot, "ADD_CONSOLIDATION_REQUESTS_ROLE")`.

**Status:** first oracle-backed derivation of the P-CONSOLIDATION-
ETH-1 role check past its `ACLState.hasRole` naming scaffold. -/

namespace LidoSRv3.Audit.Source.ConsolidationRoleViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource

/-- Real derivation of the ADD_CONSOLIDATION_REQUESTS_ROLE check via
the shared oracle. -/
def hasAddConsolidationRequestsRoleFromOracle
    (oracle : KeccakOracle) (aclBaseSlot : Nat) : Bool :=
  hasRoleFromOracle oracle aclBaseSlot "ADD_CONSOLIDATION_REQUESTS_ROLE"

/-- Under the pinned nonzero role-slot premise, the oracle-backed
role check passes. -/
theorem hasAddConsolidationRequestsRoleFromOracle_true_of_nonzero
    {oracle : KeccakOracle}
    {aclBaseSlot : Nat}
    (hNonzero : (LidoSRv3.Audit.Source.MappingSlotViaOracleSource.realMappingStorage
                    oracle aclBaseSlot).slotAt
                    (LidoSRv3.Audit.Source.AragonACLSource.roleKeyEncoding
                       "ADD_CONSOLIDATION_REQUESTS_ROLE") ≠ 0) :
    hasAddConsolidationRequestsRoleFromOracle oracle aclBaseSlot = true := by
  unfold hasAddConsolidationRequestsRoleFromOracle
  exact hasRoleFromOracle_true_of_nonzero hNonzero

end LidoSRv3.Audit.Source.ConsolidationRoleViaOracleSource
