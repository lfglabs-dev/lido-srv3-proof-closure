# SSZ-1 compiled CL-entry rollback

Additive lot on `grok/lido-ssz-compiled-rollback-20260911` from
`e9d6288ae84ba4191a8c705a85220b35cc44e7ca` (merge of #349). No existing
Lean, registry, Trust, or import-DAG file is edited.

## Identities

| Pin | SHA |
| --- | --- |
| Specified base | `e9d6288ae84ba4191a8c705a85220b35cc44e7ca` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns ssz-compiled-rollback since 2026-09-11

STATUS: claimed

## Obligation

`PSsz1.actual_compiled_cl_entry_tree` (#330) / declared siblings (#349)
cover the success arm of one compiled `SszCompiledClEntry.run`. This lot
is the complementary error arm: proof-loop or root-comparison failure
commits no `EVM.State`, hence no storage write, event, returned memory
or value. Success and that failure share `beforeRoot` then `rootCall`
until `afterRoot` diverges.

EIP-4788 authenticity/freshness stay declared. Compilation, crypto, gas
and consensus stay outside.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/SszCompiledEntryRollback.lean` | Additive theorems |
| `LidoSRv3/Tests/SszCompiledEntryRollbackMutants.lean` | Named kill-lines |
| `audit/ssz-compiled-rollback/README.md` | This note |

## Out of scope

- Editing `SszCompiledClEntry.run` or `PSsz1CompiledClEntry`
- `guarantees.yaml` / Trust
- Closing SHA correctness or EIP-4788 authenticity by a premise
