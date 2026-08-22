# Pack F brief — consolidation observe/payloads

One node, one PR. Not Best-of-N. No new guarantee IDs. Gateway/bus stay
out. `A-CONSOLIDATION-GATEWAY-NONZERO` remains a named hyp.

## Work

1. Unregistered child: `observe` of a successful consolidation transaction
   rereads `sourceMapSlot` / `targetMapSlot` via `readPayloads`. It does not
   trust `Result.payloads`.
2. Persist correspondence stays `persist_read_payloads`: written maps reread
   as the normalized source-then-target pairs.
3. Do not start a live verifier from SSZ `Nat.pair`. Do not start the bus.

## Kill-lines

- Mutant observe that rereads target-then-source disagrees with honest
  `observe` on a one-pair batch whose source ≠ target.

## Out of scope

Gateway/bus, EIP-4788, Join deposit/top-up ETH journals, live SSZ verifier.
