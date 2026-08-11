# P-TOPUP-2 headroom/budget correspondence

Pinned source: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.
The checked slice is `TopUpGateway.topUp` lines 160--237,
`_evaluateTopUpLimit` lines 396--415, and the call boundary at
`CLValidatorVerifier._verifyValidator` lines 44--57.

## Checked and open slices

The Lean MODEL preserves the exit/slash early return, target-reached return,
strict `gap < minTopUpGwei` threshold, accepted gap, left-to-right headroom
capping, and aggregate block/module budget after the Solidity checked addition
has succeeded. The pinned source reverts when `effectiveBalance +
pendingBalanceGwei` overflows uint256; that rollback is not represented in the
Nat model. The Verity contract uses #2249 `UIntN` packed lowering at the exact
ERC-7201 base and executes masked setters/readers plus a synthetic fail-closed
budget transaction through `.run`. `recordBudget` is not connected to the
pinned `topUp` batch transition or post-state. Parent SOURCE and TX therefore
remain OPEN.

## Explicit boundaries

No source theorem connects the earlier guards and full execution:
batch non-emptiness and aligned lengths, length cap, strict validator-index
order, TOP_UP_ROLE, resumed state, block-distance/root-age checks, type-0x02
withdrawal credentials, pubkey length, activation, and call ordering. It also
assumes linked StakingRouter summaries. Validator proof acceptance is not a
premise silently converted into truth: EIP-4788 `BEACON_ROOTS` behavior at
`0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02`, GIndex/SSZ binding, and the
SHA-256 oracle remain separate assumptions. Generated Yul, solc Yul-to-bytecode,
and EVM semantic equivalence remain OPEN. A separate reproducible gate closes
identity between the pinned Solidity build artifact and the exact deployed
TopUpGateway runtime at mainnet block 25,730,798; it does not establish
Solidity-to-Verity correspondence or Verity model refinement. P-SSZ-1 and
EVM/runtime semantics are not closed.

## Solidity layout method

Solidity standard `storageLayout` does not list this namespaced struct as a
normal state variable because `_gatewayStorage` assigns its slot in assembly.
The experimental gate therefore compiles the pinned 0.8.25 source with its
Foundry settings (optimizer 200, via-IR, Cancun), extracts the `Storage`
definition/member order and elementary widths from the solc AST/types, and
independently asserts the literal ERC-7201 base from the source. The comparison
receipt matches those derived base/word/bit offsets against
`GatewayPackedContract.spec.fields`.

The committed comparison target is
`audit/p-topup-2-layout-comparison.json`; `scripts/check_p_topup2_layout.sh`
recompiles the exact pinned checkout with AST output, locates the compiled
`Storage` declaration, recomputes packing offsets from its types, extracts the
ERC-7201 literal from pinned source, and compares every derived field. The
committed `matches` boolean is not trusted. The empty direct storage layout is
recorded as a finding, not treated as evidence of no storage.

## Optional mainnet runtime-provenance gate

`audit/p-topup-2-runtime-provenance.json` pins the five source blobs shared by
the audited commit and `v4.0.0`, compiler settings, constructor arguments,
proxy/implementation addresses, EIP-1967 slot, reference block, runtime length,
and code hash. Run:

```sh
LIDO_CORE_DIR=../lido-core MAINNET_RPC_URL="$YOUR_MAINNET_RPC" \
  make p-topup2-runtime-provenance
```

The script rebuilds all 478 Solidity sources with the repository Hardhat
configuration, deploys the exact constructor locally, and compares local and
mainnet runtime bytes. It also checks `chainId == 1` and reads the proxy slot and
implementation code at block 25,730,798. No credential is embedded. With no
`MAINNET_RPC_URL`, local reconstruction still runs, but the script explicitly
reports `SKIPPED_NO_RPC` and exits 2; absence cannot appear as a green live gate.
