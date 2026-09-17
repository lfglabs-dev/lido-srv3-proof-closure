import LidoSRv3.Audit.Source.ReserveCorrespondence

/-! # Pinned `Lido.setDepositsReserveTarget` source model

**Chantier 2 (Piste A, Thomas 2026-09-13) source model for the second
of the four ETH-reserve partition writers.**

The pinned `Lido.setDepositsReserveTarget(uint256 _newReserveTarget)` is
an admin-only setter that updates `storedDepositsReserve`.  Solidity
sketch (post-audit form, guarded by
`_hasRole(SET_DEPOSITS_RESERVE_ROLE)`):

```
function setDepositsReserveTarget(uint256 _newReserveTarget) external {
    _auth(SET_DEPOSITS_RESERVE_ROLE);
    STORED_DEPOSITS_RESERVE_POSITION.setStorageUint256(_newReserveTarget);
    emit DepositsReserveTargetSet(_newReserveTarget);
}
```

This is ONE of the four ETH-reserve partition writers named in
`audit/SITE-CORRECTIONS.md`:

1. `Lido._spendDepositableEther` (the top-up spend path — covered by
   the registered P-RESERVE-1 parent).
2. `Lido.setDepositsReserveTarget` (the reserve-target update — THIS
   MODULE).
3. Report-time rebalance via `_updateBufferedEtherAllocation` (not
   modeled).
4. `WithdrawalQueue.finalize` (WQ-side, updates `unfinalizedStETH`, not
   modeled).

This module names the second writer as a source-level state machine.
Real derivation (not a naming scaffold): the setter only touches
`storedDepositsReserve`, so the other partition fields are preserved
by construction.  Under the ACL admission premise, the setter
succeeds; else it aborts. -/

namespace LidoSRv3.Audit.Source.ReserveSetTargetSource

open LidoSRv3.Audit.SolidityReserve

/-- The pinned `setDepositsReserveTarget` transition on the reserve
state.  Under `auth = true`, `storedDepositsReserve` is set to the new
target; other fields are preserved.  Under `auth = false`, the call
reverts and the state is untouched. -/
def setDepositsReserveTarget (state : ReserveState) (newTarget : Word)
    (auth : Bool) : ReserveState :=
  if auth then
    { state with storedDepositsReserve := newTarget }
  else
    state

/-- Under the ACL admission premise, only `storedDepositsReserve` is
touched.  All four other partition fields (`buffered`,
`unfinalizedStETH`, `depositedPostReport`,
`depositedNextReportAdjusted`) are preserved by construction. -/
theorem setDepositsReserveTarget_preserves_other_fields
    (state : ReserveState) (newTarget : Word) (auth : Bool) :
    (setDepositsReserveTarget state newTarget auth).buffered = state.buffered ∧
    (setDepositsReserveTarget state newTarget auth).unfinalizedStETH =
      state.unfinalizedStETH ∧
    (setDepositsReserveTarget state newTarget auth).depositedPostReport =
      state.depositedPostReport ∧
    (setDepositsReserveTarget state newTarget auth).depositedNextReportAdjusted =
      state.depositedNextReportAdjusted := by
  cases auth <;> simp [setDepositsReserveTarget]

/-- Under `auth = true`, the setter writes `newTarget` to
`storedDepositsReserve`. -/
theorem setDepositsReserveTarget_of_auth
    (state : ReserveState) (newTarget : Word) :
    (setDepositsReserveTarget state newTarget true).storedDepositsReserve = newTarget := by
  simp [setDepositsReserveTarget]

/-- Under `auth = false`, the setter is a no-op. -/
theorem setDepositsReserveTarget_of_unauth
    (state : ReserveState) (newTarget : Word) :
    setDepositsReserveTarget state newTarget false = state := by
  simp [setDepositsReserveTarget]

/-- The setter is idempotent under identical targets. -/
theorem setDepositsReserveTarget_idempotent
    (state : ReserveState) (newTarget : Word) (auth : Bool) :
    setDepositsReserveTarget (setDepositsReserveTarget state newTarget auth) newTarget auth =
      setDepositsReserveTarget state newTarget auth := by
  cases auth <;> simp [setDepositsReserveTarget]

end LidoSRv3.Audit.Source.ReserveSetTargetSource
