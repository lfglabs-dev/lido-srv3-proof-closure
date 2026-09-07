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

## Empty-branch allocation and exact compiler evidence

Read-only retrieval of the complete optimized SRLib IR matched the writer's
recorded SHA-256. `compiler-memory/SRLib.ir.yul` preserves it, and
`compiler-memory/inspection.json` identifies five relevant source spans. The
empty branch emits two 32-byte allocations before returning; it skips division,
but does not skip allocation. The guarded parent now models their possible
panic 0x41 under its explicit pointer input. Four source execution checks cover
empty failure/success and nonempty division/allocation/call precedence. The
68-module bounded closure passes; see `allocation-parent-empty-init-receipt.json`.

The IR also shows a further 224-byte scratch configuration allocation after the
array/cache prefix, 224-byte configuration allocations within the producer loop,
and response allocation before short-return decoding. Those interleaved effects
are not yet in the guarded parent. The archived inspection is evidence directing
that remaining work, not a refinement theorem.

Full remote job `7d446706-1b44-4950-82ef-3537bd3e6f66` on old-agent is
running at `8bf49588`, under durable job
`b6ea9946-055f-5a46-9072-885ed6cc56d1`. It includes the VM guard translation
and twelve-case suite, but predates the empty-branch correction. The earlier
Nippur job at `03f17085` failed `make test` on the stale canonical receipt tree
after passing the full build and proof gate. Neither is final-head certification.


## Response allocation and decoding

`ReturnMemory` models the pinned compiler's successful STATICCALL response
allocation before decoding. Its all-outcome decoder projections prove that
clipping to 96 summary bytes or 32 stake bytes preserves the decoded result.
The call-tree correspondence theorems derive allocation safety from an explicit
pointer bound of 2^32, for arbitrary response length, and preserve attempted
calls. Allocation failure precedes short-return decoding; reverted and
exceptional calls bypass successful-response allocation.

`return-memory-init-receipt.json` checks 70 Init-only modules with matching
source hashes. Seven source cases cover short/empty responses, allocation
failure priority, rejection/exception priority, and both copy caps. Seven
corresponding VM cases are wired into `RunVerityParent` but have not yet been
compiled or executed remotely. These helpers are not yet threaded through the
whole producer; physical memory stores/copies, initial pointer provenance and
gas remain outside these proofs. The compiler inspection now preserves the
stake-response span as well as the summary-response span.

`remote-03f17085` archives the authoritative failed receipt and complete durable
logs. Its full build and `make prove` passed, along with 12 producer vectors,
six parent VM checks and eight emitted parent differential records. `make test`
stopped at the stale canonical validation-receipt tree. Its recorded scope
predates the guarded parent and does not establish a twelve-case comparison.
The canonical tree binding must be refreshed after staging each complete
integration checkpoint; refreshing that binding does not certify the new code.


## Published writer integration at 2026-09-07 14:43 UTC

Integrated ALLOC-1 `56787713`, ALLOC-2 `5b40ce1d`, and RESERVE-1
`a102dae0`. The readonly checkpoint found each local HEAD equal to its remote
branch, but ALLOC-1 had an unpublished `RecordInvariant.lean` and RESERVE-1
had unpublished `ACL.lean` and receipts. This is not an all-work-pushed checkpoint.

ALLOC-1 now proves public admission preserves the physical producer invariant
under explicit lifecycle-record and finite storage-separation obligations.
ALLOC-2 characterizes exact conversion success/arithmetic failure and supplies
actual enclosing Solidity rollback cases plus six source mutants. RESERVE-1
adds physical sequence refinement and concrete Aragon/Kernel permission
forwarding. Those component results retain their documented assumptions and
are not final-head independent certification.

The combined Init-only check passes 73 modules including `AdmissionFacts` and
`ParentErrors`; `writer-admission-parent-init-receipt.json` binds every checked
source hash. The full remote target now also includes staged `ParentErrors`.
The canonical metadata, proof-escape, source-annotation, import-DAG and Python
quality checks passed on the combined source. Full remote validation of this
integration remains required, including the new response-memory VM cases.


## Interleaved first-pass memory guards

`RowMemory.firstRow_exact` threads the 224-byte configuration allocation before
enum validation, followed by the actual summary and optional stake calls and
their response allocations. With pointer + 352 <= 2^32 it equals the original
row call tree plus the exact successful pointer (320 or 352 additional bytes).
`firstRow_erasure` preserves every return/error alternative and attempted call
when the pointer is erased. `config_failure` covers allocation failure before
any enum check or external call.

`firstLoop_exact` lifts that result to the complete first pass, with the explicit
budget pointer + 352*n <= 2^32. It threads each successful row's pointer rather
than independently assuming room for each row; `endPointer_bound` derives the
final upper bound. Seven source cases cover configuration/enum/decoder priority,
summary and stake buffer sizes, two-row success and allocation failure in the
second row after an earlier call. `row-memory-init-receipt.json` passes 75 modules
with matching source hashes and only standard logical axioms for these proofs.

This pass still needs composition with the entry array/cache prefix, the initial
scratch configuration allocation, the following capacity array, second pass and
parent ABI copies. Its pointer is a source value; physical stores, memory aliasing,
gas and full compiler refinement are not proved. The new row/loop source needs
full remote compilation and actual VM execution after that composition.

