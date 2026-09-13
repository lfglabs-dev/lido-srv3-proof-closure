import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # ConsolidationGateway whenResumed pause guard source model

**General rule (Thomas 2026-09-13, real derivation of the
P-CONSOLIDATION-ETH-1 pause guard chantier 5 disclosed.)**

Chantier 5 (PR #431) disclosed as `fidelity.missing` on
P-CONSOLIDATION-ETH-1 that
`ConsolidationGateway.addConsolidationRequests` is `whenResumed`
(contract-level pausable state); a paused gateway must revert before
the modeled arms. This composition names the pause slot as a
source-level function of the shared `KeccakMappingStorageSource
.MappingStorage`.

Pinned Solidity (17005714):

- `ConsolidationGateway.sol` `whenResumed` modifier inherited from
  Pausable, checks a paused-flag storage slot.

**Status:** first real derivation of the pause guard past chantier 5's
disclosure. Under a live-storage premise the pause check is derived
from a named storage read — no free boolean. -/

namespace LidoSRv3.Audit.Source.ConsolidationPauseGuardSource

/-- Definition of `isPaused` from source-level MappingStorage read:
the gateway is paused iff the stored pause-slot value is non-zero. -/
def isPausedFromStorage
    (m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage)
    (pauseSlotKey : Nat) : Bool :=
  decide (LidoSRv3.Audit.Source.KeccakMappingStorageSource.read m pauseSlotKey ≠ 0)

/-- Under the pinned pause-slot premise (slot is zero, i.e., not
paused), `isPausedFromStorage = false`. Real derivation from a named
pause-slot read. -/
theorem not_paused_of_slot_zero
    {m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage}
    {pauseSlotKey : Nat}
    (hSlot : m.slotAt pauseSlotKey = 0) :
    isPausedFromStorage m pauseSlotKey = false := by
  simp [isPausedFromStorage,
        LidoSRv3.Audit.Source.KeccakMappingStorageSource.read, hSlot]

/-- Definition of `whenResumed` modifier as the negation of
`isPaused`: the modifier passes iff the gateway is not paused. -/
def whenResumedGuard
    (m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage)
    (pauseSlotKey : Nat) : Bool :=
  !isPausedFromStorage m pauseSlotKey

/-- Under the pinned not-paused premise, the `whenResumed` guard
passes. Real derivation. -/
theorem whenResumed_passes_of_not_paused
    {m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage}
    {pauseSlotKey : Nat}
    (hSlot : m.slotAt pauseSlotKey = 0) :
    whenResumedGuard m pauseSlotKey = true := by
  simp [whenResumedGuard, not_paused_of_slot_zero hSlot]

end LidoSRv3.Audit.Source.ConsolidationPauseGuardSource
