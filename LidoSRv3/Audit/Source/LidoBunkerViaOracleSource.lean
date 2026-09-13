import LidoSRv3.Audit.Source.LidoStakingStateStorage
import LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! # Lido isBunkerActive MappingStorage via shared KeccakOracle

**General rule (Thomas 2026-09-13, chain
`LidoStakingStateStorage.isBunkerActiveFromStorage`'s MappingStorage
through the shared oracle-backed realMappingStorage.)**

`LidoStakingStateStorage.isBunkerActiveFromStorage` takes a free
`MappingStorage`. This composition specialises it to a
`realMappingStorage oracle bunkerBaseSlot` so the bunker slot is
derived through the shared A-KECCAK-COMMITMENT oracle.

**Status:** derives the bunker-slot MappingStorage from the shared
oracle, tightening `isBunkerActiveFromStorage` past a free
`Nat → Nat`. -/

namespace LidoSRv3.Audit.Source.LidoBunkerViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.LidoStakingStateStorage

/-- Compose `isBunkerActiveFromStorage` with the shared oracle-
backed mapping storage. -/
def isBunkerActiveFromOracle
    (oracle : KeccakOracle)
    (bunkerBaseSlot bunkerSlotKey : Nat) : Bool :=
  isBunkerActiveFromStorage
    (realMappingStorage oracle bunkerBaseSlot) bunkerSlotKey

/-- Under the pinned zero-bunker-slot premise, the oracle-backed
bunker check returns `false`. Real derivation. -/
theorem isBunkerActiveFromOracle_false_of_zero
    {oracle : KeccakOracle}
    {bunkerBaseSlot bunkerSlotKey : Nat}
    (hSlot : (realMappingStorage oracle bunkerBaseSlot).slotAt bunkerSlotKey = 0) :
    isBunkerActiveFromOracle oracle bunkerBaseSlot bunkerSlotKey = false := by
  unfold isBunkerActiveFromOracle
  exact isBunkerActive_false_of_slot_zero hSlot

end LidoSRv3.Audit.Source.LidoBunkerViaOracleSource
