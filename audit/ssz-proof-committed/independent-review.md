# Independent exact-source review — PR299 (DRAFT)

- Repo: `lfglabs-dev/lido-srv3-proof-closure` PR #299 "Connect successful raw SSZ consumption to the independent Merkle branch"
- Head reviewed (exact): `d23f318af5720a74c9324699935cca1faab1cd76` (single commit on top of base)
- Base (integrated main, merge-base with origin/main): `8125d79f90029fd759eaea3a153d6e97aa328657` (confirmed `git merge-base d23f318… origin/main` = 8125d79f…)
- Pinned Solidity subject: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436` (git submodule `lido-core`, checked out and `rev-parse HEAD` = pin)
- Reviewer capability: read-only. No edits, commits, pushes, comments, merges performed. Predecessor Grok 23d88ee6 not resumed.
- Note: the predecessor's claimed packet paths (`/tmp/lido-ssz-proof-review-d23f318a-ee514/…`, `/var/lib/hermes-assistant/…`) do NOT exist in this workspace. All validation below was reconstructed independently from origin and pinned package repos; nothing was taken on trust from that packet.

## Scope of the diff (8125d79f..d23f318)

One commit, 17 files, +7029/−1: `LidoSRv3/Audit/Source/SszProofCommitted.lean` (310 lines, 10 theorems, 0 private helpers), `LidoSRv3/Tests/SszProofCommittedRegression.lean` (53 lines, 3 named kernel theorems + 5 kernel examples), `audit/ssz-proof-committed/*` (README, receipt, check script, logs, dependency-inputs, inherited-validation), and a one-field `audit/ux2/index.json` tree-hash regeneration (`835f2105…` → `9f5a2135…`).

## Main integration note (frozen inputs)

Current main tip `564d729f` (PR297) sits on top of the PR base and changes root `lakefile.lean` among receipt-frozen inputs. Verified: that change only extends `AccountAddressChecks` roots (`ReportWriteFee`), unrelated to the SSZ closure; the PR299 tree's `lakefile.lean` matches the receipt-frozen hash `856f7b02…`. No frozen receipt input was replaced; integration will still need a real merge (out of scope, not performed).

## What was PROVED (verified independently at the exact head)

Build: independent local build with elan Lean `v4.31.0` (toolchain matches `lean-toolchain`), mathlib cache from origin, in a detached copy of the exact head tree:
`lake build +LidoSRv3.Tests.SszProofCommittedRegression` → "Build completed successfully (1137 jobs)", exit 0. `SszProofCommitted` elaborated (4.9s) and the regression target built (2.8s). All 14 `#print axioms` outputs report only `[propext, Classical.choice, Quot.sound]` — matching `audit/ssz-proof-committed/axioms.log` exactly (14 query occurrences, 13 distinct declarations; `run_success_branch` queried twice).

Theorem chain (all in the new file, composing accepted PR296 results on the same state):
- `prepared_memory`/`prepared_read`: the two scratch stores put `pairInput index leaf (st.calldataload offset)` at scratch words 0–63 for arbitrary calldata and arbitrary (wrapping) uint256 offsets — the sibling is the actual `calldataload` result.
- `step_call_digest`: from the actual nonzero CALL flag (plus the explicit `ShaWidth` and `hwidth` premises) derives the mload-0 digest, `activeWords = max init 2`, and caller-environment preservation. Depth and precompile-gas admission are derived from the real flag, not supplied.
- `step_success_shape`/`step_success_effects`: invert the real source guard (`parentIndex = 0 → extraItem`), transport the one-item independent fold, derive offset `+32` (wrapping) and `continues = decide (offset+32 < ending)`.
- `proofWords`/`loop_success_fold`: the consumed-word list follows the actual unsigned cursor/continuation over `st.executionEnv.calldata`; successful iteration refines the existing independent `SszProofFold.sourceFold` over exactly those words.
- `verify_success_branch`: consumes the real final index (`=1`) and root checks; success ⇒ nonempty consumed list ∧ independent `Branch ffiPair (decodeIndex rawIndex).toNat leaf consumedWords root` ∧ env/extent preservation.
- `verify_success_depth`: `0 < length = (decodeIndex rawIndex).toNat.log2 ∧ length ≤ 247` via the existing `SszProofFold.verify_success_iff`/`verify_depth`.
- `run_success_branch`: the unchanged raw consumer `SszWitnessAbi.run` success ⇒ header/key-tail/FieldsMatch/proof-tail witnesses, `keySlice.length = 48`, `branch.length ≤ 2^64-1`, and the independent branch from the existing typed validator leaf (`validatorLeaf st keySlice.offset f`, same expression as PR296's computed leaf) to the original root word `calldataload(abiWord 68)`, over `proofWords branch.length st.executionEnv.calldata branch.offset (endOffset …)` — the words actually read. Environment and scratch extent of `afterState` derived.

## Exact-source correspondence vs pinned Solidity 17005714 (line-checked)

`lido-core/contracts/common/lib/SSZ.sol:179-249` (`verifyProof`) vs the Lean model:
- empty proof → `InvalidProof` ≡ `verify … count = 0 → .invalidProof` (kernel-checked example in the test file).
- `end := add(proof.offset, shl(5, proof.length))` (wrapping) ≡ `endOffset offset count = offset + (ofNat count <<< ofNat 5)`.
- `scratch := shl(5, and(index,1))`; `mstore(scratch, leaf)`; `mstore(xor(scratch,0x20), calldataload(offset))` ≡ `scratchAddress`/`preparedStep` (kernel-checked `scratch_even`/`scratch_odd`, xor facts).
- staticcall(0x02, 0, 0x40, 0, 0x20), success checks the CALL flag only, no returndatasize check ≡ `sourceStep` checks only `flag ≠ 0`; the missing size guard is exactly why `ShaWidth` is an explicit premise (SSZ cannot inherit BLS's returndata-size guard — confirmed `BLS.sol` has the separate check; not imported into SSZ).
- `leaf := mload(0x00)`; `offset := add(offset, 0x20)`; continue iff `lt(offset, end)` (unsigned) ≡ model's `offset + 32`, `decide (next < endOffset)`.
- final `index == 1` else `BranchHasMissingItem`, `leaf == root` else `InvalidProof` ≡ `finish`.
- `GIndex.index() = unwrap >> 8` (`GIndex.sol:39-41`) ≡ `decodeIndex raw = raw >>> 8`.

Raw bytes / producer→consumer payload: the consumer reads `st.executionEnv.calldata` directly with the pinned engine's zero-padded decoder; `rawWord raw off = uInt256OfByteArray (raw.readBytes off.toNat 32)` is definitionally `EvmYul.State.calldataload` (used via `simpa only […, rawWord, EvmYul.State.calldataload]` in `loop_success_fold`). The proof tail is decoded by `SszWitnessAbi.tail` on the post-BLS state whose `executionEnv = st.executionEnv` (PR296 `hle`), so producer and consumer see the exact same raw input bytes — no re-encoded copy, no caller-supplied word list. `header` enforces `weiValue = 0` and the calldata-size guards; `tail` enforces relative-pointer, `length ≤ 2^64-1`, and signed span bounds (`offset + 32·length` within size) — the declared span is in-bounds; the consumed list is a wrap-sensitive prefix of that span.

## ASSUMPTIONS vs PROVED (as declared; verified present in source, none hidden)

Assumed / OPEN (explicit premises or declared required work):
- `hwidth : st.activeWords.toNat < 2^251` on the INITIAL state — INTERNAL required work (initial memory-width obligation retained; not closed, not renamed away).
- `ShaWidth` — external FFI output-width specification. Supported only by source inspection of pinned `EvmYul/FFI/ffi.c` (lines 8, 15–21: 32-byte output allocated/pushed) and the opaque `ffi.lean` declaration; no C refinement, no native execution. SHA implementation/cryptographic correctness remain external trust.
- Consumed list ≠ ABI-declared list under wrap: equality must still be derived for the actual admitted/reachable entry — OPEN. Kernel regressions (`wrapped_early_stop`: 4 rounds consume 1 word; `wrapped_two_words`: cursor wraps to offset 0) prove the distinction exists; they are primitive cursor fixtures, NOT ABI-admission or compiled-Solidity counterexamples (verified: model wrap semantics match Yul `add`/`lt` word arithmetic by hand evaluation of both fixtures).
- Complete raw entry/slot/proposer/root/GIndex prefix, EIP-4788 lookup, compiler allocations/free-pointer/spills, surrounding opcode gas, exact error ABI, whole-World rollback — all remain internal OPEN. No whole-World conservation claimed by the new theorems (only executionEnv and activeWords).
- No fresh Forge or native C execution claimed; inherited Solidity/compiler evidence reused by exact hash identity only.
- All eight complete guarantees remain OPEN; P-SSZ stays OPEN.

Proved (this increment, kernel-checked at the exact head): the ten source theorems and three named regressions/five examples listed above; axiom footprint limited to `propext, Classical.choice, Quot.sound` on every queried declaration.

## Receipt and guard validation (independent, exact head)

- `python3 audit/ssz-proof-committed/check_receipt.py` (with real lake/lean prefix): **1296 checks, 0 errors** — 31 validated inputs + 11 evidence hashes + 116 inherited identity checks + 1120 dependency-closure files + 11 package pins + 7 Lean core sources.
- The 16 `.lake/packages/evmyul/*` receipt/inherited hashes were additionally verified against an independent clone of `lfglabs-dev/EVMYulLean` at pinned `f7e4ee0dc8f8d5265ce822a937ab5be771f182e9` — all match, including `EvmYul/FFI/ffi.c` (`0ca09954…`).
- The three pinned Solidity files (`SSZ.sol`, `BLS.sol`, `CLValidatorVerifier.sol`) hash-match the receipt at the submodule pin.
- `scripts/check_proof_escapes.py`: pass — "534 project Lean files; no sorry/admit/axiom/constant/unsafe/Lean.ofReduceBool; native_decide inventory 3310d7fb…", identical to the recorded log.
- `scripts/generate_ux2.py check`: pass — "11 guarantee records match the registry and the Lean declarations"; `audit/ux2/index.json` hash matches receipt (`3ba4a790…`); `scripts/verified_source_tree.sh` prints `9f5a2135…` matching the index's regenerated `lean_source_tree`.
- Writer logs internally consistent: source build 1136 jobs / test build 1137 jobs; `validation.log` ≡ `test-active-validation.log` (same hash, as recorded); three failed-attempt logs are error-containing diagnostics only (3/12/4 error lines), given no proof credit in the receipt.
- Remote builder note: `remote-lean-build` dispatch of the exact head failed for infra reasons (runner `old-agent` disk floor: 251 GiB available < 12 GiB + 250 GiB floor); the local elan build above supersedes it and succeeded.

## Conclusion

The central claim — successful raw `SszWitnessAbi.run` ⇒ an independent Merkle branch from the existing typed validator leaf to the original root over the calldata words the unchanged verifier actually consumes (wrap-sensitive unsigned cursor, zero-padded reads, flag-only CALL success) — is proved at the exact head `d23f318af5720a74c9324699935cca1faab1cd76` against pinned `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`, with an independently reproduced build, ordinary axioms only, and a 1296/1296 receipt. The declared assumptions (`hwidth` initial width, external `ShaWidth`/SHA trust, consumed≠declared equality, entry/compiler/World correspondence) are explicit in the source and README and remain OPEN as stated. No discrepancy between claimed and proved content was found.

VERDICT: CLEAN
