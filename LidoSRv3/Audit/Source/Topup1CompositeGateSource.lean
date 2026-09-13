import LidoSRv3.Audit.Source.SRModuleMappingViaOracleSource
import LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource
import LidoSRv3.Audit.Source.WCType2ByteDecodeSource

/-! # P-TOPUP-1 composite entry-gate source model

**General rule (Thomas 2026-09-13): compose the three chantier-2/
P-TOPUP-1 pinned entry-gate source models (top-up-gateway ACL role
+ SR module exists + WC type-2) into a single named composite
gate.**

The registered P-TOPUP-1 parent's three free booleans
(`isTopUpGatewayCall`, `moduleExists`, `wcIsType2`) can now be
derived by this composite gate under a live-storage + oracle
premise.

**Status:** first real composition of the three P-TOPUP-1 general-
rule (a)/(b)/(c) source models into a single named entry-gate
function. -/

namespace LidoSRv3.Audit.Source.Topup1CompositeGateSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource
open LidoSRv3.Audit.Source.SRModuleMappingViaOracleSource
open LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource
open LidoSRv3.Audit.Source.WCType2ByteDecodeSource

/-- Composite P-TOPUP-1 entry gate: caller has TOP_UP_GATEWAY_APP
role, module exists in SR registry, WC-type is 2. -/
def entryGatePasses
    (oracle : KeccakOracle)
    (aclBaseSlot moduleRegistryBaseSlot moduleId wcWord : Nat) : Bool :=
  isTopUpGatewayFromOracle oracle aclBaseSlot
    && moduleExistsFromOracle oracle moduleRegistryBaseSlot moduleId
    && wcIsType2 wcWord

/-- Under all three pinned premises, the composite entry gate passes. -/
theorem entryGatePasses_true_of_all_premises
    {oracle : KeccakOracle}
    {aclBaseSlot moduleRegistryBaseSlot moduleId wcWord : Nat}
    (hRole : isTopUpGatewayFromOracle oracle aclBaseSlot = true)
    (hModule : moduleExistsFromOracle oracle moduleRegistryBaseSlot moduleId
                = true)
    (hWc : wcIsType2 wcWord = true) :
    entryGatePasses oracle aclBaseSlot moduleRegistryBaseSlot moduleId
      wcWord = true := by
  simp [entryGatePasses, hRole, hModule, hWc]

end LidoSRv3.Audit.Source.Topup1CompositeGateSource
