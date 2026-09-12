# Independent exact-source review — lido-srv3-proof-closure PR #286 (DRAFT)

- Reviewer mission: db703d0a (read-only; no merge/push/comments/edits performed)
- Head: `9c5b239b2d93cea0b8917de220550f01dded4f24` (== `refs/pull/286/head`, DRAFT, OPEN, base `main`)
- Base: `7db9187e5d701977209735b8b6ae4441774b5e3d` (verified ancestor of head)
- Solidity pin: lido-core submodule `17005714f151e5502c559932319a3f2f74ac2436` (verified `git ls-tree` + checkout)
- Packet: `/tmp/lido-topup286-review-9c5b239b/topup286-review-packet/` — all 93 files verified against `manifest.json`; archive SHA256 `4b69aeb94c3f4c512409f8460788475f963569f160180beaab1e255a54dd01d4` reproduced from `archive.b64`; all 93 files byte-identical to the authoritative git checkout.
- Scope: necessary effects of the committed beacon helper. All eight guarantees remain OPEN; this review grants no SITE/guarantee credit.

## Diff shape

10 files, 8329 insertions, 0 deletions vs base. Exactly: 1 new source module
(`LidoSRv3/Audit/Source/TopupBeaconCommitted.lean`, 308 lines), 1 new test module
(`LidoSRv3/Tests/TopupBeaconCommittedMutants.lean`, 76 lines), 8 audit evidence files.
No existing source modified.

## Build verification (this workspace, fresh toolchain leanprover/lean4:v4.31.0)

- `lake build` (full default target): exit 0, "Build completed successfully (1646 jobs)".
- Receipt command `lake build +LidoSRv3.Tests.TopupBeaconCommittedMutants`: exit 0,
  "Build completed successfully (1274 jobs)". Matches claimed 1274 PASS.
- 9 source `#print axioms` + 5 test `#print axioms` queries all report only
  `propext`, `Quot.sound`, and (helper-input-dependent) `Classical.choice`. No `sorryAx`.
- `grep -E "sorry|admit|native_decide"` over both new files: no matches.
- Only linter warnings (unused simp args / unnecessarySimpa), consistent with receipt's
  "warnings retained" disclosure.

## Receipt / identity verification

- `python3 audit/topup-beacon-committed/check_receipt.py`: **1382 checks, 0 errors**
  = 74 validated_inputs + 5 evidence_hashes + 29 inherited identity checks +
  1256 package source closure + 11 package pins (git HEAD of each `.lake/packages/*`) +
  7 selected Lean core sources (toolchain `src/lean`). Matches claimed "1382 identity checks PASS".
- Inherited solc 0.6.11 evidence (`audit/topup-beacon-effects/`): all hashes verified;
  `foundry.toml` pins `solc = "0.6.11"`; no fresh Forge claimed or required.

## Failure-log provenance

- `wrong-initial-count-diagnostic.log`: kernel `decide` refuted the draft test's initial
  count-0 expectation (error at Mutants line 40:95, `sorryAx` in the failed draft,
  build failed). Consistent with "kernel refuted initial count 0".
- `source-build-with-failed-fixture.log`: source built, draft test failed — explicitly
  not a passing whole-target result, retained as disclosed.
- `validation.log`: final 1274-job success; axioms lines match this review's reproduction.

## Source review (bodies, not just compile)

### 9 source theorems (count matches claim)

1. `guarded_amount_fits`: `a/10^9 ≤ 2^64-1 → a < 2^256` via `Nat.mod_add_div` + omega.
   Wei fit genuinely derived from the executed uint64-gwei guard; no nowrap premise.
2. `loop_success_balances`: induction over the ACTUAL `TopupBeaconBatch.loop`; consumes
   `TopupBeaconEffects.success_balances` of the real `push`/`CallData.invoke`/dispatch/
   `deposit` chain per successful CALL; composes pointwise `CallSpec.Balances` over
   `allocSum`. No funding/key/minimum/capacity/non-alias premise. Aliased
   sender/recipient handled: `CallSpec.Balances` (CallSpec.lean:5-8) is
   `after a + (a=sender ? v) = before a + (a=recipient ? v)`, correct for self-transfer;
   final `split_ifs ... omega` covers all alias cases.
