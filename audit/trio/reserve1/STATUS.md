# P-RESERVE-1 delivery work in progress

Exact starting commit: `c7adae04416704a839d56333efad003f0a0f46b7`.
Branch: `trio/reserve1-live-queue` in an independent persistent clone.
Solidity submodule: `17005714f151e5502c559932319a3f2f74ac2436`.
Verity: `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`.
Lean: `leanprover/lean4:v4.31.0`.

Resumed the preserved checkout and own draft PR #244. No existing closure or
site branch was inspected or modified. The remote job has a terminal failure
receipt; no duplicate remote build was submitted.

## Evidence and unresolved obligations

`Packing.lean` is a checked numeric packing foundation; `PartitionSpec.lean`
proves admitted spending preservation, reserve-lowering and demand monotonicity,
and two-step spending for a fixed queue observation. These are mathematical
lemmas, not live contract correspondence. It does not establish
reachable untruncated accounting bounds, or the requested
parent guarantee. No new reserve guarantee is registered or claimed complete.

The implementation must preserve the following source facts:

* Lido.sol:815-816 reads locator -> queue -> bunker before reading the local
  active flag; a stopped contract does not skip the queue call.
* Lido.sol:869-886 checks canDeposit, resolves router, checks caller equality,
  then rejects zero amount, spends, updates seed count, and sends value.
* Lido.sol:605-616 resolves the queue and calls unfinalizedStETH on each
  allocation. A cached word/freshness premise is not a replacement.
* Lido.sol:839-859 writes packed buffer/post-report and emits two events before
  resolving the accounting oracle and reading the frame. A failure here must
  restore storage and committed logs. Reserve is written after the frame pair.
* UnstructuredStorageExt.sol:24-46 masks/shifts, silently truncating. Model
  SafeMath uint256 checks separately from physical uint128 truncation.
* WithdrawalQueueBase.sol:143-146 subtracts two uint128 cumulative values with
  Solidity 0.8.9 checked arithmetic, read at current last/finalized request ids.
* Lido.sol:670-680 immediately lowers reserve when target is below it, and emits
  target first. Raising target does not increase reserve until report rebalance.
* Lido.sol:1125-1132 raises reserve to target without capping it to buffer.
  Therefore storedReserve <= buffer must NOT be a global invariant.

Outstanding: full withdrawal independent specification; explicit
state/input and ordered observation relations; actual queue/locator/oracle
storage semantics; malformed/rejected ABI behavior for the pinned compilers;
all writer surfaces; spending/rebalance/queue sequences; ETH balances, rejection
and callbacks; instrumentation erasure; full correspondence; mutations;
pinned Solidity/Verity differential execution; production/test/trust gates;
scoped draft PR and immutable SHA.

## Integration notes (no shared patches applied)

Production and tests are already recursively globbed under Audit.Source and
Tests in lakefile.lean. Explicit Trust imports/#print axioms and canonical
source-map/guarantees/manifest inventories will need coordinated additions.
Until then full registered trust/metadata coverage of this delivery is MISSING.
Keep old declarations unchanged until replacements and consumers validate.

`make prove` writes proofs/logs and the generated proof report. Run it only in
an owned disposable validation copy, or coordinate its output destinations;
do not write those shared paths in this additive checkout. The same applies
to test scripts that generate fixtures or temporary tracked-tree mutations.

Compiler correctness and chosen EVM execution backend are explicit assumptions.
Cryptographic slot derivation needs concrete keccak evaluation/binding evidence.
No full bytecode, gas-cost, cryptographic binding or consensus-state claim.
Callbacks are an open modeling obligation, not an assumed always-success callee.

## Executed checkpoint validation

- All eleven Lake dependency Git revisions verified exactly, with separate
  non-symlink package directories in this checkout's private `.lake`.
- Lean 4.31.0 checks the two foundation modules. Owned test/trust inspection
  prints only propext and Quot.sound for these lemmas; no native decision axiom.
- Pinned Lido/queue-base compilation succeeded with solc 0.4.24/0.8.9 and source
  optimizer/EVM settings. Node 22.15.0 was installed from the source `.nvmrc`
  series and checked against upstream SHA256 sums. Initial Node 18 probes are
  retained as preliminary evidence; Node 22 reran the expanded 17-case suite.
- Seventeen pinned Solidity cases passed, with relevant physical slots and
  balances checked after success, and rollback/log erasure checked on failure.
  Trace records include ordered targets, values and payloads. These do NOT
  execute a matching Verity model and are NOT differential evidence.
- Initial proof-escape, source-annotation, theorem-inventory, Verity provenance,
  and pinned-source checks exited 0. These checker scopes do not establish new
  canonical registration. Pinned-source check retained 19 baseline warnings.
- Remote build accepted job `72e45c29-b554-4616-9fd2-cd54a38dde96` on `old-agent`
  for `lake build LidoSRv3 LidoSRv3Test LidoSRv3Audit`. Passive mode: no repeated
  polling or duplicate build. This was submitted before PartitionSpec and the
  owned tests were added; it is not a validation of this final checkpoint.
  Its acceptance receipt is NOT a success receipt. Collect the existing job
  when terminal before considering a build of the later source tree.
- `make prove`, `make test`, final production/test/trust, canonical metadata,
  comprehensive inventory and new provenance registration remain NOT VERIFIED.

