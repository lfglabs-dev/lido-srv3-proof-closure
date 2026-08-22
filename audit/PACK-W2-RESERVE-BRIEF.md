# Pack W2-RESERVE brief — named freshQueueCache child

One node, one PR. No new guarantee IDs. `freshQueueCache` stays a named
hyp. No live `WithdrawalQueue.unfinalizedStETH()` CALL. The live word
is an input.

## Frozen interfaces used

`Spec.Spend` from Wave 0. `freshQueueCache` from
`Source/ReserveCorrespondence.lean`. Registered parent
`PReserve1.source_spend_preserves_withdrawal_reserve`.

## Work

1. Restate freshness as equality of cached `unfinalizedStETH` with the
   live word (`fresh_queue_cache_is_equality`).
2. Record that the live WQ CALL remains open
   (`live_wq_call_remains_open`). No CALL frame; input word only.
3. Kill-line: freshness is not tautological (`¬ ∀ state live,
   freshQueueCache`). Cite
   `ReserveMutants.stale_queue_cache_mutant_counterexample`.

## Kill-lines

- A mismatched cache vs live word refutes
  `∀ state live, freshQueueCache state live`.
- The existing stale-cache witness still raids the live queue-facing
  reserve. Premise necessity, not a parent-shaped refutation.

## Out of scope

Live WQ CALL. Discharging `freshQueueCache`. New guarantee IDs.
Editing `PReserve1.lean`. P-RESERVE-RELATIONAL.
