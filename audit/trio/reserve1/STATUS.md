# P-RESERVE-1 delivery work in progress

Exact starting commit: `c7adae04416704a839d56333efad003f0a0f46b7`.
Branch: `trio/reserve1-live-queue` in an independent persistent clone.
Solidity submodule: `17005714f151e5502c559932319a3f2f74ac2436`.
Verity: `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`.
Lean: `leanprover/lean4:v4.31.0`.

No prior goal turn is available in this workspace to classify. This turn initialized
the exact checkout and dependencies and found source behavior that changes the
implementation: uint128 setters truncate, and the oracle call occurs after writes.
No existing closure PR or site branch was inspected or modified.

## Evidence and unresolved obligations

`Packing.lean` is a checked numeric packing foundation; `PartitionSpec.lean`
proves admitted spending preservation, reserve-lowering and demand monotonicity,
and two-step spending for a fixed queue observation. These are mathematical
lemmas, not live contract correspondence. It does not establish
bitwise storage correspondence, reachable accounting bounds, or the requested
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

Outstanding: live call interpreter and independent specification; explicit
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

Next implementation: connect a physical-word Verity executor to actual queue,
locator and oracle call semantics (including arbitrary rejection/bytes); derive
reachable accounting constraints from writers; prove full ordered observation
correspondence to an independent state/input relation; replace Solidity-only
probes with matching-input differential runs. Full writer authorization,
report-time calls, queue finalization and callbacks remain open. The fixtures
expose these gaps; they do not discharge them.
