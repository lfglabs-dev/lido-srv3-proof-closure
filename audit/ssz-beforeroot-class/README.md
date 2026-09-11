# SSZ-1 compiled beforeRoot / rootCall error classification

Additive lot on `grok/lido-ssz-beforeroot-class-20260911` from current
`origin/main`. No existing Lean, registry, Trust, or import-DAG file is
edited.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `0391c430644b0987bebac105d890ca636e2aef8b` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |

CLAIM: grok owns ssz-beforeroot-class since 2026-09-11

STATUS: claimed

## Obligation

Classify errors of the compiled prefix `beforeRoot` (IR 43-100),
`slotSibling` (IR 70-97) and `rootCall` (IR 101-114), and partition
`run` failures by phase. Disjoint from the afterRoot-class and
compiled-rollback lots. EIP-4788 authenticity stays declared.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/SszCompiledBeforeRootClass.lean` | Additive theorems |
| `LidoSRv3/Tests/SszCompiledBeforeRootClassMutants.lean` | Named kill-lines |
| `audit/ssz-beforeroot-class/README.md` | This note |
