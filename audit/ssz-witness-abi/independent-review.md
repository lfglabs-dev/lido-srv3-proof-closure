# Independent Exact-Source Review — lfglabs-dev/lido-srv3-proof-closure PR #289 (DRAFT)

- **Head (frozen):** `3521761bba0ad6e1651f620ae0d2359bfc1343b0` (`feat(ssz): bind decoded witness inputs through actual SHA call states`)
- **Base:** `912bdeca1464797597731e45c4c3eb027d169c09`
- **Solidity pin:** `17005714f151e5502c559932319a3f2f74ac2436` (lidofinance/core, submodule `lido-core`)
- **Mode:** read-only; writer=false; no merge/push/comments/source edits/site/deploy
- **Date:** 2026-09-10

## 1. Source access and identity

| Check | Result |
|---|---|
| `git fetch origin pull/289/head` + checkout exact SHA | OK; `HEAD = 3521761b…`, single commit, 18 files, +15572 |
| Base commit present | OK (`912bdeca…` resolvable) |
| `lido-core` submodule | initialized at exactly `17005714f151e5502c559932319a3f2f74ac2436` — matches `receipt.json source_pin` |
| Review packet `/tmp/lido-ssz289-review-3521761b/ssz-witness-abi-review-packet/` | 78 files, all `manifest.json` SHA-256 match; recursive diff vs the git checkout shows **zero content differences** (packet is an exact subset of the frozen tree) |
| Package pins (11) | verified by the provided checker against `.lake/packages/*/HEAD` (verity `e977aaad…`, evmyul `f7e4ee0d…`, mathlib `fabf563a…`, …) |

## 2. Executed verification (this container)

1. **`python3 audit/ssz-witness-abi/check_receipt.py` → exit 0, `{"checks": 1246, "errors": []}`.**
   Composition: 31 validated inputs + 12 evidence hashes + 69 inherited identity checks + 1117 package-source-closure entries (16 of them the local `Source` imports; `local_import_count = 16`) + 11 package pins + 6 selected Lean core sources = **1246 comparisons, all byte-exact**.
2. **Independent targeted build reproduced:** `lake build LidoSRv3.Tests.SszWitnessAbiMutants` → exit 0, **`Build completed successfully (1134 jobs)`**, reusing existing package caches *after* the identity checks above (no full rebuild). Axiom output identical to the packet `validation.log`/`axioms.log`.
3. **Count cross-checks:** 10 public source theorems; 3 private helpers (`bind_success`, `mapped_success`, `finish_origin`); 2 named regression theorems (`negative_key_slice`, `key_failure_before_dirty_fields`); 9 kernel `example`s → 11 kernel cases; 13 axiom-query occurrences / 12 distinct declarations (`run_success_origin` queried twice); all report exactly `[propext, Classical.choice, Quot.sound]` — no `sorryAx`, no new axioms.
4. **Hidden-premise scan:** no `sorry`/`admit`/`native_decide`/`axiom` declarations in the two new files or anywhere in the 14-file transitive dependency closure (grep clean; only the pre-existing theorem *name* `call_admitted`). No free `variable` premises in `SszWitnessAbi.lean`; every theorem quantifies only over fuel/states and a `.ok` hypothesis.
5. **Forge tests:** `forge`/`solc` are not installed in this container, so the 4 tests were **not re-executed**; the four test bodies in `SszWitnessAbi.t.sol` were inspected and match the names/results in the hash-bound `solidity/validation.log` (4 PASS), and `compiler-input-identities.json` binds all 8 actual source inputs by SHA-256 + Keccak-256 (SHA-256 side byte-verified via the checker; via-IR, optimizer 200, cancun, solc 0.8.25 confirmed).

## 3. Scoped source fidelity — model vs inspected optimized IR

Compared `LidoSRv3/Audit/Source/SszWitnessAbi.lean` line-by-line against `audit/ssz-witness-abi/solidity/inspected-harness-ir.yul` (solc 0.8.25, via-IR, runs 200, Cancun, selector `0x3bd227c1` case) and against the pinned `BLS.sol`/`CLValidatorVerifier.sol`/`SSZ.sol` sources at `17005714`.

**Exact matches confirmed:**

