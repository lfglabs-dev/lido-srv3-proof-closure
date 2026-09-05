# Stage B allocation boundary slice

`MinFirstSourceEntry.allocateDecoded` is additive. The registered ALLOC-2 parent
still refers to the earlier transaction; no guarantee status or hypothesis has
been changed. This slice does not complete Stage B or its reserve/composition work.

The pinned library accepts `(buckets=[7], capacities=[], demand=0)` and returns
`(0,[7])`. It accepts `([0],[5,0],3)` and returns `(3,[3])`. The previous
`MinFirstDistributionTx.allocate` rejects both at its eager equal-length guard.
A short capacity array with nonzero demand instead reaches the first scan and
panics with `0x32`; surplus entries are unused. The new decoded entry implements
these boundaries before using the existing proportional word loop.

Its successful execution refines the independent unbounded proportional model
under explicit row representation and word-sized row-count premises. Zero-demand
and short-array theorems quantify over arbitrary lists. Contract-state preservation
and rollback quantify over every entry state. There are no observation-storage
writes or injected-failure branches in this pure entry. These results do not prove
ABI decoding, physical memory layout, full loop transcription, fuel sufficiency,
or capacity/distribution composition. The bounds error is distinct from unresolved word-loop failure (arithmetic or
fuel); the latter is not assigned a Solidity panic identity. Exact encoded
revert bytes are not yet a Lean theorem. The separate +1 algorithm is untouched.

`AllocationTx.live_revert_restores_snapshot` separately adds rollback for the live
wrapper under arbitrary modeled callee results, including the existing failure
hook. This theorem does not remove that hook or its synthetic observation slots,
and does not fix hoisted calls. The earlier comment claiming staticcall alone
justified hoisting is corrected: checked arithmetic can prevent a later call in
Solidity. No full-trace equivalence has been proved.

## Executed differential check

Run `bash scripts/test_minfirst_source_differential.sh`, also required by
`make test`. Prerequisites: the pinned Lean toolchain, Foundry/Forge with solc
0.8.25 available, and the pinned `lido-core` checkout. The script checks its SHA
and the bytes of both imported source files before building the Lean module
and executing Forge with FFI. `lake env lean --run` executes the actual Verity transaction;
Forge imports and runs the pinned Solidity library. Neither side is a copied
fixture oracle. FFI is needed only to invoke the local model runner.

The harness compares success/revert class, panic identity, allocated amount and
every returned bucket. It checks empty/mismatched arrays, zero demand, surplus
capacities, exact caps, full/overfull buckets, equal bucket values, proportional
allocation and uint256 boundaries. Two negative comparisons substitute the old
eager-guard transaction and require mismatches on its source-success witnesses.

Normalization is `(success, allocated-or-panic-code, returned-buckets)`. Solidity
revert bytes must be exactly a 36-byte `Panic(uint256)` before normalization; a
model's legacy error string is a separate sentinel. This pure slice emits no
events and accesses no balances/storage. The caller/library delegatecall/ABI
boundary is excluded, so the test does not claim to compare that boundary's call
trace or gas. Decoded inputs cannot test malformed ABI bytes. Sequential behavior
is not claimed. Tests support transcription review; they are not correspondence
proofs or evidence for the other ten paths.
