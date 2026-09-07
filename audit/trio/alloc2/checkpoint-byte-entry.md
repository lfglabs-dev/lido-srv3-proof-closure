# Constructive byte entry and indexed Verity rollback

ByteFrame proves byte preservation across the entire well-founded proportional
loop. run_frame covers every address outside the original contiguous bucket
element region. It does not claim preservation of overlapping word reads.
ByteInitialize writes array length headers and all elements by physical 32-byte
stores into arbitrary memory. constructArrays_related establishes both arrays
and disjointness without an initial ArrayAt premise. Either region order works.
The executable byte vectors now use this proved initializer.

ByteProducer.producer_output_store_bridge consumes the actual pinned ALLOC-1
produce result. producer_length_from_storage derives both header bounds from
the actual storage count. The adapter executes physical stores, establishes
ALLOC-2's array relation, and derives its execution and independent distribution
specification. No count <= 32, capacity-headroom, ArrayAt or consumer-success
hypothesis is supplied. The capacity array is adjacent to allocations in this
serialization adapter. Relating it to the compiler's actual interleaved memory
layout/write/copy schedule and uint256 address bounds remains OPEN. The theorem
is not represented as closing that source boundary.

Targeted proof receipts on ashur:
- 2b210f9b-56d9-43e7-bc5c-f8f07766d20a: ByteFrame, 31 jobs passed.
- 8336b329-623b-4d8d-bec7-a7461123539e: ByteInitialize, 31 jobs passed.
- 264481c1-538c-41b4-86c5-90d5c98993d5: ByteProducer, 33 jobs passed.
The refreshed complete byte package/vector job
3f3d1147-45f4-4140-a493-ae09c0d0c3ca passed all 42 jobs over the exact
41-file source bundle, including the vectors using constructArrays.

The refreshed physical-byte differential passed all five exact Solidity return
comparisons, including 129 rows (durable c3bd1ddd-f89f-4821-8967-860fbbf475a7,
exit 0). The reset mutant reached the intended two-calls exact bytes assertion
and exited 1 (296147cf-fa56-4508-9601-9920a14628ca). The byte-sequence JSON
receipts now bind to source receipt3f3d1147, not the previous initializer.

Indexed Verity job87bd ended with a parse failure because prefix is a Lean
keyword. Renaming the bound identifier to enclosing fixed the error. Job
25bab09b-edbd-47a0-b8af-071531fe598c passed all 62 jobs, including the whole-state
indexed success theorem, arbitrary enclosing-prefix rollback theorem, five
sequential memory vectors and the storage/balance/memory rollback vector.

The exact current 52-file runtime source overlay passed memory-sequence.mjs
admission. All five sequential comparisons and the sixth Solidity transaction
rollback case passed: exact panic 0x32, reverted status, no committed logs and
restored marker. Positive durable job6a43f827-74bf-4c04-b379-9ed58b28c1a6 exited 0.
The reset mutant exited 1 at two-calls exact bytes; job
a8cc7446-abb3-4bb1-96e6-11269521199e. Both JSON receipts include source hashes;
the positive artifact retains full compiler input/output and deployed code.

```
python3 audit/trio/alloc2/runtime/prepare.py
# in ../temp/alloc2-runtime/audit/trio/alloc2/runtime:
REMOTE_BUILD_NODE_ID=nippur remote-lean-build lake build
# in the implementation checkout:
node solidity/trio-alloc2/memory-sequence.mjs audit/trio/alloc2/receipt-25bab09b-edbd-47a0-b8af-071531fe598c.json
ALLOC2_SEQUENCE_MUTANT=reset node solidity/trio-alloc2/memory-sequence.mjs audit/trio/alloc2/receipt-25bab09b-edbd-47a0-b8af-071531fe598c.json
```

Canonical review: PAlloc2.step_correspondence_and_full_loop_conservation remains
the registered fuel-bounded parent. The UX2 artifact is generated from that
registry; the new well-founded and byte-memory modules are not yet registered
parent evidence. Its existing missing list includes algorithm distinctions and
proved memory-oracle independence alongside actual gaps. Updating it requires
reviewing the parent, assurance-detail digest in scripts/audit_metadata.py,
source-map evidence and generated surfaces together, with full regression gates;
standalone green receipts are not sufficient to claim canonical closure.

Still OPEN: compiler/producer store/copy layout, byte-backed Verity integration,
lifecycle and enclosing consumer composition, canonical registration and final
full make prove/test/UX2/trust gates. The +1 algorithm is unchanged.