- `header`: value ≠ 0 reject; `slt(size−4, 128)` (IR `slt(add(calldatasize(), not(3)), 128)`); `offset = calldataload(4)`; `offset > 2^64−1` reject; `slt(size−offset−4, 256)`. UInt256 wrapping subtraction ≡ IR `add(…, not(3))`.
- `tail`: `relative = calldataload(h+f)`; guard `¬ slt(relative, size−h−35)` (IR `_9 = add(_6, not(34))`, the same reused `_9` for both tails); `base = h+relative` (wrapping); `length = calldataload(base+4) ≤ 2^64−1`; data at `base+36`; `sgt(addr, size − scale·length)` exact for scale 1 (IR `sub(calldatasize(), length)`) and scale 32 (IR `sub(calldatasize(), shl(5, length_1))`; `shl` wrap ≡ `UInt256.ofNat (32*length)`).
- **Signed negative offsets retained, no canonical/aligned/positive admission:** relative `2^256−128` is slt-negative, passes the guard and wraps `base` to `h−128`. Kernel theorem `negative_key_slice` executes `h=256 → slice (164, 48)`; the Forge test `test_wrappedNegativePubkeyOffsetStillExecutes` uses identical arithmetic (word 4 := 256, word 292 := `2^256−128`, length at 132, key at 164) and executes with real SHA. Both artifacts agree.
- **Order:** key-tail guards → `length == 48` (`.bls .invalidPubkeyLength`) → `mstore(32,0)` then `calldatacopy(0, addr, 48)` (`scratch`, source order preserved, inSize 64 = 48 key + 16 zero bytes) → `staticcall(gas, 0x02, 0, 64, 0, 32)` → `flag=0 ∨ returndatasize≠32 → .bls .sha256PrecompileFailed` (`finish`) → WC = `calldataload(36)` → field decode in the IR's exact order: effectiveBalance `h+68`, slashed `h+228` (0/1-only guard), eligibility `h+100`, activation `h+132`, exit `h+164`, withdrawable `h+196`, each with dirty-upper-bit uint64 rejection (`read_from_calldatat_uint64`) → **seven** `sha256Pair` calls in the exact (0,1)(2,3)(4,5)(6,7)→(l₁₀,l₁₁)(l₁₂,l₁₃)→(l₂₀,l₂₁) tree order → proof-tail decode (`h+4`, scale 32, same guards) → GIndex `shr(8, calldataload(100))` (`decodeIndex = >>> 8`) → proof loop → final `eq(leaf, calldataload(68))`. `verify` argument order (rawIndex, leaf, root, offset, count) checked against the IR — no swap.
- **Actual consumption:** no decoded field, key/proof length or leaf digest is a caller argument; `pubkeyRun`/`merkleRun`/`SszProofCalldataLoop.verify` receive decoder outputs and the threaded actual post-call states. `run_success_input_binding` binds fields/WC/root/GIndex/proof slice to the **original** `st` calldata while `verify` runs on `leaf.state` (the actual state returned by the real 8 SHA calls) with `leaf.digest` (the actual mload) — calls are not replaced by an unused payload.
- **Caller-environment invariant unconditional on resources:** `EVM.call` (`.lake/packages/evmyul/EvmYul/EVM/Semantics.lean:141-219`) returns `.ok (x, {evmState with accountMap, substate, createdAccounts, toMachineState})` — `executionEnv` is carried identically on *every* `.ok` path, including `x=0` (codeExecutionFailed / notEnoughFunds / depth-limit) and arbitrary Θ account/substate/createdAccounts results. `call_environment` is therefore a pure consequence of the `.ok` hypothesis with no gas/depth/memory/SHA-output premise. `prepared`/`preparePair`/`finish` touch only `toSharedState`, so the `pubkey/pair/merkle_environment` chains are sound. Read the bodies; confirmed.
- **Failure fixtures genuine:** `key_failure_before_dirty_fields` sets `depth = 1024` so `EVM.call` itself yields `z=false → x=0 → sha256PrecompileFailed` — real engine rejection, no fake SHA reply, as claimed. The Forge fault-order tests mock selected SHA replies via `vm.mockCall` (disclosed as synthetic); the accepted negative-offset test uses the real precompile.

**Disclosed omissions (verified absent from the model, and listed OPEN in README/receipt — correctly not closed):**

- Compiler dynamic-array allocation, free-memory-pointer/`0x41` panic blocks, memory spill layout, surrounding opcode gas (IR lines 71–79, 154–162, 181–189 have no model counterpart).
- Full raw-byte/typed-tree equivalence; derived calldata extents and initial reachable size/memory/depth/gas.
- Exact revert bytes, full World frame, compiled rollback; the complete slot/root/GIndex prefix and the actual `CLValidatorVerifier` entrypoint (the harness wrapper is explicitly *not* the full entrypoint).
- External trust: opaque FFI SHA (`ffi.sha256`; kernel cannot inspect the external binary) and authentic consensus/deployed configuration.
- **P-SSZ OPEN; all eight guarantees remain OPEN.** Nothing in this increment closes them.

## 4. Non-blocking observations

1. `header` evaluates the value check before the size/selector checks; the compiled dispatcher does selector first. Unobservable: every branch raises the same `Error.abi`, and success requires the same conjunction.
2. Cosmetic `linter.unusedSimpArgs` warnings in the test file (also present in the author's log).
3. `inherited-validation.json`: `fresh_inherited_execution = false` — the five earlier Forge tests/fuzz runs were reused by identity, not rerun; disclosed in the receipt.
4. Huge-calldata execution (calldata size ≥ 2^256) is explicitly not claimed; kernel examples use bounded layouts.

## 5. Defects

None found within the scoped claims. Guards, signed-offset arithmetic, evaluation/failure order, absolute static offsets (WC 36 / root 68 / GIndex 100), the 7-pair tree order, actual consumption through threaded states, and the unconditional environment invariant all check out against the pinned IR, the pinned Solidity at `17005714`, and the evmyul `EVM.call` body at the pinned package commit. Omitted IR allocations/spills/gas/full prefix remain OPEN as stated.

VERDICT: CLEAN
