# Existing-memory consumer correspondence

This continuation adds the missing write relation at the agreed v0 word-memory
boundary. It does not certify compiler byte memory or close the full goal.

MemoryWrite.store and writeWords perform writes into the supplied memory map.
The outside and element theorems prove frame preservation and read-after-write
for arbitrary prior memory. writeArray_related preserves the array length word;
writeArray_preserves preserves disjoint capacity arrays in either region order.
There is no fixed 128-word spacing and no reconstruction from zero memory.

run_success transfers actual decoded allocation totality, conservation and the
independent Spec.Distributes relation to memory observations. sequential feeds
the first written memory directly to the second call and proves cumulative
conservation and the second distribution relation. interface_run_success takes
the agreed producer MemoryArraysRelated as its input, derives the needed length
premise and preserves both nonwrapping extents. It does not prove the compiler
establishes that input relation; that is still an explicit producer-memory gap.
The adapter writes all final bucket words. Exact refinement to the compiler's
individual indexed stores and overlapping byte-level effects remains open.

dropped_write_refutes_postcondition refutes the universal ArrayAt postcondition
when writes are omitted, using a concrete valid initial array and equal-length
replacement. It is a kernel-checked counterexample to the write contract, not a
second specification equality or an assumed mutation result.

Runtime.memoryExecute installs the resulting memory in ContractState. The
memory_run_success theorem determines the entire returned state, preserving all
other fields. Five emitted cases execute the second Contract.run on the first
returned state: ordinary and reversed regions, capacity below current allocation,
zero first demand, and 129 buckets. Nonzero sentinel memory, capacities and
balance are checked in these executions.

The Solidity sequence uses the pinned public library twice and passes its first
returned buckets to the second call. Its original caller arrays remain separate
because the public library boundary copies through delegatecall ABI. The runner
compares exact bytes, including first/second amounts and arrays and the original
caller arrays/capacities. It checks both sets of Lean/Verity vectors and rejects
stale source manifests before execution. ALLOC2_SEQUENCE_MUTANT=reset changes
only the second Solidity call's input back to the original buckets, requiring
behavioral rejection by the exact sequence comparison.

Reproduction:

```
python3 audit/trio/alloc2/composition/prepare.py
python3 audit/trio/alloc2/runtime/prepare.py
cd ../temp/alloc2-runtime/audit/trio/alloc2/runtime
remote-lean-build lake build
```

The successful runtime receipt is then supplied to:

```
node solidity/trio-alloc2/memory-sequence.mjs audit/trio/alloc2/receipt-9170d429-ad2f-4995-8fff-166651d51bea.json
ALLOC2_SEQUENCE_MUTANT=reset node solidity/trio-alloc2/memory-sequence.mjs audit/trio/alloc2/receipt-9170d429-ad2f-4995-8fff-166651d51bea.json
```

The positive command must exit 0; the reset mutant must fail the exact-byte
comparison, not source admission or compilation. The execution receipt contains
full compiler input/output and deployed code as well as source and model hashes.

UX2 artifact generation and metadata checks pass. The complete UX2 regression
suite remains unverified here because local Lean is absent and compute policy
requires remote execution. Querying the historical durable execution service
returned Missing Authorization header, not a usable remote test environment.
Full-head prove/test, producer lifecycle/migration, compiler memory/copy/dispatch
refinement and final integration remain open. No completion claim is made.

Validation completed: remote 9170d429-ad2f-4995-8fff-166651d51bea passed
61 jobs with current source identity. The interface, sequential, dropped-write
and Verity memory theorems list only propext, Classical.choice and Quot.sound
(the dropped-write theorem uses no Classical.choice). The positive Solidity
runner exited 0 with all five exact sequences. The reset mutant exited 1 at
`two-calls exact bytes`, after successful source admission and compilation.
Receipts: memory-sequence-execution.json and memory-sequence-mutant.json.
The +1 algorithm is unchanged.
