# SSZ-1 compiled header ite rewrite

Additive lot on `grok/lido-ssz-header-ite-20260911` from current
`origin/main`. Applies the do-free `header` raccord documented on #370
and #377.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `6388f80b35a9c6e8ed934857210d7a58c5748bee` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |

CLAIM: grok owns ssz-header-ite since 2026-09-11

STATUS: claimed

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/SszCompiledClEntry.lean` | `header` rewrite only (same seven guards) |
| `LidoSRv3/Audit/Source/SszCompiledHeaderIte.lean` | Additive theorems |
| `LidoSRv3/Tests/SszCompiledHeaderIteMutants.lean` | Named kill-lines |
| `audit/ssz-header-ite/README.md` | This note |
