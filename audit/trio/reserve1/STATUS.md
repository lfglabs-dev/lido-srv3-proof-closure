# P-RESERVE-1 — incomplete additive delivery

## Aragon target-writer admission

`Aragon` implements the inherited initialization/kernel prefix and the external
Lido target writer's role check. It reads the physical initialization block and
kernel pointer, sends exact hasPermission(sender,self,role,empty-bytes) calldata,
and decodes actual reply bytes. Missing initialization/kernel, missing code,
denial, short replies and kernel rejection are distinct. Failed admission restores
the original world. Successful permission evaluation retains the callee world;
the target writer's independent relation starts from that world, so callbacks
are not silently discarded. `AragonSpec` independently describes the prefix.

Ten draft comparisons against pinned inherited Lido/Aragon bytecode match, covering
all these cases plus noncanonical nonzero bool and trailing return bytes. The
executed call opcode is CALL. Kernel replies are explicit boundary fixtures;
this does not implement Kernel.hasPermission, ACL permission evaluation or its
oracle recursion. Full ACL and callback binding remain required. Immutable
component and runtime checks follow the source commit.

## Internal writer and committed withdrawal sequences

`SequenceSpec` independently distinguishes target min, rebalance max, and admitted
spending with buffer conservation, saturating reserve debit and unchanged target.
`PhysicalSequence.corresponds` relates arbitrary finite interleavings of the
internal target/rebalance writers and committed withdrawal worlds to this relation.
Each spend reads demand from its incoming physical queue. All storage of distinct
contracts is preserved throughout, so queue IDs, rows and live demand survive.
`concrete_success_step` derives the independent spend transition from the actual
Pipeline withdrawal execution and its raw configuration/numeric conditions.

Target lowering cannot reduce protection; rebalance establishes the explicitly
recomputed partition and may reduce protection. These proofs do not cover ACL
admission, enclosing report execution, queue-changing transitions or exhaustive
parent failures. Their sequence constructors describe internal/committed effects;
they are not a claim that every constructed sequence is externally executable.
At `e47b7d1720dffeb0d09a2aa52e0fd0a5335e0ecf`, SequenceSpec, PhysicalSequence
and updated LiveTrust pass (3 selected checks), along with all seven baseline/import
checks. The other 36 modules' source and olean hashes match prior receipts. Only
standard axioms appear. `receipts/physical-sequence-summary.json` records exact
evidence. Runtime sources remain unchanged; the 51-case execution is still tied
to its original source commit. No new full remote gate receipt is claimed.

## Physical reserve preservation

`PhysicalReserve.success_preserves` connects the concrete `Pipeline.success`
execution to final physical buffer/reserve subtraction and the independent
`PartitionSpec.protectedReserve` equality. It derives admission from the actual
allocation formula and proves every storage cell of a distinct contract survives
the accounting, seed and receiver effects. The resulting live queue read therefore
returns the same demand. No reserve <= buffer or mapping-hash injectivity premise
is added. Queue/Lido namespace separation is explicit. This is forward successful
withdrawal coverage, not an exhaustive parent specification or writer-sequence proof.

At `de68e309d6cef918e7153c971f2396aaa1ec8b2a`, the new module and updated
LiveTrust inspection passed (2 selected checks). Source and olean hashes for the
other 35 component modules match their prior receipts. All seven baseline/import
checks passed; inspected axioms are only propext, Classical.choice and Quot.sound.
`receipts/physical-reserve-summary.json` records this bounded evidence. Existing
51-case runtime evidence remains tied to `4b82879f28d0e1d58a9972a3db92aa5ea225d898`;
runtime sources are unchanged and were not rerun. Full remote gates remain open.

## Concrete withdrawal pipeline

`Pipeline` composes locator, queue, oracle, consensus and receiver implementations.
Physical pointer and code preservation are proved across accounting writes. Its
prefix theorem derives status, immutable router lookup, live allocation, frame
calls and spending from explicit physical/configuration inputs and numeric
checks, with no successful-callee-result premise. The successful withdrawal
returns the exact world including accounting/seed writes, logs, actual ETH
transfer and receiver event. Source receiver rejection and ETH shortage restore
the original transaction world and retain the complete attempted-call trace.
Receiver immutable authorization and code are separate from prefix bindings.

The independent component specifications remain separate from an exhaustive
whole-parent return/revert relation. Constructor/layout/code-body/primitive and
bounded-EVM-world binding, remaining failure coverage, enclosing writers and
sequence invariants remain required. This is a concrete forward source theorem,
not a full certification claim.

The differential runner now uses Pipeline.external for complete unmutated source
configurations and records sourcePipeline per case. Incomplete/adversarial
configurations retain their explicit fixtures. The execution script accepts an
owned receipt directory so fresh evidence cannot overwrite historical receipts.
All 36 Lean modules passed at `2e4b6a50f68077d65a3d716522f9818fafd50073`.
A subsequent test-only commit `4b82879f28d0e1d58a9972a3db92aa5ea225d898` added
full-pipeline receiver rejection and ETH shortage. Every checked Lean source hash
was revalidated unchanged. Fresh execution at that commit passed 51 comparisons
and seven mutant kills; nine cases use Pipeline.external.
`receipts/pipeline-summary.json` links exact source/toolchain/component/execution
evidence, six baseline checks and import-DAG validation (all 0). The earlier
49-case pipeline run and original historical runs remain retained separately.
Full remote gates remain missing; no remote bundle/node/job was created.

## Consensus-to-Lido frame composition

`ConsensusCalls` executes the actual HashConsensus dispatcher under STATICCALL,
using block timestamp and the physical frame word. It derives uint64 reference/
deadline bounds from FrameSpec, decodes the returned reference exactly, and binds
AccountingOracle's checked timestamp to that result. Independent FrameSpec and
OracleSpec relations use the same actual source inputs. Consensus rejection,
missing code, and timestamp overflow preserve the exact nested-attempt distinction:
a successful consensus call followed by oracle overflow remains an accepted
nested attempt inside the outer rejection.

`lido_frame` composes the complete getter path through Lido's physical locator,
immutable oracle lookup, BaseOracle's consensus pointer, source consensus getter,
and both ABI decoders. It returns exact natural reference/time values with the
unchanged world, two direct attempts and one nested STATICCALL. Constructor,
compiler-layout, code/address and primitive binding remain explicit obligations;
this does not establish full deployment or whole-withdrawal specification closure.

All 35 owned modules passed at `a5492850a01aefb8f188f9f172d7172348de1d38`.
`receipts/consensus-binding-summary.json` links exact source/toolchain/commands/exits,
standard-axiom inspection, six baseline checks and import-DAG validation (all 0),
dependency/wrapper identity and source delta. The differential runner and its
previously executed source remain unchanged. Full gates still lack terminal
receipts and supported complete-source/dependency transport.

## Concrete getter and callee binding

`CallResults` now proves all three immutable locator lookups through physical
pointer read, code guard, CALL, byte decoding and address cast. `QueueCalls`
composes locator and actual queue source dispatch: status uses physical bunker/
pause state; demand success and panic are exact; allocation receives the live
physical row difference through ABI decoding. Successful demand is bounded by
uint128 from physical extraction. The independent LiveDescribes relation uses
the same physically related queue state, without cached-demand or monotone-row
premises. These getters preserve the full world and exact direct-call trace.

`OracleCalls` composes locator/queue/oracle dispatch and binds actual Oracle.frame
success/rejection to the enclosing current-frame getter. Successful tuple decoding,
bubbled failures and nested STATICCALL attempts are exact. Code presence and
relevant address separation are explicit input/deployment obligations. Oracle.frame
still takes the read-only consensus interpreter: complete concrete consensus
input/deployment binding and independent whole-parent coverage remain open.

All 34 owned modules passed at `2aa7917f6223628208dd06e835b1be263b7e584b`.
`receipts/concrete-summary.json` links exact source/toolchain/commands/exit evidence,
standard-axiom inspection, six baseline checks and import-DAG validation (all 0),
dependency/wrapper identity and source delta. The differential runner and its
previously executed source remain unchanged; new composition helpers are Lean-checked.
Full gates still lack terminal receipts and a supported dependency transport.

## Spending specification and parent composition

`SpendingSpec` independently relates admitted allocation to untruncated buffer,
post-report, next-report and reserve quantities. `Spending` binds that relation
to actual live queue bytes and the actual frame execution. Exact before/after
worlds retain external effects, packed writes, event order and attempted calls.
Bounds are derived from successful allocation and physical packed reads: admitted
amounts and saved next values are below uint128; accounting additions fit uint256.
Physical uint128 truncation is retained, not ruled out by an unproved invariant.
Allocation failure, insufficiency and frame failure have exact rollback/trace
results; the checked arithmetic cannot add another failure under derived bounds.

`WithdrawalComposition.after_frame` replaces the former successful-spending
premise with actual allocation and frame executions and preserves the router
saved before spending. Spending and late-tail failure restore the original
withdrawal world with the complete attempted-call prefix. This advances source
composition; complete independent parent return/revert specification, full
source-callee deployment/primitive binding, enclosing writers and sequential
invariants remain required. No overall correspondence completion is claimed.

All 32 owned modules passed at `53878264fd7d2030afcf176d398dfe0fa5114271`.
`receipts/spending-summary.json` links exact commands/toolchain/source hashes,
standard-axiom inspection, six baseline checks and import-DAG validation (all 0),
dependency/wrapper identity and the proof-only source delta. Historical runtime
receipts retain their original source. Full remote gates remain missing.

## Getter and withdrawal-tail composition

`CallResults` binds actual locator/frame CALL results to exact return values,
worlds and traces using the ABI lemmas. The concrete queue lookup executes the
immutable locator getter from the physical pointer and its code guard. Frame
adjustment preserves the packed value saved before external calls; short/rejected
frame replies preserve exact failure and attempted-call prefixes.

`WithdrawalTail` factors the final seed/receiver block with a checked source
identity and sequencing law. Zero seeds, successful checked addition, overflow,
physical packing and the seed event are explicit. The successful tail executes
Router.dispatch with its immutable authorization, ETH transfer and receiver event.
After-spend composition retains the previously looked-up router and ordered
prefix traces. Tail failure restores the original withdrawal world, including
earlier callee effects and spending writes/events. Actual prefix executions are
premises of this composition lemma; the independent spending/whole-withdrawal
specification still must discharge them. This is not full parent completion.

All 29 owned modules passed at `3275479a6803833bc6808a7456bf9fecd3e73ebb`.
`receipts/tail-summary.json` links exact component/toolchain evidence, six baseline
checks and import-DAG validation (all 0), dependency/wrapper identity and source
delta. Inspected axioms are only propext, Classical.choice and Quot.sound.
Historical runtime receipts retain their original source; no runtime implementation
changed. Full gates remain missing, with no new remote job/bundle/node identity.

## Admission and ABI continuation

`AdmissionSpec` independently specifies ordered status, caller and nonzero-amount
admission. `Admission` relates successful withdrawal admission to actual queue
lookup, bunker CALL bytes and the physical pause word after that call. It also
relates false status to bunker/pause observations and proves exact early-failure
fault precedence, retained attempted calls and complete transaction rollback.
The external interpreter remains arbitrary; no successful-callee assumption is
introduced. These prefix theorems do not prove the later spending/seed/ETH path.

`ABI` proves byte encoder length, arbitrary-width decode/encode reduction,
bounded exact round trips, and actual `decodeWord` results for the first and
second 32-byte words with arbitrary trailing bytes. This closes the arithmetic
byte-conversion lemma, not full deployment or caller/callee composition.
`LiveTrust` inspects these new theorems. The immutable component checker now
contains 27 modules, all exit 0 at `1a56fc36b89d4acb0368471639f5d89648e8864f`.
`receipts/admission-summary.json` links the terminal component, six baseline and
import-DAG checks (all 0), dependency/wrapper identity, and proof-only source delta.
Axiom inspection reports only propext, Classical.choice and Quot.sound.
Historical 49-case/seven-mutant execution below belongs to source `0fde648`;
this proof-only continuation does not relabel it as current-head execution.

## Oracle and nested-call continuation

Validated implementation source: `0fde6481707ba16f63ff324547bc2761e1d7b136`.
`receipts/oracle-summary.json` records all 24 owned modules (exit 0), 49 matching
executions (exit 0), seven executed mutant kills, six baseline checks (all 0)
and the import-DAG check (0). `component-checks/<source SHA>/receipt.json` and
`oracle-execution-context.json` bind the commands, source/artifact hashes, toolchain
and dependency identities. Compiler input hashes were rechecked after execution.
The exact-source remote full attempt exits 2 while encoding the gitlink; no
remote job, node or completed bundle digest exists for that attempt.

`Oracle` executes the actual BaseOracle physical consensus-pointer read and
typed STATICCALL, checks tuple length, and applies checked timestamp arithmetic.
`Consensus` executes the HashConsensus frame getter from the physical packed
frame configuration and block timestamp. `OracleSpec` covers timestamp success
and overflow; `FrameSpec` independently selects slot/epoch/frame by quotient
intervals, including uint64 projections, and proves uniqueness. The source
success correspondence and oracle whole-world frame properties are checked.

Nested STATICCALL observations now retain request, relative depth, status and
returned bytes through outer rollback. `StaticCall` rejects forbidden state
operations; `Erasure.call_nested_erasure` removes nested instrumentation without
changing call return/world effects. Arbitrary recursive callback semantics and
the full withdrawal parent are not discharged by these components.

The 49-case draft run (`oracle-execute-2`, exit 0) matches actual Solidity and
Lean, including malformed/rejected static tuples, no code, actual SSTORE under
STATICCALL, initial epoch failure, zero frame length, checked timestamp overflow,
and a real frame-boundary accounting reset. The first executed failure exposed
and corrected uint64 frame-span multiplication modeled as uint256; its log is
retained. The expanded final suite adds cached-frame, static-write-success and
wide-frame-span mutants to the earlier four negative controls. Exact immutable
source validation is recorded in the subsequent oracle summary and component
receipts; do not infer full-gate success from a component description.

Solidity inherits complete pinned AccountingOracle and HashConsensus bodies.
Raw setup still bypasses production consensus-pointer/frame writer admissions.
The frame slot comes from compiler storageLayout and is checked against the
harness's inherited slot query. Vector timestamps are checked against the actual
transaction block. Full ABI/physical/deployment composition, admission/writer
and sequence proofs, bounded EVM world relation, canonical integration, remote
full gates and independent review remain open. No parent completion is claimed.

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
