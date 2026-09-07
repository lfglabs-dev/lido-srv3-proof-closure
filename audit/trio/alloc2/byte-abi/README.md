# ABI bytes through pinned Verity copy operations

`ByteABI.copied_bytes` proves exact contiguous-byte readback after the pinned
Verity `Memory.copyFrom`, for every byte list and destination and arbitrary
initial memory. `copyFrom_frame` preserves every byte outside the destination
interval, including zero-filled observations after memory expansion.
`calldata_arguments` and `returndata_output` name the actual `denoteMemoryOp`
operations and connect copied bytes to the established ABI decoder theorems.

`ByteABIProducer.producer_copied_abi` starts from successful interleaved
`ProducerMemory.produceM` execution. It derives the actual pinned ALLOC-1
execution and ABI extent, executes the copied argument bytes through the
proportional source executor, and proves the independent distribution result
and decoded copied return. It assumes neither a consumer success result nor a
separate size bound. Caller and callee use separate memory structures.

`ByteABIFrame.copyFrom_array_frame` preserves the caller's original array when
the complete return-copy interval is disjoint, in either order. Its premise is
explicit physical separation, not merely different word starting addresses.
The compiler allocation schedule must still establish that separation.

These results do not claim complete compiler decoder/allocation scheduling or
replace the canonical word-map transaction model with a lowered byte program.
The producer memory-guard refinement's scope remains explicit. No gas or
whole-program lowering refinement is claimed; the +1 algorithm is unchanged.

```
python3 audit/trio/alloc2/byte-abi/prepare.py
# in ../temp/alloc2-byte-abi/audit/trio/alloc2/byte-abi:
REMOTE_BUILD_NODE_ID=nippur remote-lean-build lake build audit.trio.alloc2.runtime.ByteABIVectors
```

The materializer verifies the predecessor byte-runtime manifest, reads producer
modules from the exact pinned producer Git blobs, and records 58 source/config
files with an explicit Verity dependency lock. The successful 57-file precursor
was remote job `78df9909-b8d4-4268-88e9-c60eccc0d6a5` (68 jobs). The preceding
attempt `8cd1cd92` failed on a Nat-versus-Fin lemma application and is not proof
evidence. Pre-citation-fix validation including `ByteABIFrame` passed 69 jobs on `nippur`, remote
job `4862113d-74db-4a6f-80f4-06587ad189e9`, using Lean 4.31.0.
Its verified 58-file overlay digest is
`07c5c605625f03775d0f1a502cf78166e886bcef421d311ba0187c7f4e328b2b`.

`solidity/trio-alloc2/ByteCopy.sol` explicitly uses calldata and returndata copy
opcodes. `byte-copy.mjs RECEIPT` first checks successful exact-source admission,
then compares both operations for seven Lean-generated vectors: empty, 31 and
33 bytes, three allocation argument packets, and an allocation return packet.
It records complete compiler inputs/outputs and deployed harness code. The
`ALLOC2_BYTE_COPY_MUTANT=shift` variant must fail the intended exact-byte
assertion after successful source admission. Full native UX2/trust and
`make prove test` remain unverified under the current remote-only protocol.

The differential run `c1bdf3d2-5e61-49b7-8d49-7b1c219da76d` exited 0
with all 14 comparisons. Mutant `f871ed48-5ea9-4ff4-a9b7-158272136125`
exited 1 at `31-bytes copyCalldata exact bytes`, after the two empty-copy
checks passed. `byte-copy-mutant.json` retains the assertion and source digests.

After correcting Step.lean to cite the actual pinned function span 63–107,
job `b0faae30-98d7-49cd-ab1c-f3e53ec42d83` passed all 69 jobs on nippur.
The current 58-file content digest is
`5cca3fc8c15a41604b27180027cd0090f99b5c1fb376b9b4b8b25efdb8a843e9`.
`focused-validation.json` checks all current source hashes and the eight
printed axiom reports. This is not the native full trust-checker receipt.
`source-checks.json` records passing proof-escape, source-annotation, pinned
source, metadata and UX2 consistency checks. The canonical and byte-runtime
source manifests are refreshed; their older receipts precede the citation fix.

Refreshed differential `95ecd821-90cf-4ec8-91c3-431101e12e88` exited 0
(14 comparisons); mutant `40c60719-9bc5-46bf-ba71-bfe6724e41c0` exited 1
at the same intended assertion. Current execution and mutant JSON use b0faae30.
