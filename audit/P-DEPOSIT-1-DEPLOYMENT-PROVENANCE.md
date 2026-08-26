# P-DEPOSIT-1 deployment provenance packet

Outcome: **(b), OPEN**. No reproducible deployed `StakingRouter` runtime or
constructor transaction is pinned by this repository at base
`2569cc0f34fc4aa2100bcaa765923c4e315ad5a4`.

## Available source pin

- Repository: `https://github.com/lidofinance/core.git`
- Commit: `af095e48bbc1c3841c2c9936219c8461af01056b`
- `contracts/0.8.25/sr/StakingRouter.sol` blob:
  `b37af8bfc2948f0edd3f80738e2558a90a222093`
- `contracts/0.8.25/lib/BeaconChainDepositor.sol` blob:
  `dd8ce7ca757a7195b40ce25c396db90c3110baa1`

The source proves only that `BeaconChainDepositor.DEPOSIT_SIZE` is the literal
`32 ether`. The router constructor checks `_depositContract != 0` and
`_maxEBType1 != 0`, then assigns those inputs directly to `DEPOSIT_CONTRACT`
and `MAX_EFFECTIVE_BALANCE_WC_TYPE_01`. It does not enforce the canonical
beacon deposit address or equality with `DEPOSIT_SIZE`.

The exact `StakingRouter.sol` L88--L106 source slice is vendored at
`fixtures/solidity-reference/StakingRouter.constructor.L88-L106.sol`.
`scripts/audit_metadata.py` checks its pinned SHA-256, the complete constructor
guard sequence, the two relevant guards, and their direct immutable bindings;
`audit/source-map.yaml` pins the same immutable source span.

`Deposit.openAssumptionsCounterexample` is the checked source-level negative
control: nonzero constructor inputs `0xDEAD` and `64 ether` satisfy the pinned
constructor guards while violating both desired identities. It is deliberately
not described as deployed.

## Missing deployment evidence

The repository contains no StakingRouter runtime bytecode, runtime hash,
deployment address plus reference block, creation transaction, or decoded
constructor arguments. Accordingly:

- `A-DEPOSIT-CONTRACT` remains OPEN.
- `A-DEPOSIT-32-ETHER` remains OPEN.
- `PDeposit1.NFrame.LinksSource` remains caller-supplied.
- No stronger public parent is registered.

Reproduce the checked counterexample:

```sh
lake build LidoSRv3.Audit.Provenance.Deposit \
  LidoSRv3.Tests.PackGDepositProvenanceMutants
```
