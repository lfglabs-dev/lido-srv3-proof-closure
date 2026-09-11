# P-TOPUP-2 keccak memory-array oracle boundary

Additive lot on `grok/lido-topup-keccak-20260911`. No existing Lean, registry,
Trust, or import-DAG file is edited. Integration is a later agent’s job.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `8690e1b050c954ae9e3df2827a97cf3105e46bf7` |
| CLAIM commit | `066ae7eac38aa4085651f5b620833f7891d8693c` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns topup-keccak-oracle since 2026-09-11

STATUS: ready

## Obligation

`PTopup2.verity_tx_simulates_topup2_spec` decodes four memory arrays through
`Topup2DistributionTx.readArray`. That path is `evalExpr` of
`.memoryArrayElement`, a direct word-addressed memory read
(`Verity.Core.Model.Denote` 634–640). It does not evaluate `.keccak256` and
does not call `DenoteOracle.keccakMemorySlice`. The keccak hook is used only
by `.keccak256` (`Denote` 991–994).

The private stub `keccakMemorySlice := fun _ _ _ => 0` is therefore unused
by the registered parent. This lot proves that independence and exhibits
that two oracles which differ only on keccak still agree on every
`readArray` premise of the parent.

This is the same boundary ALLOC-2 already recorded for
`MinFirstDistributionTx.memory_array_read_is_oracle_independent`, now
stated for the P-TOPUP-2 public parent.

This is **not** a close of the named P-TOPUP-2 fidelity gap “keccak
memory-array oracle”. Solidity mapping-slot keccak and any `.keccak256`
expression remain unmodeled. `guarantees.yaml` is not edited.

## Theorems

| Theorem | Claim |
| --- | --- |
| `memory_array_read_is_oracle_independent` | Two `DenoteOracle`s agree on every `readWordWith` / `memoryArrayElement` observation. |
| `read_array_with_is_oracle_independent` | Same for `readArrayWith`. |
| `readWord_eq_readWordWith` / `readArray_eq_readArrayWith` | Public `Topup2DistributionTx.readWord` / `readArray` equal the same lookup under an *arbitrary* oracle. The private stub is not a hidden keccak premise. |
| `evalKeccak_eq` | `.keccak256` is exactly `oracle.keccakMemorySlice` on the normalized offset/size. |
| `zero_and_nonzero_disagree_on_keccak` | The two stubs (keccak = 0 vs 1) disagree on every `.keccak256`. |
| `memory_array_agreement_does_not_imply_keccak_agreement` | Kill-line: agreement on every `memoryArrayElement` ⇏ agreement on `.keccak256`. |
| `verity_tx_simulates_topup2_spec_any_oracle` | The registered parent restated with an arbitrary oracle on the four decode premises. Equivalent, not a close of keccak correspondence. |

## Mutants

Same two-validator `stateFor` batch as `Topup2DistributionTxMutants` happy path
(`[32,40] / [0,0] / [6,8] / [32,24]`).

| Theorem | Claim |
| --- | --- |
| `sample_readArray_*` | Public `readArray` recovers each `stateFor` column. |
| `sample_readArray_independent_of_keccak` | Both stubs recover every parent decode. |
| `sample_keccak_disagrees` | On that same state, keccak still disagrees. |
| `sample_parent_holds` | `verity_tx_simulates_topup2_spec` fires (observe = sourceView). |
| `sample_parent_any_oracle_nonzero` | Same conclusion through the oracle-quantified restatement at keccak = 1. |
| `parent_readArray_premises_do_not_constrain_keccak` | Kill-line: the four `readArray` premises do not force the two keccak hooks to agree. |

## Hypotheses

- The four `readArray` / `readArrayWith` success premises already required by
  `verity_tx_simulates_topup2_spec`, plus equal lengths and `count ≤ 32`.
- Interval / mapping-slot keccak is not in this model. `memoryArrayElement`
  reads `state.memory (wordNormalize (dataOffset + 32 * idx))`.
- `.keccak256` remains an unconstrained oracle hook.

## Axioms

Source exports: `propext` / `Quot.sound` on the independence lemmas;
`propext` only on the keccak / kill-line pair; `propext` / `Classical.choice` /
`Quot.sound` on the parent restatement (inherited from
`verity_tx_simulates_topup2_spec`). No `sorryAx`.

Mutants additionally use `native_decide` for the concrete `stateFor` decodes,
same as `Topup2DistributionTxMutants`.

## Gate

```
lake build LidoSRv3.Audit.Source.TopupKeccakOracle
lake build LidoSRv3.Tests.TopupKeccakOracleMutants
lake env lean LidoSRv3/Audit/Source/TopupKeccakOracle.lean
lake env lean LidoSRv3/Tests/TopupKeccakOracleMutants.lean
```

## Out of scope / still open

- Live wei conversion, `allocateDeposits` policy, A-TOPUP-BEACON-ADDRESS
- Bytecode, gas, deployed LidoLocator
- Editing `Topup2DistributionTx`, `PTopup2Verity`, or `guarantees.yaml`
- Claiming keccak correspondence or replacing the stub with a real hash
- `returnBuffer` origin on the public `run` (still a phase input;
  `TopupRouterLocatorCall` forwards it unchanged)
- Named P-TOPUP-2 gaps that this lot does not touch: `_verifyValidator`,
  0x02 module WC, block-distance, same-block accumulation, withdraw /
  makeBeaconChainTopUp, gwei vs wei, 48-byte pubkeys, pendingBalanceGwei
  as trusted calldata
