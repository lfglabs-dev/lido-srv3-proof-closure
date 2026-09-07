# Scan bounds continuation — full objective remains open

Recovered clean checkpoint `77deca452be85fe22ab180de2efeb7b833eec45a`.
The previous goal turn was progress (checked conservation implementation).

Added `ScanBounds.lean`: first-scan tie count grows by at most the number of
visited rows; initial count is bounded by bucket length; nonzero candidates
point to visited positions under the sentinel invariant; the initial scan
therefore returns an in-bounds bucket index; the second scan only lowers its
upper level. These derive from actual scan success, without intermediate-success
premises or a fixed module limit. They are not complete selection correspondence,
byte-memory bounds, or proofs that all checked operations succeed.

Remote final slice job `4e36023a-cf09-421b-abff-17ea544c2f15`, old-agent,
exit 0, 14 jobs. Source overlay
`557a875e788df943e1fa0a613b0b2f6da536d4047914e98c6fb41ac536e0fa2f`;
13 per-file identities in `scan-source-identity.json`. Five new theorem axiom
inspections contain only propext and Quot.sound. Earlier failed and successful
attempts have individual receipts. Submission exit 75 means accepted asynchronous
work, not a build failure. Proof escape check passes for 229 files; diff check
passes. No full-suite success or independent certification is claimed.

Current-main integration worktree is `../temp/alloc2-integration`, originally
at `bcfbb5f027a5c370594891c1a455fde137709941`. Owned source/test files were
copied there; unchanged UX2 generator regenerates only index.json's source hash.
Generation and check pass; `ux2-current-main.patch` records that exact delta.
The first test_ux2 process exited 1 because copied Lean inputs were untracked
when its late source-identity check ran. The correct next step is a local
integration commit and rerun, preserving the guard. No checks were weakened.

Full remote command `lake build LidoSRv3 LidoSRv3Test LidoSRv3Audit` submitted
from this complete public base plus owned-source overlay as job
`4090a961-f137-4909-bc68-c19a42879623` on old-agent. Last authoritative receipt
says running, after successful pinned Solidity/Verity/EVMYul checkouts and during
mathlib clone. Reconcile this exact handle before any further full submission.
Full remote source overlay is
`c86e59e19db3fb9a3a31738b9c1663ded5fe7033ef6fa5960e3d217c4c44acd6`.
The runner materializes manifest-pinned dependencies. No credentials were
inspected or modified. Local disk preflight: 1.9T free, 48% used.

ALLOC-1 mission c01b16cf-8eb0-444b-82a9-4310211c4847 was confirmed running;
consumer interface acceptance and request for executor-success theorem/SHA sent
via orchestrator (message 41216ab3-1ff3-4cc6-b804-40c80721a45c).
No producer changes adopted. Composition still needs that concrete implementation.
Current user explicitly requests a scoped PR; earlier historical notes about
publication clarification are not a new approval requirement. No PR yet exists.

Remaining full scope is unchanged from checkpoint-conservation.md and the active
objective: independent selection/loop correspondence, row bounds, arithmetic
success and exact errors, memory/ABI, actual-producer composition, parent effects
and rollback/sequential behavior, executed Solidity/Verity differential tests and
mutants, full applicable prove/test/trust gates, scoped immutable PR and independent
certification readiness. +1 remains separate and unmodified. No merge, site
publication, Lido contact, or unrelated PR mutation occurred.
