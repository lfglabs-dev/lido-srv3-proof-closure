# P-TOPUP-2 keccak memory-array oracle boundary

Additive lot on `grok/lido-topup-keccak-20260911`. No existing Lean, registry,
Trust, or import-DAG file is edited. Integration is a later agent’s job.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `8690e1b050c954ae9e3df2827a97cf3105e46bf7` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns topup-keccak-oracle since 2026-09-11

STATUS: claimed

## Obligation

`PTopup2.verity_tx_simulates_topup2_spec` decodes four memory arrays through
`Topup2DistributionTx.readArray`. That path is `evalExpr` of
`.memoryArrayElement`, a direct word-addressed memory read. It does not
evaluate `.keccak256` and does not call `DenoteOracle.keccakMemorySlice`.

The private stub `keccakMemorySlice := fun _ _ _ => 0` is therefore unused
by the registered parent. This lot proves that independence and exhibits
that two oracles which differ only on keccak still agree on every
`readArray` premise of the parent.

This is **not** a close of the named P-TOPUP-2 fidelity gap “keccak
memory-array oracle”. Solidity mapping-slot keccak and any `.keccak256`
expression remain unmodeled. `guarantees.yaml` is not edited.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/TopupKeccakOracle.lean` | Additive theorems |
| `LidoSRv3/Tests/TopupKeccakOracleMutants.lean` | Witnesses and kill-lines |
| `audit/topup-keccak-oracle/README.md` | This note |

## Out of scope

- Live wei conversion, `allocateDeposits` policy, A-TOPUP-BEACON-ADDRESS
- Bytecode, gas, deployed LidoLocator
- Editing `Topup2DistributionTx`, `PTopup2Verity`, or `guarantees.yaml`
- Claiming keccak correspondence or replacing the stub with a real hash
