# Pack J-TOPUP brief — Join top-up ETH journal

One node, one PR. No new guarantee IDs. VaultHub stays out. This is not
all SRv3 ETH.

## Frozen interfaces used

`Spec.ApprovedDestination` (`lidoPull` | `beaconDeposit`) and
`Spec.EthJournal` after Pack G0. The call journal is
`TopupTx.sourceObservables`: value-moving success names
`withdrawDepositableEther` then `makeBeaconChainTopUp*`, targets
`lidoAddress` (`0xF00D`) then `beaconAddress*` (already the production
pin), call-values `0` then the push amounts. Wrap-to-zero is empty.

## Work

1. Unregistered child: project that journal onto `Spec.EthJournal`.
   Value-moving success is one `lidoPull` of the wrapped total followed
   by one `beaconDeposit` per nonzero source push.
2. Wrap-to-zero (unchecked total 0) is the empty journal. Cite the
   registered parent wrap-precludes-value-moving-commit. Do not
   re-prove wrap. `A-TOPUP-NOWRAP` stays named.
3. Kill-lines: a beacon push tagged `.consolidationRequest` fails the
   Join dest restriction; a nonempty journal when wrapped = 0 fails
   emptiness.

## Out of scope

Discharge wrap. All SRv3 ETH. VaultHub. Merge ALLOC into DEPOSIT.
Live SSZ verifier. Pack B remapping.
