# SSZ-1 compiled header ite rewrite

Lot on `grok/lido-ssz-header-ite-20260911` from current `origin/main`.
Applies the do-free `header` raccord documented on #370 and #377.

Spark's other 2026-09-11 work on `main` has been Trust registration
(eth-model, provenance, alloc/mint, trio-consol, mutants-batch1). The
SSZ compiled-entry lots #370/#375/#377/#379 are still open; composition
of those modules is blocked until they land. This lane unblocks their
header remainder instead.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `6388f80b35a9c6e8ed934857210d7a58c5748bee` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns ssz-header-ite since 2026-09-11

STATUS: ready

## Obligation

Rewrite `SszCompiledClEntry.header` from `do`/`throw` (elaborates to
`__do_jp` join-points; `fun_cases` only collapses the first guard) to
an explicit `if`/`.error`/`.ok` nest. Same seven guards, same order,
same `.abi .abi` error. Then every `header` failure is constructor-
visible, and every `beforeRoot` error is `isBeforeRootClass` with no
remainder.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/SszCompiledClEntry.lean` | `header` rewrite only |
| `LidoSRv3/Audit/Source/SszCompiledHeaderIte.lean` | Additive theorems |
| `LidoSRv3/Tests/SszCompiledHeaderIteMutants.lean` | Named kill-lines |
| `audit/ssz-header-ite/README.md` | This note |

`header_env` / `beforeRoot_success` on the existing module still build
(`lake build LidoSRv3.Audit.Source.SszCompiledClEntry`).

## Theorems

| Theorem | Reflects | Statement |
| --- | --- | --- |
| `header_error_is_abi` | IR 40-55, all seven guards | `header = error e` ⇒ `e = .abi .abi` |
| `header_of_nonzero_value` | first guard | `weiValue ≠ 0` ⇒ ABI |
| `header_of_short_calldata` | second guard | `size < 4` (and nonpayable) ⇒ ABI |
| `header_ok_is_nonpayable` | first guard converse | success ⇒ `weiValue = 0` |
| `header_ok_is_offset` | word 100 | success ⇒ offset = `calldataload 100` |
| `beforeRoot_of_header_error` | first `beforeRoot` bind | header error is the `beforeRoot` error |
| `slotSibling_error_is_slot_class` | IR 70-97 | panic11 / panic32 / invalidSlot |
| `beforeRoot_error_is_beforeRootClass` | IR 43-100 | **no header remainder** |
| `run_of_nonzero_value` | compiled `run` | payable ⇒ `.abi .abi` |

## Mutants

| Kill-line | Mutant killed |
| --- | --- |
| `header_value_kill_line` | Nonzero `msg.value` still dispatches |
| `header_short_calldata_kill_line` | Selector-short calldata still dispatches |
| `header_error_not_panic11_kill_line` | Header failure is a slot-panic |
| `run_value_kills_success` | Payable entry is a successful `run` |
| `beforeRoot_error_not_proof_kill_line` | `beforeRoot` failure is `.proof` |

## Hypotheses (declared, not proved here)

- EIP-4788 authenticity and freshness.
- Compilation / crypto / gas / consensus.

## Axioms

`#print axioms` of every export is only `propext` / `Classical.choice` /
`Quot.sound`, or a subset. No `sorry`.

## Merge note for Spark

#370 and #377 carry their own `header_of_nonzero_value` via `fun_cases`
on the old `do`/`throw` header. After this rewrite those proofs should
get easier (`if_pos`), not harder. This PR does not rebase those
branches.

## Recheck

```sh
export PATH="$HOME/.elan/bin:$PATH"
lake build LidoSRv3.Audit.Source.SszCompiledClEntry
lake build LidoSRv3.Audit.Source.SszCompiledHeaderIte
lake build LidoSRv3.Tests.SszCompiledHeaderIteMutants
```
