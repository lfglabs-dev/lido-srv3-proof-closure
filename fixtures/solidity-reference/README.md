# Solidity reference fixtures

These files are copies, not tests. This repo does not run them.

Source: Lido core v4.0.0 (PR #1811 merged 2026-07-24) commit
`17005714f151e5502c559932319a3f2f74ac2436`.

Upstream paths:

- `test/0.8.25/stakingRouter/stakingRouter.getDepositAllocations.test.ts`
- `test/0.8.25/stakingRouter/stakingRouter.rewards.test.ts`
- `test/0.8.25/stakingRouter/stakingRouter.status-control.test.ts`
- `test/integration/core/accounting-oracle-module-balances.integration.ts`
- `test/integration/core/deposits-reserve.integration.ts`

`make test` only checks that all five files exist and are non-empty.
Compare them to the Lean model when you need the original test intent.
