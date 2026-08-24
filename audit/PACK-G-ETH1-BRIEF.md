# Pack G-ETH1 brief — ensemble request rewrite

One node, one PR. No new guarantee IDs. Registered Verity ETH-1 parents
stay on ensemble `requestAddr` = 5.

## Honest claim

`Verity.MultiContract.requestAddr` is 5. The model pin
`PConsolidationEth1.canonicalRequestAddress` is the pinned EIP-7251 literal
`0x0000BBdDc7CE488642fb579F8B00f3a590007251`. Those Nats are not equal. An unregistered observe rewrite
maps ensemble 5 to the canonical literal and leaves every other address
unchanged.

`A-CANONICAL-REQUEST-ADDRESS` stays OPEN. This rewrite is not deployed
target identity and does not fold the canonical literal into the
registered Verity parent.

## Work

1. Pin ensemble `requestAddr` as 5.
2. Prove the parent model literal is the pinned EIP-7251 value.
3. Prove ensemble 5 is not that literal.
4. Define the observe rewrite and prove it maps 5 to the literal and
   preserves every other address.

## Kill-lines

- A mutant rewrite that maps ensemble 5 to `0xDEAD` is not the
  canonical rewrite.

## Out of scope

Changing registered ETH-1 parents. Composition with P-CONSOLIDATION-1.
VaultHub. `native_decide` on a parent. Discharging
`A-CANONICAL-REQUEST-ADDRESS`.
