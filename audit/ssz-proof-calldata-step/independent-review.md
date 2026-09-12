Starting with grok identity, then cloning the isolated PR head for a full read-only review.Existing clone is on a different commit. Fetching and checking out the exact PR279 draft head.17 files confirmed at the exact draft head. Reading the primary Lean sources and audit artifacts in full.Primary Lean and most audit artifacts are in. Next: Solidity dossier, identity hashes, pin 17005714, and accepted deps.Receipt SHA256 matches. Verifying identities against live files, then reading accepted deps and SSZ correspondence.Lake packages and `lido-core` are missing. Searching for existing pins and fetching only what's needed for identity checks.Pin 17005714 and EvmYul sources are missing from the checkout. Fetching those identities and inspecting CALL/Theta correspondence.Pin 17005714 hashes match. Reading SSZ/GIndex and checking EvmYul identities against the receipt.Continuing the read-only review: confirming grok/checkout, then finishing engine correspondence and the verdict.Checkout and grok identity confirmed. Finishing engine correspondence against the primary sources.Reading remaining critical source sections for engine vs opaque correspondence.Checking accepted SHA-call path, mutants, SSZ loop, and axiom/receipt details.Need remaining artifacts the continuation didn't fully load: mutants, axioms, WordBytes, checker, and Solidity tests.Checking receipt-head binding, the tautological depth example, checker, and remaining Solidity/identity details.Checker cloned lake packages; pins and 1111-source closure now match. Verifying remaining keccak identities and the tautological depth example.Independent read-only review is complete. Identities matched; receipts reused; no rebuild of Lean/Forge; no edits.

**Grok:** `/usr/local/bin/grok` → `grok 0.1.211 (2f2cd6d5c)`. Version **0.1.211** matches expected 4ed7c2ad; this build hash is **2f2cd6d5c**, not 4ed7c2ad. Workspace UUID `a582a491-be96-4ede-8d14-1fb7897f7622` is **not** a Grok git hash.

**Candidate:** isolated clone, detached `d5f2acbdd811b49ac16aa33be8d50ba5366d660a`, parent `3fbdd877d6fdf07edb93f41cb2d781f1dbe0fc9d`, **17 files**, dirty=0. Pin `17005714f151e5502c559932319a3f2f74ac2436`. Author receipt SHA256 **match** `901903ba70a6cd546b7ae72685f5da576aaaa59bf45b939b99f201f256828749`.

---

## Claim (held, at stated bounds)

Independent fixed-32 BE layout (`prefix ++ wordStream ++ suffix`) → derived cursor → **actual** `State.calldataload` → same-state ordered `mstore` / `calldataload` / `mstore(xor)` → reused PR278 `EVM.call` → `Θ` → `Ξ_SHA256` → opaque `ffi.sha256` → **flag-only** then `mload(0)` → one `SszProofFold.sourceFold` step at `UInt256` with **the same** `ffiPair`/`shaOutput` pair → next cursor/end/continue from `layout.size < 2^256` and raw `>>> 8` / width. No loaded-sibling, noWrap, accepted-digest, or root-match premise.

P-SSZ-1 remains **OPEN**.

---

## Source correspondence

| SSZ.sol / GIndex.sol @ 17005714 | Lean |
|---|---|
| `gI.index()` = `unwrap >> 8`; pack width uint248 | `decodeIndex`, `decode_nat`, `decode_width` |
| `scratch := shl(5, and(index,1))` **before** `shr(1)` | `scratchAddress` on **current** index; `parentIndex` after |
| `if iszero(index) revert BranchHasExtraItem` | `sourceStep` parent=0 → `.extraItem`; `sourceStep_extra` for `index.toNat ≤ 1` |
| `mstore(scratch, leaf); mstore(xor, calldataload(offset))` | `preparedStep`: first mstore, then `calldataload` on that state, then second mstore |
| `staticcall(gas(), 0x02, 0, 0x40, 0, 0x20)` | `callSha` = `EVM.call` with `t=r=2`, in 0/64, out 0/32, `permission=false`; `toExecute` → precompile 2; `Θ` `| 2 => Ξ_SHA256`; `ffi.SHA256` = opaque `sha256` |
| `if iszero(result) revert(0,0)` — **no** `returndatasize` | flag-only; `hout : shaOutput.size = 32` is a hypothesis |
| `leaf := mload(0); offset += 0x20; if iszero(lt(offset,end)) break` | `mload 0`; `next = offset+32`; `continues = decide (next < end)` |
| empty / missing / root checks | **not** in `sourceStep` (honest) |

`calldataload` is the engine def (`uInt256OfByteArray (calldata.readBytes v.toNat 32)`). Word bytes go through actual `UInt256.toByteArray` / FFI leading-zero pad, bridged to independent `fixedBE` (no private encoder name). `ByteArray.toList.loop` related to `data.toList`. `readBytes` unfolded including `copySlice` and large-offset list branch.

