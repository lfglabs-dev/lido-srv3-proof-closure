# P-RESERVE-1 — live `WithdrawalQueue.unfinalizedStETH` STATICCALL

## CLAIM

- **Guarantee:** `P-RESERVE-1`
- **fidelity.missing entry:** `live WithdrawalQueue.unfinalizedStETH call (freshness is now an explicit freshQueueCache hypothesis with a stale-cache kill-line, not an implicit assumption)`
- **Branch:** `grok/lido-reserve-unfinalized-20260912`
- **Base:** `origin/main` @ `0debc40f5f7b1a1b687782710484397eaa7f781b`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** claimed — implementing

This lot does **not** claim ADDRESS singleton-actor exclusion (PR #403) or
ACCOUNT fee derivation (PR #402). `spark/lido-official-oracle-reserve-registration-20260911`
is Trust registration, not this live-call entry.

## Targeted gap

Registered parent `PReserve1.source_spend_preserves_withdrawal_reserve` takes
`freshQueueCache before live` as an explicit hypothesis standing in for
`Lido.sol:612` `_withdrawalQueue().unfinalizedStETH()`. This lot adds a
derived consumer that obtains `live` from a STATICCALL observation
(selector `0xd0fb84e8`, 32-byte ABI decode, fail-closed) and derives
freshness from that result.

The parent `freshQueueCache` definition, `source_spend_preserves_withdrawal_reserve`,
and `guarantees.yaml` are not edited.
