# Public allocation wrapper integration

`LidoSRv3/Audit/Source/TrioComposition/Parent.lean` adds the decoded
`SRLib._getDepositAllocations` wrapper from pinned Solidity
`17005714f151e5502c559932319a3f2f74ac2436`.

The executor preserves the storage-count-zero branch before division, converts
requested Ether to WC01 validator units, calls the actual producer even for zero
demand when modules exist, uses the proportional consumer for positive demand,
and performs checked total/delta/new-allocation Ether multiplication in source
order. The original allocation list is retained across the interpreted external
library call. This represents the required copy boundary; it is not yet a proof
of solc's DELEGATECALL/ABI implementation or its concrete memory mutations.

Theorems currently checked:

- `getDepositAllocations_empty`: empty storage enumeration returns empty arrays
  before division or any module call, even with zero initial-deposit unit.
- `getDepositAllocations_zero_unit`: nonempty enumeration and zero unit fail
  with panic 0x12 before any module call.
- `convertPositive_refines` and `convertZero_refines`: successful per-row
  conversions satisfy independent unbounded Ether equations, including the
  zero-demand branch. These component theorems expose list-length premises.
- `getDepositAllocations_total_bound`: every successful actual wrapper run
  returns an Ether amount no larger than requested; no callee/consumer-success
  hypothesis is supplied. The proof combines executed division, the consumer's
  demand bound and the actual checked final multiplication.

Nine execution checks cover empty enumeration, division priority, rounding down,
zero-demand module reads and rejection, late Ether multiplication overflow,
subtraction underflow, failure after an earlier row converted, and short arrays.
They execute the Lean source model, not Solidity or Verity Contract.run. Test
layout hashes are instrumentation, not actual keccak evidence.

Still required: concrete Solidity correspondence beyond the decoded public model;
exact delegated library call and ABI return/revert bytes; concrete
allocation/copy/mutation and panic precedence; caller/deployment binding;
state/balance/event frames and recursive callback interpretation;
registered-parent mutants; full gates and independent
certification. The existing byte-memory bridge is a representation theorem, not
compiler-memory execution evidence. No canonical guarantee is upgraded.

## Composition with ALLOC-2 row bounds

ALLOC-2 `4dce12b799ae9950901a680b4ac976210f786929` is integrated locally.
`ParentComposition.lean` discharges the conversion length premises using actual
producer storage-count correspondence and actual consumer length preservation.
It also derives success of the exact `TrioAlloc1.checkedSub` called by the parent
from the new consumer row bound. Later Ether products remain checked operations,
with executed overflow tests; their success is not assumed or asserted globally.

The 32-module Init-only closure passes, including all 16 memory/parent execution
checks. `parent-composition-init-receipt.json` records the checked file hashes.
Metadata, proof-escape and import-DAG checks pass. The UX2 regression also passed
on the previous committed memory-composition head `b5dff873`; that result is not
a gate for subsequent parent or row-bound changes.

## Exact decoded parent relation

`ParentRelational.lean` specifies returns, reverts and attempted module-call
prefixes using independent arithmetic relations, producer relations and the
independent proportional distribution relation. It derives consumer success from
actual producer length/bound evidence; no successful-callee or consumer premise
is added to the public theorem. Row relations retain first-error order.

`ParentDeterminism.lean` proves uniqueness of mathematical distribution, consumer
outputs and the complete parent relation. `ParentSpec.public_iff` proves exact
two-way correspondence between that relation and the public SOURCE executor for
all outcomes. Compiler-memory execution, delegated library ABI and concrete EVM
world binding remain open. This is not full Solidity/Verity correspondence.

The 37-module Init-only closure passes. Four executed mutants change division
priority, skip zero-demand module calls, return validator units instead of Ether,
or erase failure transcripts. All produce mismatches; the generic
`changed_observation_rejected` theorem links any such discrepancy to rejection by
`public_iff`. These are SOURCE-parent tests, not canonical registered-parent or
VM mutants. The original 16 execution vectors also pass. The receipt is
`parent-iff-init-receipt.json`; all checked source hashes were compared with the
working tree before recording it.

