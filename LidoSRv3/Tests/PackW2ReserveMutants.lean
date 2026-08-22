import LidoSRv3.Audit.Spec.ReserveQueueCacheChild
import LidoSRv3.Tests.ReserveMutants

/-!
# Pack W2-RESERVE fail-closed vectors

Cite the existing stale-cache premise-necessity witness. Freshness is
not tautological. This is not a parent-shaped refutation of
`PReserve1.source_spend_preserves_withdrawal_reserve` (the parent cannot
be instantiated on a stale cache).
-/

namespace LidoSRv3.Tests.PackW2ReserveMutants

open LidoSRv3.Audit.SolidityReserve
open LidoSRv3.Audit.Spec.ReserveQueueCacheChild

/-- Citation of the existing public stale-cache premise-necessity
witness. A legal spend that preserves the cached-field invariant can
still raid the live queue-facing reserve once the cache is stale. Not a
parent-shaped kill-line. -/
example := LidoSRv3.Tests.ReserveMutants.stale_queue_cache_mutant_counterexample

/-- Kill-line: freshness is not `True` for every cache/live pair. -/
theorem fresh_queue_cache_not_universal :
    ¬ ∀ (state : ReserveState) (live : Word), freshQueueCache state live :=
  fresh_queue_cache_is_not_vacuous

end LidoSRv3.Tests.PackW2ReserveMutants
