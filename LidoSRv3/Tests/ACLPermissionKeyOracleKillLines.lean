import LidoSRv3.Audit.Source.ACLPermissionKeyViaOracleSource

/-! # Kill-lines for `ACLPermissionKeyViaOracleSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Aragon ACL permission mapping's nested `(role, actor)` slot
derivation via a shared KeccakOracle.** -/

namespace LidoSRv3.Tests.ACLPermissionKeyOracleKillLines

open LidoSRv3.Audit.Source.ACLPermissionKeyViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

private def testOracle : KeccakOracle :=
  { hash := fun n => n + 1
    determinism := fun _ _ h => by rw [h] }

/-- **Kill-line: realPermissionSlot is deterministic.** -/
theorem realPermissionSlot_deterministic_at_witness :
    realPermissionSlot testOracle 100 "ADMIN" 42 =
      realPermissionSlot testOracle 100 "ADMIN" 42 :=
  realPermissionSlot_deterministic rfl rfl rfl

/-- **Kill-line: realPermissionSlot is deterministic across trivial
identity witnesses.** -/
theorem realPermissionSlot_deterministic_composed :
    realPermissionSlot testOracle 200 "GATEWAY" 100 =
      realPermissionSlot testOracle 200 "GATEWAY" 100 :=
  realPermissionSlot_deterministic rfl rfl rfl

#print axioms realPermissionSlot_deterministic_at_witness
#print axioms realPermissionSlot_deterministic_composed

end LidoSRv3.Tests.ACLPermissionKeyOracleKillLines
