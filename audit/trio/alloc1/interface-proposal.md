# ALLOC-1 producer interface proposal — v0, awaiting mediated agreement

Base: `c7adae04416704a839d56333efad003f0a0f46b7`.
Solidity: `17005714f151e5502c559932319a3f2f74ac2436`.
Namespace: `LidoSRv3.Audit.Source.TrioAlloc1`.
This is a proposed producer contract, not an agreed shared type or a completed
source-correspondence claim. ALLOC-2 owns its consumer and composition. Incompatible
changes require explicit producer/consumer agreement through the orchestrator.

## Cut and exact ordering

Cut is SRLib.sol `_getModulesAllocationAndCapacity` (493–559), returning two
`uint256[] memory` arrays to `_getDepositAllocations` (391–431), immediately before
the latter calls the external MinFirst library. Producer input demand is already
`allocateAmount / cfg.maxEBType1`, in WC01 validator equivalents. The outer function's
zero-module return precedes division; do not move this guard into the helper.

All module IDs are enumerated by `SRStorage.getModuleIdAt(i)` in EnumerableSet's
stored array order. Neither inactive modules nor WC01 modules in top-up mode are
removed. IDs and addresses are distinct concepts. Array index is neither an ID nor
an address. The producer emits the exact two arrays; identity annotations in Lean
are ghost observations, absent from Solidity memory/ABI. Inactive capacity equals
its current allocation. Active capacity can be BELOW its current allocation.
There is no read-time `min(count, 32)` guard in the pinned helper.

First loop: read ID, copy packed config, cache share/status/WC; call summary; cache
depositable; checked deposited minus max(summary exited, router exited); cache
active; for WC02 only call stake then ceilDiv(stake, maxEBType1); write allocation;
checked add allocation to total. Finish every first-loop row before allocating the
capacity array and starting the second loop. Second loop: initialize capacity to
allocation; if Active, calculate top-up active*maxEBType2/maxEBType1 for WC02 or
allocation+depositable otherwise, THEN calculate share*total/10000 and take min.
The checked operations and their failure precedence are not interchangeable.

## Representation proposal

`Word = Fin (2^256)`, `Address = Fin (2^160)`, bytes `Fin 256`. Output arrays hold
Word values in validator equivalents, not wei or gwei. Stake responses and Config
maxEB fields are wei. Router accounting balance is gwei; accounting exited is a
uint64 count. Module config fields: address bits 0–159, moduleFee 160–175,
treasuryFee 176–191, share 192–207, exit threshold 208–223, enum status 224–231,
WC 232–239; upper 16 bits reserved. Accounting exited is bits 64–127 at module
base+2. Deposits and name occupy module base+1 and base+3.

Physical router base is SRStorage.ROUTER_STORAGE_POSITION's ERC-7201 expression;
module mapping is at base, ID array length base+1, ID positions mapping base+2,
router accounting base+3, withdrawal credentials base+4, packed lastModuleId and
maxTopUpPerBlockGwei base+5. Module record base is keccak256(abi.encode(id, base));
ID element i is at keccak256(abi.encode(base+1))+i (word arithmetic).
These layout obligations must be tied to pinned dependency layout and compiler
storage output before claiming physical correspondence. Keccak is not assumed
injective over all words. Any relevant-slot separation premise must be explicit.

The initial Lean definitions express a mathematical view and its word-memory
relation. They do not yet prove the compiler's byte-memory or library ABI bridge.
`MemoryArraysRelated` requires both exact lengths and every length-prefixed element
at byte pointer+32*(i+1), disjoint allocations, and valid bounded pointer arithmetic.
Consumer ABI is a separate copied encoding: MinFirst is an external library and
its mutations do not alias the caller's `allocated` array. Producer itself returns
internal memory arrays, not ABI-encoded returndata.

## Outcomes and observations

Proposed result: `Except Failure CapacityOutput`, with explicit attempted-call
trace carried by the execution layer even on failure. Failure includes raw revert
bytes, empty decoder failure, panic code, and exceptional call failure; raw external
revert payloads must be preserved, not replaced by a successful-callee premise.
Summary accepts a uint256 triple (exited, deposited, depositable) at byte offsets
0/32/64 with minimum length 96; stake accepts a uint256 at offset 0 with minimum
length 32. Trailing bytes are permitted. Exact solc code-existence/returndata rules,
malformed enum panic, panic encoding, and exceptional behavior remain obligations.

State/input relation must bind actual storage, router immutable Config, entrypoint
arguments, router/library addresses, call context, and the same adversarial callee
behavior. getDepositAllocations is permissionless view; no invented authorization
flag. Writer proofs must derive role admission from router state and caller.
Observe outcome/returns, relevant storage and balances, call kind/target/value/raw
payload/order/returndata, and committed events. This view helper performs no storage
writes, value transfers, or events; memory changes before failure are discarded by
its caller frame. Full parent rollback and writer rollback after intermediate
storage changes remain separate required proofs, not inherited from AllocationTx.

## Derived versus open bounds

Type decoding supplies only width bounds (uint16 share, uint64 accounting exited,
uint256 external fields). `_addModule` rejects count>=32 and duplicate addresses;
share writers validate share<=10000. Proving reachable invariants requires genesis,
migration assumptions and every relevant writer, including uint24 last-ID handling.
These are source observations, NOT discharged Lean reachability theorems yet.
Migration copies old config and therefore needs its own validated pre-state relation.
Arbitrary summary/stake responses do not inherit router writer bounds. Underflow,
addition/product overflow and zero-divisor outcomes must be modeled, not assumed
away. An unconditional always-success capacity theorem is not proposed.

## Initial exclusions and outstanding gates

Excluded: gas-cost equivalence, full deployed bytecode refinement, full consensus
truth, cryptographic correctness/injectivity. Solidity compilation and library
linking/runtime provenance remain explicit assumptions. Permitted static callbacks
must be represented or separately excluded at a precisely stated correspondence
boundary; arbitrary rejection is in scope.

Open: physical/byte ABI proofs; actual executor and independent specification;
all-outcome correspondence and rollback; reachable writer bounds/address uniqueness;
executed pinned Solidity/Verity differential and parent-shaped mutation tests;
production/test/trust and full repository validation. No existing declaration is
replaced and no canonical status is upgraded by this checkpoint.
