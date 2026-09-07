# Pinned Verity byte-memory denotation

Pinned Verity e977aaad6e1a9e92e0132d41b3d33a14135a4d46 contains
Verity.Core.Model.DenoteMemory, a byte-precise memory module distinct from the
historical ContractState word map. ByteRuntime.view observes Memory.readByte,
including zero filling beyond size. view_writeWord proves exact correspondence
between its actual writeWord primitive and the physical ByteMemory.store.
readWord_decode is definitional, with no axioms. mstore_result and mload_result
refer to denoteMemoryOp itself and include its memory/size result.

ByteLoop executes the proportional loop over that pinned memory structure using
readWord and writeWord. Its universal loop relation includes error outcomes;
run_success transfers independent Spec.Distributes. ByteInitialize executes the
array-header and element writes through the pinned primitive, and its producer
bridge derives the array entry relation and consumer execution from the actual
ALLOC-1 produce result. No ArrayAt or callee-success premise is supplied to that
bridge. As before, its adjacent serialization layout still needs correspondence
with the compiler's interleaved store/copy schedule.

The covered-mload lemma states when memory expansion is the identity. The
initializer derives full array coverage and preserves word alignment; the
loop-size theorem preserves the initialized extents through all iterations.
Targeted build aff984a0 passed 65 jobs. Final build
e47f752f-ca00-44fb-bda3-0ba31f319483 passed 74 jobs, including header and
whole-run coverage corollaries. Threading these facts
through the complete compiler read schedule remains separate. The loop directly
uses readWord; no full lowered-Yul program, dispatcher, EVM address-space, or gas
refinement is claimed. The canonical source Denote and ContractState still use
their historical word maps; this module does not silently change those models.

Initial job3a39de23 failed because the new Lake library omitted the imported
composition modules. The corrected package passed 72 jobs in
eade96ff-4171-4b41-8993-186ff467d722. The subsequent vector build960940c0 failed on an unused copied helper with
the wrong memory type. Its printed vector output is not a passing receipt.
The helper was removed; corrected build44f69c14 passed 73 jobs. Its 47-file
manifest admitted six exact Solidity comparisons and the expected reset-mutant
assertion failure. The new ByteCoverage extension brings the manifest to 48
files. Build e47f752f passed all 74 jobs, and the refreshed six-case differential
passed (durable 507e0c05). The reset mutant reached and failed the intended
`two-calls exact bytes` assertion (durable 3e4955a3).

ByteVectors starts from actual DenoteMemory.Memory.empty, constructs arrays,
and executes the five sequential cases including 129 rows. A separate vector
stores 1 at byte128, loads from byte159 and checks value2^248 and expanded
size192 via denoteMemoryOp. DenoteSequence.sol exposes the same overlapping
load and msize observation. Its compiler settings deliberately disable the Yul
optimizer to permit msize; optimizer enabled/runs200 and Istanbul otherwise
remain explicit. No gas-equivalence claim is made.

After successful current source admission, denote-sequence.mjs compared five
library sequences plus overlap/msize against the pinned Solidity library and
harness. The reset mutant must reach the intended exact-output assertion.
This is distinct evidence from prior word-map ContractState tests.

```
python3 audit/trio/alloc2/byte-runtime/prepare.py
# in ../temp/alloc2-byte-runtime/audit/trio/alloc2/byte-runtime:
REMOTE_BUILD_NODE_ID=nippur remote-lean-build lake build
```

Still OPEN: complete read/allocation/copy scheduling and its bounds, canonical
source/Yul integration, lifecycle and enclosing consumer composition, and immutable-final-head full prove/test/UX2/trust gates. The canonical UX2
parent now includes the well-founded success/error domain; build c54d0852
passed 1529 production/test/trust-import jobs with verified source identity.
The +1 algorithm is unchanged.