## Executed canonical library ABI in the parent

`ParentABI.lean` adds `getDepositAllocationsABI`, which executes argument encoding, library byte
decoding, proportional allocation, return encoding and caller-side return
decoding before the checked Ether conversions. `public_abi_iff` transfers the
independent all-outcome parent relation to this executor, preserving module-call
transcripts. Consumer success and return size are derived from producer results.

The `ReachableABIExtent` premise applies only to positive-demand producer
outcomes reached after the actual division. It is still an unproved compiler
allocation/reachability obligation. The theorem is not deployed DELEGATECALL,
physical memory, or concrete EVM world correspondence. The explicit bound is
not removed by the finite vectors.

The 41-module Init-only closure passes with standard axioms only. Six existing
parent scenarios now also execute the ABI wrapper and compare exact results and
complete module transcripts, alongside eleven byte vectors, the original sixteen
vectors, and four SOURCE parent mutants. The receipt is
`parent-abi-init-receipt.json`. No canonical guarantee or certification status is
upgraded. UX2 passed on the earlier ABI integration head `2d8e182e`.

## Allocation primitive bounds

`AllocationExtent.lean` derives the exact nonwrapping end pointer from a
successful `allocateArray`, including its panic-0x41 checks. Two successful
equal-length, nonoverlapping allocations after the ABI head imply the canonical
packet's 64-bit extent bound; gaps are allowed and no fixed module-count bound
is assumed. The actual compiler schedule-to-producer connection remains open.
The bounded closure now checks 43 modules. This primitive result alone does not
discharge `ReachableABIExtent` for the decoded producer.

The full production/test/audit build at earlier `91684800` succeeded on DGX
Spark (1577 jobs, 455 seconds). `remote-91684800/receipt.json` records its exact
scope and the runner's capped terminal log tail. It does not certify the newer
parent ABI, allocation-extent or withdrawal-composition source.

## Writer invariant to parent byte extent

`WriterExtent.lean` derives `ReachableABIExtent` from the physical enumeration
count bound using actual producer success and its array-length theorem. It
then derives this obligation after every outcome of the checked share writer,
using `WriterInvariant.share_writer_preserves`. The initial physical invariant
and concrete slot-separation premises remain explicit. This closes that numeric
composition step, not all-writer reachability, deployment, or compiler memory.
The 49-module Init-only closure passes; see `writer-extent-init-receipt.json`.

The integration also includes producer checkpoint `4aa9557e`, consumer
`1fac0206`, and reserve `f27b39d8`. These add admission/enumeration checks,
parent array safety and a pure-library Verity runtime adapter, and concrete
queue/oracle/consensus call binding respectively. Their component receipts do
not replace final integration validation or independent certification.

## Actual parent VM differential execution

At `da32cc4e297f234726026050ccaf152b9ef038a8`, the remote driver compiled
the parent VM correspondence and executed six VM checks plus eight differential
cases. `remote-da32cc4e/receipt.json` contains the terminal service receipt.
`compare-parent-executions.py` verified the transitive VM source closure against
that commit, the original Solidity execution provenance and fixture inputs, and
all eight raw return/revert byte strings and module-call sequences. Its recorded
result is `SOLIDITY_PARENT_VERITY_PASS`; see `parent-comparison.json` in the same
directory. These are actual Verity executions, with the library still interpreted
by the source ABI executor. They do not establish compiler memory, deployed
DELEGATECALL, or recursive callback/world fidelity.

The full run failed: Foundry's four Solidity tests passed, then `make test`
stopped because the remote checkout omitted the immutable historical review-base
Git object required by the audit metadata check. Validation setup now fetches
that exact object when absent without changing HEAD. This repair still needs a
fresh remote gate run. The failed receipt remains failed; neither the successful
parent cases nor the protocol-1 build receipt constitutes independent final
certification. The log files retain only the runner's capped terminal tail.

