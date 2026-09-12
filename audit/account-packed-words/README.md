# P-ACCOUNT-1 packed uint64 accounting words

Additive lot on `grok/lido-account-packed-20260912`. No existing Lean, registry,
Trust, or import-DAG file is edited. Integration is a later Spark agent’s job.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `93e103d453e655febb59c82778a1da92761460b3` |
| CLAIM commit | `683ea5e4e3833710ab68026f584615da8021a5b3` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns account-packed-words since 2026-09-12

STATUS: ready — targeted `fidelity.missing` entry is closed (Spark applies the yaml diff below)

## Obligation

`audit/guarantees.yaml` P-ACCOUNT-1 `fidelity.missing`:

> packed uint64 accounting words

Closed. The registered parent `handleOracleReport` persists balances through
`persistBalances` = `writeArray moduleBalancesSlot (bals.map ofNat)`
(`HandleOracleReportTx` 162–164, citing `SRLib.sol:886`) and the router total
through `writeSlot totalBalanceSlot total` (line 252, citing `SRLib.sol:891`).
`observe` (282–287) reads those same slots back as `.val`.

This lot models the exact pack/unpack of `ModuleStateAccounting`
(`SRTypes.sol:157-164`) and `RouterStateAccounting` (`SRTypes.sol:166-172`),
proves the parent’s committed reads/writes factor through that packing, and
kills width/offset mutants.

## Theorems

| Theorem | Claim | Solidity / IR |
| --- | --- | --- |
| `unpack_pack_module` / `pack_unpack_module` | Exact inverses on the declared field widths | `SRTypes.sol:157-164` |
| `unpack_pack_router` / `pack_unpack_router` | Exact inverses on the router word | `SRTypes.sol:166-172` |
| `uint64Cast_eq_of_le_max` | `uint64(x) = x` on `x ≤ MAX_VALUE_GWEI` | `SRLib.sol:884`, `SRUtils.sol:23` |
| `writeLow64_sets_balance` | Field write sets bits 0..63 to the cast | `SRLib.sol:886`, `891` |
| `writeLow64_preserves_exited` / `_reserved` | Field write preserves bits 64+ | `SRTypes.sol:161-163` |
| `ofNat_eq_pack_zero` / `ofNat_eq_writeLow64_zero` | Parent `ofNat b` is `pack ⟨b, 0, 0⟩` = field write on the zero word | `HandleOracleReportTx` 164 |
| `persistBalances_writes_packed_zero` | Parent array words are `ofNat (pack ⟨b, 0, 0⟩)` | `HandleOracleReportTx` 162–164 / `SRLib.sol:886` |
| `persistBalances_getter_recovers` | `getStakingModuleStateAccounting` recovers each balance | `StakingRouter.sol:396-403` |
| `writeSlot_total_is_packed_router` | Parent total slot is `packRouter ⟨total, 0⟩` | `HandleOracleReportTx` 252 / `SRLib.sol:891` |
| `observe_balances_eq_unpacked_module_words` | Parent `observe.balances` unpacks the stored module words | `HandleOracleReportTx` 284 |
| `observe_total_eq_unpacked_router_word` | Parent `observe.total` unpacks `totalBalanceSlot` | `HandleOracleReportTx` 285 / `StakingRouter.sol:819` |
| `committed_module_words_are_packed_zero` | On a committed parent run the stored values are `pack ⟨b, 0, 0⟩` | `handleOracleReport` success |
| `parent_observe_eq_sourceView` | Citation of the registered Verity parent | `PAccount1.verity_tx_simulates_oracle_report` |

## Mutants

| Theorem | Claim |
| --- | --- |
| `width32_misses_parent_balance` | A `uint32` decode of the parent word `ofNat (2^32+1)` is `1`, not the balance |
| `offset64_disagrees_parent_ofNat` | Writing the balance at bits 64..127 disagrees with parent `ofNat` |
| `offset64_lands_in_exited` | That offset write lands in `exitedValidatorsCount` |
| `parent_ofNat_clobbers_exited` | Source field write preserves nonzero exited; parent `ofNat` forces exited = 0 |
| `raw_ofNat_past_uint64_is_not_source_pack` | Skipping `SRLib.sol:884` `uint64` cast, `ofNat (2^64+1)` is not `pack ⟨1, 0, 0⟩` |
| `sample_*` | Happy-path `[10, 20]` / total `30` witness; width/offset kill-lines on that layout |

## Hypotheses

- Committed parent admission: `idsAndBalancesValid` (`balances ≤ MAX_VALUE_GWEI < 2^64`) and `checkedTotal64` (`total ≤ uint64Max`). Under those, the `uint64` cast is the identity, so parent `ofNat` equals `pack ⟨b, 0, 0⟩`.
- Parent storage is the isolated `writeArray` / `writeSlot` projection (`moduleBalancesSlot` 10, `totalBalanceSlot` 11). There is no live neighboring `exitedValidatorsCount` in that array: the packed exited field of a parent write is the zero default.
- `writeLow64` is the source-shaped field assignment. It coincides with the parent write iff the preexisting word is zero. That is proved, not assumed away.
- No keccak of `moduleStates` keys. No EVM / bytecode / deployment claim.

## Axioms

Source exports: `propext` / `Quot.sound`, and `Classical.choice` on the pack-inverse and persist/getter lemmas. No `sorryAx`.

Mutant kill-lines: `propext` / `Quot.sound` / `Classical.choice`. Sample `native_decide` witnesses use the same native-decide axiom family as `HandleOracleReportTxMutants`.

## Gate

```
lake build LidoSRv3.Audit.Source.AccountPackedWords
lake build LidoSRv3.Tests.AccountPackedWordsMutants
lake build LidoSRv3Test
lake env lean LidoSRv3/Audit/Source/AccountPackedWords.lean
lake env lean LidoSRv3/Tests/AccountPackedWordsMutants.lean
```

## Spark registry diff (do not apply in this lot)

In `audit/guarantees.yaml` P-ACCOUNT-1:

Remove from `fidelity.missing`:

```
"packed uint64 accounting words"
```

Add to `fidelity.covered`:

```
"packed uint64 ModuleStateAccounting / RouterStateAccounting words: parent persistBalances / writeSlot are pack(uint64Cast, 0) on the admission domain; observe unpacks the low uint64; getStakingModuleStateAccounting recovers the balance; source field-write preserves bits 64+; width/offset mutants"
```

Do not edit Trust. Do not widen the registered parent. Decrement the README fidelity-gap count for P-ACCOUNT-1 from 7 to 6 when this diff is applied.

## Out of scope / still open

- `sharesToMintAsFees` remains an argument (next menu item)
- SRStorage membership / unique uint24 module ids
- `accountingOracle` caller and `REPORT_EXITED_VALIDATORS_ROLE`
- `submitReportData` / `_handleConsensusReportData`
- Re-read of the written router snapshot for rewards
- Full live-report success
- Parent storage stays an isolated array: preexisting `exitedValidatorsCount` is the zero default, not a live neighboring field in the same slot. `parent_ofNat_clobbers_exited` records that residual; it is not the targeted entry
- Bytecode, gas, deployed locator
