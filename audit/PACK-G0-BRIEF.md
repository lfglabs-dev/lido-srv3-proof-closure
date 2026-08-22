# Pack G0 brief — Join Spec destinations

One node, one PR. No new guarantee IDs. VaultHub stays out.

## Frozen interfaces used

`Spec.ApprovedDestination` from Wave 0.

## Work

1. Add exactly two Join destinations: `beaconDeposit` and `lidoPull`.
2. Do not map them in Pack B. Pack B stays consolidation-only.
3. Do not treat `EthJournal` as all SRv3 ETH.

## Out of scope

VaultHub, pause, bus, provenance discharge, live SSZ verifier.
