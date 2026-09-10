# Independent Exact-Source Review — lfglabs-dev/lido-srv3-proof-closure PR #293 (DRAFT)

- **Head (frozen):** `3e54bc475c83c0d5591d54a0aba88723d0efa00c` (`Derive committed SHA effects in raw witness consumer`, single commit, branch `codex/local-lido-ssz-sha-committed-20260910`)
- **Parent / integration base:** `a455cc1ab0f75f7ebd6e11dddee18c7e87a1dd0f` (`Merge PR #289`), verified ancestor of head
- **Solidity pin:** `17005714f151e5502c559932319a3f2f74ac2436` (lidofinance/core; `lido-core` gitlink unchanged between parent and head)
- **Mode:** read-only, writer STOPPED, sole reviewer; no repository/PR mutation (PR head fetched to `FETCH_HEAD` only; all execution in a private copy under `/tmp/pr293-build`)
- **Date:** 2026-09-10
- **Relation to prior work:** new obligation for #293. The #289 review (`3521761b`) is consumed as accepted inherited evidence only, not re-reviewed.

## 1. Source access and identity

| Check | Result |
|---|---|
| Packet `/tmp/lido-ssz-committed-review-3e54bc47/ssz-sha-committed-review-packet/` | 1204 files listed in `manifest.json`; **1204/1204 SHA-256 recomputed and matched**, 0 missing, 0 extra on disk (only `manifest.json` itself is unlisted) |
| Manifest header | `head=3e54bc47…`, `base=a455cc1a…`, `source_pin=17005714…`, `writer=STOPPED` |
| Packet vs git tree at head | all **90** non-package, non-toolchain, non-`lido-core` packet files byte-identical to `git show 3e54bc47:<path>` (0 mismatches, 0 missing) |
| Head diff vs parent | 13 files, **+6730/−0, all additions**: `SszShaCommitted.lean`, `SszShaCommittedMutants.lean`, 11 files under `audit/ssz-sha-committed/`. No existing source, guarantee, lakefile, manifest, toolchain or Solidity file touched |
| Pinned Solidity | 6 `lido-core/contracts` files in packet fetched independently from `raw.githubusercontent.com/lidofinance/core/17005714…`; **6/6 SHA-256 identical** (`CLValidatorVerifier.sol d6e89f69…`, `BLS.sol 0187cc6a…`, `SSZ.sol 91ef497b…`, `ValidatorWitness.sol`, `BeaconTypes.sol`, `GIndex.sol`) |
| Package pins (11) | `.lake/packages/*` in the copy resolve to exactly the receipt pins (verity `e977aaad…`, evmyul `f7e4ee0d…`, mathlib `fabf563a…`, …); `git status` clean in all 11 |
| Import closure (independently recomputed from `import` lines) | 17 local `LidoSRv3.Audit.Source.*` modules + the test module; matches `local_import_count = 17`; the three `Ssz*` files present in git but absent from the packet (`SszStatePlacement`, `SszVerifierProgram`, `SszPerfectTree`) are **not** in the closure |

## 2. Executed verification (this container)

