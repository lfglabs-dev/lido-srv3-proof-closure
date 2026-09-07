# Independent final stored-parent source review

2026-09-07. Observed HEAD: `b8219123ee1636b5cb210def74be26a0971cdb8f`. The new source was uncommitted during review: the SHA-256 manifest below identifies the reviewed bytes. The four parent/memory/caller/test fingerprints exactly match the root's freeze message. Solidity pin: `17005714f151e5502c559932319a3f2f74ac2436`.

Requested reviewer configuration: GPT-6 Astra. The supplied session identifies GPT-6 without an independently verifiable runtime model ID; this report does not attest actual Astra assignment. Read-only source review; no production edits, Lean builds, remote jobs, or new execution receipts. Only this report was authored. Earlier round-4 and published-delta reports remain unchanged.

## Decision

**No remaining source-composition blocker was found in this frozen candidate within its explicit compiler/deployment/world assumptions. Recommend merging once the actual exact-candidate gates pass and the report inputs are rebound and regenerated. Validation is still pending; this is not an unconditional merge or completion certificate.**

Round-4 R4-1 is closed at source-review level: the final parent now composes the executed producer stores, memory-fed library boundary, raw-return staging, live caller copy and indexed wei conversion. R4-2 is addressed by the explicit local compiler-memory/frame boundary, preserved in source comments and supplementary metadata. R4-3 remains the final validation/publication obligation. No new full-bytecode, gas, DSL-migration or all-protocol-writers requirement is introduced.

## Source findings

**Single executed memory parent.** `FinalMemoryStoredParent.program` performs the outer allocation before reading/branching on count and dividing. It evaluates `FinalMemoryStoredProducer.producer` once. Positive demand invokes the closed library on arrays read from that output memory; zero demand allocates/zeros its separate result array without a delegate event. The returned raw bytes feed `FinalMemoryStoredParentMemory.receive`, which stages bytes, finalizes the buffer, decodes, allocates the caller array and executes a live copy. Conversion then updates the actual two output arrays before observation.

`FinalMemoryStoredParentCaller.afterProducer_projection` obtains array relations and lengths from the reached producer execution, obtains a canonical library reply by running the closed library model, and derives buffer separation and space from allocator geometry. It does not assume a successful library result, correct final memory or the allocation conclusion. `projection_abi` covers every modeled result under the stated count and entry-budget premises. `public_iff` transfers the independently proved proportional parent specification. `success` additionally exposes the final memory observations: its ArrayAt conjuncts alone are observation identities, while the substantive allocation property comes from the independent Public relation proved by the projection.

**Errors and calls.** Division, producer-call/decoder/arithmetic failures, zero-path conversion failures and positive conversion failures retain their relevant source transcript. Raw-response bytes are passed directly from the closed library call to receive. `positive_calls` gives the exact memory-derived request and raw response event after a successful producer even if later caller processing fails. `trace_shape` covers all branches and every failure: the supplied history occurs once, followed by this invocation's module suffix and at most one delegate event. The executable branch condition and `afterProducer_trace` establish when that event occurs. The positive library transfer value is zero; this does not assert inherited DELEGATECALL msg.value is zero.

The simplified receive decoder is justified only for the canonical bytes derived from the closed library. This is not equivalence for arbitrary malformed linked-library returns or arbitrary deployed target code. Likewise all-outcome equivalence is conditional on count <=32 and `pointer +1184*count+704 <=2^32`; high-pointer failure regressions inspect executable guard behavior outside that correspondence domain and do not remove its premises. Partial private memory on a reverted path is intentionally unobserved. These are honest scope limits, not circular assumptions.

**Lifecycle and VM bridges.** `LifecycleHistory.stored_parent_iff` derives count and budget from actual modeled initialization, ACL execution and the four public writer families plus pointer <=2^31. Its finite separation/callback and excluded migration/writer assumptions remain unchanged; no desired post-invariant is introduced. `VerityParent.stored_correspondence` composes the existing actual module-call VM correspondence with the new source projection and proves its external world unchanged. It expressly does not execute the separately observed linked DELEGATECALL or the stored parent memory operations in that VM. The source-map wording preserves that distinction.

**Reserve repair.** The sole change to `ReserveLeafAllocation.partition_unique`, `change actual = buffer at total`, exposes a definitional projection after destructuring the allocation. It does not strengthen a premise, replace a computation, or introduce a proof escape. Its actual repaired elaboration remains a gate obligation. The accepted independent reserve-leaf and concrete-pipeline boundaries from the earlier reviews are unchanged.

