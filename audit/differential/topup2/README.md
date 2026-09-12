# TOPUP-2 Solidity ↔ Verity differential

CLAIM: grok owns lido-differential-topup-2 since 2026-09-12

Pinned Solidity `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Registered parent exposed: `LidoSRv3.Audit.Source.Topup2.sourceRun`.

## Status

BLOCKED: model divergence

The harness is green. `_evaluateTopUpLimit` after slash/exit agrees with
`sourceLimits` on the numeric slice (checked add, target, minTopUp).
`sourceRun` then applies a leftover-budget walk that the pinned gateway
does not execute.

## Divergences (model obligations)

Existing proof files were not edited.

### D-CONSUME-1 — leftover walk vs independent limits

Pinned `TopUpGateway.sol:226-232` writes
`topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei` independently and
hands the array to `stakingRouter.topUp`. It never walks a leftover
budget. `sourceRun` does `sourceCandidates` then `sourceConsume` of
`min(valueGwei, min(moduleLimit, remainingCap))`.

Two keys each eligible for 20 gwei with `remainingCap = 20`:
Solidity limits `[20e9, 20e9]` (gwei) / `[20e18, 20e18]` wei;
`sourceRun` allocations `[20e9, 0]`.

Obligation: drop `sourceConsume` from the registered parent, or prove
the leftover walk against a module `allocateDeposits` policy, not
against `TopUpGateway.topUp`.

### D-SLASH-1 — slash / exit not on `evaluateTopUpLimit`

Pinned `_evaluateTopUpLimit` (`:403-405`) returns 0 when
`exitEpoch != FAR_FUTURE_EPOCH` or `slashed`. `sourceRun` /
`evaluateTopUpLimit` take only effective/pending/target/minTopUp.
A slashed validator with a supplied `topUpLimits = [0]` (the pin)
fails `evaluatedLimits != topUpLimits` and returns `none`.

Obligation: take slash/exit as inputs of `evaluateTopUpLimit`.

### D-AUTH-1 / D-SORT-1 / D-WC-1 / D-PUBKEY-1 / D-MAX-1

`onlyRole(TOP_UP_ROLE)`, strictly increasing indices, type-0x02 WC,
48-byte pubkeys, and `maxValidatorsPerTopUp` are source guards.
`sourceRun` sees numeric arrays only.

Obligation: run the `:160-223` prefix in the CLI parent.

### D-UNITS-1

Live line 226 multiplies by `1 gwei` before the router call. The model
stays in gwei. Comparing `used` to on-chain `topUpLimits[i]` is a
`10^9` disagreement unless the harness converts.

### D-TOTAL-1

Solidity `totalLimits +=` sits in `unchecked` and gates
`_setLastTopUpData`. Model `used` is the leftover-consumed total, not
the sum of independent limits.

## Solidity-side finding

None. Independent per-key evaluation, overflow panic, slash/exit zero,
empty-array revert, role, sort, WC, pubkey, and max-validators match
`report/P-TOPUP-2.md`. The leftover walk is a model obligation, not a
pin bug. Thomas: no pin bug to escalate.

## Vectors

Nominal one-key gap; zero pending at exact minTopUp; empty arrays;
at-target zero limit (no `LastTopUpChanged`); overflow panic vs `none`;
slash flag (D-SLASH-1); unauthorized caller; duplicate indices; two-key
block cap leftover vs independent (D-CONSUME-1); wrong WC; bad pubkey;
max-validators; router failure after the evaluate loop; below-min zero;
pending shrinks gap; length mismatch; Solidity mutants (dropped
slash/exit, reversed batch write, wrong packed field as target).

## Recheck

```
bash scripts/test_topup2_source_differential.sh
lake build LidoSRv3.Audit.Verity.Topup2SourceEntry
FOUNDRY_PROFILE=topup2_source forge test --ffi --match-contract Topup2DifferentialTest -vv
```
