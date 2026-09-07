# Provenance: from the audited lines to the deployed bytecode

This page is for a Lido reviewer who does not want to trust this repository's authors.
It answers three questions, each with a script you run yourself, and it is explicit about
what the scripts do not establish.

| Question | Script | Needs |
| --- | --- | --- |
| (a) Are the Solidity lines cited by the audit exactly those of the pinned commit? | `python3 scripts/check_pinned_source.py` | git, the `lido-core` submodule |
| (b) Is the pinned commit what Lido shipped as `v4.0.0`? | same script, section 4 | the `v4.0.0` tag (fetched automatically) |
| (c) Does the mainnet bytecode correspond to that source? | `python3 scripts/check_deployed_code.py` | an Ethereum RPC; optionally `ETHERSCAN_API_KEY` |

Both scripts are Python 3 standard library only, contain no stored hashes or expected values
(everything is recomputed from the submodule, the chain and the verification services), and
print what they compare so the output can be read rather than trusted.

## The pin

* Repository: `lidofinance/core`
* Pinned commit: `17005714f151e5502c559932319a3f2f74ac2436`
* Release: tag `v4.0.0` (2026-07-24) points exactly at this commit.
* `audit/source-map.yaml` declares the pin once (`pinned_source`) and every source span in
  it carries a GitHub permalink to that commit.
* The `lido-core/` git submodule is checked out at the pin, so all paths in the audit can be
  opened locally: `git submodule update --init lido-core`.

Later releases: `v4.0.1` (2026-08-18) changed only `contracts/0.8.9/TokenRateNotifier.sol`
and two `ITokenRatePusher*` interfaces, which are outside the audited scope. Run
`git -C lido-core diff --stat v4.0.0 v4.0.1 -- contracts` to see it yourself.

## (a) and (b): `scripts/check_pinned_source.py`

```
python3 scripts/check_pinned_source.py            # about 0.3 s
python3 scripts/check_pinned_source.py --strict   # identifier heuristics become failures
```

Output, section by section:

1. **Pin consistency.** Prints the `pinned_source` of `audit/source-map.yaml`, the commit
   the submodule is checked out at, and the number of spans whose `source_sha` or
   `permalink` names another commit. All three must agree (`ok`, `0`).
2. **Source-map spans.** One line per span (96 today): guarantee id, `path:start-end`, a
   verdict and the first line of the span as read from `lido-core/`. The verdict is `ok`
   when the range exists; the parenthesis tells you whether the identifier named by the
   span (`getDepositAllocations`, `_refundFee`, ...) occurs inside the range, or is the
   enclosing declaration a few lines above (`declared at line N, encloses range`). A
   `(fn?)` means the label could not be tied to the lines and deserves a look.
3. **Inline citations.** Every `<File>.sol:<line>` or `<File>.sol:<a>-<b>` mentioned in
   `LidoSRv3/Audit/**/*.lean`, `report/*.md` and `diagram/README.md` (73 distinct
   citations today) is resolved to a unique file under `lido-core/contracts` and its line
   range must exist. When a backticked identifier precedes the citation on the same line,
   the identifier must occur in the range or be the enclosing declaration; otherwise the
   row reads `ident? ...` and is listed as a warning. A file that resolves to several
   basenames or a range beyond the end of file is a failure.
4. **Release link.** `v4.0.0` is resolved (fetched if needed) and the pin must be an
   ancestor of it, then `git diff --stat <pin> v4.0.0 -- contracts` is printed. Today the
   tag is the pin, so the diff is empty; if Lido ever re-tags, this section is where a
   difference would show up.

Exit code 0 means every hard check passed; 1 lists the mismatches under `Summary`; 2 means
the submodule or the source map is missing. Warnings (heuristic identifier association)
never change the exit code unless `--strict` is given: they are there so a human reads the
handful of rows where a comment cites a function by name while pointing at a single
statement inside it.

## (c): `scripts/check_deployed_code.py`

```
python3 scripts/check_deployed_code.py                          # RPC + Sourcify, no key
ETHERSCAN_API_KEY=... python3 scripts/check_deployed_code.py    # adds the Etherscan bundle
ETH_RPC_URL=http://localhost:8545 python3 scripts/check_deployed_code.py --recompile
```

The address table inside the script is copied from
<https://docs.lido.fi/deployed-contracts> and maps each audited contract to its file under
`lido-core/contracts`. Fifteen contracts are covered: StakingRouter, TopUpGateway,
ConsolidationGateway, ConsolidationBus, ConsolidationMigrator, WithdrawalVault, Accounting,
AccountingOracle, ValidatorsExitBusOracle, TriggerableWithdrawalsGateway, Lido,
DepositSecurityModule, WithdrawalQueueERC721, HashConsensus (AccountingOracle) and the
Curated Module v2.

**Step A, on-chain (always runs).** For each proxy the script reads the EIP-1967
implementation slot (`keccak256("eip1967.proxy.implementation") - 1`, printed at the top so
you can recompute it) with `eth_getStorageAt`. When the slot is empty (Lido is an Aragon
`AppProxyUpgradeable` proxy) the script calls `implementation()` instead and the `slot`
column says `aragon`. The resolved
implementation must equal the documented one (`ok` / `aragon` / `MISMATCH`); for
WithdrawalQueueERC721 the documentation gives no implementation, so the slot value is
printed `(from slot)`. Then `eth_getCode` fetches the runtime code of the implementation
(or of the contract itself when there is no proxy) and prints its size and `keccak256`,
computed by a pure-Python Keccak-f[1600] (self-tested against the standard test vectors;
`hashlib.sha3_256` would give a different value). Compare the hash with the deployed
bytecode shown by Etherscan, Sourcify, or your own node.

