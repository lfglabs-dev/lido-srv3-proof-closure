# Executed allocation guards and producer byte extent

MemoryPrefix.lean models aligned allocation checks emitted by solc 0.8.25:
word addition wraps, then the compiler rejects a free pointer above 2^64-1 or
below its starting pointer. The pre-call prefix allocates two count-sized
arrays and count five-word cache structs. Its exact extent is
pointer + 224*count + 64. Success and memory-overflow conditions are explicit;
the canonical ABI extent 160 + 64*count follows from successful guards without
a count<=32 premise.

The producer candidate advanced to 8691c7881a863715ab5ec9b39631ab41243e7c91.
Its Interface and the six previously consumed modules are byte-identical to
the earlier pin. The consumer now also imports its AllocationMemory module.
AllocationMemoryBridge proves the aligned operations, arrays and complete
prefix equal execution of those exact producer primitives, including size
rounding and panic 0x41. MemoryExtent derives the canonical byte-execution
bound from actual producer lengths and successful execution of that prefix.

This remains a compositional boundary: the full compiled parent execution must
still be related to this prefix and the rest of its allocation schedule,
zeroing, stores, copies, ABI dispatch and gas behavior. The decoded producer
alone still does not establish memory success. No claim of full compiler-memory
correspondence is made.

MemoryVectors emits four early failures (maximum count, count beyond the
compiler length limit, byte-size overflow, division before allocation). The
Solidity parent runner requires these four modeled outcomes in addition to the
eight existing parent cases. All four must produce exact panic bytes and no
module calls; there is no successful producer stub for oversized inputs.

Infrastructure: ashur rejected a 2 GiB estimate with HTTP 422 because 81 GiB
available was below estimate plus the 80 GiB emergency floor. Earlier job
bc513385-701b-4116-a6c4-58fb9c1c67b5 remains queued on nippur and targets
older source. Subsequent source changes and the updated producer pin are
validated by distinct old-agent submissions; the queue is not treated as failure.
Producer diagnostics confirm it is running, but coordination messages still
fail with writer_identity_stale for PR #245; no retag was attempted.

Composition receipt c890ba0f-da73-4495-97c3-77d9229ef483 succeeded with
41 jobs and the complete 40-file source/config closure, including seven exact
producer blobs at 8691c78. The consumer receipt
00e0d884-96af-47b8-ac77-32659aba28b9 succeeded with 30 jobs and 29 files.
The exact prefix success/overflow conditions, primitive equivalence and composed
byte execution all checked; neither successful log contains sorryAx.

Runtime receipt 7676eb95-78f9-46f2-b64f-120d97c3810f succeeded with
46 jobs, complete 44-file closure and all eleven Contract.run vectors.
The refreshed byte differential 19a6f3f6-dea5-49ae-9365-da70946f3222
passed 127 exact comparisons. Metadata checks, proof escapes and source
annotations passed. Full root build at earlier 1fac020 remains live and does
not validate this candidate; full make prove/test and independent review remain
open alongside the compiler schedule, physical memory, parent rollback/mutants,
exact conversion error conditions and producer integration/agreement.

Parent job e63df71c-bb35-439c-a433-9549da301230 exited 0 with all twelve
cases. This includes all four new guard failures, exact panic bytes, no module
calls and unchanged observed state. The division-before-memory case passed.
