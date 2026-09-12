# P-ACCOUNT-1 packed uint64 accounting words

Additive lot on `grok/lido-account-packed-20260912`. No existing Lean, registry,
Trust, or import-DAG file is edited. Integration is a later Spark agent’s job.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `93e103d453e655febb59c82778a1da92761460b3` |
| CLAIM commit | *(this commit)* |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns account-packed-words since 2026-09-12

STATUS: claimed — proofs in progress

## Obligation

`audit/guarantees.yaml` P-ACCOUNT-1 `fidelity.missing`:

> packed uint64 accounting words

The registered parent `handleOracleReport` persists balances through
`persistBalances` = `writeArray moduleBalancesSlot (bals.map ofNat)`
(`HandleOracleReportTx` 162–164) and the router total through
`writeSlot totalBalanceSlot total` (line 252). `observe` (282–287) reads
those same slots back as `.val`. Live Solidity writes
`ModuleStateAccounting.validatorsBalanceGwei` / `RouterStateAccounting.validatorsBalanceGwei`
as packed `uint64` fields (`SRTypes.sol:157–172`, `SRLib.sol:884–891`).

This lot models the exact pack/unpack of those words, proves the parent’s
committed reads/writes factor through that packing, and kills width/offset
mutants.

## Gate

```
lake build LidoSRv3.Audit.Source.AccountPackedWords
lake build LidoSRv3.Tests.AccountPackedWordsMutants
lake build LidoSRv3Test
lake env lean LidoSRv3/Audit/Source/AccountPackedWords.lean
lake env lean LidoSRv3/Tests/AccountPackedWordsMutants.lean
```
