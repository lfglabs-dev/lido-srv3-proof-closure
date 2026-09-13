import LidoSRv3.Audit.Source.KeccakMappingStorageSource
import LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

/-! # Solidity mapping-slot derivation via KeccakOracle

**General rule (Thomas 2026-09-13, real derivation of the Solidity
mapping-slot layout past the abstract `MappingStorage.slotAt`
placeholder.)**

`KeccakMappingStorageSource.MappingStorage.slotAt` is an abstract
`Nat → Nat` function. The pinned Solidity mapping rule computes the
value slot for `mapping(K => V) public m` at key `k` as
`keccak256(abi.encode(k, mSlot))`.

This composition consumes the shared `KeccakOracle` (PR #478) and
names the real slot derivation. Downstream consumers of a
`MappingStorage` whose `slotAt` matches `realSlotDerivation` obtain
the pinned Solidity storage layout, not a free `Nat → Nat`.

**Status:** first real derivation of the Solidity mapping-slot rule
past the `slotAt` naming scaffold. The slot is now
`oracle.hash (encodeMappingKey k baseSlot)`. -/

namespace LidoSRv3.Audit.Source.MappingSlotViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-- Encode a `(key, baseSlot)` pair as a nat for the mapping slot
derivation (source-level abstraction of `abi.encode`). -/
def encodeMappingKey (key baseSlot : Nat) : Nat :=
  key * (2 ^ 256) + baseSlot

/-- Real slot derivation for `mapping(K => V)` at key `key` and
mapping-storage slot `baseSlot`, per pinned Solidity. -/
def realSlotDerivation
    (oracle : KeccakOracle) (baseSlot key : Nat) : Nat :=
  concreteMappingSlot oracle (encodeMappingKey key baseSlot)

/-- A `MappingStorage` whose `slotAt` follows the real Solidity
mapping-slot rule at a specific `baseSlot`. -/
def realMappingStorage
    (oracle : KeccakOracle) (baseSlot : Nat) : MappingStorage :=
  { slotAt := realSlotDerivation oracle baseSlot }

/-- The real mapping storage's `slotAt` equals the pinned Solidity
mapping-slot rule, definitionally. -/
theorem realMappingStorage_slotAt_eq
    (oracle : KeccakOracle) (baseSlot key : Nat) :
    (realMappingStorage oracle baseSlot).slotAt key =
      concreteMappingSlot oracle (encodeMappingKey key baseSlot) :=
  rfl

/-- Determinism of the real mapping-slot derivation on identical
inputs. Real derivation from the shared oracle's determinism law. -/
theorem realSlotDerivation_deterministic
    {oracle : KeccakOracle} {b1 b2 k1 k2 : Nat}
    (hBase : b1 = b2) (hKey : k1 = k2) :
    realSlotDerivation oracle b1 k1 = realSlotDerivation oracle b2 k2 := by
  subst hBase
  subst hKey
  rfl

end LidoSRv3.Audit.Source.MappingSlotViaOracleSource
