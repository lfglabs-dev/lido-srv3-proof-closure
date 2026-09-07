# Actual producer and parent conversion checkpoint

ParentConversion.lean models the ordered post-library conversion at pinned
SRLib.sol:415–431. It proves exact scalar success conditions and values, zero
demand overflow, and safe uint256 source-index increments. The total-allocation
multiplication bound is derived from actual checked division and actual
allocation success: allocatedTotal * unit <= inputAmount < 2^256. Overflow of
that multiplication in the standalone conversion fragment is consequently not
presented as a reachable parent failure. Per-row multiplication can still fail.

The consumer-owned composition/Parent.lean runs the pinned actual ALLOC-1
producer, preserving the empty-count guard, division, call transcript, allocation,
and both conversion branches. The first two guard/error ordering theorems are
checked. ParentVectors.lean emits eight actual model executions and their input
parameters. It uses a test-only slot projection and normalized module addresses;
the Solidity harness uses physical keccak slots and deployed module addresses.
This normalization is an execution-fixture relation, not a physical-memory proof.

Remote parent/composition job 411a7646-5694-42fc-9173-37012c66f717 succeeded
with 33 jobs and all eight parent plus eleven library ABI vectors. Its complete
32-file closure is composition/source-identity.json. Consumer arithmetic job
b024369c-68e3-4a39-a4db-f2f9744cad58 succeeded with 27 jobs and the complete
26-file closure in differential-source-identity.json. No sorryAx occurs in these
successful axiom reports. Earlier failed receipts retain the parser/proof errors.

solidity/trio-alloc2/parent/run.cjs compiles the exact pinned SRLib and recursively
links its real libraries with solc 0.8.25, viaIR, optimizer 200, Shanghai. It pairs
model inputs, output/revert bytes, and module calls with actual execution. Cases
include normal allocation, zero demand, empty count with zero divisor, division
before producer calls, zero-demand conversion overflow, second-row overflow,
late raw producer rejection, and malformed summary bytes. Transaction traces
check module order, MinFirst library invocation/absence, no SSTORE, no events,
and unchanged seeded storage and balances. This is finite differential evidence.

The parent dependency lock marks Ganache's bundled Darwin fsevents optional,
matching chokidar's optional dependency; clean npm ci succeeds on Linux. Ganache
reports its unavailable native uWS binary and uses its JavaScript fallback.
The receipt reader accepts the remote protocol's optional operations_sha256 field
while retaining exact source digest, file count, local source hashes and pin checks.

Full root build 560e32a9-a498-4c0f-9ad3-d225ccf4ca9d succeeded with 1526
jobs at 4dce12b799ae9950901a680b4ac976210f786929. It does not certify these
new files. UX2 b210e56f-7247-49d7-912c-3265e5d596cd passed at b279d57;
a fresh fixed-source run is required after this checkpoint is committed.

Still required: universal parent conversion correspondence; producer byte extent
and physical memory/copy/ABI relation; Verity runtime differential execution and
parent mutants; parent frame/rollback proof; producer agreement/integration;
final current-source make prove/test/trust receipts and independent review.
The separate +1 algorithm is unchanged. This checkpoint is not certification.

Paired execution completed successfully: durable job
fd0dc861-43de-4198-90ce-f4cb8b194f0e exited 0 with all eight parent cases;
4b4dccc4-046a-444e-8eb1-083255dc0ae9 exited 0 with 116 library comparisons.
The first paired attempts rejected the new receipt field before executing tests;
no source-identity assertion was bypassed. Proof escape and source annotation
checks passed. Provenance regression initially rejected the untracked new Lean
file as intended; it must be rerun after committing this source.
