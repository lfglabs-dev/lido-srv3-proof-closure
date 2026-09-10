# SSZ-1: initialized memory consumed by the validator proof loop

This increment closes the initial-memory and leaf-load connection for the
compiled harness consumer. The public theorem is
`PSsz1.actual_memory_validator_branch`, imported by `AllGuarantees` and
queried by `Trust`. It supplements the actual deposit CALL result; neither
result replaces the other. SSZ-1 remains open for the complete CL entry and
the full ABI-declared proof-list connection described below.

## Useful promise and exact consumer

The useful validator promise requires the branch root to bind the validator
fields actually submitted. Trusting SHA does not establish its input bytes.
`SszCompiledConsumer.run` executes initialization, allocations, field stores,
loads, actual SHA calls and the existing proof loop on the returned frame.
`SszCompiledMerkle.run_success_branch` derives the typed validator leaf and
branch over the actually consumed calldata words. The public theorem consumes
this run directly; it has no initial-memory-width, memory-shape, supplied-leaf,
successful-intermediate-stage or per-call-success premise. Its conditions are
actual run success and the inherited SHA output-width condition.

`fuel` remains the existing interpreter parameter. This theorem does not
assert that every source invocation succeeds with arbitrary fuel or gas.
General gas, compiler correctness and the declared Verity semantics retain
their previously accepted scope. No new calldata-size, hash-injectivity,
allocation or consensus assumption is introduced.

## Source correspondence that the consumer needs

Solidity pin: `17005714f151e5502c559932319a3f2f74ac2436`.
The existing `BlsCompositionHarness.verify` calls the unmodified pinned
`CLValidatorVerifier._validatorHashTreeRoot` and `SSZ.verifyProof` suffix.
The retained solc 0.8.25, viaIR, optimizer 200, Cancun artifact is
`audit/ssz-witness-abi/solidity/inspected-harness-ir.yul`. Its compiler input
identities and selected executable test receipts are reused by byte identity.
This is a selected compiled harness, not the entire `_verifyValidator` entry.

| Necessary source behavior | Executed model and proof consumption |
| --- | --- |
| Runtime initializes fresh memory and writes free pointer 128 at byte 64 | `SszCompiledMemory.fresh`, `prologue`, `xi_uses_fresh`; `begin_values` derives the pointer and initial extent rather than accepting a memory frame. The fresh initializer is the one used by the pinned EVM initializer, as checked by `xi_uses_fresh`. |
| Allocate the 256-byte leaf array before key-tail admission; guard allocator wrap and uint64 free pointer | `SszCompiledConsumer.begin` executes that order. `allocate_effects` and `allocate_frame` derive pointer 128, free pointer 384, zeroed region and preservation of earlier cells. |
| SHA key preimage is 48 bytes followed by 16 zeros; output is read from the actual call result | The existing pubkey call runs on the initialized/allocated state. `begin_values` consumes its returned state and derives the exact key slice. The inherited byte-padding and SHA results bind the digest to these bytes. |
| Store key digest, withdrawal credentials, little-endian balance, slashed flag and four epochs in the eight leaf cells at 128 through 352 | `fields_effects` follows the uint64 and bool guards and physical stores, derives `FieldsMatch`, all eight stored values, and preserved free pointer. |
| Allocate 128 bytes at 384, load each pair of prior leaf cells, pass those loaded words to SHA and store the four digests | `merkle_effects` consumes `pairStore_effects` and `allocate_frame`. Each prior-cell load is justified by the same state after preceding writes/calls. |
| Allocate 64 bytes at 512; compute/store the next two digests, then load the left cell and use the retained right digest for the final SHA | The actual `SszCompiledConsumer.merkle` follows the inspected IR’s retained right operand. Its theorem derives equality to the independent typed pair tree and a final active extent at most 20 words. |
| Decode proof tail after all leaf SHA calls; verify using the computed leaf and original root/index calldata | `run_computed_leaf` and `run_success_branch` compose the actual returned frame with `SszProofCommitted.verify_success_branch`. The latter’s initial-memory-width premise is discharged from the derived extent, not moved to the public assumptions. |

The SHA primitive uses the existing EVM call with static permission, recipient
2, zero value, 64-byte input and 32-byte output. The proof accounts for the
physical scratch writes, loads and returned digest. It does not merely attach
a desired preimage or digest to an auxiliary result.

## Remaining required connections and exclusions

The full CL entry must connect its EIP-4788/root lookup, slot and proposer
checks, generalized-index calculation and actual calldata frame to this
selected consumer. The current harness receives root/index arguments; it does
not prove that the full CL entry computes them correctly. The registry keeps
this obligation open under SSZ-1.

The branch theorem concerns `proofWords` actually consumed by the pinned
wrapping cursor loop. It does not yet identify them with the entire
ABI-declared proof list for every admitted frame. The list is nonempty on
success and its declared length is uint64-bounded; those facts alone do not
close the full-list connection. No calldata-size bound is newly assumed to
close it. Historical wrapping-cursor fixtures remain evidence of this limit.

The separate deposit CALL theorem still binds its actually decoded key,
credentials, signature and value to its root. General malformed deposit ABI
acceptance and exact revert/event encodings remain unproved. This increment
does not claim complete TOPUP/DEPOSIT state-machine or rollback composition.
General SHA correctness, compiler correctness, declared semantics, gas and
consensus are accepted external boundaries, not new delivery prerequisites.

## Verification

The public facade, full Trust inventory, registry generation/mutations and
proof-escape checks are recorded with exact input identities. Two kernel
regressions check that initialization discards poisoned incoming memory and
that a later allocation preserves the key stored by the earlier allocation.
They use the actual transition lemmas, with ordinary foundational axioms;
they introduce no native fixture axiom.

The reused Solidity runs comprise five BLS/proof tests (including 1,024 fuzz
runs and finite SHA fault-order injections) and four witness-ABI tests. They
execute the pinned leaf and proof suffix, not the complete CL entry. The
receipt verifies each source and compiler input before reusing those runs.
The failed development builds are diagnostic history only. Independent
review must assess the complete sources and exact frozen candidate, including
the memory operation order, before integration.
