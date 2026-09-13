# P-DEPOSIT-1 deployment provenance packet

Outcome: **(b), OPEN**. No reproducible deployed `StakingRouter` runtime or
constructor transaction is pinned by this repository at base
`2569cc0f34fc4aa2100bcaa765923c4e315ad5a4`.

## Available source pin

- Repository: `https://github.com/lidofinance/core.git`
- Commit: `17005714f151e5502c559932319a3f2f74ac2436`
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

Historical (pre-chantier-4) status: the repository contained no
StakingRouter runtime bytecode, runtime hash, deployment address, or
reference block, so:

- `A-DEPOSIT-CONTRACT` was OPEN.
- `A-DEPOSIT-32-ETHER` was OPEN.
- `PDeposit1.NFrame.LinksSource` remains caller-supplied.
- No stronger public parent is registered.

**Chantier 4 update (Thomas 2026-09-13):**

- `A-DEPOSIT-CONTRACT` is DISCHARGED via
  `scripts/verify_beacon_deposit_immutable.py` (invoked by `make test`)
  against fixture-anchored codehash
  `0x9cd5d45ddde5f74d3867aa22c98fd79a85df89d202145bc588173d92e00600ec`
  on `StakingRouter_implementation` at
  `0xDD76927045435C7605cf6f5F978cfb8CABDb5F80`; see
  `audit/artifacts.lock.json` and
  `audit/findings/A-TOPUP-BEACON-ADDRESS-and-A-DEPOSIT-CONTRACT-discharged.md`.
- `A-DEPOSIT-32-ETHER` is DISCHARGED via
  `scripts/verify_deposit_thirty_two_ether.py` (folds all five PUSH32
  sites at 32000000000000000000 wei = 32 ether); see
  `audit/findings/A-DEPOSIT-32-ETHER-discharged.md`.
- `PDeposit1.NFrame.LinksSource` remains caller-supplied.
- No stronger public parent is registered.

Reproduce the checked counterexample:

```sh
lake build LidoSRv3.Audit.Provenance.Deposit \
  LidoSRv3.Tests.PackGDepositProvenanceMutants
```