**Compiler and world interpretation.** The word view, omitted scratch/cache writes, preserved cached fields, private callee memory and copy interpretation remain explicit local representation/frame assumptions. They may not be replaced with the final ArrayAt/property as a premise. Word/byte refinement must concern the disjoint observed windows, not arbitrary overlapping MLOAD addresses. Storage/hash and configured library identity are explicit bindings. RESERVE retains its concrete pipeline, aggregate balance/world and limited internal/committed-history scope. The final metadata does not advertise protection against arbitrary successful callback world changes.

## Validation and reporting still required

The inspected test source contains 16 full-parent cases plus an exact request/raw-return/copy-memory check. They cover nonempty prehistory, one producer invocation, module order, empty/zero/positive paths, several allocation error locations and conversion errors after the delegate event. This report reviewed those executable checks but did not rerun or independently certify the root-reported Init-only passes.

The production/test and Trust targets must actually compile these exact files, including `VerityParent.stored_correspondence` and the repaired reserve leaf, and complete the required prove/test, metadata, provenance and proof-escape checks. The test glob includes the new final-parent tests. The currently inspected targeted `RunFinalComponents.lean` only names ReserveLeafSpend and MemoryParentVM; that targeted run by itself is not the final stored-parent test receipt. Use the full registered test target or explicitly include the new module. Existing archived Solidity records remain evidence for their identified closure, not newly executed evidence for this final parent.

The new supplementary source-map scopes and `trio_report.source_composition_review` retain the legacy primary registrations and label validation pending. That is appropriate. The inspected `scripts/audit_metadata.py` still records the old R1 structured-input basis and source-map digest. `validate_r1_review_basis` will reject the changed source map until a deliberate new basis/digest is recorded; preserve that guard and regenerate the dossier/site from the new recorded inputs after validation. Do not relabel candidate evidence as passed merely because this source review found no blocker.

Trust imports and named inspections cover the new principal producer, parent, lifecycle, VM and reserve theorems. The new parent module itself prints axioms for `trace_shape`; optionally list it alongside `positive_calls` in the central Trust/supplementary entries to make the universal trace claim easier to discover. This is not a missing proof.

## Frozen fingerprints

| File | SHA-256 |
|---|---|
| `LidoSRv3/Audit/Source/TrioComposition/FinalMemoryStoredParentMemory.lean` | `69ae5885e6be81e1238d2b6b73118f5253dd1823540332817e687581fc40af8b` |
| `LidoSRv3/Audit/Source/TrioComposition/FinalMemoryStoredParentCaller.lean` | `8c7b9889ea1ea57a0d3f5c043f1701738355bbb72d56ab79b3cbba88acc10037` |
| `LidoSRv3/Audit/Source/TrioComposition/FinalMemoryStoredParent.lean` | `d4864a2ba24eb4c455d660628b58851e94c8d3f57e62f2c8d36b89a9c6268223` |
| `LidoSRv3/Tests/TrioIntegration/FinalMemoryStoredParent.lean` | `7bb5026d6d03df348b8672eedb0ed5038d0381453b2eb1144a60684d5e30af14` |
| `LidoSRv3/Audit/Source/TrioComposition/LifecycleHistory.lean` | `2abf592153ba758c999da1a75d8b4393e96c15130bcdacc8e7597592fc9de0fe` |
| `LidoSRv3/Audit/Source/TrioComposition/VerityParent.lean` | `b27d7622016ea0838696616196c11f4a7af133377e398c3c0542e04ab3500719` |
| `LidoSRv3/Audit/Source/TrioComposition/ReserveLeafAllocation.lean` | `ede8b3cd9bdf78a52d2b0ef9fb3b01041395e1fc547bedefbd4f14f13cc1e327` |
| `LidoSRv3/Audit/Trust.lean` | `05cce26bbe722dbc92b4861e96fc76bd6a2c3654510bb4b3a3026de95a385637` |
| `audit/source-map.yaml` | `908ebd69f962382279e58deb0986c8dcf7ed15d09929813aa88bb1f76a161351` |
| `scripts/trio_report.py` | `f89dec9cd7568e665024cc94a0e4e515c7fa064f21a1629013aa95f784058598` |
| `scripts/audit_metadata.py` | `ed31ad8beb903bddd639bec53577724bb6686d7a363ffeaaaf6c0908e5b8726f` |
| `lakefile.lean` | `6bfe5035ab6c6b3ca7fe53272769b12249bdb997e491911b74a39ec5ebaf1b2f` |
| `audit/trio/integration/RunFinalComponents.lean` | `ad429abf15a0f384352914ddece7812b96bd5f278f9171151ba3a40ebc3d8ccd` |
| `audit/trio/integration/check-init-composition.py` | `68bab86e989bdf7f90a85097c69dd67ad4f61c216e70b215e69cdb4c81e4fd0e` |

This review is of these bytes and their previously inspected dependencies. Subsequent semantic edits require a focused review; no future SHA or unobserved validation result is certified.
