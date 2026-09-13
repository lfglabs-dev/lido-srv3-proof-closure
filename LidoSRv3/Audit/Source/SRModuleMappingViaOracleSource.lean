import LidoSRv3.Audit.Source.SRStorageSourceModel
import LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! # SR module-registry MappingStorage via shared KeccakOracle

**General rule (Thomas 2026-09-13, chain
`SRStorageSourceModel.moduleExistsFromMapping`'s MappingStorage
through the shared oracle-backed realMappingStorage.)**

`SRStorageSourceModel.moduleExistsFromMapping` takes a free
`MappingStorage`. This composition specialises it to a
`realMappingStorage oracle moduleRegistryBaseSlot` so the module-id
slot is derived through the pinned Solidity mapping-slot rule.

**Status:** derives the SR module-registry MappingStorage from the
shared oracle, tightening `moduleExistsFromMapping` past a free
`Nat → Nat`. -/

namespace LidoSRv3.Audit.Source.SRModuleMappingViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.SRStorageSourceModel

/-- Compose `moduleExistsFromMapping` with the shared oracle-backed
mapping storage. Module existence is now a function of
`(oracle, moduleRegistryBaseSlot, moduleId)`. -/
def moduleExistsFromOracle
    (oracle : KeccakOracle) (moduleRegistryBaseSlot moduleId : Nat) : Bool :=
  moduleExistsFromMapping
    (realMappingStorage oracle moduleRegistryBaseSlot) moduleId

/-- Under the pinned nonzero-module-slot premise, the oracle-backed
module-exists check returns true. Real derivation. -/
theorem moduleExistsFromOracle_true_of_nonzero
    {oracle : KeccakOracle}
    {moduleRegistryBaseSlot moduleId : Nat}
    (hNonzero : (realMappingStorage oracle moduleRegistryBaseSlot).slotAt moduleId ≠ 0) :
    moduleExistsFromOracle oracle moduleRegistryBaseSlot moduleId = true := by
  unfold moduleExistsFromOracle
  exact moduleExists_true_of_mapping_nonzero hNonzero

end LidoSRv3.Audit.Source.SRModuleMappingViaOracleSource