Full job `592f6ed2-a8ee-4af8-8e5e-6887ab80aa86` on Nippur validates
`431e73ee` under durable `7c33729b-a873-5380-a416-d7d3855dbc55`. It includes
the published writer integrations and seven response-memory VM cases, but
predates `RowMemory`. Both it and old-agent job `7d446706` were authoritatively
running at the latest check; neither is final-head certification.


## Complete producer guard sequence in the parent

`MemoryProducer` composes the array/cache prefix, 224-byte scratch allocation,
interleaved first-pass allocations, capacity array and second-pass arithmetic.
Its `producer_exact` theorem derives their success from count <= 32 and one
budget: pointer + 608*count + 320 <= 2^32. It equals the original producer call
tree plus the final pointer on success, while retaining every source failure.
Eight source cases cover success, early scratch failure, late capacity failure,
and arithmetic/allocation precedence on both sides of the capacity allocation.

`MemoryParentCalls.program_eq` connects that producer to canonical consumer ABI
and checked Ether conversion. `ParentCalls.afterProducer` shares the existing
conversion code. `WriterMemory` derives the budget from the physical invariant
and pointer <= 2^31, including every outcome of the public share, parameter and
admission writers. Existing finite-layout, lifecycle-record and initial invariant
premises remain explicit; all-writer reachability and entry-pointer provenance
are not newly asserted.

The combined Init-only closure passes 79 modules with matching source hashes;
see `writer-memory-init-receipt.json`. `producer-memory-init-receipt.json` records
the 78-module checkpoint before the writer bridge. Source metadata, proof-escape,
annotation, import-DAG and Python quality checks pass. No new project axiom was
introduced.

`VerityParent.executeWithMemory` now executes this larger producer guard tree,
and its conditional public relation uses the derived whole-producer budget.
Eight additional actual call-VM parent cases are wired into `RunVerityParent`.
These changed VM proofs and cases require a fresh remote compile/run; both
currently running older jobs predate this change. Prior receipts remain scoped
to their exact source. The comparator now also rejects mutated Solidity baseline
artifacts and binds the mutation-definition input hash.

These are compiler allocation guards in the source call tree, not physical
MSTORE/MLOAD, a proof of memory aliasing, or the whole parent ABI-copy schedule.
Consumer/deployed-call memory, returndata copies, pointer provenance, gas,
recursive callback/deployment binding and final independent certification remain
open. The numeric budget is a derived sufficient bound under the stated writer
invariant; arbitrary storage is still executed and may fail in the modeled order.


## Executed interleaved parent VM and twelve-case comparison

Remote job `526f3902-a6e4-47b1-a3ed-611b8441ae10` on Ashur completed
successfully at `3f22469d5be4c5f77732ca59406726f46cca4895` on 2026-09-07.
`RunVerityParent` compiled the changed VM correspondence theorems and executed
six parent checks, twelve differential records, seven response-memory checks
and eight interleaved memory-parent checks. `remote-3f22469d` archives the
terminal receipt, complete durable logs and exact twelve-case Solidity comparison.
Inputs, return/revert bytes and ordered module calls match the recorded pinned
Solidity execution. This is actual Verity call-VM execution, not transcript replay.

The comparator regression uses that real VM receipt in a separate clean checkout.
Both normal and optimized Python accept the unchanged baseline and reject nine
corruptions each: mutated Solidity baseline, changed original harness, changed
mutation input, empty/duplicate Solidity cases, changed result bytes, truncated
VM records, wrong repository and nonterminal receipt. See
`parent-comparator-interleaved-rejections.json` and `test-parent-comparator.py`.
The disposable checkout's modified reference artifact is restored even on failure.

The original brief permits explicit compilation/cryptographic/consensus
assumptions and excludes gas, migration to the compilable DSL and full deployed
bytecode. Those are scope boundaries rather than extra completion requirements.
Remaining required work is source-level memory/ABI and observable correspondence
under explicit justified relations, all stated writer/authorization/accounting
obligations, final-SHA full gates, independent source/composition review, sequential
merges, final writer checkpoints and the aligned dossier/site. This targeted
protocol-1 runner receipt is execution evidence, not independent certification.

The full `8bf49588` and `431e73ee` jobs remain separately tracked. They validate
older source snapshots and cannot certify the changed interleaved producer.


## Full-build dependency failure and corrected Lake coverage

The `8bf49588` run terminated with two failed gates. Its combined build could
not find `audit.trio.alloc2.composition.Parent.olean`: the integration library
listed only its root, so Lake did not own or schedule the staged dependencies.
`make prove` passed in its legacy scope; `make test` failed the old canonical
receipt tree binding. The parent VM gate passed and its twelve-case comparison
was independently rerun in a clean isolated checkout at the executed SHA.
`remote-8bf49588` preserves that scoped comparison, authoritative failed receipt,
durable wrapper logs and the complete node log containing the actual build error.

The root `TrioIntegrationChecks` target now explicitly owns all ten staged
composition/proof/vector modules plus `IndexedParentBridge`. It excludes the
standalone nested lakefile. The expanded 83-module bounded closure passes with
matching source hashes in `staged-build-init-receipt.json`; import-layer checking
also passes. A fresh remote full run must verify Lake scheduling and all gates.
The already running `431e73ee` snapshot predates this scheduling fix.
