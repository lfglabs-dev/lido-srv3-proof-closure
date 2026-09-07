# Pointwise parent return values

ParentValues.lean states and proves values at every index of successful
positiveRows and zeroRows execution. Positive conversion gives
(newAllocation - originalAllocation) * unit and newAllocation * unit.
Zero-demand conversion gives zero and originalAllocation * unit. Both preserve
entries outside the visited range. The public positive_values and
zeroDemand_values theorems include total allocation and all visited rows.

The 29-job consumer build 72722f6e-8035-4b0c-85cb-85e9e86627cd succeeded
with the complete 28-file closure. Axiom reports contain only propext,
Classical.choice and Quot.sound. Earlier failed receipts retain the simplifier
errors; no proof escape was introduced.

Consumer-owned ParentPostconditions.lean connects these formulas to actual
Parent.run returns and actual producer outputs. Positive-branch consumer success
is derived from the producer; the resulting allocation satisfies the independent
Spec.Distributes relation. The zero branch retains producer calls before
conversion. Both return the exact producer transcript. These are decoded
compositional postconditions, not compiler-memory or parent EVM rollback proofs.

UX2 passed at 1fac020. Full root job 44749901-f424-4f4a-8396-089420f242e9
is still live at that earlier head; reconcile it before another full submission.
The remote service rejected lake env make prove test before job creation,
HTTP 422: lake command must use build, test, check, or fixed env lean form.
The full lake build is not a substitute for actual make prove/test receipts.

Still required: exact parent conversion success/error conditions, producer byte
extent and reachable memory allocation, compiler dispatch/copying/noncanonical
ABI correspondence, parent frame/rollback and mutants, producer agreement and
integration, final current-source full validation and independent review.
The separate +1 algorithm remains unchanged. No merge or deployment.

Final composition job 8b45612f-72ab-422e-be2f-3488195f6399 succeeded,
36 jobs, with the complete 35-file closure. Both branch connections and both
composed postconditions report only propext, Classical.choice and Quot.sound.
Runtime refresh d97d5d80-6558-443e-8379-7acce3a602af succeeded, 44 jobs,
39-file closure and all eleven vectors.

inspect-memory.cjs compiles the exact pinned SRLib with solc 0.8.25, viaIR,
optimizer 200 and Shanghai and retains generated allocation/size excerpts plus
compiler input, source, lock and IR hashes in parent-memory-inspection.json.
Full generated IR is in ../output/alloc2-parent-memory.yul (regenerable). The
emitted finalize_allocation rejects newFreePtr > 2^64-1 or wraparound with
Panic(0x41). Array sizing separately rejects length > 2^64-1 before computing
32*length+32. The producer allocates its allocation array and cache (including
five-word per-row cache structs) before module calls; capacities are allocated
later. These observations identify a path to deriving byte extents from actual
successful memory allocation, not from the decoded count word alone. They are
compiler inspection evidence, not yet a formal memory-prefix refinement.

Current paired suites exited 0: 7815bd0c-4439-4ecf-90e2-2dca85fc871e
passed eight parent cases; 41056367-32e6-46a0-82a9-dd5d5080a507 passed
127 byte comparisons. Compiler inspection c1c9502d-6388-4b7f-af35-776fdff45e05
exited 0. Generated metadata checks, proof escapes and source annotations passed.
