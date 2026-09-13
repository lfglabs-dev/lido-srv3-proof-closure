# Verify it yourself

This guide shows how to rebuild the proofs, check the Solidity we refer to,
and compare it with the source published for the deployed contracts. Each
check covers part of that work. The remaining assumptions are listed below.

## Before you start

Use a clone with full Git history and follow the tool setup in
[README.md](README.md#reproduce). From the repository root, run:

```bash
git submodule update --init lido-core
```

The Solidity pin is `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`,
the commit used for `v4.0.0`. The source map in
[audit/source-map.yaml](audit/source-map.yaml) lists the files and lines in scope.

## Rebuild the proofs

```bash
lake build
lake build LidoSRv3Test LidoSRv3Audit
make prove
make test
```

These commands build the models, proofs and tests, inspect their axioms, and
run the repository checks. `make prove` also builds the legacy proof target
and records its results in `proofs/logs/proof-report.json`.

A successful build confirms the named Lean statements under their hypotheses.
The cards on `/lido` explain what each statement covers and what remains open.

## Check the cited Solidity

```bash
python3 scripts/check_pinned_source.py
```

This checks that the submodule and source map use the same pin, that the cited
line ranges exist, and how the pin relates to the `v4.0.0` tag. It prints any
contract changes between them.

Read the summary and any `fn?` or `ident?` warnings. These mean the script could
not confidently associate a function name with its cited lines. Add `--strict`
to make these warnings fail the check. Locating the lines does not prove that
the Lean model implements them correctly.

## Compare with the deployed contracts

```bash
python3 scripts/check_deployed_code.py
```

The script reads mainnet code and proxy implementations through an Ethereum
RPC, then compares source bundles from Sourcify with the pinned files. Set
`ETH_RPC_URL` to use your own node. Setting `ETHERSCAN_API_KEY` also enables
Etherscan source checks.

### Fixture codehash (EIP-1052 EXTCODEHASH)

The pinned deployed-runtime fixtures under `fixtures/deployed/` each carry
both a SHA-256 (fixture-bytes identity) and a keccak-256 codehash
(EIP-1052 EXTCODEHASH — what an on-chain `EXTCODEHASH <implementation>` call
returns) in `audit/artifacts.lock.json`. The three `verify_*_immutable.py`
scripts recompute keccak-256 of the fixture and reject any mismatch. With
`ETH_RPC_URL` set they also refetch the implementation runtime bytecode via
`eth_getCode` and re-verify both hashes.

Recorded codehash values (Thomas 2026-09-13):

- `WithdrawalVault_implementation` (`0xfB4521BD151BFB45DB6045D2d07e58e0f597e340`) —
  `keccak256 = d1e0d1b48e4f5abd04bdfd14805366f0cf7946b7bb41b7a5ad8652361f3e3d36`
- `StakingRouter_implementation` (`0xDD76927045435C7605cf6f5F978cfb8CABDb5F80`) —
  `keccak256 = 9cd5d45ddde5f74d3867aa22c98fd79a85df89d202145bc588173d92e00600ec`

These are the exact EIP-1052 EXTCODEHASH values that any Ethereum node returns
for the two implementations at any block where the code has not been upgraded.
They discharge the runtime-code identity strand of `A-RUNTIME-PROVENANCE`
down to "fixture bytes = mainnet runtime code, sha256 = X, codehash = H" for
those two contracts. Historical block-number binding is a separate follow-up.

The contract addresses are listed in the script and come from
[Lido's deployment documentation](https://docs.lido.fi/deployed-contracts).
The Curated Module v2 uses a separate repository, so only its on-chain code
and address checks apply. Package sources are compared only when available
in `lido-core/node_modules`.

Read the results as follows:

- `identical to pin`: the compared files match after normalising line endings.
- `comments/whitespace differ`: the comparison found only those differences.
- `CODE DIFFERS` or `MISMATCH`: a source or implementation difference needs review.
- `unchecked`: a check could not run, for example because a source record or network access was unavailable.

Exit code `0` means the performed checks passed, `1` means a check failed,
and `2` means checks remain incomplete without a reported failure.

The previously recorded comparison found a difference in `PausableUntil.sol`,
used by ConsolidationGateway: the pin adds the `IPausableUntil` interface
import and inheritance. The script flags this for review. It does not prove
that the difference is harmless. Run it again to check the current deployment.

Sourcify's `exact_match` and `match` describe its recompilation results, with
and without matching metadata respectively. These are third-party results.
The script's `--recompile` option prints instructions; it does not compile
the contracts or compare a local build with deployed bytecode.

## What remains assumed

These checks still rely on the Lean kernel, compiler, RPC, verification
services and the address documentation used. Recompiling locally can check
the services' results, but still relies on the compiler.

The checks do not establish full correspondence between the Lean models,
Solidity and deployed bytecode. Use the cards' **Proof boundary** sections and
the linked theorems to review that correspondence and its remaining gaps.
A contract appearing in the deployment script is not necessarily in proof scope.
