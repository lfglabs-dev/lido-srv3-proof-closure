import LidoSRv3.Audit.Source.AragonACLRoleKeyViaOracleSource
import LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource
import LidoSRv3.Audit.Source.ACLPermissionKeyViaOracleSource

/-!
Kill-lines pinning the shared A-KECCAK-COMMITMENT-derived
`realRoleKey`, `realNestedSlotDerivation`, and `realPermissionSlot`
identities used by P-RESERVE-1 / P-TOPUP-1 role checks.
-/

namespace LidoSRv3.Tests.SourceNestedMappingPermissionKeysKillLines

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.AragonACLRoleKeyViaOracleSource
open LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource
open LidoSRv3.Audit.Source.ACLPermissionKeyViaOracleSource

/-! ## `roleNameToNat` — length + sum of ASCII codepoints. -/

theorem roleNameToNat_empty : roleNameToNat "" = 0 := rfl

theorem roleNameToNat_positive : 0 < roleNameToNat "A" := by decide

/-! ## `realRoleKey` reduces to oracle.hash of roleNameToNat. -/

theorem realRoleKey_reduces (oracle : KeccakOracle) (roleName : String) :
    realRoleKey oracle roleName =
      concreteRoleKey oracle (roleNameToNat roleName) := rfl

/-! ## `realRoleKey` determinism — restated. -/

theorem realRoleKey_deterministic_restated
    {oracle : KeccakOracle} {r1 r2 : String} (hEq : r1 = r2) :
    realRoleKey oracle r1 = realRoleKey oracle r2 :=
  realRoleKey_deterministic hEq

/-! ## `realNestedSlotDerivation` — two chained mapping-slot derivations. -/

theorem realNestedSlotDerivation_reduces
    (oracle : KeccakOracle) (baseSlot k1 k2 : Nat) :
    realNestedSlotDerivation oracle baseSlot k1 k2 =
      concreteMappingSlot oracle
        (encodeMappingKey k2 (realSlotDerivation oracle baseSlot k1)) := rfl

/-! ## `realNestedSlotDerivation` determinism — restated. -/

theorem realNestedSlotDerivation_deterministic_restated
    {oracle : KeccakOracle} {b1 b2 x1 y1 x2 y2 : Nat}
    (hBase : b1 = b2) (hOuter : x1 = x2) (hInner : y1 = y2) :
    realNestedSlotDerivation oracle b1 x1 y1
      = realNestedSlotDerivation oracle b2 x2 y2 :=
  realNestedSlotDerivation_deterministic hBase hOuter hInner

/-! ## `realPermissionSlot` — Aragon ACL nested key derivation. -/

theorem realPermissionSlot_reduces
    (oracle : KeccakOracle) (permissionsBaseSlot : Nat)
    (roleName : String) (actor : Nat) :
    realPermissionSlot oracle permissionsBaseSlot roleName actor =
      realNestedSlotDerivation oracle permissionsBaseSlot
        (realRoleKey oracle roleName) actor := rfl

/-! ## `realPermissionSlot` determinism — restated. -/

theorem realPermissionSlot_deterministic_restated
    {oracle : KeccakOracle} {b1 b2 : Nat} {r1 r2 : String} {a1 a2 : Nat}
    (hBase : b1 = b2) (hRole : r1 = r2) (hActor : a1 = a2) :
    realPermissionSlot oracle b1 r1 a1 = realPermissionSlot oracle b2 r2 a2 :=
  realPermissionSlot_deterministic hBase hRole hActor

end LidoSRv3.Tests.SourceNestedMappingPermissionKeysKillLines
