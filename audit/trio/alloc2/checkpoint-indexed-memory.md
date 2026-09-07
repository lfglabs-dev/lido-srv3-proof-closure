# Indexed word-memory source loop

This work replaces the full-array writeback execution in the new Verity sequence
vectors with a loop that applies the source-selected indexed store at every step.
The prior MemoryWrite bulk adapter remains a separate observation model.

IndexedMemory.plan preserves the source guards, two scans, ceilDiv, next-level
and capacity clamps, checked subtraction and checked addition. Its successful
update retains the selected Nat index. plan_valid derives that index's bounds
from actual source selection; bounds are not a new caller premise.
plan_matches_step relates its result to the prior decoded source step.

store_array and store_preserves relate that single store to List.set while
preserving array headers and disjoint capacities. loop_related propagates the
relation through the source's terminating loop, including error outcomes. There
is no fuel parameter or synthetic exhaustion failure. run_success transfers the
independent Spec.Distributes theorem to the indexed execution. loop_frame proves
that word-map addresses other than the original bucket element slots retain
their entry words throughout a successful loop. This is a word-map frame, not a
claim about overlapping EVM byte reads.

wrong_index_refutes_postcondition uses a valid two-element array and the second
index to refute the exact array postcondition of a mutant always writing the
first index. The existing decoded selection/amount mutants remain separate.

Runtime.indexedMemoryExecute executes this loop in ContractState.memory.
indexed_memory_run_success fixes every other returned ContractState field and
retains the array, frame and distribution conclusions. run_short_error derives
the actual indexing failure from positive demand and shorter capacities;
indexed_after_prefix_reverts transfers that derived failure through an arbitrary
executed Contract prefix and restores the entire entry snapshot.

The five sequence vectors now execute indexedMemoryExecute on actual successive
ContractState values. A sixth runtime case checks storage, balance and memory
rollback after a prefix. MemorySequence.sol additionally writes a marker and
emits an event before the failing public library call; the runner checks exact
panic bytes, failed transaction status, no committed event and restored marker.
Public-library ABI copies are preserved; no claim is made that the library
mutates the caller's original arrays. The second sequence call uses the first
returned array.

The indexed Lean proofs passed in byte-memory jobs
caec8506-fa63-424c-83be-5a80ccbb04f1 (38 jobs) and
d36a873d-c8f9-4604-bd20-b039c005a877 (39 jobs). Runtime job87bd eventually
failed on the reserved Lean identifier prefix. Renaming it to enclosing yielded
62 passing jobs in 25bab09b-edbd-47a0-b8af-071531fe598c, including the rollback
theorem and vector. memory-sequence-execution.json now records all six passing
Solidity/Verity cases against that receipt; memory-sequence-mutant.json records
the reset mutant's expected exact-output assertion failure.

The root build 04ef92f0-4338-4fd0-abfb-587bdf0bdd36 passed 1531 jobs at
b9da6107262e32b7e6d0f960d696fbf1ce4886db. Root job
e327ddb0-19e3-47c0-9741-c51974a34331 is running at byte-proof head
924891ed58bbd9f424f298dae57b8982a82aad24. Neither is final-head validation
of the subsequent byte-entry changes. See checkpoint-byte-entry.md.

Reproduction after materializing the manifests:

```
python3 audit/trio/alloc2/composition/prepare.py
python3 audit/trio/alloc2/runtime/prepare.py
cd ../temp/alloc2-runtime/audit/trio/alloc2/runtime
REMOTE_BUILD_NODE_ID=nippur remote-lean-build lake build
```

Current differential reproduction:

```
node solidity/trio-alloc2/memory-sequence.mjs audit/trio/alloc2/receipt-25bab09b-edbd-47a0-b8af-071531fe598c.json
ALLOC2_SEQUENCE_MUTANT=reset node solidity/trio-alloc2/memory-sequence.mjs audit/trio/alloc2/receipt-25bab09b-edbd-47a0-b8af-071531fe598c.json
```

Complete UX2/full prove/test gates, actual producer/compiler memory writes and
copies, and lifecycle/integration requirements remain unfinished. The +1 model
is unchanged.
