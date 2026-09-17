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

Step 1c (Thomas 2026-09-17) extends the same fixture pattern to the rest of
the SRv3 pipeline in `fixtures/deployed/srv3-identities.json`, verified by
`scripts/verify_srv3_identities.py` (a `make test` target; with `ETH_RPC_URL`
it also re-reads the proxies, `StakingRouter.getStakingModules()`, the locator
getters and `AccountingOracle.getConsensusContract()` on the live chain):

- the link map of the StakingRouter implementation: `SRLib`
  (`0xc0be9942fd8f54ab126a5f0ba649a90049ccad14`, codehash
  `229241c1e92c1e6637f8d725f96dd1d28d9b4847376dd7c94644ba5075278e64`, 21
  PUSH20 sites) and `BeaconChainDepositor`
  (`0xf98ac162eab766bdb9507c3584c00c535b8f6216`, codehash
  `6797d364cb1333d35eee131f2ad344d9617e3df82be294c8a87bc400801cfbb9`, 3 sites),
  and the `MinFirstAllocationStrategy` library linked into SRLib
  (`0x98f1da239a199574a4f7f371fd8fc0a872022c73`, codehash
  `6b5903d7b3609cfd3640a078471331f0b0f6effb5eade6d5f56e99fced33dca0`, 1 site);
- the four registered staking modules and their implementations:
  NodeOperatorsRegistry (id 1) and SimpleDVT (id 2) share
  `0x6828b023e737f96b168acd0b5c6351971a4f81ae` (codehash
  `125bca109785e7910597ce9cd368ae9ba26d62b245adaecce6a84a6934df9e4b`), CSModule
  (id 3) `0x63992a86f009fcc796a8369feefb68880aef4e3a` (codehash
  `ad8440167e7f77ee8608b98317881e8e0a5af0698a0bd1bcdc9b0eaebd22a55b`),
  CuratedModuleV2 (id 4) `0x959fc67fe53c8a6c7a1aed73430aa07a36ed9337` (codehash
  `f7bc4da51d6f2f0f1394fd0bd084feaf2bde68a4dcb00d5354d679761c9c0560`);
- the LidoLocator implementation `0xf2ffb952e129a63f0614ff87126e1d4a494a2313`
  (codehash `d6f9c11ca7f1480827784165c28b406960050a4b21267d3efcfc9852b786d9ce`)
  and, through its getters, the WithdrawalQueueERC721 implementation
  `0xe42c659dc09109566720ea8b2de186c2be7d94d9` (codehash
  `7606999c03ae51ffb1d29b8b80a0d0cf85912f32f088ba1a52c45df312c36e64`), the
  AccountingOracle implementation `0xe4f03d1107d1905b6f2a28fcb6af221e0ce19136`
  (codehash `f8312f2b0c6973525ea0fd0b38d6b1a98afcfe214babd614498648fc254cef20`)
  and its HashConsensus `0xd624b08c83baecf0807dd2c6880c3154a5f0b288` (codehash
  `6ea7bf85038c3fffa4b909373e773cd899ee4278c582ea3c1d6524b35a69dfa4`).

All values were read at mainnet block 25997829 and are block-independent while
the code is not upgraded. CSModule and CuratedModuleV2 are built outside
`lidofinance/core`, so only their address and codehash identity is recorded.

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
