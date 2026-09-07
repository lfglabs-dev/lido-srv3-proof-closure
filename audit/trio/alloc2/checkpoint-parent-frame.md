# Actual enclosing transaction and mutation checks

The Solidity parent harness now exposes parentWithPriorEffects. It writes 42
into a dedicated test slot, emits BeforeParent(42), and transfers one wei to a
separate account before calling the unmodified pinned SRLib parent. The runner
checks the same twelve exact Lean outcomes and module-call sequences as the
isolated parent suite. It also checks transaction status and the enclosing
caller's storage, event and balance effects.

On success, the prior effects must commit while the parent leaves the router
and module state unchanged. On failure, those effects must all disappear, even
though the actual opcode trace contains the prior SSTORE, LOG1 and CALL. Cases
include late second-row arithmetic overflow, late producer rejection, malformed
summary, division errors and early memory guards. The first frame run
4eaf2c61-05d8-40f5-bc1c-2a86ecec013d passed twelve cases; baseline run
5f17d663-3b34-412c-8f8c-0476744cccc1 passed twelve cases.

Six named mutations are applied only in compiler input memory after the original
pinned sources are verified. Each mutation has a unique source anchor. They
remove total scaling, alias the original allocation array, omit zero-demand
conversion, make zero-demand multiplication unchecked, divide before the empty
count guard, or swallow a late parent revert in the enclosing caller. The
runner requires an actual executed case and the expected semantic assertion
failure; compilation errors, signals, missing artifacts and unrelated failures
do not count as killed mutants. The swallowed-revert mutant must also show that
its prior storage, event and transfer incorrectly committed.

Reproduction from the repository root (after installing the existing locked
parent dependencies):

```sh
node solidity/trio-alloc2/parent/run.cjs audit/trio/alloc2/receipt-e4079b62-cb45-4f69-819c-739ca3496339.json
node solidity/trio-alloc2/parent/run.cjs audit/trio/alloc2/receipt-e4079b62-cb45-4f69-819c-739ca3496339.json --frame
node solidity/trio-alloc2/parent/test-mutants.cjs audit/trio/alloc2/receipt-e4079b62-cb45-4f69-819c-739ca3496339.json
```

This is concrete compiled Solidity transaction evidence, not a universal Lean
frame or compiler-refinement theorem. The original full memory/copy/ABI, gas,
producer integration, real full make prove/test, and independent certification
obligations remain open. Working-tree algorithm and pinned source files remain
unchanged; the altered mutant compiler inputs are explicitly recorded.

The current baseline and frame runner completed in durable job
ce1c4a43-11c0-4d54-917e-e5d0ec801388, exit 0: 24 cases. Both saved
execution artifacts match the current runner, harness and mutation-definition
hashes. Lean source and the composition source manifest are unchanged.

Mutation job e9979882-b8f1-4ebf-a086-edd026f2f4b9 exited 0. All six
mutants were rejected by their specified return/revert-byte assertion. The
swallowed-revert mutant additionally demonstrated committed prior storage,
event and value transfer. The aggregate artifact records SHA-256 hashes of
each actual mutant execution, with original and mutated compiler-input hashes.

Compiler-memory inspection 414a65d9-8ce3-4f85-a303-5aba3f63c614 regenerated
3528 optimized SRLib IR lines and 71 excerpts. The retained inspection artifact
is unchanged, as are the Lean source and composition closure.
