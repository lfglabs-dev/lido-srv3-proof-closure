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

end LidoSRv3.Audit.Source.LidoStakingStateStorage
