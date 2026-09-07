# Trio handoff recovery — 2026-09-07

This records recovery evidence, not a replacement for the structured project roadmap.
The sandboxed.sh MCP is not exposed in this session. Read-only SSH inspection of
the production mission database and actual workspaces recovered the following:

| Track | Mission | Published and workspace HEAD | Unpublished work observed |
| --- | --- | --- | --- |
| ALLOC-1 | c01b16cf-8eb0-444b-82a9-4310211c4847 | 8269ac576cf119975a7e9954459cd4aa04d5cd82 | Determinism, ShareWriter, Correspondence test |
| ALLOC-2 | 44053c4f-2578-4df5-84f2-4f66bc73586a | 460cc599d9fd350af51db27e4e8d175561f99773 | RowBounds and slice build config |
| RESERVE-1 | f19a12b3-e941-4b0b-b2ba-619314079ee9 | 7173594e7518cc636fff9099f864fa61b021a7cf | Admission, AdmissionSpec, trust/check harness and receipts |

At 12:34 UTC the first two mission runs reported waiting_remote_job and the
reserve run reported running, all with current heartbeats and no ended_at.
Do not restart or duplicate their proof work based on the earlier MCP suspension.
The workspaces were inspected without mutation. No complete checkpoint is claimed:
all three contain unpublished work despite local HEAD equaling the GitHub head.

Local integration owns shared build wiring, composition integration and delivery
metadata. Track implementations remain owned by their existing writers. PRs
#230 and #231 are confirmed merged and are preserved through current main.

Remaining acceptance requirements: complete each track's source correspondence;
memory/ABI and parent composition; reachable writer/accounting/authorization
invariants; callbacks, rejection and rollback; actual Solidity/Verity differential
execution and registered-parent mutants; full production/test/trust, prove/test,
metadata/provenance/receipt gates on final heads; independent certification;
sequential GitHub merges; aligned site and reproducible final dossier. Keep all
11 IDs and the eight non-trio IDs WIP. Final publication and Lido contact require
Thomas's approval. No delivery status has been upgraded.

Next: collect final writer checkpoints, integrate their successor heads, complete
shared composition and full validation, and obtain independent certification.

## Integrated memory bridge

The consumer now reads length-prefixed memory arrays. Producer-to-consumer
distribution is proved through the memory relation and through the existing byte
encoding theorem. The memory extent bound is explicit and not yet derived from
compiler allocation. All 27 modules in the Init-only closure and seven execution
checks pass. Proof-escape, import layering, annotations and metadata checks pass;
UX2 artifacts were regenerated after the new declarations. This does not complete
bytecode/source fidelity, parent callbacks/rollback, Verity differentials or full
validation. The three remote writer heads remained unchanged when rechecked.

## Public wrapper and row-bound integration

Local integration now includes ALLOC-2 successor `4dce12b7`, the public allocation
wrapper, independent per-row Ether conversion equations, and the universal
successful-return Ether bound. `ParentComposition.lean` discharges the conversion
length/subtraction premises from real producer/consumer outcomes. The bounded
check covers 32 Init-only modules and 16 executed memory/parent cases. See
`parent-status.md` for exact remaining obligations. UX2 passed on `b5dff873`;
newer source heads require their own gate. No full or independent certification
has been claimed, and the original final-delivery scope remains open.

## All-outcome decoded parent and new checkpoints

The decoded wrapper now has an independent deterministic relation and an exact
return/revert/transcript iff theorem. Its 37-module Init-only closure passes,
including 16 vectors and four parent mutants. Concrete memory/ABI/world binding,
full Verity differentials and final certification remain open.

Read-only remote workspace inspection found ALLOC-1 clean at
`a35ca25a350610ce803dd3a2de019b5a66c80e8c`, matching GitHub. This is a snapshot
checkpoint, not track completion. ALLOC-2 remains at `4dce12b7` with unpublished
`composition/LibraryABI.lean`, preparation/config changes and receipts. RESERVE-1
is at `016052c7` with unpublished `CallResults.lean`, `WithdrawalTail.lean` and
receipts. Those active workspaces were preserved without mutation.

## Latest integration and tracked full build

Integration `9d0bcdbe` includes writer checkpoints ALLOC-1 `9923f9d6`,
ALLOC-2 `b279d572`, and RESERVE-1 `1b3adaed`. These publish the memory allocation
primitives and callback fixtures, staged canonical library ABI bridge, and
getter/withdrawal-tail composition respectively. The ABI modules still need
production integration and alignment with the current producer. The full
withdrawal theorem still must discharge the spending premise. These are not
completed track claims or fresh clean-workspace attestations.

Proof-escape (305 project Lean files), source annotations (750 citations), and
import-DAG checks passed after integration. The source index was regenerated.

A command-only Sandboxed mission `239f13eb-952d-495f-8341-a0c7319f6c0f`
owns a separate validation checkout and durable job
`2eeec2f4-ab09-5940-9948-718b991b00a7`. The official remote-build wrapper
submitted job `e380a57b-921d-46af-b2ea-38053f29ad72` to DGX Spark for
`lake build LidoSRv3 LidoSRv3Test LidoSRv3Audit` at **91684800**, before these
latest writer merges. Its terminal result must be collected; it cannot certify
9d0bcdbe or subsequent source. Earlier admission attempts failed on Ashur's
unchanged disk reserve. Explicit command routing resolved the workspace's
default-node override. No AI harness or duplicate writer was launched.

## Executed producer comparison and current validation

Producer checkpoint `fcfa8419` publishes an actual Verity execution receipt at
`03abaac4` and twelve Solidity/Verity comparisons. The integrator reran the
comparison against the recorded Solidity and VM outputs, verified their hashes,
and obtained the identical comparison receipt. The producer source and test
trees are unchanged from the executed commit. Scope: decoded results or raw
errors and ordered top-level calls, not the full nested world or compiler memory.

The comparator's assertions allowed optimized Python to accept two empty lists.
Explicit checks now reject them. Ten checks cover genuine, empty, truncated,
duplicate and changed-result inputs in normal and optimized modes; the genuine
receipt remains identical. `comparator-regression.json` records their exits.

Read-only workspace inspection found ALLOC-1 clean at `fcfa8419`, matching
GitHub. ALLOC-2 remains at `b279d572` with unpublished parent conversion,
parent harness and receipts. RESERVE-1 remains at `dac0fc30` with unpublished
locator/queue/oracle-call composition and receipts. No final all-writer
checkpoint is claimed.

The expanded full-suite job `1a3ffae2-3854-4335-beee-dbf883bd76f3` on DGX
Spark is running at `c2f9f0fc`, under durable handle
`4deb4669-060e-5552-a2df-01fe34d79680`. It executes the full build, make
prove, make test and actual producer Verity vectors. The earlier full build at
`91684800` succeeded; its checked receipt is `remote-91684800/receipt.json`.
