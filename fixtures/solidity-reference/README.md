# Solidity reference fixtures

These files are copies, not tests. This repo does not run them.

Source: Lido core PR #1811 commit
`af095e48bbc1c3841c2c9936219c8461af01056b`.

Upstream paths:

- `test/0.8.25/stakingRouter/stakingRouter.getDepositAllocations.test.ts`
- `test/0.8.25/stakingRouter/stakingRouter.rewards.test.ts`
- `test/0.8.25/stakingRouter/stakingRouter.status-control.test.ts`
- `test/integration/core/accounting-oracle-module-balances.integration.ts`
- `test/integration/core/deposits-reserve.integration.ts`

`make test` only checks that all five files exist and are non-empty.
Compare them to the Lean model when you need the original test intent.
