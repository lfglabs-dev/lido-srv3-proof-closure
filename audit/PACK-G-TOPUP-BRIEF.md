# Pack G-TOPUP brief — Verity beacon pin

One node, one PR. No new guarantee IDs.
`A-TOPUP-BEACON-ADDRESS` stays OPEN (deployed immutable identity).
This node does not discharge it.

## Work

1. Prove `TopupTx.beaconAddress.toNat` equals
   `PTopup1.canonicalBeaconDepositAddress`.
2. Prove the top-up canonical pin equals the deposit canonical pin as Nats.
3. Do not add a top-up `LinksSource`.

## Kill-lines

- A model using `0xDEAD` as beacon disagrees with the pin.

## Out of scope

Discharge of `A-TOPUP-BEACON-ADDRESS` from deployment artifacts.
Top-up `LinksSource`. New guarantee IDs. Integrator files.
