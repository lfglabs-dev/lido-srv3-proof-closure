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

The indexed Lean proofs also passed in byte-memory job
caec8506-fa63-424c-83be-5a80ccbb04f1 (38 jobs), followed by
d36a873d-c8f9-4604-bd20-b039c005a877 (39 jobs). Validation of the indexed
Verity runtime remains pending. Earlier draft builds failed with
Lean proof-script errors; none is positive evidence. Job
87bd283a-a145-41c4-833d-dc31f64a2a24 on nippur was re-polled and is queued, not
terminal. Do not replace it merely because observation expires. An intervening
auto-placement request was rejected before compilation on old-agent: 258 GiB
free versus 12 GiB estimate plus 250 GiB emergency floor. No floor was changed.

The prior root build bc88cbaa-3898-4c3b-8d1b-0fdc345a2966 is now succeeded:
1531 jobs at 3e254f729300dde1d41089bbade6eb244bd1036d. It is earlier-head
evidence, not current indexed-source or final-head validation.

Reproduction after materializing the manifests:

```
python3 audit/trio/alloc2/composition/prepare.py
python3 audit/trio/alloc2/runtime/prepare.py
cd ../temp/alloc2-runtime/audit/trio/alloc2/runtime
REMOTE_BUILD_NODE_ID=nippur remote-lean-build lake build
```

Once a matching successful runtime receipt exists, run the positive and reset
mutant memory-sequence.mjs commands. Old receipts must fail admission because
both source and harness have changed. Complete UX2/full prove/test gates,
producer-created memory contents, byte-store/copy correspondence and the open
lifecycle/integration requirements remain unfinished. The +1 model is unchanged.
