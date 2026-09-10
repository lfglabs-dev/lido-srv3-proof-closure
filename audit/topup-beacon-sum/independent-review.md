# PR #290 independent exact-source review

**Mode:** READ-ONLY. Sole reviewer. No merge, push, comments, source edits, site, or deploy. No Cerebras. No full rebuild. No host-path search. Event-2680 180s timeout is not a technical verdict. Duplicate `49c00b83` INFRA_BLOCKED is not a technical verdict.

**Subject:** `lfglabs-dev/lido-srv3-proof-closure` PR #290 frozen head vs pin `StakingRouter.topUp` / `BeaconChainDepositor.makeBeaconChainTopUp` / `DepositContract.deposit`.

**Deliverable only:** this file.

## Identity

| Item | Actual |
|---|---|
| Isolated HEAD | `89acb917ccaa452303610f0c5c3654d5556a771a` |
| `git rev-parse HEAD` | **equals frozen SHA** |
| Parent / integration base | `a3245527ed2ef8a96e8b1e7877124ab1d5e7ef07` (merged source 287) |
| Subject | `feat(topup): derive exact positive router sum from executed beacon guards` |
| Core pin | `17005714f151e5502c559932319a3f2f74ac2436` (`git -C temp/lido-core-pin rev-parse HEAD`) |
| Packet | `/tmp/lido-topup290-review-89acb917/topup290-review-packet` |
| Manifest | `head`/`base`/`source_pin` match the three SHAs above; `writer: STOPPED`; `files: 162` |
| Disk vs manifest | 163 paths on disk = 162 content files + `manifest.json`. Manifest-missing-on-disk: none. |
| Diff vs parent | 12 files, +10241/−0. New Lean: `TopupBeaconSumBound.lean` (226), `TopupBeaconSumBoundMutants.lean` (94). Rest is `audit/topup-beacon-sum/`. |
| `docs/1489-identity.md` | **absent** (not reused, not invented) |
| `1508.md` | **not sought**. 1508 is a checker-comparisons count, not a document. |

Packet vs git HEAD for the two new Lean files: byte-identical.

| Path | SHA256 | Lines |
|---|---|---|
| `LidoSRv3/Audit/Source/TopupBeaconSumBound.lean` | `e68900945d8b66ae248d6381c8e0dc8631fb907ecede496cba13d4b225c87fac` | 226 |
| `LidoSRv3/Tests/TopupBeaconSumBoundMutants.lean` | `e06cbe501e979b51f0fc9a7dd0d7a29df5fc020acc26fc9efd1d294abe7a24a6` | 94 |

Receipt `validated_inputs` for both files equals disk. Unchanged consumer sources are identical at parent and HEAD:

`TopupRouterCommitted.lean`, `TopupBeaconCommitted.lean`, `TopupBeaconBatch.lean`, `TopupRouterContinuation.lean`, `TopupLiveWithdrawal.lean`, `TopupModuleCall.lean`.

Receipt `source_pin` and `integration_base` match git. Goal field: `all eight complete guarantees OPEN`.

## Pin bodies (complete files, not excerpts)

Packet `lido-core/` vs `/workspaces/mission-a8310864/temp/lido-core-pin` SHA256 match for all nine vendor files. In-repo `lido-core` remains an empty submodule pointer; bodies are taken from the packet / pin checkout at `17005714`.

Receipt `validated_inputs` lists **eight** Solidity pins (matches manifest “8 pinned Solidity bodies”). Packet also contains `IStakingModule.sol` (ninth vendor file, not in this receipt’s `validated_inputs`). Hashes:

| File | SHA256 prefix | vs pin `17005714` |
|---|---|---|
| `Lido.sol` | `3bf84b96fb155af2` | match |
| `deposit_contract.sol` | `2a8db249155e8502` | match |
| `BeaconChainDepositor.sol` | `b4afeac2e4dab53d` | match |
| `SRStorage.sol` | `62e922f76a1db775` | match |
| `SRTypes.sol` | `22c28be7ceaf6ed8` | match |
| `StakingRouter.sol` | `4d5b83fc73736db6` | match |
| `IDepositContract.sol` | `d7b36c2de36cfc68` | match |
| `IStakingModuleV2.sol` | `eacc19c668dd2ad9` | match |

### `BeaconChainDepositor.makeBeaconChainTopUp` (pin 66–108)

