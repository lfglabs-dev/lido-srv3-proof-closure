# Source-fidelity implementation contract

Pinned Solidity remains `17005714f151e5502c559932319a3f2f74ac2436`.
This program covers all eleven stable guarantee IDs. Existing declarations,
independent specifications, proof statuses and open assumptions are retained
until replacements compile and their consumers migrate. A checked model theorem
is distinct from correspondence for a named Solidity path, and both are distinct
from deployment and trust assumptions.

## Required evidence for each refined path

Extend `source-map.yaml` with the entrypoint, helper/modifier graph, physical
storage (including custom slots and packing), external calls, and known deviations.
Classify each deviation as omitted behavior, abstraction, instrumentation or added
behavior. An incomplete inventory cannot be called full source correspondence.

Preserve function boundaries, guard/revert precedence, loops, call order and memory
mutation. Do not hoist calls, collapse loops or add guards without an equivalence
result for the claimed observables. Preserve word widths, checked/unchecked
arithmetic, truncation and division. Name source errors separately; exact ABI error
encoding remains a separate obligation until modeled. Derive admission from caller,
configuration and storage rather than supplied authorization/validity flags.

Separate proof observations and failure injection from contract storage. Prove
instrumentation erasure preserves source-visible behavior. Replace synthetic memory
with explicit decoding relations, proving valid construction and malformed-input
rejection. Expected results must not invoke the executable under verification.

Each entrypoint needs a correspondence statement for success/revert, returns,
relevant storage, balances, call target/value/payload/order and events under an
explicit state/input relation. List excluded observables. Arbitrary modules and
recipients may reject; permitted callbacks must be covered or explicitly excluded.
Success stubs and successful-call premises cannot close adversarial-call gaps.

## Delivery sequence and current state

| Stage | IDs | Required outcome | State |
| --- | --- | --- | --- |
| A | ALLOC-1, TOPUP-2 | Scope rollback citation to `AllocationTx.allocate`; exclude same-block accumulation from the single-call cap | Disclosure implementation; no model strengthening |
| B | ALLOC-1, ALLOC-2, RESERVE-1 | Actual capacity/distribution loops composed, live rollback, queue read, packed reserve accounting and ETH transfer; derive reachable arithmetic bounds where writers are covered | Open |
| C | DEPOSIT-1 | Single-module router path, authorization, allocation, key lengths, checked value, Lido withdrawal, per-validator beacon calls and final balance assertion; success and failure composition | Open; NFrame remains an aggregate abstraction |
| D | SSZ-1, TOPUP-2, TOPUP-1 | Targeted SSZ/Yul traversal, production indices/encoding/root freshness and actual cross-call policy; compose gateway limits, adversarial module allocation, router rechecks and wei/gwei movement | Open |
| E | CONSOLIDATION-1, CONSOLIDATION-ETH-1 | Bus/Gateway/Vault composition, 48-byte keys, 96-byte payloads, fees, recipient credit/refund, arbitrary rejection and rollback | Open |
| F | ACCOUNT-1, ADDRESS-1 | Fee calculation consumes updated balances; actual address-sensitive bodies and claim batches, physical storage and consistent renaming of state/inputs, rejection/callbacks | Open |

Keep the separate `+1` allocation algorithm separate. `PhysicalClaimSlots` remains
a premise until physical layout is derived. Structural SSZ results do not establish
functional hashing correctness or cryptographic binding; exact injectivity is not
collision resistance. Compiler, cryptographic primitive and consensus assumptions
remain explicit. Gas-cost correctness and full consensus-state truth are excluded.

## Validation and publication

Each stage requires production/test/trust Lean targets, `make prove`, `make test`,
source annotations, metadata, inventory, provenance and proof-escape checks. No new
`sorry`, unchecked escape or unreviewed axiom. Differential tests must execute both
pinned Solidity and the Verity model on matching inputs; fixture presence is not
execution. Compare outcomes, returns, relevant state/balances/calls/events, documenting
normalization. Exercise empty/mismatched inputs, zeros, exact caps, word limits,
duplicates, malformed bytes, unauthorized/stale inputs and failures after effects.
Mutations must falsify the relevant result or produce an executed mismatch.
Sequential claims require sequential proofs and tests.

After validation, pair immutable proof evidence with website text, math, notes,
boundaries and regression snapshots; validate the pinned checkout, build, and
review desktop/mobile. Preserve layout and protocol map. Open reviewable PRs;
do not merge or deploy. Record derived assumptions, closed gaps and remaining gaps
for each delivery. Added premises cannot count as unconditional strengthening.

Stage A changes only two disclosures; all eleven statuses and all 68 canonical gap
entries remain. No assumption is discharged. It adds no executed differential test
and does not satisfy the source-model completion gates for B–F.
