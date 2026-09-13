import LidoSRv3.Audit.Source.AragonACLRoleKeyViaOracleSource
import LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource

/-! # Aragon ACL permission-mapping key via shared KeccakOracle

**General rule (Thomas 2026-09-13, real derivation of the Aragon
ACL permission-mapping-key layout past
`AragonACLSource.hasRoleFromMapping`'s single-mapping simplification.)**

The pinned Aragon ACL stores permissions in
`mapping(bytes32 role => mapping(address actor => uint256))
permissions`. The value slot is derived at
`keccak256(abi.encode(actor, keccak256(abi.encode(role, slot))))`.

`AragonACLSource.hasRoleFromMapping` used a single-mapping simplification
(one MappingStorage keyed by role only). This composition names the
real (role, actor) nested-mapping-key derivation via
`realNestedSlotDerivation` and the shared `KeccakOracle`.

**Status:** first real derivation of the Aragon ACL permission
mapping's nested-key rule. -/

namespace LidoSRv3.Audit.Source.ACLPermissionKeyViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.AragonACLRoleKeyViaOracleSource
open LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource

/-- Real derivation of the Aragon ACL permission mapping's slot at
`(roleName, actorAddress)` for a given `permissionsBaseSlot`. The
`roleName` string is first hashed via the shared oracle (per
`realRoleKey`), then the nested-mapping-slot rule folds the actor
address in. -/
def realPermissionSlot
    (oracle : KeccakOracle)
    (permissionsBaseSlot : Nat) (roleName : String) (actor : Nat) : Nat :=
  realNestedSlotDerivation oracle permissionsBaseSlot
    (realRoleKey oracle roleName) actor

/-- Determinism of `realPermissionSlot` on identical inputs. Real
derivation from the shared oracle's determinism law. -/
theorem realPermissionSlot_deterministic
    {oracle : KeccakOracle} {b1 b2 : Nat} {r1 r2 : String} {a1 a2 : Nat}
    (hBase : b1 = b2) (hRole : r1 = r2) (hActor : a1 = a2) :
    realPermissionSlot oracle b1 r1 a1 = realPermissionSlot oracle b2 r2 a2 := by
  subst hBase
  subst hRole
  subst hActor
  rfl

end LidoSRv3.Audit.Source.ACLPermissionKeyViaOracleSource