**Real engine transport:** `calldataload`, `mstore`/`M`, `readBytes`/`copySlice`, `EVM.call`, `Ccall`/`Ccallgas`/`Cgascap`, `Θ`, `Ξ_SHA256`, `mload`, `UInt256` shifts/and.

**Opaque / Nat / constructor / Bool (not engine):** `ffi.sha256` (`@[extern] opaque`) — no SHA-256 correctness; `ffiPair` is `Option` wrapping `ofNat ∘ fromByteArrayBigEndian ∘ shaOutput` (always `some`); `sourceFold` is a typed Nat list fold, not the Solidity `for` or `X`; `StepError` is a Lean tag, not revert selector/`revert(0x1c,4)`; `continues` is `decide`; `Θ` precompile arm sets `createdAccounts := ∅`. `ffi.ByteArray.zeroes` has a Lean body (`Array.replicate`) plus extern.

---

## Findings

**LOW — tautological depth “regression.”** [`SszProofCalldataStepMutants.lean`](/tmp/lido-review/repo/LidoSRv3/Tests/SszProofCalldataStepMutants.lean) L130–133 claims depth rejection through the source driver, then proves `errorTag (...) = some .hashFailure` by `change some StepError.hashFailure = some StepError.hashFailure; rfl`. It does **not** reduce `sourceStep` at depth 1024. Extra-item (`sourceStep_extra`) and cold `Ccallgas = 83` **are** real kernel examples. Does not touch `sourceStep_success`.

**INFO — receipt git HEAD vs PR head.** `checkout_head_at_validation` / `fresh-validation.json` `"head"` = **parent** `3fbdd877…`. The three Lean files **do not exist** at parent; they are new at `d5f2acbd…`. Content SHA256 of those files at HEAD equals receipt `after` hashes (`unchanged: true` is “already in the worktree when recorded”). Bind review to **file hashes at `d5f2acbd`**, not the recorded git HEAD field.

**INFO — isolated checker vs 1185.** Arithmetic is 43+6+1111+11+11+3 = **1185**. After lake clone: package pins 11/11, closure 1111/1111, selected core 11/11, keccak of four compiler inputs OK, pin SSZ/GIndex/BeaconTypes SHA256 OK. Isolated `lido-core` is an empty gitlink; `check_receipt.py` died on `git show 17005714:contracts/common/lib/SSZ.sol` there. Pin files were hashed from a separate fetch. Checker is identity-only (no Lean/Forge).

No `sorry` / `admit` / `native_decide` / `bv_decide` / `axiom` decls in the three new Lean files. 46 public theorems (incl. `@[simp]`), 34 examples + 1 fixture lemma, 10 axiom queries: ordinary `propext` / `Classical.choice` / `Quot.sound` (`decode_width` omits choice). Kernel examples normalize via `actual_word_bytes` / `calldata_read_fit` / `prepared_read` where opaque padding would block reduction.

---

## Receipt-reuse limits (no mass-rebuild)

**Reused (hashes match live HEAD / pins / toolchain):** author `receipt.json`; evidence set; 43 `validated_inputs`; 1111 package-source closure; 11 core sources at `leanprover--lean4---v4.31.0`; EvmYul `f7e4ee0d…`; Solidity compiler keccak + source SHA256; parent `audit/ssz-sha-call-memory/receipt.json` + `validation.log` (claimed SHA83 / fuel0/1 / mload-wrap **not** rerun).

**Not reused as a git-HEAD proof:** `checkout_head_at_validation = 3fbdd877`. **Not executed here:** lake lean 1.978s / 2.775s, 1128-job TestsBuilt 126s, Forge 4 tests / 1024 fuzz / 256 coupled cases (logs consistent with claims; identity-only confirmation). **Not a full-toolchain/binary closure.** Inherited PR278 SHA path is identity-reused, not freshly kernel-rerun.

---

## Honest OPEN (agreed)

Raw ABI layout supplied (not a proved decoder/caller). `index > 1`. Actual gas/depth/`fuel+2`/paid `Ccall` fee. Opaque FFI length 32; SSZ has no size guard. `activeWords < 2^251` (UInt256 `M` wrap). Error tags ≠ selector/revert ABI. No full loop, opcode/`X` gas, empty/root/missing outer checks, `standardSha` adapter, entry/membership, EIP-4788, provenance. No World frame (`Θ` resets `createdAccounts`). P-SSZ-1 **OPEN**.

Solidity dossier: unmodified `SSZ.verifyProof`, real SHA, real compiler proof.offset vs independent ABI formula, no mocks; two full source iterations vs Lean **one** step; finite 4-position two-level tree.

CONSOL / DEPOSIT / site426 / TOPUP: not touched.

VERDICT: CLEAN
