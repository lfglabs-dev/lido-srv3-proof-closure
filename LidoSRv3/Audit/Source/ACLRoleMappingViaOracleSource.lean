import LidoSRv3.Audit.Source.AragonACLSource
import LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! # Aragon ACL role-mapping via realMappingStorage

**General rule (Thomas 2026-09-13, chain
`AragonACLSource.hasRoleFromMapping`'s MappingStorage through the
shared oracle-backed realMappingStorage.)**

`AragonACLSource.hasRoleFromMapping` takes a free `MappingStorage`.
This composition specialises it to a `realMappingStorage oracle
aclBaseSlot` so the role slot is derived through the shared A-KECCAK-
COMMITMENT oracle.

**Status:** derives the ACL role-mapping's MappingStorage from the
shared oracle, tightening `hasRoleFromMapping` past a free
`Nat → Nat`. -/

namespace LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.AragonACLSource

/-- Compose `hasRoleFromMapping` with the shared oracle-backed
mapping storage. Role permission is now a function of
`(oracle, aclBaseSlot, roleName)`. -/
def hasRoleFromOracle
    (oracle : KeccakOracle) (aclBaseSlot : Nat) (roleName : String) : Bool :=
  hasRoleFromMapping (realMappingStorage oracle aclBaseSlot) roleName

/-- Under the pinned mapping premise (the oracle-backed role-slot
value is non-zero), `hasRoleFromOracle = true`. Real derivation. -/
theorem hasRoleFromOracle_true_of_nonzero
    {oracle : KeccakOracle} {aclBaseSlot : Nat} {roleName : String}
    (hNonzero : (realMappingStorage oracle aclBaseSlot).slotAt
                    (roleKeyEncoding roleName) ≠ 0) :
    hasRoleFromOracle oracle aclBaseSlot roleName = true := by
  unfold hasRoleFromOracle
  exact hasRole_true_of_mapping_nonzero hNonzero

end LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource
