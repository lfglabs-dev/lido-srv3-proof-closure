# P-RESERVE-1 — incomplete additive delivery

## Current source composition work

Immutable validated source: `df5a6b52d561ffa6014d6cf4cdae48481b398a3f`.
`source-composition-summary.json` records eight component checks (all exit 0),
35 matching Cancun executions (exit 0), and four executed mutant kills.
An out-of-range account-balance input is rejected with expected exit 1. Source,
artifact and compiler-input hashes were rechecked against the immutable source.
The exact-head remote full-source attempt again exits 2 before submission;
node/job/bundle identities are absent because encoding never completed.

`Allocation.successful_queue_observation` now connects the independent maximal
allocation relation to the actual locator result, queue CALL, first ABI word and
saved pre-call physical buffer/reserve locals. Arbitrary callee effects are
allowed; no freshness or preservation premise replaces the live observation.

`Router`/`RouterSpec` implement and check immutable LIDO authorization, exact
NotAuthorized rejection, DepositableEthReceived event and value-CALL effects.
`Locator` models the three immutable getters, with checked exact-selector
replies and no state effects. Pinned Solidity tests inherit these real bodies,
with linked StakingRouter libraries and the repository's 0.8.25 viaIR/Cancun
settings. The in-process test EVM is Hardhat 2.26.3 Cancun. Router forwarding
remains fixture admission; oracle/consensus behavior remains a fixture boundary.

`Transfers` proves sender debit, recipient credit, other-account frame,
self-transfer balance identity and exact ETH conservation. The credit-bound
theorem explicitly requires an aggregate balance bound. Deriving that bound
from a full bounded EVM world remains open. The JSON driver rejects account
balances outside uint256 rather than accepting them as EVM input states.

Receipts `router-execute-1` and `router-execute-2` record respectively 32 and 35
matching executions, each with two executed mutant kills. The expanded driver
adds receiver-authorization and receiver-event mutants. Final component and
execution receipts against immutable source are recorded separately under
`source-composition-immutable` and `router-composition`; consult their actual
exits rather than infer success from this description. Earlier 29-case receipts
and the 32-case comparison are retained. Component checks report standard axioms
only; they use existing imported oleans and are not clean/full build evidence.

The remote wrapper hash is unchanged from continuation-recovery.json. Its
complete-source/dependency transport blocker remains; no new remote job was
submitted. Full gates, complete withdrawal and writer/oracle/sequence composition,
canonical registration and independent review remain required. The older status
sections below retain the prior checkpoint's historical evidence and limitations.

## Continuation after recovery of fa377ac

Recovered exact head `fa377ac1372733b8781255a5e47cfde80f92e9d6` and verified
open draft PR #244 at that SHA. All eleven local dependency heads still match
the pinned manifest. `receipts/continuation-recovery.json` retains the check.

The installed remote wrapper's supported `REMOTE_BUILD_SOURCE_MODE=full`
fails locally with exit 2 on the tracked `lido-core` gitlink: it requires a
regular file. No job or bundle digest was produced. This wrapper also rejects
`.lake` path components and exposes no dependency-bundle transport. The old
remote authentication failure remains infrastructure evidence. Do not treat
either failure as proof failure or completion, or silently omit dependencies.
The wrapper's attempted `--help` was interpreted as build argv and rejected by
the node with HTTP 422 (only lake/lean commands allowed); it was not a build.

`AllocationSpec.lean` adds independent maximality/conservation allocation,
uniqueness, and two-spend protection with separately related queue observations.
Its lightweight Lean elaboration passed (`allocation-spec-2.exit` = 0), using
existing imported oleans. This is not a clean/full-build receipt. The first
elaboration failure is retained. Physical CALL/ABI and queue-writer composition
are still required; this does not close the sequence or withdrawal parent.

The old local gate runner is absent from the current process table; its retained
log has no terminal exit receipt. It is interrupted/unverified, not a live wait
or passing full gate. Heavy validation must use remote-lean-build with complete
source and dependencies once that supported transport is available.

Implementation checkpoint: `b06cf0dc0861b93592f1de80820b68ff10b6905f`.
Own draft: https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/244
Branch: `trio/reserve1-live-queue`; exact base:
`c7adae04416704a839d56333efad003f0a0f46b7`.
Solidity: `17005714f151e5502c559932319a3f2f74ac2436`.
Verity: `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`.
Lean: `leanprover/lean4:v4.31.0`.

No P-RESERVE-1 parent closure or integration readiness is claimed. All changes
are under the four owned directories. Old declarations, shared Trust/build
configuration, canonical YAML/manifests/reports, and the site remain unchanged.
No other closure/site PR or branch was inspected or modified.

## Checked component properties

- `Live.lean`: handwritten executable with pinned Verity words and
  contract-indexed physical storage, real caller equality against locator router
  reply, live bunker/pause/queue calls, saved locals across external effects,
  compact accounting, actual balances and ETH transfer. External replies may
  reject, return arbitrary bytes, or produce successful world effects. This is
  not yet a complete Verity EDSL/compiled Solidity refinement theorem.
- Independent `QueueSpec.lean` and physical `Queue.StateRel`:
  `Queue.unfinalized_corresponds` proves numeric success or panic 0x11 using
  current last/finalized ids and packed cumulative rows, even malformed rows.
  `cumulative_bound` derives the physical uint128 bound. Keccak is an explicit
  primitive parameter; no freshness, monotonicity or injectivity assumption.
- `PhysicalPacking.pack_matches_bitwise` proves the executor's numeric packing
  equals the actual mask/shift/OR word expression for arbitrary inputs.
  `low_pack`, `high_pack`, `physical_low_bound`, `physical_high_bound` prove
  projections/truncation. They do not imply untruncated arithmetic sums.
- `Erasure.erase_bind`, `erase_pure`, `erase_run` prove compositional erasure
  and rollback commutation. `failure_restores_world` restores all modeled
  storage, balances and committed logs after arbitrary intermediate failure.
  These are interpreter properties, not full Solidity entrypoint correspondence.
- Independent `WriterSpec`: `Writers.target_corresponds` proves buffer unchanged,
  target=requested and reserve=min(old,requested); `rebalance_corresponds`
  proves buffer/target unchanged and reserve=max(old,target). The separate
  `target_observations` / `rebalance_observations` prove success, no external
  calls, preserved balances and exact appended event order. These are INTERNAL
  helper claims; Aragon ACL and report-parent correspondence are open.
- Earlier independent `PartitionSpec.spend_preserves`, `lowering_reserve`,
  `demand_monotone`, `two_spends` and numeric `Packing` lemmas remain. The
  two-spend lemma is for fixed demand and does not prove queue-changing sequences.

The physical reserve may exceed the buffer after rebalance. No global
storedReserve <= buffer invariant is assumed or claimed. Detailed pinned spans,
writer inventory and missing composition are in `SOURCE-MAP.md`.

## Executed evidence

Commands are from repository root; for current runs prepend the private binary
directory `audit/trio/reserve1/.local/lean4-v4.31.0/bin` to PATH.

| Command | Exit / receipt | Scope |
| --- | --- | --- |
| `lake build LidoSRv3.Tests.TrioReserve1.LiveTrust` | 0, `live-trust-final.txt/.exit` | Component modules and owned axiom inspection |
| `lake build LidoSRv3.Audit.Source.TrioReserve1.Writers` | 0, `writers-4.txt/.exit` | Scalar writer spec and observation proofs |
| `lake build LidoSRv3.Audit.Source.TrioReserve1.PhysicalPacking` | 0, `physical-packing-1.txt/.exit` | Bitwise relation and projections |
| `solidity/trio-reserve1/.tools/node-v22.15.0-linux-x64/bin/node solidity/trio-reserve1/compile.cjs` | 0, `solidity-full-queue-compile.txt/.exit` | Inherited pinned 0.4.24 Lido and 0.8.9 queue, source compiler settings |
| Same Node binary, `solidity/trio-reserve1/execute.cjs` | 0, `differential-execute-2.txt/.exit` | 29 matching cases, 2 executed mutant kills |
| Six baseline Python gates | all 0, `resumed-checks.json` | Escape, annotation, inventory, provenance, pin, metadata; not new registration |
| `python3 scripts/check_proof_escapes.py` | 0, `checkpoint-proof-escape.txt/.exit` | After final component additions |

`owned-trust-environment.txt/.exit` records exit 0: the repository dependency
probe independently confirms all 16 new reports against the built
`LidoSRv3.Tests.TrioReserve1.LiveTrust` environment. This is component evidence,
not canonical Trust registration.

Owned axiom inspection reports only standard `propext`, `Classical.choice`,
`Quot.sound`. No new axiom declarations, native decision proofs, or proof escapes.
Retained failed elaboration logs are diagnostics, superseded by named green
receipts, not hidden or interpreted as passing.

Matching inputs/outputs are in `differential-input.json`,
`differential-solidity.json`, `differential-verity.json`; the comparison is in
`differential-comparison.json`. Mutant inputs/outputs and killed comparisons have
parallel `mutation-*` filenames. Source hashes/dependency identities are in
`resumed-source-context.json`; source compiler hash inventory is in
`solidity-compilation.json`.

The differential relation compares exact root return/revert bytes, seven Lido
physical words, current queue ids/bunker/cumulative mapping words, five account
balances, ordered directly Lido-issued target/value/payload calls, and ABI
committed events. Current-row mapping preimages are computed by ethers keccak;
missing preimages fail the Lean driver. Root forwarding/nested callee traces,
gas and deployment size are excluded from this finite comparison.

Cases include live enqueue/finalization, malformed physical cumulative underflow,
unauthorized/zero/pause/bunker, malformed/trailing replies, dirty address/bool
words, 128/256-bit bounds and truncation, stale/current frame, actual ETH shortage,
recipient rejection, failures after writes, target lowering, rebalance above
buffer, and a second spend after queue growth. The two executed mutants replace
live demand with a cached word and omit rollback; both disagree with Solidity.
These are tests, not replacements for correspondence or sequential proofs.

The harness inherits the ACTUAL bunker getter and unfinalized demand. Its raw
setup/internal writer wrappers bypass production admission; locator/oracle/router
fixtures are test boundaries, not production callees or success assumptions.
Successful arbitrary callback effects are allowed by the generic interpreter but
are not covered by the finite differential suite or a full composition proof.

## Toolchains and broader gates

All eleven Lake dependency revisions were rechecked exactly in private,
non-symlink package directories. A private Lean 4.31.0 copy now resides in the
owned `.local/lean4-v4.31.0`; its version and binary hashes are recorded in
`private-lean-toolchain.txt`. The inherited toolchain path vanished during
mathlib cache extraction: `mathlib-cache.txt/.exit` retains that failure.
`mathlib-unpack-private.exit` is 0 after unpacking the already-downloaded cache
with the private toolchain. Node 22.15.0's upstream distribution hash was checked
and retained in `node-toolchain.txt`.

Earlier remote job `72e45c29-b554-4616-9fd2-cd54a38dde96` terminated FAILED,
exit 1: the pinned evmyul Git fetch failed with exit 128 for missing remote
authentication. `remote-resume-original-env.txt` is the terminal receipt.
No duplicate remote build, credential change or security-setting change.

`run-gates.sh` starts one isolated owned validation worktree per immutable SHA,
with a separate copied mutable `.lake`, runs production/test/trust followed by
`make prove` and `make test`, and records each command/exit externally in owned
receipts. It prevents duplicate invocation for the same SHA. Generated proof
reports and mutation-test outputs are confined to that disposable tree.
Current checkpoint gates were launched; terminal outcomes belong in
`full-production-test-trust`, `make-prove`, `make-test` receipts and
`gates-terminal.txt`. Until those terminal receipts exist, these gates are PENDING.

## Remaining required work

1. Full independent withdrawal state/input and return/revert/storage/balance/
   ordered-call/event correspondence, including malformed/rejected results and
   later failure. Component theorems do not discharge this parent.
2. Actual immutable locator, AccountingOracle/BaseOracle/consensus frame, and
   StakingRouter receiver composition (including receiver auth/event), and
   callback/nested-call behavior. No unconditional successful callee premise.
   World balances currently use Nat: relate EVM account-balance bounds and
   value-credit behavior explicitly rather than infer them from small fixtures.
3. Aragon target/pause admissions, initialization/migration, all report/buffer/
   accounting and queue writer surfaces needed by invariants; derive untruncated
   bounds where needed. Sequential queue/rebalance/spending proofs remain open.
4. Complete full gates and retain actual failures. New canonical Trust imports,
   guarantee/source-map/manifest/provenance registration are MISSING under the
   additive-only boundary even if baseline checks pass. Put proposed shared
   edits in owned notes; do not edit shared files without coordinated integration.
5. Keep draft PR updated with immutable source and terminal evidence; no merge,
   self-certification, publication, deployment or Lido contact.

Compiler, runtime and primitive correctness are explicit assumptions. Full
bytecode/gas/full consensus-state truth and cryptographic injectivity are excluded.