1. **`python3 audit/ssz-sha-committed/check_receipt.py`** (in the head copy, real `lake env lean --print-prefix` from `leanprover/lean4:v4.31.0`) → exit 0, **`{"checks": 1258, "errors": []}`**. Composition independently recounted: 27 validated inputs + 8 evidence hashes + 87 inherited identities + 1118 closure entries (17 local + 1101 package) + 11 pins + 7 selected core sources = 1258. This confirms the packet's package/toolchain bodies are the pinned git/toolchain bodies, not just self-consistent copies.
2. **Independent targeted build reproduced:** `lake build +LidoSRv3.Tests.SszShaCommittedMutants` with the local v4.31.0 toolchain on the cached parent build → exit 0, **`Build completed successfully (1135 jobs)`**. Exactly two modules were actively elaborated (`Built LidoSRv3.Audit.Source.SszShaCommitted (11s)`, `Built LidoSRv3.Tests.SszShaCommittedMutants (4.1s)`); everything else replayed. Axiom output for all 13 queries is byte-for-byte the packet `axioms.log`: only `[propext, Classical.choice, Quot.sound]`.
3. **Count cross-checks:** 13 `theorem` declarations in the source file = 10 public + 3 `private` (`theta_underfunded`, `finish_success`, `bind_success`); test file = 1 named theorem (`successful_guard_keeps_wrap`) + 7 `example`s; 13 `#print axioms` occurrences / 11 distinct declarations (`merkle_success_digest` and `run_success_computed_merkle` queried twice). All match README/receipt.
4. **Hidden-premise scan:** no `sorry`, `admit`, `axiom`, `native_decide`, `bv_decide`, `opaque`, `unsafe`, `implemented_by`, `extern`, `set_option`, or `variable` in the two new files. Every theorem quantifies only over `fuel`, states, words and an explicit `.ok` hypothesis plus, where stated, `hwidth`. The only opaque in the closure is the pre-existing engine FFI `ffi.sha256` (`EvmYul/FFI/ffi.lean`), which is never evaluated by any proof.
5. **Diagnostic logs:** the three retained failed logs are genuine earlier failures (`SszTypedFfiBridge.chunk` unknown identifier + heartbeat timeout at line 298; `rfl` failure at test line 56; `decide`/type-mismatch failures at test lines 19–45), each corrected in the final sources. They carry no evidentiary weight and are not claimed to.
6. **Not executed:** Forge/solc are not installed here (`which forge solc` → none). The #284 (5 tests, 1024 fuzz, 24 faults) and #289 (4 tests) Solidity evidence is reused by hash identity only, exactly as the receipt states (`fresh_solidity_execution=false`). No full `lake build` of the default target was run by the author or by me; the new module is a leaf that nothing imports, and no existing file changed, so the targeted build is the relevant check.

## 3. Semantic audit of the increment against the pinned engine and Solidity

Read in full: `SszShaCommitted.lean` (347 lines), `SszShaCommittedMutants.lean` (64), README, receipt, `SszWitnessAbi.lean`, `SszBlsComposition.lean`, `SszShaCallMemory.lean`, `SszShaCallBytes.lean`, `SszProofCalldataLoop.lean`, `SszProofLoopResources.lean`, `SszScratchEvmMemory.lean`, `SszTypedFfiBridge.lean`, the relevant parts of `SszProofCalldataStep`/`SszWordBytes`/`SszScratchByteArray`, evmyul `EVM.call` (`Semantics.lean:141–219`), `Θ` (`:717–815`), `Ξ_SHA256` (`PrecompiledContracts.lean:56–76`), `Ccallgas/Cgascap/Ccall/Cextra/Caccess` (`Gas.lean`), `MachineState.M/lookupMemory/mload/mstore` (`MachineStateOps.lean`), `calldatacopy`, `calldataload`, `readWithPadding`, `toExecute`/`π`, `ffi.lean`, the pinned `BLS.sol:516–561`, `CLValidatorVerifier.sol:60–85`, `SSZ.sol:179–254`, and the inherited optimized IR (`inspected-harness-ir.yul`, 329 lines).

**Depth inversion — `call_success_depth`.** `EVM.call` only enters `Θ` when `value ≤ balance ∧ depth < 1024`; otherwise it returns `(…, false, .empty)` and `x := 0` because `codeExecutionFailed = !z`. With `value = 0` the balance test is trivially true, so a nonzero flag forces `depth < 1024`. The proof covers every `depth ≥ 1024`, not only `== 1024`. Sound.

**Gas inversion — `call_success_gas` / `theta_underfunded`.** `callgas := Ccallgas t r value gas σ μ A` is computed from the pre-subtraction machine state, exactly as the theorem states with `st.toMachineState`. `Ξ_SHA256` charges `60 + 12·⌈64/32⌉ = 84` and returns `(false, ∅, 0, A, .empty)` below it; `Θ` then yields `z = false`, so `x = 0`. `gas_fits` (inherited) excludes `UInt256` wrap of `ofNat callgas`. Hence nonzero flag ⇒ `84 ≤ Ccallgas …`. No gas premise is supplied by any consumer in this file. Sound.

**Output — `call_success_output`.** With depth and gas derived, `theta_sha` gives `Θ = .ok (∅, accounts, gas−84, substate, true, shaOutput input)` and `EVM.call` sets `returnData := o` unconditionally (`n = min outSize o.size` handles any FFI length). Only the 64-byte input size is required, and that is discharged by `prepared_read` (two actual `mstore`s) or `read_exact` (actual `mstore(32,0)`+`calldatacopy`). Sound.

**Flag vs size guard — `finish_success` / `pair_success_output`.** `SszBlsComposition.finish` (unchanged, hash `dae0997c…`) rejects `flag = 0 ∨ returnData.size ≠ 32`, mirroring `iszero(and(success, eq(returndatasize(), 0x20)))` in `BLS.sol` and IR lines 106/318. Success therefore *derives* `(shaOutput block).size = 32`; no `hout`/`hffi` premise remains in the pair theorems. The SSZ loop (`sourceStep`) checks the flag only, and this increment correctly does **not** transfer the size fact into `SszProofCalldataLoop.verify`; `verify` enters the final theorem purely as the consumer's own `.ok` hypothesis. Correct boundary.

**mload and activeWords — `call_words`, `pair_success_words`, `pubkey_success_words`, `pair_success_digest`.** `EVM.call` sets `activeWords := ofNat (M (M s 0 64) 0 32)` from the pre-call extent on *both* branches (Θ and non-Θ), with arbitrary callee outputs; `M s 0 64 = max s 2`, `M (max s 2) 0 32 = max s 2`. `preparePair`/`scratch` give `max s 2` before the call; `mload` afterwards gives `M · 0 32 = max · 1`, so the post-`finish` extent is `max s 2`, proved without any width bound. The digest theorem needs `mload32`, whose `lookupMemory` guard `addr ≥ activeWords * ⟨32⟩` wraps at `2^251`; this is the one retained `hwidth` premise, and it is threaded so that only the *initial* state's bound is assumed (`b0…b5` derived from `w0…w5`). Sound.

**Seven-call chain — `merkle_success_digest`.** `merkleRun` (unchanged) threads one state through `(a,b),(c,d),(e,f),(g,h),(l10,l11),(l12,l13),(l20,l21)`; the rewrite chain `d6,d4,d5,d0,d1,d2,d3` closes `merkleDigest` by `rfl`. This is the order in `CLValidatorVerifier.sol:_validatorHashTreeRoot` and in the IR (`fun_sha256Pair` calls at lines 164–197). Sound.

**Actual consumer substitution — `run_success_computed_merkle`.** The hypothesis is `SszWitnessAbi.run fuel st = .ok afterState` on the unchanged #289 consumer. Via `run_success_input_binding` the proof obtains the real `verify` call *as executed by `run`*: `verify fuel leaf.state (st.calldataload 100) leaf.digest (st.calldataload 68) branch.offset branch.length = .ok afterState`, on `leaf.state` (the state returned by the eighth real SHA call) with the same `afterState`. It then rewrites only `leaf.digest` with the derived equality `leaf.digest = merkleDigest key.digest (calldataload 36) (chunk …)…`. The conclusion is therefore the actual verifier on the actual returned state receiving the independently computed digest, not an unused payload. Original-calldata binding of fields (`FieldsMatch st offset f`), credentials (`calldataload 36`), root (`68`), raw GIndex (`100`), signed key/proof slices (`tail`) and `keySlice.length = 48`, `branch.length ≤ 2^64−1` are inherited unchanged. `key.digest` is left as the actual key-call result; its byte-level identity is *not* claimed (correctly listed OPEN). Confirmed.

**Signed offsets / original calldata / IR.** `header`/`tail` (unchanged) match IR lines 60–87 and 199–207 (`slt(add(calldatasize(), not(3)),128)`, `_9 = add(_6, not(34))`, `gt(length, 2^64−1)`, `sgt(addr, sub(calldatasize(), shl(5,length)))`), with negative relative pointers accepted as in the compiler. Nothing in #293 alters or re-admits these.

