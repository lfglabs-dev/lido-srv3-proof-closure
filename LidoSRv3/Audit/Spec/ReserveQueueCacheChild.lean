import LidoSRv3.Audit.Guarantees.PReserve1
import LidoSRv3.Audit.Source.ReserveCorrespondence

/-!
# Wave 2 W2-RESERVE: named freshQueueCache child

Unregistered child. `freshQueueCache` stays a named hypothesis: the
state's cached `unfinalizedStETH` equals a caller-supplied live word.
There is no live `WithdrawalQueue.unfinalizedStETH()` CALL frame in this
repository. This file does not invent a guarantee ID and does not
discharge freshness.
-/

namespace LidoSRv3.Audit.Spec.ReserveQueueCacheChild

open LidoSRv3.Audit.SolidityReserve

/-- Re-export: freshness is equality of the cached `unfinalizedStETH`
field with the live word. The live word is an input, not a CALL
observation. Field names follow `ReserveCorrespondence.freshQueueCache`. -/
theorem fresh_queue_cache_is_equality (state : ReserveState) (live : Word) :
    freshQueueCache state live ↔ state.unfinalizedStETH = live :=
  Iff.rfl

/-- No live `WithdrawalQueue.unfinalizedStETH()` CALL frame exists in the
model. `freshQueueCache` remains a named hypothesis on an input word.
This pack does not inhabit a CALL observation and does not discharge
freshness. -/
theorem live_wq_call_remains_open : True := trivial

/-- Mismatched cache used by the non-vacuity kill-line. Cached
`unfinalizedStETH = 50`; the live word below is `80`. Same numbers as
the existing stale-cache premise-necessity witness. -/
private def mismatchedCache : ReserveState :=
  { buffered := Verity.Core.Uint256.ofNat 100
    storedDepositsReserve := Verity.Core.Uint256.ofNat 20
    unfinalizedStETH := Verity.Core.Uint256.ofNat 50
    depositedPostReport := Verity.Core.Uint256.ofNat 3
    depositedNextReportAdjusted := Verity.Core.Uint256.ofNat 2 }

/-- Kill-line: freshness is not tautological. A mismatched cache vs live
word is a counterexample to `∀ state live, freshQueueCache`. -/
theorem fresh_queue_cache_is_not_vacuous :
    ¬ ∀ (state : ReserveState) (live : Word), freshQueueCache state live := by
  intro h
  have hfresh := h mismatchedCache (Verity.Core.Uint256.ofNat 80)
  exact absurd hfresh (by decide)

/-- Anchor: this unregistered child imports the registered parent and
does not replace it. `freshQueueCache` remains a hypothesis of
`source_spend_preserves_withdrawal_reserve`. -/
example := @LidoSRv3.Audit.Guarantees.PReserve1.source_spend_preserves_withdrawal_reserve

end LidoSRv3.Audit.Spec.ReserveQueueCacheChild
