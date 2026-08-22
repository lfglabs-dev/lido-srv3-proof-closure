# Pack N4 brief — fuel-bounded live claim batch

One node, one parent. No new guarantee ID and no pause row.

## Parent

`p_address_batch_1_fuel_bounded_live_claim_batch` is universal over request
and hint lists whose lengths are equal and bounded by an explicit natural
fuel value. `BatchReady` retains, for each iteration, the unclaimed finalized
request checks, valid checkpoint hint, storage-derived `claimableEther`,
locked-ETH funding, and payout-balance funding.

Distinct encoded request keys preserve entry-snapshot reads across claimed
writes. A successful live run therefore:

- journals `payoutEntry` calls equal to entry-snapshot reads, in list order;
- marks every request key claimed; and
- decreases locked ETH by the payout sum.

`every_revert_restores_snapshot` is re-exported from the existing transaction
boundary theorem.

## Kill-line

The retained three-item witness has payouts `[30, 40, 10]`, fits fuel `8`,
has equal request/hint lengths, distinct encoded keys, and satisfies
`BatchReady`. The `[40, 30, 10]` mutant journal cannot agree with those
ordered pre-state reads.

## Scope

This node does not change the universal address-writer theorem, add a pause
predicate, claim all address writers are permissionless, refine mapping keys
to machine slots, or model EnumerableSet removal and events.
