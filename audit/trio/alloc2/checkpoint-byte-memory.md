# Physical byte-memory proportional loop

ByteMemory defines memory as Nat → Fin 256, a 32-byte big-endian load and a
store that changes exactly 32 consecutive bytes. bytes_store/load_store prove
readback, and store_outside/load_store_disjoint prove the physical byte and
nonoverlapping read frames. store_array and store_other_array transport the
existing array relation through an actual selected 32-byte store, including the
array header and a disjoint array. Both orders of the array regions are admitted.

The kernel-checked overlapping_read_changes witness shows that reading at the
last byte of a stored word changes. Thus the old word-map frame cannot be used
for overlapping physical reads. This is not a native_decide assertion.

ByteIndexed uses the source-selected plan and performs one physical store per
step. step_related and the well-founded loop_related prove correspondence with
the decoded proportional loop, including errors; no fuel or synthetic exhaustion
failure is added. run_success transfers the independent Spec.Distributes result.
run_short_error derives the actual source indexing failure from positive demand
and shorter capacities. No independent consumer-success premise is used. The
+1 algorithm remains separate and unchanged.

This advances the physical-store boundary but does not complete the full task.
Memory addresses here are natural numbers. EVM address bounds, expansion gas,
compiler allocation/copy scheduling, producer-created array bytes, lifecycle
composition, the final Verity runtime integration and full gates remain separate.
ByteIndexed itself takes ArrayAt at entry. The subsequent ByteProducer bridge
derives it from actual ALLOC-1 success and an executed serialization adapter;
that adjacent-layout adapter is not yet connected to compiler write scheduling.
See checkpoint-byte-entry.md.

The byte-memory package and preparation manifest are separate so the already
queued indexed Verity runtime source bundle remains unchanged.

Validation so far:
- 78e49651-7d02-4da2-8e87-9cffad750c55: primitive proofs, 10 jobs passed.
- f7e51878-f278-4e33-aaa6-72d417af8cd7: array-store proofs, 10 jobs passed.
- caec8506-fa63-424c-83be-5a80ccbb04f1: proportional byte loop, 38 jobs passed.
- d36a873d-c8f9-4604-bd20-b039c005a877: current witness and five sequential
  vectors passed, 39 jobs. All theorem axiom reports use only propext,
  Classical.choice and Quot.sound (some use fewer).

Reproduction:

```
python3 audit/trio/alloc2/byte-memory/prepare.py
cd ../temp/alloc2-bytes/audit/trio/alloc2/byte-memory
REMOTE_BUILD_NODE_ID=ashur remote-lean-build lake build
```

The original physical-source/EVM comparisons passed against receipt d36a873d
at the previous source identity. The byte-entry extension now has a successful
42-job receipt, 3f3d1147-45f4-4140-a493-ae09c0d0c3ca, for 41 files.
The refreshed differential commands use that receipt:

```
node solidity/trio-alloc2/byte-sequence.mjs audit/trio/alloc2/receipt-3f3d1147-45f4-4140-a493-ae09c0d0c3ca.json
ALLOC2_BYTE_SEQUENCE_MUTANT=reset node solidity/trio-alloc2/byte-sequence.mjs audit/trio/alloc2/receipt-3f3d1147-45f4-4140-a493-ae09c0d0c3ca.json
```

The indexed Verity runtime has separately passed 62 jobs and six Solidity cases
against receipt 25bab09b-edbd-47a0-b8af-071531fe598c. These observations do not
establish a byte-backed Verity representation or compiler store-trace refinement.
See checkpoint-byte-entry.md for the exact completed slice and remaining gaps.
