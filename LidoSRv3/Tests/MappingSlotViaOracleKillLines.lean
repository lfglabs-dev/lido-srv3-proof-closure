import LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! # Kill-lines for `MappingSlotViaOracleSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
the pinned Solidity `mapping(K => V)` slot-derivation rule via a
shared keccak oracle.**

`MappingSlotViaOracleSource` names:
- `encodeMappingKey key baseSlot = key * 2^256 + baseSlot`.
- `realSlotDerivation oracle baseSlot key`.
- `realMappingStorage oracle baseSlot` as a `MappingStorage` whose
  `slotAt` uses the pinned rule.

These kill-lines pin the encoding rule and demonstrate determinism
at witnesses. -/

namespace LidoSRv3.Tests.MappingSlotViaOracleKillLines

open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

private def testOracle : KeccakOracle :=
  { hash := fun n => n + 1
    determinism := fun _ _ h => by rw [h] }

/-- **Kill-line: encodeMappingKey follows the pinned rule (key first).** -/
theorem encodeMappingKey_at_witness :
    encodeMappingKey 5 10 = 5 * (2 ^ 256) + 10 := rfl

/-- **Kill-line: encodeMappingKey is asymmetric in its two arguments.**

`encodeMappingKey 5 10 ≠ encodeMappingKey 10 5` — key and baseSlot
occupy distinct positions in the encoding. -/
theorem encodeMappingKey_asymmetric :
    encodeMappingKey 5 10 ≠ encodeMappingKey 10 5 := by
  unfold encodeMappingKey
  decide

/-- **Kill-line: realMappingStorage.slotAt equals concreteMappingSlot
composed with encodeMappingKey.** -/
theorem realMappingStorage_composition
    (oracle : KeccakOracle) (baseSlot key : Nat) :
    (realMappingStorage oracle baseSlot).slotAt key =
      concreteMappingSlot oracle (encodeMappingKey key baseSlot) :=
  realMappingStorage_slotAt_eq oracle baseSlot key

/-- **Kill-line: realSlotDerivation is deterministic on identical
inputs.** -/
theorem realSlotDerivation_deterministic_at_witness :
    realSlotDerivation testOracle 100 5 = realSlotDerivation testOracle 100 5 :=
  realSlotDerivation_deterministic rfl rfl

#print axioms encodeMappingKey_at_witness
#print axioms encodeMappingKey_asymmetric
#print axioms realMappingStorage_composition
#print axioms realSlotDerivation_deterministic_at_witness

end LidoSRv3.Tests.MappingSlotViaOracleKillLines