**Step B, verified source against the pin.** For every implementation the script asks
Sourcify (`https://sourcify.dev/server/v2/contract/1/<address>?fields=all`, no key) and,
when `ETHERSCAN_API_KEY` is set, Etherscan API v2
(`module=contract&action=getsourcecode&chainid=1`) for the verified source bundle, then
compares each in-repo file of the bundle (`contracts/**`) with the same path in
`lido-core/`. Files from `@openzeppelin` and other packages are only compared when
`lido-core/node_modules` is installed. Three verdicts:

* `identical to pin (N files)`: byte-identical after line-ending normalisation.
* `comments/whitespace differ in N file(s)` followed by `doc-only: <path>`: the two files are
  equal once comments and whitespace are stripped. Solidity comments and layout do not
  reach the runtime bytecode (only the metadata hash appended to it), so this is reported
  as a note, not a failure. It happens because several contracts were deployed from a
  commit other than the `v4.0.0` tag (comment fixes merged between the two)
  (for example `contracts/0.8.9/WithdrawalVault.sol` gained four `@param` lines, so its
  deployed source is offset by four lines relative to the pin: `WithdrawalVault.sol:81-85`
  in the audit is lines 77-81 on Etherscan).
* `CODE DIFFERS`: a token-level difference, printed as a unified diff excerpt and counted as
  a failure so that a human decides. Today there is exactly one:
  `contracts/common/utils/PausableUntil.sol`, pulled in by ConsolidationGateway, gained
  `import {IPausableUntil}` and `is IPausableUntil` in the pin (commit `695facd59`,
  2026-04-23, "enforce PausableUntil interface on inherited contracts") while the deployed
  ConsolidationGateway was compiled without it. Inheriting an interface whose functions the
  contract already implements adds no runtime code, and Sourcify reports a runtime `match`
  for that address, but the script does not pretend to know that: it fails and shows you
  the diff.

Sourcify's own verdict is printed as well: `exact_match` means Sourcify recompiled the
submitted source and obtained the deployed bytecode including the metadata hash; `match`
means everything except the metadata hash matched; `not found` means Sourcify has no
record (today: Accounting, AccountingOracle, ValidatorsExitBusOracle, which therefore need
the Etherscan path). The Curated Module v2 is built from a separate repository
(`src/CuratedModule.sol`, solc 0.8.33), so only step A applies to it.

**Step C, `--recompile`.** Prints whether `forge` and `npx` are available and what a full
reproduction would require: the exact solc versions and settings shown in step B (0.4.24,
0.8.9 and 0.8.25 are all involved), `yarn install --frozen-lockfile` and `yarn hardhat
compile` inside `lido-core`, then comparing `deployedBytecode` with the keccak256 from step
A. The script does not run that compilation.

Exit codes: 0 when every performed check passed; 1 when a performed check failed (a proxy
pointing elsewhere than documented, a token-level source difference); 2 when nothing
failed but some checks could not be performed (no network, no key, no Sourcify record).
The `Summary` lists every `note`, `unchecked` and `FAIL` line.

## What these checks do not establish

* **Compiler trust.** Source equality is not bytecode equality. Sourcify `exact_match` and
  Etherscan verification are recompilations performed by third parties; the `--recompile`
  step tells you how to do it yourself, which is the only way to remove that trust.
* **Verification-service trust.** Step B trusts Sourcify and Etherscan to serve the source
  they verified. Step A does not: the code hash comes straight from the RPC you choose
  (`ETH_RPC_URL`), and you can run it against your own node.
* **Documentation trust.** The address table is copied from Lido's documentation. If the
  documentation and the chain disagree, step A says `MISMATCH`; it cannot tell which one is
  right.
* **Model-to-source faithfulness.** The scripts prove that the cited lines exist and are the
  lines of the shipped commit. Whether the Lean model of each function is a faithful
  abstraction of those lines is established only by reading the Lean next to the Solidity:
  `LidoSRv3/Audit/Source/*Correspondence.lean` and the per-guarantee reports in `report/`
  are written for that reading, and `audit/source-map.yaml` gives the line ranges.
* **Scope.** Only the contracts and functions listed in `audit/source-map.yaml` are in
  scope. The Curated Module v2, the Aragon kernel and proxies, and the `contracts/upgrade/*`
  templates are not audited here even though some appear in the address table.

## Rebuilding the proofs

```
lake build                 # production library
lake build LidoSRv3Test    # mutants, vectors, nested Verity tests
make prove                 # builds LidoSRv3 and LidoSRv3Legacy, writes proofs/logs/proof-report.json
```

The Lean toolchain is pinned by `lean-toolchain` and `lake-manifest.json`; `make prove`
records the verified source tree and the Lean version in `proofs/logs/prove.txt`. Together
with the two scripts above, a reviewer holds the full chain: proofs that compile, over a
model whose cited lines exist in `lidofinance/core@17005714`, which is `v4.0.0`, whose
verified source matches the code running at the documented mainnet addresses up to the
differences printed by `check_deployed_code.py`.
