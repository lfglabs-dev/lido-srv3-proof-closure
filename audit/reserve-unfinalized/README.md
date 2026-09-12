# P-RESERVE-1 — live `WithdrawalQueue.unfinalizedStETH` STATICCALL

## CLAIM

- **Guarantee:** `P-RESERVE-1`
- **fidelity.missing entry:** `live WithdrawalQueue.unfinalizedStETH call (freshness is now an explicit freshQueueCache hypothesis with a stale-cache kill-line, not an implicit assumption)`
- **Branch:** `grok/lido-reserve-unfinalized-20260912`
- **Base:** `origin/main` @ `0debc40f5f7b1a1b687782710484397eaa7f781b`
- **Pinned Solidity:** `17005714f151e5502c559932319a3f2f74ac2436`
- **Claimed by:** grok cloud agent, 2026-09-12
- **Status:** closed on this consumer — Spark raccord pending

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

## What is proved

Additive files:

- `LidoSRv3/Audit/Source/ReserveUnfinalizedCall.lean`
- `LidoSRv3/Tests/ReserveUnfinalizedCallMutants.lean`

| Theorem | Source span | Claim |
|---|---|---|
| `live_requires_selector` | `unfinalizedStETH()` = `0xd0fb84e8` | decoded live word implies that selector |
| `live_requires_zero_value` | view STATICCALL | value must be 0 |
| `live_requires_success` | call failure | success bit required |
| `live_requires_32_bytes` | ABI `uint256` | `returndatasize == 32` |
| `failed_call_not_fresh` | fail-closed | `none` cannot witness `freshQueueCache` |
| `success_fresh_iff` | Lido.sol:612 | derived freshness ↔ parent hyp at decoded word |
| `spend_preserves_from_live_call` | Lido.sol:869-886 / 612 | cites unchanged parent at the decoded word |
| `decode_abiWord_small` | 32-byte ABI | leading-zero word decodes |

Mutants: happy 50/50; failed call; wrong selector `isBunkerModeActive` (`0x2b95b781`);
nonzero value; 1-byte returndata; stale 80 vs cache 50.

Axioms: `propext` / `Quot.sound` only. No `sorryAx`.

## Spark raccord (do not apply in this lot)

In `audit/guarantees.yaml` under `P-RESERVE-1`:

1. Remove this exact `fidelity.missing` string:
   ```
   - "live WithdrawalQueue.unfinalizedStETH call (freshness is now an explicit freshQueueCache hypothesis with a stale-cache kill-line, not an implicit assumption)"
   ```
2. Add a `fidelity.covered` bullet that `freshQueueCacheFromCall` derives
   freshness from a STATICCALL observation (`0xd0fb84e8`, 32-byte decode,
   fail-closed) and `spend_preserves_from_live_call` cites the parent at
   that decoded word.

## Honesty (not this entry)

The STATICCALL **observation** (success bit + returndata bytes + selector +
value) is an input, not a full EVM interpreter. The physical
`WithdrawalQueueBase.sol:143-146` subtraction
`cumulativeStETH[last] - cumulativeStETH[finalized]` is already modeled in
`TrioReserve1.Queue.unfinalizedStETH` and is not re-proved here. `canDeposit`
/ bunker / router authorization remain the separate P-RESERVE-1 missing
entry.
