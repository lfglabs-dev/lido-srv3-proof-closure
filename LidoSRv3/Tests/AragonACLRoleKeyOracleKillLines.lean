import LidoSRv3.Audit.Source.AragonACLRoleKeyViaOracleSource

/-! # Kill-lines for `AragonACLRoleKeyViaOracleSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Aragon ACL role-key derivation via shared KeccakOracle.** -/

namespace LidoSRv3.Tests.AragonACLRoleKeyOracleKillLines

open LidoSRv3.Audit.Source.AragonACLRoleKeyViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

private def testOracle : KeccakOracle :=
  { hash := fun n => n + 100
    determinism := fun _ _ h => by rw [h] }

/-- **Kill-line: roleNameToNat on empty is 0.** -/
theorem roleNameToNat_empty :
    roleNameToNat "" = 0 := by
  unfold roleNameToNat
  decide

/-- **Kill-line: roleNameToNat distinguishes distinct chars.** -/
theorem roleNameToNat_distinguishes_a_b :
    roleNameToNat "a" ≠ roleNameToNat "b" := by
  unfold roleNameToNat
  decide

/-- **Kill-line: realRoleKey is composition of oracle and roleNameToNat.** -/
theorem realRoleKey_composition
    (oracle : KeccakOracle) (roleName : String) :
    realRoleKey oracle roleName = concreteRoleKey oracle (roleNameToNat roleName) :=
  rfl

/-- **Kill-line: realRoleKey is deterministic.** -/
theorem realRoleKey_deterministic_at_witness :
    realRoleKey testOracle "ADMIN" = realRoleKey testOracle "ADMIN" :=
  realRoleKey_deterministic rfl

#print axioms roleNameToNat_empty
#print axioms roleNameToNat_distinguishes_a_b
#print axioms realRoleKey_composition
#print axioms realRoleKey_deterministic_at_witness

end LidoSRv3.Tests.AragonACLRoleKeyOracleKillLines
