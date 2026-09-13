import LidoSRv3.Audit.Source.MappingSlotViaOracleSource
import LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource

/-!
Kill-lines pinning `MappingSlotViaOracleSource` (real Solidity
mapping-slot derivation) and `ACLRoleMappingViaOracleSource` (Aragon
ACL specialisation).
-/

namespace LidoSRv3.Tests.SourceMappingSlotViaOracleKillLines

open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.AragonACLSource

/-! ## `encodeMappingKey` — abi.encode(k, baseSlot) source model. -/

theorem encodeMappingKey_zero_zero :
    encodeMappingKey 0 0 = 0 := rfl

theorem encodeMappingKey_key_zero (k : Nat) :
    encodeMappingKey k 0 = k * (2 ^ 256) := by
  simp [encodeMappingKey]

theorem encodeMappingKey_zero_base (baseSlot : Nat) :
    encodeMappingKey 0 baseSlot = baseSlot := by
  simp [encodeMappingKey]

theorem encodeMappingKey_key_one_base_ten :
    encodeMappingKey 1 10 = 2 ^ 256 + 10 := by
  simp [encodeMappingKey]

/-! ## `realSlotDerivation` reduces to oracle hash of `encodeMappingKey`. -/

theorem realSlotDerivation_reduces
    (oracle : KeccakOracle) (baseSlot key : Nat) :
    realSlotDerivation oracle baseSlot key =
      concreteMappingSlot oracle (encodeMappingKey key baseSlot) := rfl

/-! ## `realMappingStorage.slotAt` — definitional identity. -/

theorem realMappingStorage_slotAt_reduces
    (oracle : KeccakOracle) (baseSlot key : Nat) :
    (realMappingStorage oracle baseSlot).slotAt key =
      concreteMappingSlot oracle (encodeMappingKey key baseSlot) :=
  realMappingStorage_slotAt_eq oracle baseSlot key

/-! ## Determinism restated. -/

theorem realSlotDerivation_deterministic_restated
    {oracle : KeccakOracle} {b1 b2 k1 k2 : Nat}
    (hBase : b1 = b2) (hKey : k1 = k2) :
    realSlotDerivation oracle b1 k1 = realSlotDerivation oracle b2 k2 :=
  realSlotDerivation_deterministic hBase hKey

/-! ## `hasRoleFromOracle` reduces to `hasRoleFromMapping` composed with
    `realMappingStorage`. -/

theorem hasRoleFromOracle_reduces
    (oracle : KeccakOracle) (aclBaseSlot : Nat) (roleName : String) :
    hasRoleFromOracle oracle aclBaseSlot roleName =
      hasRoleFromMapping (realMappingStorage oracle aclBaseSlot) roleName :=
  rfl

/-! ## `hasRoleFromOracle_true_of_nonzero` restated. -/

theorem hasRoleFromOracle_true_of_nonzero_restated
    {oracle : KeccakOracle} {aclBaseSlot : Nat} {roleName : String}
    (hNonzero : (realMappingStorage oracle aclBaseSlot).slotAt
                    (roleKeyEncoding roleName) ≠ 0) :
    hasRoleFromOracle oracle aclBaseSlot roleName = true :=
  hasRoleFromOracle_true_of_nonzero hNonzero

end LidoSRv3.Tests.SourceMappingSlotViaOracleKillLines
