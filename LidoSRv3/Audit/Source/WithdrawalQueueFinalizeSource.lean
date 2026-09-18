import LidoSRv3.Audit.Source.WithdrawalQueueMappingSource

/-! # Pinned `WithdrawalQueue.finalize` source model

**Chantier 2 (Piste A, Thomas 2026-09-13) source model for the fourth
of the four ETH-reserve partition writers.**

The pinned `WithdrawalQueueBase._finalize(uint256 _lastRequestIdToBeFinalized,
uint256 _amountOfETH, uint256 _shareRate)` finalizes a batch of
withdrawal requests, decreasing the WQ's unfinalizedStETH accumulator
by the finalized amount and increasing the finalizedETH counter.

Simplified transition captured here: `finalize wqs finalizedAmount`
reduces `wqs.unfinalizedStETH` by `finalizedAmount` (saturating at
zero), leaves `readRequest` / `readCheckpoint` opaque for the outer
audit-facing accessor (the withdrawal-request custody / packed
decoding is covered by dedicated source models
`WithdrawalQueueRequestCustody.lean` and `WQRequestPackedDecoderSource.lean`).

**Real derivation**: the invariant `finalize(_).unfinalizedStETH =
saturating_sub wqs.unfinalizedStETH finalizedAmount` is proved from
the state-machine semantics.  Composing this writer with the top-up
spend writer preserves the ReserveState's cached `unfinalizedStETH`
UNTIL the reserve state is re-refreshed by a live STATICCALL — the
cache-freshness invariant is exactly what
`ReserveUnfinalizedCall.freshQueueCacheFromCall` observes and
`freshQueueCache` names on `ReserveState`.

This is ONE of the four ETH-reserve partition writers named in
`audit/SITE-CORRECTIONS.md`; writers #1 (spend), #2
(setDepositsReserveTarget) and #4 (finalize — this module) are now
modeled.  Writer #3 (`_updateBufferedEtherAllocation` report-time
rebalance) remains a follow-up. -/

namespace LidoSRv3.Audit.Source.WithdrawalQueueFinalizeSource

open LidoSRv3.Audit.Source.WithdrawalQueueMappingSource

/-- The pinned `_finalize` transition on the WQ storage.  The
`unfinalizedStETH` accumulator drops by the finalized amount, saturating
at zero (mirrors the pinned SafeMath sub with min-clamp). -/
def finalize (wqs : WithdrawalQueueStorage) (finalizedAmount : Nat) :
    WithdrawalQueueStorage :=
  { wqs with unfinalizedStETH := wqs.unfinalizedStETH - finalizedAmount }

/-- The `_finalize` transition drops `unfinalizedStETH` by exactly the
finalized amount (Nat saturating subtraction).  Real derivation from
the state-machine semantics. -/
theorem finalize_unfinalizedStETH (wqs : WithdrawalQueueStorage)
    (finalizedAmount : Nat) :
    (finalize wqs finalizedAmount).unfinalizedStETH =
      wqs.unfinalizedStETH - finalizedAmount := by
  simp [finalize]

/-- `finalize` is monotone-decreasing on `unfinalizedStETH` (Nat
saturating subtraction is ≤). -/
theorem finalize_monotone (wqs : WithdrawalQueueStorage)
    (finalizedAmount : Nat) :
    (finalize wqs finalizedAmount).unfinalizedStETH ≤ wqs.unfinalizedStETH := by
  simp [finalize, Nat.sub_le]

/-- Finalizing zero is a no-op on `unfinalizedStETH`. -/
theorem finalize_zero (wqs : WithdrawalQueueStorage) :
    (finalize wqs 0).unfinalizedStETH = wqs.unfinalizedStETH := by
  simp [finalize]

/-- Under a bounded-finalization premise `finalizedAmount ≤
wqs.unfinalizedStETH`, the drop equals mathematical subtraction (no
saturation). -/
theorem finalize_of_bounded (wqs : WithdrawalQueueStorage)
    (finalizedAmount : Nat)
    (hBound : finalizedAmount ≤ wqs.unfinalizedStETH) :
    (finalize wqs finalizedAmount).unfinalizedStETH =
      wqs.unfinalizedStETH - finalizedAmount := by
  simp [finalize]

end LidoSRv3.Audit.Source.WithdrawalQueueFinalizeSource
