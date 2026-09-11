# Complete indexed list at the existing compiled330 entry

All source references are to core17005714. No executable or compiler transcription is changed. Complete compiler evidence remains byte-identical in `audit/ssz-compiled-cl-entry/solidity` and its Mac replay under `validation`; the new validator pins the entire accepted packet and current providers.

| Connection | Existing source / actual consumer | New proof |
|---|---|---|
| Declared proof slice and uint64 count | `SszWitnessAbi.tail`; `CLValidatorVerifier.sol:44–57`; compiled CL entry prologue/beforeRoot and unchanged 567-line IR | Existing330 success supplies actual branch.offset/count; `declaredWords` uses all `List.range count` indexed loads |
| Modular endpoint and 32-byte do-while step | `contracts/common/lib/SSZ.sol:179–248`; `SszProofCommitted.endOffset`, `proofWords`; actual loop sourceStep/loop | `end_eq`, `advance_succ`, `cursor_arithmetic`, `all_steps`, `cursor_dichotomy` |
| Excluding a one-word partial result | `CLValidatorVerifier.sol:19–22,54`; `SszWrapperIndex.wrapper_success`, `appendIndex`; actual `SszProofFold.Branch` | `wrapper_depth` (3..247), `complete_of_branch` |
| Same penultimate slot/proposer word | `CLValidatorVerifier.sol:89–95`; actual `SszCompiledClEntry.slotSibling` and beforeRoot success | `declared_get`, `penultimate`; option index count−2 is derived in range |
| Same root, timestamp, fields and tree | Unchanged `PSsz1.actual_compiled_cl_entry_branch`, root reply, produced gi and validatorLeaf; `SszTypedFfiBridge.branch_transport` | `actual_compiled_cl_entry_complete_declared_branch` retains the full 330 conjunction and adds complete-list word and tree Branch |
| Retained successful concrete case | Accepted 2180-byte calldata/50-sibling vector, 32-byte root, four reviewed whole-entry IO/FFI diagnostics | Byte-exact test literals, symbolic full-list equality and public theorem specialization; successful opaque execution remains reused IO evidence |

The literal old theorem declaration through its entire conclusion is checked as a prefix of the new theorem after its name is changed, followed by the additional conjunction. Parameters and success/ShaWidth hypotheses are unchanged. New conclusions bind to the same existential witnesses, not separately supplied slices or stage certificates.

`rawWord` calls `uInt256OfByteArray (raw.readBytes offset.toNat 32)`. The existing `readBytes` contains the opaque `ffi.ByteArray.zeroes` primitive; the new theorem is about the same function at every indexed offset, and does not require evaluating it or strengthening its semantics. All modular additions are UInt256 additions. `end_eq` proves the actual shift-by5 endpoint equals the indexed 32*count endpoint, rather than assuming natural nonwrapping arithmetic.

The assessment used to select this lot is archived verbatim as `assessment.md`; it is feasibility reasoning. The implemented kernel dichotomy and public theorem, not that assessment, are the new evidence.
