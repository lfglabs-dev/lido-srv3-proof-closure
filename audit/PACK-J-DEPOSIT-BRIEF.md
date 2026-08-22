# Pack J-DEPOSIT brief — Spec.EthJournal projection of deposit ETH

One node, one PR. Not Best-of-N. No new guarantee IDs. VaultHub owner
withdraw stays out. Do not start a live SSZ verifier.

## Frozen interfaces used

`Spec.ApprovedDestination` (`lidoPull` | `beaconDeposit`, added in G0) and
`Spec.EthJournal` from Wave 0. These are the destinations the two-batch
deposit success journal actually emits. Pack B mapping stays
consolidation-only (`consolidationRequest` | `refundRecipient`).
`LinksSource` stays a named hyp.

## Work

1. Unregistered child: a successful two-batch `DepositParentTx` journal
   projects onto `Spec.EthJournal`. Value-moving legs only: the Lido
   pull is value 0 on `withdrawDepositableEther` (credit is explicit)
   and is still projected as `lidoPull` with wei = `pulled` /
   `totalAmount`; each `depositToBeacon` is `beaconDeposit` with wei =
   `batch.amount`. The two `obtainDepositData` frames stay off the
   journal.
2. Named `LinksSource` child: pulled / total equals the two batch
   amounts under that hyp. Keep the hyp. Do not merge ALLOC into
   DEPOSIT. Do not register a composition ID.
3. Parent-shaped kill-line: a mutant that adds `.consolidationRequest`
   or uses dest `.refundRecipient` fails "every dest is lidoPull or
   beaconDeposit". A mutant that routes a beacon push to a third dest
   fails Spec projection totality.

## Out of scope

VaultHub / `StakingVault.withdraw`, live SSZ verifier, widening
`Spec.ApprovedDestination`, discharging `LinksSource`, ALLOC→DEPOSIT
composition, J-TOPUP, provenance G-nodes.
