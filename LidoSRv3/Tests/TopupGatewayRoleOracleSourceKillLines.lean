import LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource

namespace LidoSRv3.Tests.TopupGatewayRoleOracleSourceKillLines

open LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-- Pin `topUpGatewayRoleName`: the pinned Aragon ACL role string for
`TOP_UP_GATEWAY_APP`. -/
theorem topUpGatewayRoleName_pinned :
    topUpGatewayRoleName = "TOP_UP_GATEWAY_APP" := rfl

/-- Pin `isTopUpGatewayFromOracle` reduction: real derivation via the
shared ACL-mapping oracle chain closes P-TOPUP-1 item (c) of the
general-rule follow-up. -/
theorem isTopUpGatewayFromOracle_reduces (oracle : KeccakOracle) (aclBaseSlot : Nat) :
    isTopUpGatewayFromOracle oracle aclBaseSlot =
      LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource.hasRoleFromOracle
        oracle aclBaseSlot topUpGatewayRoleName := rfl

/-- Pin `isTopUpGatewayFromOracle_true_of_nonzero`: under a nonzero
role-slot premise on the pinned mapping storage, the oracle-backed
top-up-gateway check passes. -/
theorem isTopUpGatewayFromOracle_true_of_nonzero_restated
    {oracle : KeccakOracle}
    {aclBaseSlot : Nat}
    (hNonzero : (LidoSRv3.Audit.Source.MappingSlotViaOracleSource.realMappingStorage
                    oracle aclBaseSlot).slotAt
                    (LidoSRv3.Audit.Source.AragonACLSource.roleKeyEncoding
                       topUpGatewayRoleName) ≠ 0) :
    isTopUpGatewayFromOracle oracle aclBaseSlot = true :=
  isTopUpGatewayFromOracle_true_of_nonzero hNonzero

end LidoSRv3.Tests.TopupGatewayRoleOracleSourceKillLines
