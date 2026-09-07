# ALLOC-2 initial implementation checkpoint — incomplete

Base `c7adae04416704a839d56333efad003f0a0f46b7`; private local branch
`trio/alloc2-proportional-composition`. Solidity submodule remains
`17005714f151e5502c559932319a3f2f74ac2436`. No existing tracked file changed.
No repository AGENTS.md was found. Read README, SOURCE-FIDELITY, lake manifest,
toolchain, audit manifests and the complete ALLOC-1/2 registry/source-map entries.

Consumer acceptance is in `interface-acceptance.md`. Producer checkpoint is
`2a4e9d2a91d257353470677c6101fd91293cf4e4`; no orchestrator record of both
agreements has been observed. No producer declarations are imported or changed.

## Implemented and checked scope

`Word.lean`: checked arithmetic and source conditional ceilDiv. Semantic panic
variants are not yet ABI error bytes. Checked addition and multiplication expose
their exact Nat value on success.

`Step.lean`: first and second source scans, count increment, earliest tie choice,
proportional amount, array update, zero-demand precedence and array-bound errors.
The recursive scans structurally terminate. This does not establish outer-loop
termination or bounded Solidity index correspondence. Lists are decoded views,
not a proven byte-memory/ABI representation.

`Spec.lean`: independent global minimum, tied rows and higher-level ceiling over
unbounded Nat rows. It imports Init only and does not call the source executor.
Its step preserves length. Source/spec correspondence remains open.

Eleven concrete kernel-reduction checks cover zeros, short/surplus capacities,
overfull rows, max-word arithmetic and proportional ties. These are model tests;
neither Solidity nor Verity differential execution is claimed. In the source's
illustrative example, ceilDiv(31,2) gives 16 at the second step; the executable
source, rather than the comment's stated intermediate 15, determines our check.

## Commands and evidence

Initial disk preflight: `df -h .` reported 1.9T available, 47% used. Local
`.lake` is private and all 11 dependency Git HEADs match lake-manifest.json;
see `dependency-pins.json`. Pinned toolchain was available read-only at
`/tmp/pr241-elan/toolchains/leanprover--lean4---v4.31.0/bin/`.
`ELAN_HOME=/tmp/pr241-elan /tmp/pr241-elan/toolchains/leanprover--lean4---v4.31.0/bin/lake env lean --version`
exited 0 after materializing the exact manifest. An initial `lake update` was
stopped during the first clone and replaced with manifest-preserving initialization;
the root manifest and lakefile have no diff.

Remote submissions use `REMOTE_BUILD_PASSIVE=1`, return a durable job handle,
and exit 75 while pending. Terminal states below were fetched from each exact
job handle once available, without polling loops or credential changes.

| Command and job | Result |
| --- | --- |
| Root `remote-lean-build lake build LidoSRv3.Audit.Source.TrioAlloc2.Step LidoSRv3.Tests.TrioAlloc2.Step`; c6e6d497-6fee-4957-b4c0-a29cf1b4a02f | Exit 1: Word/Step compiled; test `decide` lacked Except equality instance. Replaced concrete test proofs with `rfl`. |
| Same targets; eca803cd-d77b-4d8a-968a-b3b02f8c8dd7 | Exit 1 before tests: pinned plausible Git fetch failed. See step-build-receipt.json. |
| Root targets Spec, Step and Tests.Step; 813c19ce-2892-4553-ba52-1d44ca3227bc | Exit 1 before compilation: pinned Verity Git fetch failed. See spec-step-build-receipt.json. |
| From audit/trio/alloc2: `REMOTE_BUILD_PASSIVE=1 remote-lean-build lake build`; 39933a63-072a-4e60-b2ec-18a32e6a6097 | Exit 0: all four modules, six Lake jobs. See slice-build-receipt.json and slice-source-sha256.json. Init-only isolated configuration; NOT a production/test/trust full-suite receipt. |
| `python3 scripts/check_proof_escapes.py` | Exit 0, 221 project Lean files, no new escape. |
| `python3 scripts/check_source_annotations.py` | Exit 0, 720 citations checked; 95/142 transcribing declarations annotated. This does not certify complete annotation coverage for the new slice. |
| `make audit-check` | Exit 2: registry check passes, generated UX2 index differs only in lean_source_tree. See integration-ux2-delta.json. |

Logs are retained in this owned directory. The successful remote validation binds
base tree, five-file source overlay, pinned toolchain, command and cwd. The remote
receipt is for this source overlay, not an assertion that the base alone contains
these modules.

## Remaining work and integration recommendations

1. Prove the independent step correspondence, word bounds, all checked operations,
   outer proportional loop termination and full independent loop correspondence.
   Preserve the existing +1 algorithm and old declarations.
2. Implement and prove actual byte memory and library ABI encoding/decoding,
   malformed inputs, exact errors, copied caller arrays, checked parent conversions
   and guard precedence. Model permitted arbitrary external rejection and late
   failures, with a precisely stated callback boundary.
3. After recorded interface agreements and a concrete producer executor theorem,
   implement the named consumer-owned bridge deriving consumer premises from actual
   producer success. Track any revised producer SHA explicitly. A pair of assumed
   compatible predicates is insufficient.
4. Establish explicit state/input and all-outcome correspondence over returns,
   relevant storage/balances, call kind/target/value/payload/order and events;
   separate attempted-call instrumentation and prove its erasure. Handle parent
   rollback and sequential cross-call claims with both proofs and executions.
5. Execute pinned Solidity AND Verity on matching inputs. Include malformed bytes,
   rejected calls, word boundaries, parent-shaped mutants and failures after effects.
   Current pure Lean examples satisfy none of this differential gate.
6. Run repository production, test and trust targets, make prove/test, metadata,
   inventory, provenance and proof-escape checks on the final candidate. Current
   production/test globs already include the owned source/test directories. The
   shared Trust module will need coordinated imports/axiom inspection. Generated
   UX2 source hash requires coordinated regeneration; do not edit it here. Do not
   run make prove in this worktree until its existing report writes are isolated
   or coordinated. Existing source-map/guarantee claims must stay unchanged until
   correspondence and migration are validated.
7. Prepare a draft scoped PR with immutable head and complete evidence/gaps; no
   merge. GitHub reports the target repository PUBLIC. User clarification of the
   requested PR versus the prohibition on public publication is pending; retain
   this implementation privately until resolved. No public push or PR was made.

PR230/231/243 and the existing site chain remain outside this implementation's
ownership. PR243 was inspected only for the specifically requested source-entry
document, and remains unintegrated. No contact, review, comment, merge, site edit,
deployment or self-certification occurred. This checkpoint is progress toward the
full objective, not a completion claim or a canonical guarantee upgrade.