Guard order on the executed helper:

1. `len = _publicKeys.length`; `len == 0` **return** (no amount inspection).
2. `len != _amount.length` → `ArrayLengthMismatch`.
3. Per key: `pk.length != 48` → `InvalidPublicKeysBatchLength`.
4. `amount == 0` → **continue** (no CALL, no capacity consume).
5. `amount < 1 ether` → `DepositAmountTooLow`.
6. `amount / 1 gwei > type(uint64).max` → `AmountTooLarge`.
7. Then `_depositContract.deposit{value: amount}(...)`.

Exact gwei alignment is **not** this helper’s check; the deposit-contract callee requires `msg.value % 1 gwei == 0`.

### `DepositContract.deposit` (pin 101–159)

`pubkey` 48 / WC 32 / sig 96; `msg.value >= 1 ether`; multiple of 1 gwei; `deposit_amount = msg.value / 1 gwei` as uint64; reconstructed deposit-data root; `deposit_count < MAX_DEPOSIT_COUNT` (`2^32-1`) then `deposit_count += 1`. Physical slot32 capacity is the Merkle-tree bound.

### `StakingRouter.topUp` (pin 717–758)

Starts **after** the rounded-target preamble (preamble remains OPEN). `allocateDeposits` → unchecked loop: gwei alignment, then limit, then `amount += allocations[i]` → `amount > rounded` revert → `amount > 0` withdraw + `makeBeaconChainTopUp` + balance assert → emit `StakingRouterETHTopUp`. Zero `amount` skips withdrawal/helper and still emits.

Lean `guardSum` transcribes alignment-then-limit then `(acc+a) % uint256Modulus`. `helper` transcribes empty-key early return then length mismatch then `TopupBeaconBatch.loop`. `loop` transcribes 48-byte → skip zero → min `10^18` → `a/10^9 ≤ 2^64-1` → CALL.

## Eight source theorems (complete bodies)

File: [`LidoSRv3/Audit/Source/TopupBeaconSumBound.lean`](/workspaces/mission-a8310864/temp/repo/LidoSRv3/Audit/Source/TopupBeaconSumBound.lean) (226 lines). `sorry`: 0. `axiom` decls: 0. Eight `theorem`s. Eight `#print axioms`. No `Admissible`, funding, capacity, frame, or no-wrap hypothesis on any of the eight.

### Short chain (as executed, not as advertised)

**1. `loop_success_amount_bounds`**  
`TopupBeaconBatch.loop` success ⇒ `∀ a ∈ amounts, a < 2^64 * 10^9`.

Derived by induction on the actual loop:

- length mismatch / bad key width / `a ≠ 0 ∧ a < 10^18` / `a/10^9 > 2^64-1` are `fail` (contradict success);
- `a = 0` (after 48-byte) skips CALL and contributes `0 < 2^64*10^9` by `decide`;
- nonzero executed arm uses `a/10^9 ≤ 2^64-1` plus `Nat.mod_add_div` to get `a < 2^64*10^9`.

This is the executed uint64-gwei ceiling. Zeros are included without a supplied amount-admission predicate. Correspondence: pin helper skip-zero + `AmountTooLarge`; deposit-contract uint64 gwei is the callee-side twin, not a new Lean premise.

**2. `sum_le_nonzero`**  
`∀ a ∈ amounts, a < 2^64*10^9` ⇒ `allocSum amounts ≤ nonzeroCount amounts * (2^64*10^9 - 1)`.

Zeros do not consume the multiplier. Independent list arithmetic; no World.

**3. `loop_success_nonzero_bound`**  
Loop success ⇒ `nonzeroCount amounts ≤ maxCount` (`maxCount = 2^32-1` in `TopupBeaconCallee`).

Consumes existing `TopupBeaconCommitted.loop_success_count` (parent-identical): physical slot32 grows by `nonzeroCount`, and `nonzeroCount > 0` ⇒ final count `≤ maxCount`. Empty / all-zero: `omega` after `unfold maxCount`; **no bound on the initial physical count**. Matches pin `deposit_count < MAX_DEPOSIT_COUNT` only on executed nonzero deposits.

**4. `loop_success_sum_fits`**  
Loop success ⇒ `allocSum amounts < uint256Modulus`.

