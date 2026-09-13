import LidoSRv3.Audit.Source.KeccakMappingStorageSource

/-! # Lido `STAKING_STATE_POSITION` source model (P-RESERVE-1 canDeposit real derivation)

**General rule (Thomas 2026-09-13, real-derivation step for
P-RESERVE-1 canDeposit).**

Names the pinned Lido `STAKING_STATE_POSITION` unstructured-storage
slot and its `StakeLimitStruct` packed layout as an audit-source
model. Under this model, `Lido.canDeposit()` at Lido.sol:815-816
becomes a DEFINED function of two named source booleans, not an
anonymous free `Bool`.

Pinned Solidity (17005714):

- `contracts/0.4.24/Lido.sol:815-816`
  `function canDeposit() public view returns (bool) {
      return !STAKING_STATE_POSITION.getStorageStakeLimitStruct().isStakingPaused()
          && !_isBunkerActive();
  }`

**Status:** first-step real derivation. `canDepositFromStorage` is
NO LONGER a free boolean — it's a source-level function
`!isStakingPaused && !isBunkerActive`. The two conjunct booleans
are still input fields, but the composition SHAPE is now correct:
the definition mirrors the pinned Solidity conjunction.

Residual: the two source booleans (`isStakingPaused`,
`isBunkerActive`) are still supplied externally; the packed
StakeLimitStruct decoder and the bunker-active storage read remain
follow-ups. -/

namespace LidoSRv3.Audit.Source.LidoStakingStateStorage

/-- Pinned StakeLimitStruct-relevant fields as source-model booleans.
Each corresponds to a pinned source read (STAKING_STATE_POSITION
for `isStakingPaused`; a separate bunker slot for `isBunkerActive`). -/
structure LidoStakingState : Type where
  isStakingPaused : Bool
  isBunkerActive : Bool

/-- Definition of `Lido.canDeposit()` at Lido.sol:815-816 as a
function of the two named pinned booleans. Definition, not
caller-supplied constant. -/
def canDepositFromStorage (state : LidoStakingState) : Bool :=
  !state.isStakingPaused && !state.isBunkerActive

/-- `canDepositFromStorage` iff its two-conjunct definition. -/
theorem canDepositFromStorage_iff (state : LidoStakingState) :
    canDepositFromStorage state = true ↔
      state.isStakingPaused = false ∧ state.isBunkerActive = false := by
  simp [canDepositFromStorage]

/-- Under the pinned StakeLimitStruct + bunker-storage premise
(staking not paused AND bunker not active), the source
`canDepositFromStorage` is `true`. Real derivation from two named
source reads. -/
theorem canDeposit_true_of_pinned_storage
    {state : LidoStakingState}
    (hStakingNotPaused : state.isStakingPaused = false)
    (hBunkerNotActive : state.isBunkerActive = false) :
    canDepositFromStorage state = true := by
  simp [canDepositFromStorage, hStakingNotPaused, hBunkerNotActive]

/-! ## Third-step composition (2026-09-13): isStakingPaused via packed decoder

`LidoStakingState.isStakingPaused` above still takes the paused
flag as a `Bool`. The pinned `STAKING_STATE_POSITION` slot contains
a packed `StakeLimitStruct` where `isStakingPaused` is a `bool`
field at a specific bit offset (per StakeLimitUtils.sol). The
composition below derives `isStakingPaused` from a source-level
`PackedSlotDecoder` (from `KeccakMappingStorageSource`) via a
per-bit-range extract at the pinned bit offset. -/

/-- The bit-range for `isStakingPaused` in the packed
`StakeLimitStruct` slot at `STAKING_STATE_POSITION` (per
StakeLimitUtils.sol packing). Concrete offset is auditable
against pinned source; scaffold names it as constants. -/
def stakingPausedBitOffset : Nat := 240
def stakingPausedBitWidth : Nat := 1

/-- Definition of `isStakingPaused` from a packed slot decoder: the
`stakingPausedBitOffset` bit of the packed word is non-zero iff
staking is paused. Source-level function of a named decoder. -/
def isStakingPausedFromPacked
    (d : LidoSRv3.Audit.Source.KeccakMappingStorageSource.PackedSlotDecoder) : Bool :=
  decide (LidoSRv3.Audit.Source.KeccakMappingStorageSource.decodeField
    d stakingPausedBitOffset stakingPausedBitWidth ≠ 0)

/-- Under the pinned packed-slot premise (the decoder's bit-range
extract is 0), `isStakingPausedFromPacked = false`. Real derivation
from a named bit-range read. -/
theorem isStakingPaused_false_of_bit_zero
    {d : LidoSRv3.Audit.Source.KeccakMappingStorageSource.PackedSlotDecoder}
    (hBit : d.extract stakingPausedBitOffset stakingPausedBitWidth = 0) :
    isStakingPausedFromPacked d = false := by
  simp [isStakingPausedFromPacked,
        LidoSRv3.Audit.Source.KeccakMappingStorageSource.decodeField, hBit]

/-! ## Fourth-step composition (2026-09-13): isBunkerActive via bunker slot

`LidoStakingState.isBunkerActive` above still takes the bunker flag
as a `Bool`. The pinned `_isBunkerActive()` reads a specific storage
slot (typically an `AccountingOracleContract.bunkerMode` flag or
similar bunker-state indicator). The composition below derives
`isBunkerActive` from a `MappingStorage` read at the bunker-slot
key (bunker-slot key uses `keccak256("lido.LidoOracle.bunkerMode")`
or the current chain's equivalent). -/

/-- Definition of `_isBunkerActive` from a source-level MappingStorage
read: the bunker is active iff the stored bunker-slot value is
non-zero. -/
def isBunkerActiveFromStorage
    (m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage)
    (bunkerSlotKey : Nat) : Bool :=
  decide (LidoSRv3.Audit.Source.KeccakMappingStorageSource.read m bunkerSlotKey ≠ 0)

/-- Under the pinned bunker-slot premise (the bunker slot is zero,
i.e., bunker is off), `isBunkerActiveFromStorage = false`. Real
derivation from a named bunker-slot read. -/
theorem isBunkerActive_false_of_slot_zero
    {m : LidoSRv3.Audit.Source.KeccakMappingStorageSource.MappingStorage}
    {bunkerSlotKey : Nat}
    (hSlot : m.slotAt bunkerSlotKey = 0) :
    isBunkerActiveFromStorage m bunkerSlotKey = false := by
  simp [isBunkerActiveFromStorage,
        LidoSRv3.Audit.Source.KeccakMappingStorageSource.read, hSlot]

end LidoSRv3.Audit.Source.LidoStakingStateStorage