The executed 0.4.24 trace uses CALL (not STATICCALL) for locator, queue and
oracle view functions. The eventual executor must therefore not infer
read-only/callback-free external behavior from the source `view` annotation.
The current boundary fixtures do not close callback/reentrancy behavior.

Remaining implementation: connect the physical-word executor to actual locator,
locator and oracle call semantics (including arbitrary rejection/bytes); derive
reachable accounting constraints from writers; prove full ordered observation
correspondence to an independent state/input relation; replace Solidity-only
probes with matching-input differential runs. Full writer authorization,
report-time calls, queue finalization and callbacks remain open. The fixtures
expose these gaps; they do not discharge them.

## Resumed implementation and checked evidence

- `Live.lean` now executes the source function boundaries using pinned Verity
  words and contract-indexed storage. It reads live queue replies on every
  allocation, derives admission from caller/locator reply/local pause/live
  bunker, preserves saved locals across calls, writes uint128 packed fields,
  transfers actual balances, and accepts arbitrary rejection/bytes/world effects.
  This is a handwritten executor, not a completed Verity EDSL/bytecode refinement.
- `QueueSpec.lean` is independent of executable imports. `Queue.StateRel` binds
  current request/finalized ids and every cumulative row to physical slots.
  `Queue.unfinalized_corresponds` proves the numeric return or panic 0x11 for all
  related states, including malformed rows. Mapping keccak is an explicit
  primitive; no injectivity axiom or freshness premise is used.
- `Erasure.erase_bind`, `erase_pure`, and `erase_run` prove compositional trace
  erasure and rollback commutation. `failure_restores_world` covers arbitrary
  failure after intermediate effects. This proves the defined interpreter's
  rollback, not yet the complete Solidity entrypoint correspondence.
- `PhysicalPacking.pack_matches_bitwise` proves numeric packing equals the
  actual mask/shift/OR word expression. `low_pack` / `high_pack` prove physical
  projections with truncation; `physical_low_bound` / `physical_high_bound`
  hold for arbitrary stored words. They do not assert untruncated sums or a
  global reserve <= buffer invariant.
- Owned `LiveTrust.lean` inspection exits 0. New checked lemmas use only
  propext, Quot.sound, and (bitwise library proof) Classical.choice; no new
  axiom declarations, native decision proof, or proof escape.
- The harness now inherits actual `WithdrawalQueue.isBunkerModeActive` as
  well as `WithdrawalQueueBase.unfinalizedStETH`, using solc 0.8.9. Lido remains
  inherited solc 0.4.24. Constructor token setup and raw initialization are
  fixtures; their production authorization is not claimed.
- `differential-execute-2.txt/.exit` records exit 0: 29 matching executions
  compare root return/revert bytes, seven Lido physical words, current queue
  ids/bunker/cumulative mapping words, five account balances, ordered directly
  Lido-issued target/value/payload calls, and ABI committed events. Root router
  forwarding and nested callee calls are excluded from this comparison.
  `differential-input.json`, `differential-solidity.json`, and
  `differential-verity.json` retain the matching inputs and independent outputs.
  Locator/oracle/router fixtures are explicitly input boundaries; their success
  is not a production theorem premise. Successful arbitrary callbacks are not
  exercised in this finite suite and complete nested-call composition is open.
- The 29 cases include 128/256-bit boundaries, malformed/trailing return bytes,
  unauthorized, stopped, bunker, actual balance shortage, ETH rejection,
  intermediate-effect failure, queue enqueue/finalization and malformed queue
  underflow, stale/current frame counters, lowering targets, rebalance above
  buffer, and a second spend after queue growth. Sequential full proofs remain
  open; the independent fixed-demand `two_spends` lemma is still scoped.
- Two actual mutant runs disagree with Solidity: cached demand permits a
  queue-growth spend the source rejects; omitting rollback exposes oracle-failure
  writes. `mutation-comparison.json` records both kills.
- Baseline proof-escape, source annotation, inventory, provenance, pinned-source
  and metadata checks exit 0 again (`resumed-checks.json`). These checks do not
  establish new canonical registration. Full registration remains MISSING.
- Earlier remote job `72e45c29-b554-4616-9fd2-cd54a38dde96` terminated FAILED
  (exit 1): fetching pinned `evmyul` failed with Git exit 128 for missing remote
  authentication. `remote-resume-original-env.txt` is the terminal receipt.
  No credentials/security setting changes were attempted.

Live module, queue and erasure checks are now green after retained diagnostic
failures. Full production/test/trust and `make prove` / `make test` remain pending;
a private mathlib cache acquisition is in progress to enable those gates. The
new internal writer scalar correspondence work is in progress and is not yet
included in the checked claims above.

The internal writers now also compile: `Writers.target_corresponds` and
`rebalance_corresponds` establish the independent `WriterSpec` scalar relations
on physical projections. `target_observations` and `rebalance_observations`
prove success, no external calls, preserved balances and exact appended event
order for those internal helpers. External ACL/report-parent correspondence is
still open. See `writers-4.txt/.exit` (0) and `SOURCE-MAP.md`.

The inherited toolchain path disappeared during cache extraction. The failed
cache receipt is retained. A private Lean 4.31.0 copy is now installed under the
owned `.local` directory, with version/binary hashes recorded in
`private-lean-toolchain.txt`. `mathlib-unpack-private.exit` is 0; the downloaded
pinned cache was unpacked without another download or shared toolchain changes.
