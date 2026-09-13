import LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource

/-! # P-TOPUP-1 top-up-gateway ACL registry via shared KeccakOracle

**General rule (Thomas 2026-09-13, real derivation of the
P-TOPUP-1 `isTopUpGatewayCall` free boolean via the shared ACL-
mapping oracle chain — closing item (c) of the general-rule
follow-up in audit/STATUS.md.)**

`P-TOPUP-1`'s registered parent uses an `isTopUpGatewayCall`
boolean on the SR caller context. Item (c) of the general-rule
follow-up disclosed that this should be derived via an Aragon-ACL
top-up-gateway registry read.

This composition names the pinned `TOP_UP_GATEWAY_APP` string
constant and derives the caller-role check via the shared oracle-
backed `hasRoleFromOracle`. Downstream P-TOPUP-1 consumers can now
replace the free `isTopUpGatewayCall` with
`isTopUpGatewayFromOracle` on a live ACL storage.

**Status:** first oracle-backed derivation of the P-TOPUP-1 top-up-
gateway check past its `isTopUpGatewayCaller` naming scaffold. -/

namespace LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource

/-- Pinned Aragon ACL role string for the TOP_UP_GATEWAY_APP. -/
def topUpGatewayRoleName : String := "TOP_UP_GATEWAY_APP"

/-- Real derivation of the pinned top-up-gateway caller check via
the shared oracle. -/
def isTopUpGatewayFromOracle
    (oracle : KeccakOracle) (aclBaseSlot : Nat) : Bool :=
  hasRoleFromOracle oracle aclBaseSlot topUpGatewayRoleName

/-- Under the pinned nonzero role-slot premise, the oracle-backed
top-up-gateway check passes. Real derivation. -/
theorem isTopUpGatewayFromOracle_true_of_nonzero
    {oracle : KeccakOracle}
    {aclBaseSlot : Nat}
    (hNonzero : (LidoSRv3.Audit.Source.MappingSlotViaOracleSource.realMappingStorage
                    oracle aclBaseSlot).slotAt
                    (LidoSRv3.Audit.Source.AragonACLSource.roleKeyEncoding
                       topUpGatewayRoleName) ≠ 0) :
    isTopUpGatewayFromOracle oracle aclBaseSlot = true := by
  unfold isTopUpGatewayFromOracle
  exact hasRoleFromOracle_true_of_nonzero hNonzero

end LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource
