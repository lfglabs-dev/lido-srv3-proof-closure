# Independent source/composition review — round 4

Review date: 2026-09-07. Checkout HEAD observed: `58db7d58a8ffe0eed6e3b57507e3d9160a25072e`.
Pinned Solidity: `17005714f151e5502c559932319a3f2f74ac2436`.
The reviewed additions were uncommitted at this HEAD; the per-file SHA-256 manifest below, not HEAD alone, identifies this review.

Reviewer configuration requested by the root: GPT-6 Astra. The reviewer's supplied session identifies GPT-6 but does not expose an independently verifiable runtime model ID. This report does not attest that the requested Astra runtime was actually assigned; retain the orchestrator's launch metadata separately.

This was independent source review. No production files were edited, no local Lean builds or remote jobs were started, and no human messages were sent. The only authored artifact is this report. Authored proof text is not evidence that pending elaboration or full gates succeeded. Earlier source reviews of the decoded allocation composition and concrete reserve pipeline remain scoped to their recorded snapshots.

## Recommendation

**Accept the inspected corrections at source-review level; hold final trio merge/completion recommendation pending the final combined parent and exact-candidate validation.**

No new circular goal premise or concrete guard/arithmetic defect was found in the round-4 additions. The previously reported reserve leaf opacity and call-prefix duplication are corrected. The fused stored producer is a substantial closure of the previous disconnected guard/store models.

The remaining required source integration is one parent execution/result relation combining the corrected producer guards and writes, memory-fed library request/response, caller return copy, indexed conversion and final observation. The source theorem must derive its output-array/copy relations and region bounds from the executed path. Existing component theorems provide these ingredients; this report does not certify an uninspected future combined parent.

The permitted compiler/crypto/consensus assumptions are scope boundaries, not a demand for full deployed bytecode, gas, or migration to the compilable DSL.

## Corrections accepted

### Independent RESERVE leaves

`ReserveLeafAllocation.Describes` handles locator failure, raw queue-call failure, short reply and decoded success separately. Its success rule uses the physical total/reserve saved before external calls, the actual returned ABI word, and independent `AllocationSpec.Describes`. `partition_unique` connects that independent maximality/conservation relation to the executable min/subtraction result. No successful allocation result or final reserve property is supplied as a premise.

`ReserveLeafFrame.Describes` covers fresh oracle lookup, raw call outcome, the 64-byte tuple guard and both decoded words. The returned world and attempted-call prefixes survive every alternative.

`ReserveLeafSpend.withdrawal_corresponds` substitutes both independent leaves into the already independent status/router/spending/tail parent. The remaining executable equalities are raw CALL interfaces. These are appropriate primitive/adversarial boundaries: they expose request, returned bytes/world and rejection rather than assuming a desired higher-level computation or success. Concrete `QueueCalls`, `ConsensusCalls`, `Pipeline` and `PhysicalReserve` remain the implementation bindings for claims about the actual pinned queue/frame/receiver chain. Generic arbitrary-callee equivalence alone does not promise reserve protection against arbitrary successful callback world changes.

**Round-3 finding 3 is closed at the independent source-parent level, subject to elaboration and final integrated gates.** No additional recursive verification of arbitrary adversarial callee bytecode is requested.

### Library trace prefix

`MemoryTransportCall.producerThenCall` now appends only `after.drop before.length`. `evaluate_extends` and `evaluate_prefix_drop` justify removing the old prefix even after source failure. `nonempty_before_no_duplication` covers the concrete previously ambiguous nonempty-prefix case. The duplicated-prefix concern is closed.

### One executed stored producer

`FinalMemoryStoredProducer.producer` has one actual first pass and one capacity pass. It threads the final allocation guards and current free pointer, zeros the output arrays, performs per-row output stores and allocates capacities at the resulting pointer. It does not run the producer twice or reconstruct final memory from the completed `CapacityOutput`.

`bounds` derives lower/upper pointer bounds and separation. `success` derives actual producer execution, `MemoryArraysRelated`, and the exact returned pointers. Its separate assumptions are count and a numeric entry budget; neither is an assumed successful callee or desired final memory relation. `producer_exact` is theorem-level factorization, not a second execution. `guard_projection` connects the fused stored producer to the corrected guard producer.

The output-word store following `FinalMemoryRows.firstRow` is observed only after that row's total-add check, whereas Solidity writes its allocation before the total addition. This is compatible with the stated projection because a subsequent failure discards private memory and preserves the same externally attempted calls. Do not reinterpret this quotient as an exact trace of every internal MSTORE before failure.

### Lifecycle bridge

`LifecycleHistory.final_parent_iff` transfers the actual initialization/ACL/four-writer invariant into `FinalMemoryParent.public_iff` and the corrected numeric budget. The zero-only history defect remains closed. Its stated source-initialization scope, finite storage-separation assumptions, entry pointer bound, and exclusions of migration/remaining writer families are honest. It still targets the guard/canonical-byte parent; the eventual combined stored/copy parent needs the analogous transfer.

## Remaining necessary integration and acceptable primitive premises

### R4-1 — final combined observable parent

Priority: required before the final trio completion claim.

Connect the inspected producer to the memory-fed library boundary and caller copy/conversion in a single parent executor, preserving empty and zero-demand branches, all source failures, exact module/library attempted-call order and final array observation. Derive input/output extents and distinct array regions from successful allocation and the lifecycle count invariant. The final correspondence should not receive an unrelated final `MemoryArraysRelated`, a successful library result, or the requested arithmetic property.

The library request must stay tied to actual caller memory reads, the configured target, selector `0x2529fbc9`, zero ETH transferred by DELEGATECALL, and raw response bytes. Configured/deployed target identity and primitive execution binding can be explicit. The separate library invocation does not share caller memory. The canonical-return restriction of `FinalMemoryCaller` remains essential: its simplified decoder/allocation ordering is not a theorem about arbitrary malformed return offsets.

### R4-2 — record the local compiler-memory relation precisely

Priority: required as an explicit assumption/relation for a Solidity correspondence claim; no new full-bytecode verification obligation.

`CacheRepresentation.write_related`, `capacity_correspondence`, `write_then_capacity`, and `preserves_array` provide the requested five-field cache store/load and array-frame components. They do not, by themselves, execute the actual pointer table and interleaved cache/configuration/response writes in `FinalMemoryStoredProducer`. That module explicitly projects these private regions away.

It is acceptable to retain a local compiler-representation relation supplying:
- concrete pointer-table/cache-row identity and the five field offsets;
- primitive load/store/copy agreement on the observed word addresses;
- separation of omitted cache/scratch writes from the live output regions;
- preservation of cached fields between their source write and second-pass read;
- private callee memory and raw return-buffer/caller-array copy interpretation.

These are local representation/frame premises, not the final allocation property. `scratch_store_frame` is a useful local proof, but its `lower`/`upper` address facts must be supplied from the actual omitted write site or allocator geometry; they are not evidence that every physical scratch write lies in that band.

The `MemoryTransport.store` word view changes one address observation. A physical MSTORE also changes overlapping 32-byte windows. Therefore the byte/word relation must be restricted to the appropriate aligned/disjoint observation set; do not assert equality with physical MLOAD at every arbitrary Nat address. This limitation is already named in the primitive module and should remain explicit in the final theorem/dossier.

### R4-3 — exact-candidate validation and registration

Priority: required before final merge/completion recommendation.

The authored ReserveLeaf modules and combined stored parent require actual elaboration/trust output, production/test targets, make prove/test and the requested metadata/provenance/escape checks. Differential/mutation evidence must execute the final implementation or bind a demonstrably unchanged transitive source closure. A prior VM receipt for a different memory parent is not a receipt for the new stored/copy executor.

The canonical guarantee metadata still describes older cached/auxiliary parents, including `freshQueueCache` for RESERVE. Final registration/dossier/site work must reference the reviewed and validated new theorems while preserving the old declarations until migration is validated. Neither this review nor a metadata update upgrades their execution evidence.

## RESERVE sequence and balance scope judgment

`PhysicalSequence.Steps` is explicitly a finite relation over internal target/rebalance writers and committed-withdrawal worlds. `concrete_success_step` connects one concrete public withdrawal to that relation. Its existing claims are honest for that restricted domain. It is not a theorem of arbitrary public report/queue-writer/withdrawal histories, and the dossier must not present it that way.