`sum_le_nonzero` + `nonzeroCount ≤ maxCount` + kernel fact `maxCount * (2^64*10^9 - 1) < 2^256`. Arbitrary initial Nat ledger/count is allowed; range is a **consequence** of executed per-amount ceiling and physical nonzero capacity. No new no-wrap premise.

**5. `helper_success_sum_fits`**  
Actual `TopupRouterContinuation.helper` success ⇒  
`(if pubkeys = [] then 0 else allocSum allocations) < uint256Modulus`.

Empty-key split is the genuine helper (`helper` lines 123–126: `if i.pubkeys = [] then pureExec`). Nonempty path is `loop_success_sum_fits`. Empty keys impose **no** bound on ignored overflowing allocations.

**6. `helper_success_guard_exact`**  
`guardSum … = .ok total` **and** helper success ⇒  
`pubkeys = [] ∨ total = allocSum allocations`.

Nonempty path: `helper_success_sum_fits` gives mathematical sum `< uint256Modulus`; `guardSum_spec` gives `total = uncheckedSum 0 amounts`; `uncheckedSum_exact` (existing `TopupWeiBounds`) converts wrap-mod to exact sum. Empty-key alternative retained. Reaching a helper is **not** assumed for zero-total router paths (`program` skips helper when `total = 0`).

**7. `positive_effects_sum`**  
`guardSum … = .ok total` **and** `TopupRouterCommitted.PositiveEffects` ⇒  
`pubkeys = [] ∨ (total = allocSum ∧ allocSum < uint256Modulus)`.

Unpacks `PositiveEffects.executed` to the **same** `helper` result already required by PR287 (`Live.run suffix` then `helper hash (routerContext ctx) beacon i withdrawn`). No helper-success / capacity / amount bound is a new caller premise. Empty-key disjunct kept.

**8. `module_execute_success_sum`**  
`TopupModuleCall.execute` success ⇒ the PR287 `module_execute_success` existentials (raw CALL, `decodeReturn`, `guardSum`, `total ≤ roundedTarget`, same-world continuation, attempts = moduleTrace ++ suffix) **and**

- `total = 0` event-only suffix, **or**
- `PositiveEffects` on that suffix **and** (`i.pubkeys = []` ∨ exact `total = allocSum` with sum `< uint256Modulus`).

Proof: `obtain` PR287 `module_execute_success`, then `positive_effects_sum` on the positive branch. Actual consumer is the existing executor; decoded allocations feed `continuationInput` (same pubkeys, decoded allocations). Zero-total and empty-key source paths stay in the conclusion.

`#print axioms` on all eight (source-validation.log): only `propext` / `Classical.choice` / `Quot.sound`. `sum_le_nonzero` and `loop_success_amount_bounds` omit `Classical.choice`.

## Premises vs displayed claims

| Claim in README / receipt | Source fact |
|---|---|
| Per-amount ceiling + nonzero count from actual success → sum fits | Theorems 1–4. Yes. |
| `guardSum_spec` ⇒ exact total | Theorem 6, only when helper also succeeded and keys nonempty. Yes. |
| `module_execute_success` consumes `PositiveEffects` and the same helper | Theorems 7–8. Yes. |
| No new admission / frame / no-wrap premise | None of the eight introduce `Admissible`, funding, distinct-accounts, `codeSize`, or an independent nowrap hypothesis. Yes. |
| Empty keys explicit | Theorems 5–8 and helper def. Yes. |
| Wrapped-zero path explicit | Zero-total branch does not run the helper, so wrap-to-zero of a malicious module reply is **not** refuted. README states this. Yes. |
| Retains actual calls / world / ledger / count / events | `module_execute_success_sum` copies PR287 existentials; does not replace the executor. Yes. |
| Physical count coupling | Via `loop_success_count` / `maxCount`; zeros do not consume capacity. Yes. |
| Initial arbitrary count | Empty loop example and `loop_success_nonzero_bound` zero case. Yes. |
| Alias ledger | Not re-proved here. Existing `loop_success_balances` is pointwise including caller=recipient; `committed_funding` still requires `self ≠ target`. This increment’s sum is Nat arithmetic, account-independent. |
| Exact actual consumer | `TopupModuleCall.execute` / `TopupRouterContinuation.helper` / `TopupBeaconBatch.loop`. Yes. |

