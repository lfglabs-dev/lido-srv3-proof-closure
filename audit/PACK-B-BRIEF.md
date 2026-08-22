# Pack B brief — Spec.EthJournal projection of consolidation ETH

One node, one PR. Not Best-of-N. No new guarantee IDs. VaultHub owner
withdraw stays out.

## Frozen interfaces used

`Spec.ApprovedDestination` (`consolidationRequest` | `refundRecipient`) and
`Spec.EthJournal` from Wave 0. These are the destinations the success journal
of `gatewayExecute` actually emits. `parentApproved` also accepts `.lido` /
`.withdrawalQueue` / `.withdrawalRequestContract`; those are not Spec
destinations and are not in the success journal.

## Work

1. Unregistered child: a successful `gatewayExecute` journal projects onto
   `Spec.EthJournal`. Every move has a Spec destination; Spec wei totals match
   the move amounts and equal `msgValue`.
2. Parent-shaped kill-line: a third destination (`.other` or retired `.lido`)
   fails the Spec projection. That is the honesty check that Pack B did not
   silently widen `ApprovedDestination`.

## Out of scope

VaultHub / `StakingVault.withdraw`, deposit/top-up ETH journals (Join),
widening `Spec.ApprovedDestination`, packs C–F.