## Parameter writer and parent values integration

Published ALLOC-1 `8691c788` and ALLOC-2 `2bb0a7dc` are integrated.
`parameter_writer_abi_extent` now transfers the public parameter writer's
physical invariant preservation to the parent's numeric ABI obligation, retaining
the initial invariant and slot-separation premises. The bounded checker also
checks ALLOC-2's new per-index parent value theorems. All 54 Init-only modules
pass; `parameter-parent-values-init-receipt.json` records the exact source hashes.
The theorem trust output uses only standard Lean axioms. This is not a full
project build or all-writer reachability proof.

The validation driver now repeats all gate outcomes at the end, allowing capped
remote logs to retain the complete gate summary. It elaborates locally. The
active full run at earlier `03f170850b5b` predates these writer integrations and
the summary change; its result cannot certify this newer source.

## Indexed conversion and parent equivalence

`ConversionBridge.lean` proves exact return/error equivalence between the
indexed in-place decoded conversion loops and the recursive conversion used by
the integrated parent, including total multiplication before row reads and
ordered late failures. Producer and consumer results discharge array-length
premises; conversion success is not assumed.

`IndexedParentBridge.lean` extends this to the complete staged ALLOC-2 parent,
preserving the empty-count guard, division, producer calls, both demand branches,
all failures and attempted-call transcripts. Consumer success is derived from
the actual producer. `indexed_parent_iff` transfers the independent parent
relation, and `indexed_parent_abi_eq` connects canonical ABI execution under the
explicit reachable extent premise. This closes the decoded indexed/recursive
model alignment, not the compiler-memory or deployed-call boundary.

All 58 Init-only modules pass; `indexed-parent-init-receipt.json` records source
hashes and standard-axiom output. The new `TrioIntegrationChecks` Lake target
wires the staged-parent bridge into the remote full-validation driver. That
expanded full target still requires a fresh remote run.

## Executed allocation-prefix extent composition

Writer checkpoints ALLOC-1 `bab36c3e`, ALLOC-2 `dee0456b`, and RESERVE-1
`91c7b92a` are integrated. `memory_prefix_indexed_abi_eq` now derives the
indexed-parent ABI equality's extent premise from executed producer allocation
guards, using ALLOC-2's primitive bridge. The placement and effects of those
guards in the concrete compiler schedule remain unproved at this boundary.

The bounded closure checks 65 modules, including public admission and
string storage, indexed/recursive parent equivalence, the producer allocation
primitive bridge and the byte-extent composition. Every checked source hash
matches the integrated tree; see `memory-indexed-parent-init-receipt.json`.
These changes still need full remote validation.

The latest ALLOC-2 Solidity record adds four early memory-limit cases to the
original eight parent cases. The existing VM parent suite executes the original
eight only. The original recorded comparison remains valid for its recorded
source and case set; it does not establish VM coverage of the four new memory
cases. They require the compiler allocation prefix in the VM parent path.

## Allocation guards in the parent call VM

`MemoryGuard.run_eq` proves the constant-time guard evaluator equal to the
iterative allocation prefix on every outcome. `AllocationParentCalls` places
that guard between division and producer calls, proves division/memory failure
priority, and derives canonical ABI extent from successful guards. Its initial
free pointer is explicit. The bounded closure passes 67 modules; see
`allocation-parent-init-receipt.json`.

`VerityParent.executeWithMemory` translates this call tree through the pinned
VM and includes world-frame and conditional public-relation theorems. The parent
differential suite now invokes it with pointer 128 and includes all twelve
Solidity cases. The comparator requires eight ordinary inputs plus four early
allocation/division inputs and exact observations. These VM additions still
require remote compilation/execution; no twelve-case pass is claimed yet.

This executes proved guard arithmetic in the source call tree, not EVM MSTORE
or solc's whole allocation schedule. Pointer provenance, compiler placement,
zeroing/stores, return-data allocation, delegated call memory and gas remain
open. The original eight-case receipt does not validate this changed VM source.