**No premise laundering.** `Result`, `finish`, `preparePair`, `pairRun`, `pubkeyRun`, `merkleRun`, `run`, `verify` are byte-identical to their accepted #284/#289 versions (hashes in `inherited-validation.json` re-verified). No new definition wraps an assumption; the only free hypotheses in the file are `.ok` facts and `hwidth`. `private` helpers are pure case analyses on `Except`.

**Θ created-accounts reset.** `Θ` returns `createdAccounts = ∅` for precompiles and `EVM.call` stores it, so a successful SHA call resets `createdAccounts`; `theta_sha` also existentially hides the resulting account map/substate. No theorem here claims a World frame; README discloses this. Consistent.

**Synthetic fixture.** `successful_guard_keeps_wrap` and the two `2^251±` examples construct `memoryCase` with `activeWords = 2^251`/`2^251−1`, a 32-byte `returnData` and no SHA execution; they show the BLS guard passes while `mload` reads 0 at the wrap. This is a demonstration that the retained `hwidth` cannot be recovered from guard inversion, not reachable Solidity or actual SHA evidence, and the file and README say so. The `tooDeep`/`lowGas`/`length 47` examples are real engine rejections (`EVM.call` else-branch; `Ξ_SHA256` with forwarded gas 83 < 84; length check before depth). Consistent.

## 4. Inspected vs executed scope (honest accounting)

- **Executed:** 1204 packet hashes; 90 packet-vs-git byte comparisons; 6 upstream Solidity fetches; 11 pin/clean checks; `check_receipt.py` (1258 comparisons); targeted Lean build with axiom output; import-closure recomputation; grep-based premise scan.
- **Inspected only:** semantic correspondence of the Lean model to `EVM.call`/`Θ`/`Ξ_SHA256` and to the pinned Solidity/IR (Section 3); the retained failed logs; the inherited #284/#289 Forge logs.
- **Not done:** Forge re-execution (tool absent); full default-target rebuild; kernel audit of the toolchain beyond the 7 selected core sources; any evaluation of the external `sha256` binary.

## 5. Non-blocking observations

1. `SszShaCommittedMutants.lean` contains fixture/regression examples but no mutant-killing checks of the new theorems; the name overstates the file's role. No evidentiary claim depends on it beyond what README states.
2. In the recorded test build, `SszShaCommitted` was replayed from the source build (receipt `source_reuse`); my run elaborated it afresh (11s) and agrees.
3. `#print axioms` is not queried for the three private helpers; they are covered transitively by the public queries.
4. `call_success_output` requires the 64-byte input fact as a premise; both consumers discharge it from actual scratch writes, so no consumer-level assumption remains. Stated correctly in the docstring.

## 6. OPEN items (unchanged by this increment)

- **Required internal work (not external trust):** derivation of the initial `activeWords < 2^251` bound from real entry initialization and all preceding compiled transitions; independent raw-public-key byte digest; complete raw-byte/typed-tree equivalence and proof-fold success correspondence; slot/proposer/root/GIndex prefix and actual EIP-4788 root lookup; compiler allocations/free-pointer panics/spills (IR lines 70–79, 153–162, 180–189 have no model counterpart); surrounding opcode gas; exact error bytes; compiled World/rollback (Θ created-accounts reset prevents a full World frame).
- **External trust:** SHA implementation correctness/cryptography (opaque FFI), authentic consensus/deployed configuration; no new deployment verification.
- **All eight guarantees remain OPEN.** P-SSZ is not closed. ALLOC-1, ALLOC-2, RESERVE-1 and public identifiers are untouched (no file outside the 13 additions changed). This review carries no integration, site or full-guarantee authority.

## 7. Defects

None found within the scoped claims of this increment. Depth/gas/output inversion from actual `EVM.call`+`Θ`+`Ξ_SHA256` behaviour, guard-derived output size, exact extent propagation through all eight real calls, the seven-pair tree order, and the substitution of the independent digest into the actual verifier on the actual returned state all check out against the pinned engine, the pinned Solidity at `17005714`, and the inherited IR. The single retained premise is exactly the disclosed initial memory-extent bound.

VERDICT: CLEAN
