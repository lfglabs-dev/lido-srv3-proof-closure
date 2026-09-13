import LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource

/-! # Kill-lines for `ACLRoleMappingViaOracleSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the oracle-backed ACL role mapping derivation.** -/

namespace LidoSRv3.Tests.ACLRoleMappingViaOracleKillLines

open LidoSRv3.Audit.Source.ACLRoleMappingViaOracleSource
open LidoSRv3.Audit.Source.AragonACLSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-- **Kill-line: hasRoleFromOracle is functionally `hasRoleFromMapping`
composed with `realMappingStorage`.**

Definitionally, this is `rfl`; a mutant that swapped the composition
would produce different bytes / a different call. -/
theorem hasRoleFromOracle_composition
    (oracle : KeccakOracle) (aclBaseSlot : Nat) (roleName : String) :
    hasRoleFromOracle oracle aclBaseSlot roleName =
      hasRoleFromMapping (realMappingStorage oracle aclBaseSlot) roleName := rfl

/-- **Kill-line: hasRoleFromOracle at trivial witness.**

Concrete decidable witness demonstrating the oracle composition
computes. -/
theorem hasRoleFromOracle_trivial_witness :
    hasRoleFromOracle
      { hash := fun n => n + 1, determinism := fun _ _ h => by rw [h] }
      0
      "SOME_ROLE" =
      hasRoleFromMapping
        (realMappingStorage
          { hash := fun n => n + 1, determinism := fun _ _ h => by rw [h] } 0)
        "SOME_ROLE" := rfl

#print axioms hasRoleFromOracle_composition
#print axioms hasRoleFromOracle_trivial_witness

end LidoSRv3.Tests.ACLRoleMappingViaOracleKillLines
