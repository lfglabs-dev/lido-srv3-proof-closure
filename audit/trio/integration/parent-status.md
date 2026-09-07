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
