import LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-! # Kill-lines for `KeccakConcreteCommitmentSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the shared keccak-oracle commitment semantics.** -/

namespace LidoSRv3.Tests.KeccakConcreteCommitmentKillLines

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

private def testOracle : KeccakOracle :=
  { hash := fun n => n + 1
    determinism := fun _ _ h => by rw [h] }

/-- **Kill-line: concreteRoleKey uses oracle.hash.** -/
theorem concreteRoleKey_at_witness :
    concreteRoleKey testOracle 42 = 43 := rfl

/-- **Kill-line: concreteMappingSlot uses oracle.hash.** -/
theorem concreteMappingSlot_at_witness :
    concreteMappingSlot testOracle 10 = 11 := rfl

/-- **Kill-line: concreteAbiSelector applies modulo 2^32 to oracle output.** -/
theorem concreteAbiSelector_at_witness :
    concreteAbiSelector testOracle 100 = 101 := rfl

/-- **Kill-line: determinism theorems apply.** -/
theorem determinism_at_witness :
    concreteRoleKey testOracle 5 = concreteRoleKey testOracle 5 :=
  concreteRoleKey_deterministic rfl

#print axioms concreteRoleKey_at_witness
#print axioms concreteMappingSlot_at_witness
#print axioms concreteAbiSelector_at_witness
#print axioms determinism_at_witness

end LidoSRv3.Tests.KeccakConcreteCommitmentKillLines
