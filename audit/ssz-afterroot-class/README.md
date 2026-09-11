# SSZ-1 compiled afterRoot error classification

Additive lot on `grok/lido-ssz-afterroot-class-20260911` from current
`origin/main`. No existing Lean, registry, Trust, or import-DAG file is
edited.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `ea8e546cedba3c1bbf306eee1a059cdba19eeaca` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns ssz-afterroot-class since 2026-09-11

STATUS: claimed

## Obligation

`afterRoot` (IR 116-417) is the unique divergence after the compiled
prefix `beforeRoot` / `rootCall`. This lot classifies its error
constructors (`.reply`, `.abi`, `.gindex`, `.allocation`, `.bls`,
`.proof`) against the Solidity/IR sites they reflect, and kills a
named line per class. EIP-4788 authenticity stays declared.
Compilation, crypto, gas and consensus stay outside.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/SszCompiledAfterRootClass.lean` | Additive theorems |
| `LidoSRv3/Tests/SszCompiledAfterRootClassMutants.lean` | Named kill-lines |
| `audit/ssz-afterroot-class/README.md` | This note |
