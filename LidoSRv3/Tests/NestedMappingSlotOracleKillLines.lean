import LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource

/-! # Kill-lines for `NestedMappingSlotViaOracleSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the Solidity `mapping(K1 => mapping(K2 => V))` nested slot
derivation.** -/

namespace LidoSRv3.Tests.NestedMappingSlotOracleKillLines

open LidoSRv3.Audit.Source.NestedMappingSlotViaOracleSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

private def testOracle : KeccakOracle :=
  { hash := fun n => n + 1
    determinism := fun _ _ h => by rw [h] }

/-- **Kill-line: realNestedSlotDerivation = concreteMappingSlot ∘
encodeMappingKey ∘ realSlotDerivation composition.** -/
theorem realNestedSlotDerivation_composition
    (oracle : KeccakOracle) (baseSlot k1 k2 : Nat) :
    realNestedSlotDerivation oracle baseSlot k1 k2 =
      concreteMappingSlot oracle
        (encodeMappingKey k2 (realSlotDerivation oracle baseSlot k1)) := rfl

/-- **Kill-line: realNestedSlotDerivation is deterministic across
identical inputs.** -/
theorem realNestedSlotDerivation_deterministic_at_witness :
    realNestedSlotDerivation testOracle 10 20 30 =
      realNestedSlotDerivation testOracle 10 20 30 :=
  realNestedSlotDerivation_deterministic rfl rfl rfl

#print axioms realNestedSlotDerivation_composition
#print axioms realNestedSlotDerivation_deterministic_at_witness

end LidoSRv3.Tests.NestedMappingSlotOracleKillLines
