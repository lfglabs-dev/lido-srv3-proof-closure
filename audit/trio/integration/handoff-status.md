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
