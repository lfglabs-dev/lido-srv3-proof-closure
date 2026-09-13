import LidoSRv3.Audit.Source.Topup1CompositeGateSource

/-!
Kill-lines pinning `Source.Topup1CompositeGateSource` composite
entry-gate three-conjunct decomposition (top-up-gateway ACL + SR
module exists + WC-type is 2) and load-bearing negation witnesses.
-/

namespace LidoSRv3.Tests.SourceTopup1CompositeGateKillLines

open LidoSRv3.Audit.Source.Topup1CompositeGateSource
open LidoSRv3.Audit.Source.SRModuleMappingViaOracleSource
open LidoSRv3.Audit.Source.TopupGatewayRoleViaOracleSource
open LidoSRv3.Audit.Source.WCType2ByteDecodeSource

/-! ## `entryGatePasses` — three-conjunct composition definition. -/

theorem entryGatePasses_restated
    (oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle)
    (aclBaseSlot moduleRegistryBaseSlot moduleId wcWord : Nat) :
    entryGatePasses oracle aclBaseSlot moduleRegistryBaseSlot moduleId
        wcWord =
      (isTopUpGatewayFromOracle oracle aclBaseSlot &&
        moduleExistsFromOracle oracle moduleRegistryBaseSlot moduleId &&
        wcIsType2 wcWord) := rfl

/-! ## All-premises-true witness — kill-line restatement. -/

theorem entryGatePasses_true_of_all_premises_restated
    {oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle}
    {aclBaseSlot moduleRegistryBaseSlot moduleId wcWord : Nat}
    (hRole : isTopUpGatewayFromOracle oracle aclBaseSlot = true)
    (hModule : moduleExistsFromOracle oracle moduleRegistryBaseSlot moduleId
                = true)
    (hWc : wcIsType2 wcWord = true) :
    entryGatePasses oracle aclBaseSlot moduleRegistryBaseSlot moduleId
      wcWord = true :=
  entryGatePasses_true_of_all_premises hRole hModule hWc

/-! ## Load-bearing negation witnesses: each conjunct is required. -/

theorem entryGatePasses_false_if_role_false
    {oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle}
    {aclBaseSlot moduleRegistryBaseSlot moduleId wcWord : Nat}
    (hRoleFalse : isTopUpGatewayFromOracle oracle aclBaseSlot = false) :
    entryGatePasses oracle aclBaseSlot moduleRegistryBaseSlot moduleId
      wcWord = false := by
  simp [entryGatePasses, hRoleFalse]

theorem entryGatePasses_false_if_module_absent
    {oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle}
    {aclBaseSlot moduleRegistryBaseSlot moduleId wcWord : Nat}
    (hModuleFalse : moduleExistsFromOracle oracle moduleRegistryBaseSlot
                      moduleId = false) :
    entryGatePasses oracle aclBaseSlot moduleRegistryBaseSlot moduleId
      wcWord = false := by
  simp [entryGatePasses, hModuleFalse]

theorem entryGatePasses_false_if_wc_not_type2
    {oracle : LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource.KeccakOracle}
    {aclBaseSlot moduleRegistryBaseSlot moduleId wcWord : Nat}
    (hWcFalse : wcIsType2 wcWord = false) :
    entryGatePasses oracle aclBaseSlot moduleRegistryBaseSlot moduleId
      wcWord = false := by
  simp [entryGatePasses, hWcFalse]

end LidoSRv3.Tests.SourceTopup1CompositeGateKillLines
