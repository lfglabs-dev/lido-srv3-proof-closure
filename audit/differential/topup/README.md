# TOPUP-1 Solidity ↔ Verity differential

CLAIM: grok owns lido-differential-topup-1 since 2026-09-12

Pinned Solidity `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Registered parent exposed: `TopupTx.execute`.

## Status

BLOCKED: model divergence

The harness is green. Conservation on a gwei-aligned conserving path agrees.
`TopupTx.execute` is the allocation-suffix transaction: it does not model
authorization, WC type 2, empty-key validation, or the `allocateDeposits`
frame.

## Divergences (model obligations)

Existing proof files were not edited.

### D-CALL-1 — journal prefix

Pinned `topUp` journals `allocateDeposits` then `withdrawDepositableEther`
then per-key `deposit`. `TopupTx.execute` starts after the module call.

Obligation: expose `executeGuarded` (or extend `execute`) so the module
frame is part of the compared journal.

### D-AUTH-1 / D-WC-1 / D-EMPTY-1

`NotAuthorized()`, `WrongWithdrawalCredentialsType()`, and `EmptyKeysList()`
are source guards. `execute` has none of them: an empty allocation list is
an empty commit, and there is no caller / WC bit.

Obligation: run the `:686-718` prefix in the CLI parent, not only the
`:722-756` suffix.

### D-ADDR-1

Model Lido/beacon addresses are pins (`0xF00D`, canonical deposit). The
harness deploys mocks. Target equality is not claimed.

## Solidity-side finding

None on a conserving gwei-aligned path. The line-755 assert is reached
only when pulled ≠ pushed; gwei alignment plus `DEPOSIT_SIZE`/`value`
equality keep a nominal top-up conserving. Thomas: no pin bug to escalate.

## Vectors

Nominal 2 ETH one-key top-up; zero allocation empty commit; empty keys;
unauthorized caller; paused module; bad pubkey; array length mismatch;
allocation above limit; exact cap; zero-skip then push; model-only
unchecked wrap; duplicate pubkeys; module failure; Lido failure after
allocate; Solidity mutants (dropped assert, reversed pull/push, extra
slot write).

## Recheck

```
bash scripts/test_topup_source_differential.sh
lake build LidoSRv3.Audit.Verity.TopupSourceEntry
FOUNDRY_PROFILE=topup_source forge test --ffi --match-contract TopupDifferentialTest -vv
```