Not claimed, and not found smuggled: compiler ABI equivalence, preamble/auth, module implementation, withdrawal-interpreter preservation, uint256 physical-ledger correspondence beyond the mathematical sum, post-withdrawal balance bounds as a new theorem, complete TOPUP.

## Tests (three named + nine kernel)

[`TopupBeaconSumBoundMutants.lean`](/workspaces/mission-a8310864/temp/repo/LidoSRv3/Tests/TopupBeaconSumBoundMutants.lean) (94 lines). `sorry`: 0. `axiom` decls: 0.

Named regressions (consume fixtures; do not supply ledger/capacity postconditions as premises):

1. **`positive_exact_sum`** — actual `positive_helper` execution + `guardSum` numeral `ether` ⇒ `ether = allocSum` and sum `< uint256Modulus`. Rejects empty-key disjunct by kernel `pubkeys ≠ []`.
2. **`positive_suffix_sum`** — `positive_effects_sum` on `positive_suffix_effects` (3 ETH) ⇒ exact sum. Excludes zero and empty keys in this fixture.
3. **`module_exact_sum_chain`** — `module_execute_success_sum` on `committed_success`. Conclusion retains **both** zero-total and PositiveEffects/exact-sum branches.

Nine kernel `example`s:

| Example | What it pins |
|---|---|
| `maxCount * (2^64*10^9 - 1) < uint256Modulus` | Capacity × ceiling below uint256 |
| `(2^64*10^9 - 1)/10^9 = 2^64-1` | Edge of executed uint64-gwei |
| `¬ (2^64*10^9)/10^9 ≤ 2^64-1` | Strictness of the helper guard |
| `nonzeroCount [0,10^18,0,2*10^18] = 2` | Zeros do not count |
| `allocSum [0,10^18,0,2*10^18] = 3*10^18` | Zeros do not add |
| emptyHuge helper = `pureExec` on `before` | Empty keys ignore allocations |
| `uint256Modulus ≤ allocSum` of those ignored words | Overflowing ignored list |
| empty-key `if` yields 0 | No false bound from helper success |
| empty `loop [] []` on `countSlot = maxCount+7` unchanged | Arbitrary over-capacity initial count |

`#print axioms` in the test file: 5 (`positive_suffix_sum`, `module_exact_sum_chain`, `positive_exact_sum`, plus reprints of `helper_success_guard_exact` and `loop_success_sum_fits`).

Query accounting vs receipt: `source_queries: 8`, `test_queries: 5` → **13** occurrences. Distinct ordinary declarations: 8 source theorems + 3 named tests = **11** (the two extra test queries reprint source theorems). Matches the claimed 13/11.

Logged axioms on those 13: only `propext`, `Classical.choice`, `Quot.sound`.

## Hash-bound validation scopes (caches, not a rebuild)

Receipt (read once from `audit/topup-beacon-sum/receipt.json`; not the PR287 router receipt):

- command `lake build +LidoSRv3.Tests.TopupBeaconSumBoundMutants`, `exit_code: 0`
- `targeted_jobs: 1280`, `source_theorems: 8`, `kernel_examples: 9`, `positive_execution_and_consumer_theorems: 3`
- `active_test_seconds: 1.5`
- `source_reuse`: source-validation.log **build6 1275 jobs**; test **build8 1280 jobs**, fresh test 1.5s
- `solidity.fresh_run: false`; inherited module/beacon Forge reused by hash
- Failed modulus / namespace / test-name logs retained as diagnostics, not validation

This review **did not** re-run `lake` or Forge. Logs on disk:

- `source-validation.log` ends `Build completed successfully (1275 jobs).` plus the eight source `#print axioms`.
- `validation.log` ends `Built LidoSRv3.Tests.TopupBeaconSumBoundMutants (1.5s)` then `Build completed successfully (1280 jobs).`
- `evidence_hashes` SHA256 of those seven evidence files match disk (7/7).
- `validated_inputs` 84/84 match packet disk.

`inherited-validation.json`: `fresh_solidity_execution: false`; frozen dependency `a3245527`; 137 `identity_checks`. Packet+repo disk: **135 match, 0 mismatch, 2 missing** because Lake packages are not mounted:

- `.lake/packages/verity/Verity/Core.lean`
- `.lake/packages/verity/Contracts/Common.lean`

### Checker 1508 (count, not a file)

