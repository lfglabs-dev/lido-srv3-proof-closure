# Independent validation dependency

Reviewer `80fe125b` reviewed frozen PR #918 SHA
`4c4e7d010f8cd63d7fff7d03fdcf1bf83ddfd26d`. The controller's handoff reports:

- Independent exact-SHA library build passed.
- All 34 TOPUP/RESERVE tests passed independently.
- No material source blocker was confirmed.
- Full-gate evidence and axiom recomputation could not be independently rerun
  under the reviewer's access/runner restrictions.
- Verdict: **INFRA_BLOCKED**, neither CLEAN nor source BLOCKED. ACK acknowledges
  a receipt; it does not accept a source change.

Named open dependency **I-REVIEW-80FE-FULL-GATE-AXIOMS**: a fresh authorized
independent reviewer must execute/inspect the complete exact-SHA repository gate
and recompute the actual registered axiom dependencies. Author-exported provider
responses and passing diagnostic vectors do not satisfy this dependency.

This dependency does not narrow any registered statement and does not prevent
unblocked source work. The 4c4e7d01 review does not cover successor changes.
Representation, allocation, deposits, top-ups, accounting, reserve, address,
consolidation/ETH, SSZ and supplemental closure remain subject to the expanded
proof-only objective and a new final full-closure audit. No merge, deployment,
website work or certification is authorized by this record.

## Supported-module reachability

Named open dependency **I-ALLOC1-SUPPORTED-MODULE-REACHABILITY**: bind the
authoritative supported-module/deployment inventory to implementation SHAs and
derive summary/stake reply bounds and the router accounting relation from those
implementations and their writers. NOR packed field widths alone do not prove
the whole relation. ABI-valid arbitrary replies such as `(exited=1, deposited=0,
depositable=0)` still refute unconditional allocation success; this counterexample
must remain unresolved until the intended supported domain is justified.

The controller's ACK of receipts through `0ba13da5` acknowledges receipt only.
It is not source acceptance, CLEAN, or closure of either named dependency.

## Review c36729d4 at a645be9a

The controller reports reviewer verdict **BLOCKED** for exact SHA
`a645be9ad56f6212007428e3b871f399d31c8d76`. Reviewer-owned Spark job
`c54e919b-fa93-418d-9b88-6955d02cc96f` exited 1: `make prove`, 74 differential
cases, and the complete library/test-target build (2119 jobs) passed; `make test`
stopped at the stale UX2 fingerprint. Independent axiom recomputation and native
reevaluation were not reached. These results do not constitute CLEAN or source
acceptance and do not cover a successor SHA.

The writer reproduced the stale UX2 artifact and theorem-inventory coordinates
locally. Their repair regenerates the existing derived records and updates the
report coordinates without changing the checks or registered claims. Both checks
now precede the expensive differential suites in `make test`.

The reviewer workspace paths `/workspaces/mission-c36729d4/output/review-ledger.md`
and `reviewer-terminal-receipt.json` were not mounted in the writer container
when this record was made. The results above are attributed to the controller's
handoff; they are not a writer inspection of those artifacts. An accessible copy
has been requested. Existing author receipts remain author-collected evidence.

The following findings remain open, without narrowing the intended guarantees:

- **I-C367-NATIVE-COMPILER-SELECTION**: independently verify the native compiler
  selection path and reevaluate the registered native claims; the detailed
  reviewer diagnostic is still needed to resolve the specific selection defect.
- **I-ALLOC1-EXECUTOR-RESULT-BRIDGE**: connect the account-qualified producer's
  result to the registered allocation executor result. Conjoining producer
  correspondence and the legacy result does not establish this bridge.
- ALLOC2 decoded-loop conservation does not establish deployment correspondence.
- AccountFrame is connected to claim execution; this does not close whole-world
  ADDRESS writer coverage or the inherited semantic/public-facade obligations.

I-REVIEW-80FE-FULL-GATE-AXIOMS, supported-module reachability, and the ABI-valid
arbitrary-module counterexample remain open. The remaining DEPOSIT, TOPUP1,
TOPUP2, ACCOUNT, RESERVE, ADDRESS, CONSOLIDATION/ETH, SSZ and supplemental
obligations still require source work and a new final independent audit.
