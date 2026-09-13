import LidoSRv3.Audit.Source.ConsolidationPauseGuardSource
import LidoSRv3.Audit.Source.MappingSlotViaOracleSource

/-! # ConsolidationGateway pause guard via realMappingStorage

**General rule (Thomas 2026-09-13, chain the pause-guard's
MappingStorage through the shared oracle-backed realMappingStorage.)**

`ConsolidationPauseGuardSource.whenResumedGuard` takes a free
`MappingStorage`. This composition specialises it to a
`realMappingStorage oracle pauseBaseSlot` so the pause slot is
derived through the shared A-KECCAK-COMMITMENT oracle rather than a
free `Nat → Nat`.

Pinned Solidity (17005714):

- `ConsolidationGateway.sol` inherits `Pausable`; the paused-flag
  storage slot lives at a keccak-derived layout for the Pausable
  contract's storage-position constant.

**Status:** derives the pause-slot MappingStorage from the shared
oracle, tightening the P-CONSOLIDATION-ETH-1 pause guard past a
free MappingStorage. -/

namespace LidoSRv3.Audit.Source.ConsolidationPauseSlotViaOracleSource

open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.ConsolidationPauseGuardSource

/-- Compose `whenResumedGuard` with the shared oracle-backed
mapping storage. The pause slot is now a function of
`(oracle, pauseBaseSlot, pauseSlotKey)`. -/
def whenResumedGuardFromOracle
    (oracle : KeccakOracle)
    (pauseBaseSlot pauseSlotKey : Nat) : Bool :=
  whenResumedGuard (realMappingStorage oracle pauseBaseSlot) pauseSlotKey

/-- Under the pinned zero-pause-slot premise (the oracle-backed
mapping's slot at the pause key is zero), the composed guard
passes. Real derivation. -/
theorem whenResumedGuardFromOracle_passes_of_slot_zero
    {oracle : KeccakOracle}
    {pauseBaseSlot pauseSlotKey : Nat}
    (hSlot : (realMappingStorage oracle pauseBaseSlot).slotAt pauseSlotKey = 0) :
    whenResumedGuardFromOracle oracle pauseBaseSlot pauseSlotKey = true := by
  unfold whenResumedGuardFromOracle
  exact whenResumed_passes_of_not_paused hSlot

end LidoSRv3.Audit.Source.ConsolidationPauseSlotViaOracleSource
