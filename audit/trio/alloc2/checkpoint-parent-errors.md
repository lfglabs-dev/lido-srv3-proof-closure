# Exact decoded parent conversion conditions

ParentSuccess proves success iff mathematical row conditions for both exact
count loops and their public conversion wrappers. Under the actual array bounds,
zero demand succeeds exactly when each original allocation times the unit fits
uint256. Positive demand checks total multiplication first, then each row's
subtraction and both multiplications in source order. Failure is exactly panic
0x11 when the corresponding condition does not hold; no arithmetic success is
assumed. Previously proved row monotonicity excludes subtraction underflow for
actual successful allocation results.

ParentErrors connects these conditions to Parent.run and actual ALLOC-1 produce
at pinned producer 8691c7881a863715ab5ec9b39631ab41243e7c91. It derives the
array bounds from actual producer lengths and consumer length preservation,
and derives total multiplication safety from actual division and allocation.
Both success and panic preserve the exact producer transcript in this decoded
execution. Producer success, successful division and the nonempty count branch
remain explicit compositional premises. This is not a compiled parent inversion
or an EVM rollback proof.

Consumer receipt 668479bb-694b-43f2-8127-bf72c92151bc succeeded: 31 jobs,
30 exact source/config files. Composition receipt
0447c927-a354-4b9e-a2c5-7cb43847e95a succeeded: 43 jobs, 42 files including
the seven pinned producer modules. Successful logs contain no sorryAx.
Failed intermediate proof receipts remain available and are not evidence of
success.

The earlier full root job 44749901-f424-4f4a-8396-089420f242e9 completed
successfully with 1528 jobs at 1fac0206b99f9447a4693a40941ae5985d9e8f4e.
It does not validate newer source edits. UX2 completed at dee0456 with durable
job 5e06b1d6-0426-45c8-8483-23115243baab, exit 0. Current metadata generation
and checks, proof-escape checks (254 Lean files), and source annotations
(726 citations, zero false/mismatched quotes) passed in durable job
cccf4c73-d45c-465d-be50-1df800f56357.

Coordination resumed: the ALLOC-1 update was accepted into its queue as message
a107c6e4-da22-450a-9796-48d6fa07f1d5 after earlier writer_identity_stale
rejections. Agreement and final integration remain open. The old nippur job
bc513385-701b-4116-a6c4-58fb9c1c67b5 was reconciled as queued, not failed.

Remaining full-scope work includes compiled parent allocation schedule and
physical memory/copy/ABI correspondence, gas and parent frame/rollback/mutants,
producer integration, real full make prove/test, current immutable-head full
validation and independent certification. No full closure is claimed.

Runtime receipt 1746e384-4d02-473a-9b59-a60f9890495b succeeded with 47
jobs and the exact 46-file closure. The compiled parent differential
b14d1478-8010-4332-99f8-047e0d4c8f74 exited 0 for all twelve cases.
Producer branch advanced to b171b363c5948705894d36d5cdeb414a2bd77c0a;
the seven consumed modules are unchanged from the validated 8691c78 pin.

Byte differential 450d3971-2d69-47f4-b4e5-84bbc13c0bae passed all 127
exact return/revert byte comparisons using these three current receipts,
including the caller-copy boundary checks.
