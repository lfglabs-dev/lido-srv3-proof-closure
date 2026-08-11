# P-TOPUP-2 headroom/budget correspondence

Pinned source: `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`.
The checked slice is `TopUpGateway.topUp` lines 160--237,
`_evaluateTopUpLimit` lines 396--415, and the call boundary at
`CLValidatorVerifier._verifyValidator` lines 44--57.

## Closed slice

The Lean source transcription preserves the exit/slash early return, checked
`effectiveBalance + pendingBalanceGwei`, target-reached return, checked target
subtraction, strict `gap < minTopUpGwei` threshold, accepted gap, left-to-right
headroom capping, and aggregate block/module budget. The Verity contract uses
#2249 `UIntN` packed lowering at the exact ERC-7201 base and executes masked
setters/readers plus a fail-closed aggregate budget transaction through `.run`.

## Explicit boundaries

The source theorem assumes the earlier guards retain their pinned behavior:
batch non-emptiness and aligned lengths, length cap, strict validator-index
order, TOP_UP_ROLE, resumed state, block-distance/root-age checks, type-0x02
withdrawal credentials, pubkey length, activation, and call ordering. It also
assumes linked StakingRouter summaries. Validator proof acceptance is not a
premise silently converted into truth: EIP-4788 `BEACON_ROOTS` behavior at
`0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02`, GIndex/SSZ binding, and the
SHA-256 oracle remain separate assumptions. Generated Yul, solc Yul-to-bytecode,
EVM/runtime equivalence, and optional deployed-bytecode provenance remain OPEN.
P-SSZ-1 and EVM/runtime are not closed.

## Solidity layout method

Solidity standard `storageLayout` does not list this namespaced struct as a
normal state variable because `_gatewayStorage` assigns its slot in assembly.
The experimental gate therefore compiles the pinned 0.8.25 source with its
Foundry settings (optimizer 200, via-IR, Cancun), extracts the `Storage`
definition/member order and elementary widths from the solc AST/types, and
independently asserts the literal ERC-7201 base from the source. The comparison
receipt matches those derived base/word/bit offsets against
`GatewayPackedContract.spec.fields`.

The committed machine evidence is
`audit/p-topup-2-pinned-storage-ast.json` plus
`audit/p-topup-2-layout-comparison.json`; `scripts/check_p_topup2_layout.sh`
recompiles the exact pinned checkout and checks these records. The empty direct
storage layout is recorded as a finding, not treated as evidence of no storage.
