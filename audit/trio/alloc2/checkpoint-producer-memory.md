# Interleaved producer allocation guards

The resumed goal turn makes implementation and validation progress. It is not
full ALLOC-2 closure. The +1 algorithm remains separate and unchanged.

The initial producer memory differential failed: one-row Solidity returned a
free pointer of 1536 versus the draft model's 1024. Pinned solc 0.8.25 viaIR
optimizer-200 Shanghai output for ParentHarness.capacity reveals runtime
`constant_ROUTER_STORAGE_POSITION()` evaluations. Each emits two 64-byte ABI
allocations (the string hash input and the decremented hash input). They were
absent from the draft schedule. The corrected guard interpreter executes:

- One slot evaluation before the count read and allocation prefix.
- Two slot evaluations before each row's 224-byte storage-to-config allocation.
- One slot evaluation after enum validation, before the summary call.
- An additional slot evaluation before each type-2 stake call.

These are separately checked allocations, not a final-pointer adjustment. The
existing array/cache prefix, initial 224-byte config, bounded copied return data,
and post-scan capacities array remain in their execution order. Invalid enum
fails before the summary-address slot evaluation. A reverted call does not
finalize its copied return buffer; a short successful return does, then fails
decoding. The model still abstracts keccak, byte stores/copies, gas and dispatch.
This schedule is tied to the inspected capacity harness compilation, not silently
generalized to every compiler configuration or the complete public parent.

`ProducerMemory.produce_refines` proves by induction over the executed monadic
stages that the result is either a memory panic or the original producer result
with the same attempted-call transcript. `success_establishes_premises` derives
actual producer success and DecodedConsumerPremises. `success_prefix` extracts
an executed allocation segment after the slot buffers. `success_byte_execution`
uses its derived bound for the actual producer arrays, without assuming a
separate memory-prefix success or decoded producer output.

Reproduction from the checkout:

```
python3 audit/trio/alloc2/composition/prepare.py
cd ../temp/alloc2-composition/audit/trio/alloc2/composition
remote-lean-build lake build
```

Build 5f2465ec-7267-49a8-883d-53a74d58ef3b passed 46 jobs. The receipt's verified
source overlay is checked against composition/source-identity.json by the runner:

```
node solidity/trio-alloc2/parent/producer-memory.cjs audit/trio/alloc2/receipt-5f2465ec-7267-49a8-883d-53a74d58ef3b.json
```

All six exact outcome/call/free-pointer cases pass. Pointers are 1536 (one row),
2496 (two rows), 1696 (type two), 1408 (short summary), 1376 (rejected summary),
and 1248 (invalid enum). producer-memory-execution.json binds the Solidity pin,
compiler/settings, imported source hashes, harness, runner, lockfile, linked
bytecode and successful Lean receipt. These are finite differential tests, not
universal physical-memory correspondence. The pre-correction build failure is
retained in output/alloc2-slot-memory-build.log outside the repository.

The known full root job 405e9302-5afc-4e1e-9fb7-7b6c53a87c6e was re-polled and
is now succeeded, exit 0, 1531 jobs at da334fcf22585f9edc6452298414c2541254c877.
This is earlier-head evidence. Metadata, source annotations, proof-escape and
UX2 artifact checks pass locally. test_ux2.py reaches its Lean elaboration check
and fails because the local Lake shim has no real binary; no local regression
PASS is claimed and the remote-required compute policy is preserved.

Remaining original obligations include full physical compiler memory/copy and
public dispatch refinement, lifecycle/migration reachability, complete consumer
integration, exact-current-head full prove/test gates and independent review.
Successful migration/version must not be used to infer legacy admission bounds.
No certification, merge, rebase or force-push is claimed.
