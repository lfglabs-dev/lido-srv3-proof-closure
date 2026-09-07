# Row bounds and parent delta subtraction

`RowBounds.lean` proves `step_row_bounds`, `allocateLoop_row_bounds`, and
`allocate_row_bounds` for actual successful decoded execution. Each row starts
at `before`, ends at `after`, and satisfies `before <= after <= max(before, cap)`.
This admits zero, saturated, and overfull producer rows. Sufficient capacity
length is the existing consumer premise, already derived from actual producer
success by the composition theorem. No assumed <=32 count cap is introduced.

`allocate_delta_success` derives success of the parent checked subtraction
`newAllocations[i] - allocated[i]`. This addresses subtraction only; later wei
multiplications and their ordered errors remain open, as do the caller-copy
memory premise and its byte/ABI refinement.

Remote job 4b111ff4-89b5-474e-9b8e-0ddbba3a2656 on ashur succeeded with
exit 0 and 26 jobs. All four axiom inspections report only propext and Quot.sound.
The complete 25-file closure is recorded in differential-source-identity.json.
Earlier error receipts record the corrected Init-only tactic/helper names.

UX2 job d8d54361-7d60-48f1-b47d-c0c9cd5361a1 failed closed because
RowBounds.lean was added while the suite ran. It reported an untracked Lean
input, not a semantic regression. No gate was weakened; rerun must use a fixed,
committed source tree. Current main remains the branch base bcfbb5f027a5c370594891c1a455fde137709941.

The earlier full build 18f4a484-2c2b-44e1-be0e-ed7ceb8ec681 remains subject
to exact-handle reconciliation. It targets 02e5d3c and cannot certify this source.
Full make prove/test/trust, current-source UX2, byte-memory/ABI, parent conversion
and observations/rollback, Verity execution differentials, parent mutants,
producer integration/agreement, and independent review remain required. The
separate +1 algorithm is unchanged. No merge or deployment is authorized.