The original brief requests sequential tests/proofs for behaviors actually announced and permits visible invariant premises. It does not require proving all protocol writers merely to deliver a conditional live-queue withdrawal guarantee. Consequently, implementing every report/finalization/submission/queue writer is **not an additional merge prerequisite from this review**. If the final claim promises live-queue protection across those writers, their actual transitions must be composed; otherwise keep that reachability outside the claim. Rebalance establishes a new partition and must not be described as preserving the old one.

`Transfers` proves funded debit/credit conservation, same-account identity and a conditional credit bound. For the concrete read-only getter/fixed receiver pipeline, a stated aggregate ETH bound and a primitive relation between Nat balances and bounded EVM account balances are legitimate deployment/consensus-world premises. They are not the desired reserve-protection conclusion. Separate per-account bounds alone do not establish post-credit boundedness. No proof of the entire consensus ETH-supply history is required; retain the aggregate assumption visibly. Arbitrary successful external worlds must satisfy the selected primitive/world relation before any real-EVM interpretation is claimed.

The stored buffer is accounting, not asserted equal to the account balance. `Pipeline` checks the CALL funds separately; preserve that distinction. Exact transfer/rejection and rollback results are already meaningful without inventing a reserve<=buffer invariant.

## Reviewed source fingerprints

Paths below are relative to `LidoSRv3/Audit/Source/TrioComposition/`.

| File | SHA-256 |
|---|---|
| `ReserveLeafAllocation.lean` | `63ce844673660e4700a335cc8910dcb6b51cba97e26c8c67a3bf02755a1315cb` |
| `ReserveLeafFrame.lean` | `26d2296a7fe30ac1d8cf1a648688d57defa6215cc16a3ed5f7705f213acae511` |
| `ReserveLeafSpend.lean` | `4a3b4851c714775724ef71955719ea93be18426f9ef984918789a08a629bcff2` |
| `MemoryTransportCall.lean` | `0c770d98c81f28ec6e1ececa950f0f9fa874b6b24e9f784b54113635fc931630` |
| `CacheRepresentation.lean` | `6aeb88b1b464c095515d37b4beadc839413d28f658d494617f6b5e3e93745d2d` |
| `FinalMemoryStoredProducer.lean` | `a2d48148ecf79b4778a607d8ed17e1c6c936ae09995d789d174ec8fe6daf1c2c` |
| `LifecycleHistory.lean` | `8d40bec6818a9b80e432079e5f526ada6546bd69e6ab881548925961ef5ce11d` |
| `ProducerStores.lean` | `2b00bd4e96607d67f43752d2cb24aaa33c9b1fbdf0c90ceb655670bff23d2360` |
| `MemoryTransport.lean` | `3b165a0c0f18d0ff7cb4830b5b0f95960d37697fa487b4d07d51b62c1985f2dd` |
| `MemoryTransportCopy.lean` | `150fd1a8e452cf2ac0ef5544ab03cc2fd7a6eea464fe69d57ccbd50d939bcedd` |
| `MemoryTransportABI.lean` | `28ce681f9698b86146fdfc9fa90277e640fd9dad06cbf72a5fcfb7fad89b6dcf` |
| `MemoryTransportReturn.lean` | `8b7840e8ad210838226bff69152bd72de8564000b3ed768e10a0e1096b21c06c` |
| `MemoryTransportConversion.lean` | `87247fb5f77785a5bba7209b8aad9d31aafb1e802eaa2b8cbe7e1aacc6115f05` |
| `FinalMemoryRows.lean` | `6eeaed135ea64d5f1efae78f1945923a83c6ad7af9d326a87d0d20ddc6a59a93` |
| `FinalMemoryProducer.lean` | `acc079f777fc18107eff7319e2a4f00fe2007bb41b4ed1081ee8afe2868dd952` |
| `FinalMemoryCaller.lean` | `21ce2e6f13078f2f2cfca43e3eccb8ce290380027b5a3c6cfce626403cc8d58b` |
| `FinalMemoryParent.lean` | `f0869bf8a46b5c6b8dc14fa961906318199d06a72ff1ccb0701adb334def3af6` |

This is a candidate source review of these bytes. Changed files, a future final parent, or subsequent merges require a focused renewed review; no certification of their future SHA is implied.

