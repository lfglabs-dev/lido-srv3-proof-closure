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

STATUS: ready

## Obligation

`PSsz1.actual_compiled_cl_entry_tree` (#330) / declared siblings (#349)
cover the success arm of one compiled `SszCompiledClEntry.run`. This lot
is the complementary error arm: a proof-loop (`.proof`) or root-comparison
(`.reply`) failure commits no `EVM.State`, hence no storage write, event,
returned memory or value on the declared observables. Success and that
failure share `beforeRoot` then `rootCall` until `afterRoot` diverges.

EIP-4788 authenticity/freshness stay declared. Compilation, crypto, gas
and consensus stay outside.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/SszCompiledEntryRollback.lean` | Additive theorems |
| `LidoSRv3/Tests/SszCompiledEntryRollbackMutants.lean` | Named kill-lines |
| `audit/ssz-compiled-rollback/README.md` | This note |

## Theorems

Each statement cites the compiled function and the Solidity / inspected IR
it reflects (`CLValidatorVerifier.sol` at the core pin;
`audit/ssz-compiled-cl-entry/solidity/inspected-cl-entry-ir.yul`).

| Theorem | Source | What is proved |
| --- | --- | --- |
| `committedState_of_error` | `run` (`SszCompiledClEntry.lean:164-171`) | An error outcome has no committed `EVM.State` (no committed storage, logs, return, or value). |
| `store_preserves_accountMap` / `logSeries` | `store` / IR free-pointer `mstore` | Machine-memory writes do not update the account map or log series. |
| `prologue_preserves_*` | `prologue` / `mstore(64,128)` | First memory write keeps caller account map and logs. |
| `header_of_nonzero_value` | `header` IR 50-53 | Nonzero `weiValue` is `.abi` before later dispatcher guards. |
| `header_ok_is_nonpayable` | `header` IR 50-53 | A successful `header` implies `weiValue = 0`. |
| `slotSibling_error_not_proof_or_root` | `slotSibling` IR 70-97 | Slot/proposer sibling errors are panic 0x11 / 0x32 / `invalidSlot`. |
| `beforeRoot_of_header_error` | `beforeRoot` IR 43-55 | A `header` error is the first `beforeRoot` bind. |
| `beforeRoot_tail_error_not_proof_or_root` | `beforeRoot` IR 56-100 | After `header` succeeds, `beforeRoot` errors are ABI / BLS / slot-panic, never `.proof` / `.reply`. |
| `rootCall_error_not_proof_or_root` | `rootCall` IR 101-114 | The only `rootCall` error is `.allocation .panic41`. |
| `proof_or_root_failure_after_prefix` | `run` + `afterRoot` IR 116-417 | A `.proof` / `.reply` `run` error is either the `afterRoot` divergence after the shared prefix, or a `header` error. Both disjuncts commit no state. |
| `tree_success_excludes_proof_or_root_failure` | same `run` as `actual_compiled_cl_entry_tree` | One execution cannot be both the public success arm and a proof/root failure. |
| `proof_or_root_failure_is_nonpayable` | `header` IR 50-53 | A proof/root `run` error implies `weiValue = 0`. |
| `failed_staticcall_is_rootNotFound` | `decodeRoot` / `CLValidatorVerifier.sol:103-107`, IR 146-148 | `success = false` is `.rootNotFound`. |
| `afterRoot_of_failed_staticcall` | `afterRoot` after `copyReply` | `afterRoot` cannot succeed when the STATICCALL flag is false. |
| `empty_proof_is_invalidProof` | `SSZ.verifyProof` count guard | Empty sibling count is `.invalidProof`. |
| `extra_sibling_refutes_branch` | `SszProofFold.branch_depth` | A `Branch` of length `n` and one of length `n+1` cannot share an index. |

### Mutants (named kill-lines)

| Kill-line | Corruption | What it kills |
| --- | --- | --- |
| `falsified_root_staticcall_kill_line` | STATICCALL flag false | `decodeRoot` success |
| `falsified_root_kills_afterRoot_success` | same flag on `afterRoot` | `afterRoot` success |
| `out_of_range_index_kill_line` | validator offset `2^40` | compiled `wrapper` (`_getValidatorGI` / IR 168-233) |
| `out_of_range_index_kills_wrapper_success` | same offset | universal wrapper-success claim |
| `missing_sibling_kill_line` | empty proof list | `SSZ.verifyProof` success |
| `duplicate_sibling_kill_line` | extra sibling on the same index | `Branch` at that index |
| `altered_leaf_kill_line` | leaf ≠ decoded root at index 1 | `finish` success |

## Hypotheses kept explicit

- EIP-4788 authenticity and freshness remain declared premises. They are
  not proved here.
- SHA / FFI width, compilation, gas, and consensus stay outside.
- `SszCompiledClEntry.run` is not edited. The public success parent
  `PSsz1.actual_compiled_cl_entry_tree` is imported, not restated.

## Open / raccord

`proof_or_root_failure_after_prefix` still has a second disjunct:
`header (prologue context) = .error e` for a `.proof` / `.reply` `e`.
The source `header` only throws `.abi .abi` (IR 40-55). That constructor
restriction is not closed here because `header` is a `do` / `throw` block
whose elaborated join-points (`__do_jp`) block `split` / constructor
analysis of every guard after the first (`weiValue`).

**Minimal raccord (not applied; exclusive-file contract):** in
`LidoSRv3/Audit/Source/SszCompiledClEntry.lean` lines 53-63, rewrite
`header` from `do` / `throw (.abi .abi)` / `pure offset` to an explicit
`if` / `.error (.abi .abi)` / `.ok offset` nest with the same seven
guards in the same order. No selector, bound, or error constructor
changes. After that rewrite, the second disjunct is `False` by the same
`fun_cases` tree already used for `header_of_nonzero_value`, and the
theorem tightens to the `afterRoot` prefix only.

Also open, unchanged: EIP-4788 history-ring authenticity, SHA functional
correctness, opcode gas, bytecode correspondence, keccak-oracle
independence.

## Gates

```sh
lake build LidoSRv3.Audit.Source.SszCompiledEntryRollback
lake build LidoSRv3.Tests.SszCompiledEntryRollbackMutants
lake env lean LidoSRv3/Audit/Source/SszCompiledEntryRollback.lean
lake env lean LidoSRv3/Tests/SszCompiledEntryRollbackMutants.lean
```

`#print axioms` of every export is `propext` / `Classical.choice` /
`Quot.sound` (or a subset). No `sorry`, no extra axioms, no
always-success stub, no `keccakMemorySlice := fun _ _ _ => 0`.

## Out of scope

- Editing `SszCompiledClEntry.run` or `PSsz1CompiledClEntry`
- `guarantees.yaml` / Trust / global imports
- Closing SHA correctness or EIP-4788 authenticity by a premise
