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
In particular, ArrayAt at byte-loop entry is still a premise; no claim is made
that producer success already constructs this physical memory.

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

The current receipt passed the runner's exact 38-file source-overlay admission.
All five sequences matched the pinned public Solidity library's complete return
bytes, including unchanged original caller arrays and capacities. Results and
full compiler/deployed-code evidence are in byte-sequence-execution.json.
Durable job e577d93b-456f-4397-8219-c1ca682fc111 exited 0. The reset mutant
exited 1 at `two-calls exact bytes`, not at source admission; its complete failure
and hashes are in byte-sequence-mutant.json (job
5894ec48-e4e9-4b19-ace7-86f3f51291a9).

```
node solidity/trio-alloc2/byte-sequence.mjs audit/trio/alloc2/receipt-d36a873d-c8f9-4604-bd20-b039c005a877.json
ALLOC2_BYTE_SEQUENCE_MUTANT=reset node solidity/trio-alloc2/byte-sequence.mjs audit/trio/alloc2/receipt-d36a873d-c8f9-4604-bd20-b039c005a877.json
```

These are physical-source/EVM comparisons, not a claim that the pending indexed
Verity runtime has passed. That job87bd remains queued on nippur. The root build
04ef92f0-4338-4fd0-abfb-587bdf0bdd36 passed 1531 jobs at
b9da6107262e32b7e6d0f960d696fbf1ce4886db, before the byte-memory files were
committed; it is not final-head root validation. Full make prove/test and the
remaining composition obligations above are unfinished.
