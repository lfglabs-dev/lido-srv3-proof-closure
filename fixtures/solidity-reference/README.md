# Solidity Reference Fixtures

These are reference fixtures, not tests: nothing in this repository executes
them. They are copied from Lido core at PR #1811 commit
`af095e48bbc1c3841c2c9936219c8461af01056b` and are used as source-facing
reference material for the Verity/Lean model. (Originally vendored from
`d088bbc2deac9913b68036d73d35c37aa6279b90`; refreshed at the re-pin.)

Upstream paths at the pinned commit:

- `test/0.8.25/stakingRouter/stakingRouter.getDepositAllocations.test.ts`
- `test/0.8.25/stakingRouter/stakingRouter.rewards.test.ts`
- `test/0.8.25/stakingRouter/stakingRouter.status-control.test.ts`
- `test/integration/core/accounting-oracle-module-balances.integration.ts`
- `test/integration/core/deposits-reserve.integration.ts`

The copied fixtures are limited to the SRv3 accounting surfaces modeled in
`LidoSRv3/`:

- `deposits-reserve.integration.ts`
- `accounting-oracle-module-balances.integration.ts`
- `stakingRouter.getDepositAllocations.test.ts`
- `stakingRouter.rewards.test.ts`
- `stakingRouter.status-control.test.ts`

They are not run by this repository's `make test`, which only checks that all
five are present and non-empty. They are retained as Solidity-facing fixtures
for reviewers who want to compare the model against the original PR #1811 test
intent.
