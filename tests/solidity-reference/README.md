# Solidity Reference Tests

These files are copied from Lido core at PR #1811 commit
`d088bbc2deac9913b68036d73d35c37aa6279b90` and are used as source-facing
reference material for the local Verity-style model tests.

The copied tests are limited to the SRv3 accounting surfaces mirrored in
`tests/verity/`:

- `deposits-reserve.integration.ts`
- `accounting-oracle-module-balances.integration.ts`
- `stakingRouter.getDepositAllocations.test.ts`
- `stakingRouter.rewards.test.ts`
- `stakingRouter.status-control.test.ts`

They are not run by this repository's `make test`; the executable mirror is the
standard-library Python suite under `tests/verity/`.
