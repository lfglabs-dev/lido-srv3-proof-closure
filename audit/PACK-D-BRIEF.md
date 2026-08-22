# Pack D brief — ADDRESS live claim-batch strengthening

One node, one PR. Not Best-of-N. No new guarantee IDs. No global-pause
versus selective-block row.

## Work

1. Unregistered child: on the pinned two-item `claimWithdrawalsTo` witness,
   the journaled payout amounts are exactly `claimableEther` of the
   storage-backed `readRequest`s, in loop order, to the supplied recipient.
2. The existing `two_claim_batch_observe` receipt remains the observe
   correspondence. This pack names the read→payout link that receipt leaves
   implicit.
3. Write-side parent kill-line stays on P-ADDRESS-1. No pause row.

## Kill-lines

- Swapped payout order `[40, 30]` disagrees with the honest observe journal
  `[30, 40]`.
- A wrong recipient disagrees with `payoutEntry recipient amount`.

## Out of scope

Pause row, VaultHub, Join, packs E–F.
