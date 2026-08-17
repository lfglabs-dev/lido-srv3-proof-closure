# P-TOPUP-2 headroom/budget correspondence

Pin: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.
Slice: `TopUpGateway.topUp` 160–237, `_evaluateTopUpLimit` 396–415,
`CLValidatorVerifier._verifyValidator` 44–57.

## Checked

The Lean MODEL keeps the exit/slash return, target-reached return, strict
`gap < minTopUpGwei` test, accepted gap, left-to-right headroom cap, and
aggregate budget after checked addition succeeds.

The source reverts when `effectiveBalance + pendingBalanceGwei` overflows
uint256. The Nat model does not. Parent SOURCE and TX stay OPEN.

The Verity contract uses packed `UIntN` at the ERC-7201 base and runs masked
setters plus a synthetic budget transaction through `.run`. `recordBudget` is
not the pinned `topUp` batch.

## Open

No source theorem covers: empty/aligned batches, length cap, strict validator
index order, `TOP_UP_ROLE`, pause, block-distance/root-age, type-0x02
credentials, pubkey length, activation, call order, or linked StakingRouter
summaries.

Validator proof acceptance is not assumed. EIP-4788 `BEACON_ROOTS`, GIndex/SSZ,
and SHA-256 stay separate. Yul, bytecode, and EVM stay OPEN.

A separate gate matches the pinned Solidity artifact to TopUpGateway runtime
at mainnet block 25,730,798. That is not Solidity-to-Verity correspondence.

## Layout method

`_gatewayStorage` sets its slot in assembly, so standard `storageLayout` omits
the namespaced struct. The gate compiles pinned 0.8.25 source (optimizer 200,
via-IR, Cancun), reads `Storage` member order and widths from the solc AST,
and checks the ERC-7201 base literal. Compare
`audit/p-topup-2-layout-comparison.json` via `scripts/check_p_topup2_layout.sh`.
Do not trust the committed `matches` bit. An empty direct layout is a finding,
not proof of no storage.

## Optional mainnet runtime gate

`audit/p-topup-2-runtime-provenance.json` pins blobs, compiler settings,
constructor args, proxy/implementation, EIP-1967 slot, block, runtime length,
and code hash.

```sh
LIDO_CORE_DIR=../lido-core MAINNET_RPC_URL="$YOUR_MAINNET_RPC" \
  make p-topup2-runtime-provenance
```

The script rebuilds the pinned sources, deploys locally, and compares local
and mainnet runtime. No RPC → `SKIPPED_NO_RPC`, exit 2.
