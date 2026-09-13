import LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-!
Kill-lines pinning `KeccakConcreteCommitmentSource` shared oracle
surface — the three concrete-derivation shapes (role key, mapping
slot, ABI selector) plus determinism propagation.
-/

namespace LidoSRv3.Tests.SourceKeccakConcreteCommitmentKillLines

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-! ## `concreteRoleKey` = oracle.hash. -/

theorem concreteRoleKey_reduces (oracle : KeccakOracle) (encoding : Nat) :
    concreteRoleKey oracle encoding = oracle.hash encoding := rfl

/-! ## `concreteMappingSlot` = oracle.hash. -/

theorem concreteMappingSlot_reduces (oracle : KeccakOracle) (encoding : Nat) :
    concreteMappingSlot oracle encoding = oracle.hash encoding := rfl

/-! ## `concreteAbiSelector` = oracle.hash mod 2^32 (bytes4 truncation). -/

theorem concreteAbiSelector_reduces (oracle : KeccakOracle) (encoding : Nat) :
    concreteAbiSelector oracle encoding = oracle.hash encoding % (2 ^ 32) := rfl

/-! ## Determinism propagation restated. -/

theorem concreteRoleKey_deterministic_restated
    {oracle : KeccakOracle} {x y : Nat} (h : x = y) :
    concreteRoleKey oracle x = concreteRoleKey oracle y :=
  concreteRoleKey_deterministic h

theorem concreteMappingSlot_deterministic_restated
    {oracle : KeccakOracle} {x y : Nat} (h : x = y) :
    concreteMappingSlot oracle x = concreteMappingSlot oracle y :=
  concreteMappingSlot_deterministic h

theorem concreteAbiSelector_deterministic_restated
    {oracle : KeccakOracle} {x y : Nat} (h : x = y) :
    concreteAbiSelector oracle x = concreteAbiSelector oracle y :=
  concreteAbiSelector_deterministic h

/-! ## ABI selector fits in 32 bits (bytes4 space) — bound on every
    oracle. -/

theorem concreteAbiSelector_lt_pow32
    (oracle : KeccakOracle) (encoding : Nat) :
    concreteAbiSelector oracle encoding < 2 ^ 32 := by
  simp [concreteAbiSelector]
  exact Nat.mod_lt _ (by decide)

/-! ## The oracle's own determinism law is preserved. -/

theorem oracle_determinism_restated
    (oracle : KeccakOracle) (x y : Nat) (h : x = y) :
    oracle.hash x = oracle.hash y :=
  oracle.determinism x y h

end LidoSRv3.Tests.SourceKeccakConcreteCommitmentKillLines