3. `deposit_success_count`: from `deposit hash f req before = .success ...` derives
   physical slot32 `count+1` and `≤ maxCount`, via `insert_count` (branch loop proven to
   exclude slot 32; height+fuel ≤ 32) and `readContractSlot_writeContractSlot_same`.
   No initial-count invariant or insertion success assumed.
4. `push_success_count`: transports through the real CALL incl. provisional
   `transfer`; case-split eliminates no-code/unfunded/rejected/successWithTrace branches.
5. `loop_success_count`: per-nonzero-entry increment composed; final capacity bound only
   when `nonzeroCount > 0`. The zero-rest case correctly falls back to the single-call
   bound (`hb.2`) — empty/all-zero batches make no claim on an arbitrary initial slot,
   as documented.
6. `run_success_balances`: consumes the actual `Live.run` rollback wrapper; failed branch
   impossible under `.ok`.
7. `helper_success_balances`: actual `TopupRouterContinuation.helper`; empty-pubkeys early
   return proves movement 0 even with nonempty caller-supplied allocations; length-mismatch
   fail branch discharged; else delegates to `loop_success_balances`. Outer router input
   validation honestly left as a separate link.
8. `helper_success_count`: same structure for physical count.
9. `committed_funding`: under `ctx.self ≠ target`, aggregate funding
   `allocSum ≤ before.balances self` and exact debit equation derived as a CONSEQUENCE of
   the pointwise ledger theorem.

### Guard-order correspondence to pinned Solidity (17005714)

- `TopupBeaconBatch.loop` (key width → zero skip → min 1 ETH → uint64 gwei max → CALL)
  matches `BeaconChainDepositor.makeBeaconChainTopUp` (0.8.25/lib, lines 66–106;
  key-width revert precedes `if (amount == 0) continue`, then MIN_DEPOSIT, then
  `type(uint64).max`, then `_depositContract.deposit{value: amount}`).
- `TopupBeaconCallee.deposit` matches `deposit_contract.sol:101–159` (0.6.11):
  length checks → `msg.value >= 1 ether` → `% 1 gwei == 0` → `<= type(uint64).max` →
  DepositEvent emitted BEFORE root/tree-full checks → root match →
  `deposit_count < MAX_DEPOSIT_COUNT` (2^32-1 = `maxCount`) → `deposit_count += 1` →
  binary-carry branch insert with unreachable `assert(false)` tail. Storage:
  `bytes32[32] branch` slots 0–31, `uint256 deposit_count` slot 32 → model `countSlot=32`.
  Selector `0x22895118` is `deposit(bytes,bytes,bytes,bytes32)`.
- `TopupRouterContinuation.helper` matches `StakingRouter.sol:746–754` continuation;
  source line-73 empty-pubkeys early return preserved before length checking.

### Tests (1 positive theorem + 7 kernel examples — counts match claim)

- `positive_helper`: constructs actual callee success via `source_push_success` on the
  accepted changed-withdrawal fixture, discards producer facts, applies both new helper
  consumers; kernel proves physical count 3 → 4 (`decide +kernel` on fixture initial = 3).
- Kernel examples cover: uint64-gwei upper edge fit, refutation just above the edge,
  empty-key early return (ok, zero movement, and no spurious balance credit),
  key-width check preceding zero-skip (`InvalidPublicKeysBatchLength` with amount 0),
  length mismatch, and empty loop over an above-capacity initial slot (ok, unchanged).

## Findings

No discrepancies found. Every quantitative claim (10 files, 9/1/7 theorems-examples,
9+5 axiom queries, 1274 jobs, 1382 identity checks, 4 pinned Solidity bodies,
submodule pin 17005714, packet 93 files + tar SHA) reproduced exactly. The theorem
statements consume the actual loop/helper/callee chain, derive fit/funding/capacity
from executed guards, handle aliasing and empty batches honestly, and the README's
residual-scope disclosures (outer prefix composition, EVM/ABI correspondence, SHA
opacity, no full TOPUP guarantee) are accurate.

VERDICT: CLEAN
