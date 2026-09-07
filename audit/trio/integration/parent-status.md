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
state/balance/event frames and recursive callback interpretation; actual Verity
differential execution; registered-parent mutants; full gates and independent
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