Observed components in `dependency-inputs.json` / receipt, **not** a `1508.md`:

| Component | Observed |
|---|---|
| `package_source_closure` | **1262** |
| `local_import_count` | **69** |
| Receipt Solidity pins | **8** (manifest: 8 bodies) |
| Packet `lido-core` vendor files | **9** (includes `IStakingModule.sol` not in this receipt) |
| `selected_core_sources` | **7** (Init Nat/List/Fin/Except + Omega; toolchain `leanprover/lean4:v4.31.0`) |

1262+69+8+7 = 1346; 1262+69+9+7 = 1347. The integer **1508** is the claimed checker-comparisons count, not reconstructed here as a file and not treated as missing access. Package Git bodies are recorded in the JSON; this workspace cannot re-hash the 1262 package files because `.lake/packages` is absent in both the clone and the packet.

## Package-verification limits (recorded, not a pin defect)

- Lake package caches **not mounted** (`temp/repo/.lake/packages` absent; packet `.lake/packages` absent). Cannot independently verify the 1262 package-source SHA256s against installed trees.
- Seven selected toolchain sources are **identities in JSON**, not a full kernel audit and not re-hashed against a live Lean install in this review.
- No full repository rebuild (instruction). Kernel claims are taken from the frozen logs after source-identity of the new files and parent-identity of consumed modules.
- No new Forge; inherited module ABI (8 tests / 1024 fuzz / 64 vectors) and beacon solc 0.6.11 (4 tests / 1024 fuzz) reused only as hash-bound prior evidence.
- Decoder vs compiler `count=2^59` Panic-41 vs Lean `.empty` remains an inherited OPEN, unused by this sum increment.

## OPEN (must stay OPEN)

Explicit zero/empty alternatives and post-withdrawal ledger scope remain OPEN, as required.

1. **Parent ABI / auth / registration / rounded-target** — theorems start at pin 717 after preamble. OPEN.
2. **Arbitrary callee** — module and withdrawal `External` remain parameters. No module impl, no callback restriction, no pre-module conservation. OPEN.
3. **Payload / encoder** — reused accepted word encoder; not a universal compiler encoder theorem. OPEN.
4. **Logical decoder vs compiler alloc/gas** — inherited `2^59` split retained. OPEN.
5. **No-code traces** — Live early `codeSize` vs typed CALL. OPEN.
6. **`Live.run` rollback** — model rule, not EVM/X/revert-ABI. OPEN.
7. **Beacon address, hash correctness, runtime provenance, aggregate history** — `A-TOPUP-BEACON-ADDRESS` and related. OPEN.
8. **Complete TOPUP / P-TOPUP / P-TOPUP-1 / P-TOPUP-2** — OPEN. STATUS still lists P-TOPUP-1/2 CHECKED/CHECKED with IMPLEMENTATION_PENDING and the same fidelity gaps. Metadata does not close evidence.

Additionally named and **not closed by these eight theorems**:

- Wrapped-zero from a module reply whose `guardSum` lands on 0 without executing the helper.
- Empty-key helper success with overflowing ignored allocations (explicitly exhibited).
- Post-withdrawal physical ledger as an invariant over arbitrary withdrawal interpreters; `PositiveEffects` count/balances remain relative to the **executed** suffix/helper worlds.
- Gateway admission / uint64 count-target correspondence still required to constrain module replies before the helper.
- Uint256 physical-ledger correspondence and intermediate balance bounds.

## Defects in this increment’s stated claim

None found. Bodies exist, match the pin helper/callee/router-sum guards, consume the existing PR287 executor, and do not smuggle admission/frame/no-wrap. Claims are scoped. Remaining program obligations are listed, not hidden.

**Not claimed:** compiler equivalence, preamble, module honesty, complete TOPUP, physical post-withdrawal conservation for arbitrary interpreters, closing P-TOPUP.

## Verdict

Frozen HEAD `89acb917ccaa452303610f0c5c3654d5556a771a` on parent `a3245527ed2ef8a96e8b1e7877124ab1d5e7ef07`. Pin `17005714f151e5502c559932319a3f2f74ac2436`. Packet 162 files. New source 226 lines / 8 theorems; tests 3 named + 9 kernel. P-TOPUP remains OPEN. All eight unfinished guarantees remain OPEN.

VERDICT: CLEAN
