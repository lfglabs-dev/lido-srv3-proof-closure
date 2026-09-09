# Independent READ-ONLY review: stacked PR280 a9 + PR282 c3

**Reviewer tooling:** Grok CLI **0.1.211** (`2f2cd6d5c`) at `/usr/local/bin/grok`.  
**Workspace UUID `a582` (`/workspaces/mission-a5b20c8c`) is not a git hash.**  
**Isolated clone:** `/tmp/lido-pr282-isolated` HEAD `c3cd5450af78a73daed221082b6d368fa9d18e90`.  
**Packet:** `/tmp/lido-ssz-review-280-282-c3cd5450/ssz280-282-review-packet/` (54 source snapshots + 3 meta files).  
**Predecessor `ee65607d`:** cancelled after a verified ~85 minute resume loop (~60 repeats of Step/Fold rereads and giant 1113-entry JSON dumps). That evidence is preserved. This review did **not** dump `dependency-inputs.json` / lean-json bodies; only counts and hashes.

No merge, edit, push, or public comments. No DEPOSIT/CONSOL/site. No FFI-crypto, full-entry, X-gas, or World claims accepted.

---

## Identity

| Object | Value | Check |
|---|---|---|
| PR282 DRAFT head | `c3cd5450af78a73daed221082b6d368fa9d18e90` | clone HEAD exact |
| PR282 branch (observed) | `codex/local-lido-ssz-typed-ffi-20260909` | verify by commit, not name |
| PR280 exact | `a9f097c81db661dbd413dae298c7162ede248572` | `cat-file` commit; **ancestor of c3: YES** |
| 280 source base in receipts | `28a1187169182494be04601a660a66d628694249` | 280 receipt `checkout_head_at_validation` |
| Core pin | `17005714f151e5502c559932319a3f2f74ac2436` | receipts + packet |
| Engine pin | `f7e4ee0dc8f8d5265ce822a937ab5be771f182e9` | `.lake/packages/evmyul` (user `f7e4` prefix) |
| Lean | `leanprover/lean4:v4.31.0` | `lean-toolchain` sha `efac0b94…` |

**280 unchanged inside 282 (full tree, not last-commit-only):**

`git diff --name-status a9f097c8 c3cd5450` is **11 added files only**:

- `LidoSRv3/Audit/Source/SszTypedFfiBridge.lean` (138)
- `LidoSRv3/Tests/SszTypedFfiBridgeMutants.lean` (24)
- `audit/ssz-typed-ffi-bridge/*` (9 audit artifacts)

Log `a9..c3`: one commit, `c3cd5450 Connect typed SSZ digests and verifier to the actual FFI word loop`.

`28a11871..a9`: 17 added files (280 Lean/tests + `audit/ssz-proof-calldata-loop/*`). `a9` itself is “Retain SSZ loop validation and axiom logs” on top of `b27f19da` (the 280 proof). 280 **source modules** are therefore the 28a bodies; a9 only retained logs.

Packet Lean SHA256 matches isolated-clone Lean for all primary modules listed below.

---

## Receipt identity (hash, then reuse; no mass-rebuild)

| Lot | Claimed SHA256 | Observed | Match |
|---|---|---|---|
| 280 `audit/ssz-proof-calldata-loop/receipt.json` | `e56cb8cd216786f75047b12a0e81fb0ffcbe52e86fe675745949d0d4e8f55204` | same | YES (iso==packet) |
| 282 `audit/ssz-typed-ffi-bridge/receipt.json` | `7e3c377fc422dfcefe76c2c55732b4ae21946e9903a3fcef68c0a22d52ca07dc` | same | YES (iso==packet) |

Reconstructed `check_receipt.py` check counts (keys only; **not** a re-hash of 1113/1115 file bodies in this session):

| | vi | evidence | package_source_closure | selected_core | package_pins | pinned_sol | **total** | claimed |
|---|---|---|---|---|---|---|---|---|
| 280 | 50 | 6 | 1113 | 12 | 11 | 3 | **1195** | 1195 |
| 282 | 56 | 6 | 1115 | 16 | 11 | 3 | **1207** | 1207 |

Lean stats from receipts (match claimed):

| | public thm | kernel examples | axiom queries | fresh direct | lake jobs | Forge |
|---|---|---|---|---|---|---|
| 280 | 27 (9 Resources + 18 Loop) | 29 | 10 | 3 `lake env lean` | 1130 | 5 tests, 1×1024 fuzz, 256 heap leaves, max depth 247 |
| 282 | 12 | 8 | 6 | 2 `lake env lean` | 1132 | **no new Forge**; 280 Solidity receipt reused by identity |

`check_receipt.py` (280 and 282 **byte-identical**): “Recorded file/package-pin comparison only; no fresh proof or EVM execution.”

`fresh-validation.json` `unchanged: true` with before/after hashes equal. `validation.log` 280/282 match claimed job graphs and deprecation replays. **Whole dependency-binary / toolchain-binary certification is outside the claim.**

282 `validated_inputs` includes `audit/ssz-proof-calldata-loop/receipt.json` = `e56cb8cd…` (280 receipt reused by identity).

**279 `SszWordBytes.lean`:** sha256 `edf978676f3b42922ff121da12887e5552a9ddc2a9bb6d37c287c44132b01c23`, 183 lines, **identical in 280 and 282 `validated_inputs`**. Byte identity holds → 279 encoder theorems reusable as identity, not re-proved here.

Pinned Solidity (packet == 280/282 solidity receipt):

- `SSZ.sol` `91ef497b…`
- `GIndex.sol` `2653bd4b…`
- `BeaconTypes.sol` `9591e9af…`
- harness `SszProofCalldataStep.t.sol` 110 lines `766b504b…`
- loop tests `SszProofCalldataLoop.t.sol` 103 lines `fa850c73…`

Manifest machine-extract (packet `dependency-summary.json`, **not** an independent review): lean_json 1115 / lake 1113, lake packages 5 named in summary vs 11 `package_pins` in receipts (summary lists EvmYul/Mathlib/Cli/aesop/batteries; receipts also pin verity/plausible/LeanSearchClient/importGraph/proofwidgets/Qq). Counts only; no 1113 dump.

---

## Source coverage (complete modules / relevant defs)

Read once from packet or clone. No endless Step/Fold resume.

| Module | Lines | Role |
|---|---|---|
| `SszProofLoopResources.lean` | 217 | CALL/precompile resource lemmas |
| `SszProofCalldataLoop.lean` | 291 | loop, budget, `verify_success_iff` |
| `SszTypedFfiBridge.lean` | 138 | 282-new typed↔word transport |
| `SszWordBytes.lean` | 183 | accepted 279 actual BE codec |
| `SszProofCalldataLoopMutants.lean` | 76 | 29 kernel + 10 axiom prints |
| `SszTypedFfiBridgeMutants.lean` | 24 | 8 kernel + 6 axiom prints |
| `SszProofCalldataStep.t.sol` | 110 | reused harness |
| `SszProofCalldataLoop.t.sol` | 103 | 280 Forge suite |
| `SszProofCalldataStep.lean` | 490 | `sourceStep`, `ffiPair`, layout |
| `SszProofFold.lean` | 394 | independent `Branch`, typed `sourceVerify` |
| `SszShaCallMemory.lean` | 226 | `shaOutput`=`ffi.sha256`, `callSha`, `theta_sha` |
| `SszShaCallBytes.lean` | 91 | 32-byte memory helpers |
| `EvmYul/EVM/Gas.lean` | (packet) | `Caccess`/`Cextra`/`Cgascap`/`Ccallgas`/`Ccall` |
| `EvmYul/EVM/GasConstants.lean` | 47 | Fee schedule: `Gwarmaccess=100`, `Gcoldaccountaccess=2600` |
| `SszVerifierEntry` foldHash | relevant defs | CALL-success-only hash |

**GasConstants supplement (transport only; candidate/receipts unchanged):** packet `sources/evmyul/EvmYul/EVM/GasConstants.lean` sha256 `906cda79711e73ca637184256f6b53f5f444918ced2952ead4296797c2503fa8` (47 lines, 1422 bytes) MATCH claimed engine `f7e4ee0d…` source. Same SHA already in **280 and 282** `package_source_closure` as `.lake/packages/evmyul/EvmYul/EVM/GasConstants.lean`. Original 54-file archive immutable; `supplement-gasconstants.json` records this. `Gas.lean` imports `GasConstants`. Cold/warm numbers are now **source-visible** (`Gcoldaccountaccess := 2600`, `Gwarmaccess := 100`) and still **kernel-decided** in 280 mutants (`Caccess` 2600/100). `Gcallvalue := 9000`, `Gcallstipend := 2300`, `Gmemory := 3` etc. are in the same file; **280/282 still charge CALL/precompile only** and do not prove surrounding opcode/memory/control gas. This supplement does **not** close OPEN item 5.

Empty gitlink for `lido-core` / evmyul in the git tree: packet supplies pinned Solidity and selected EvmYul including GasConstants; lake pin `f7e4ee0d`. Limitation noted; sources used were complete snapshots.

---

# VERDICT 280 — exact `a9f097c81db661dbd413dae298c7162ede248572`

**Bounded-lot status:** claims in the 280 README/receipt are **source-supported inside the stated CALL-only interpreter domain**.  
**Campaign status:** does **not** close P-SSZ-1. Remaining boundaries stay OPEN.  
**This lot is not CLEAN.**

### Claims vs code

1. **`verify_success_iff` = nonempty proof ∧ independent `Branch` over the same opaque FFI UInt256 hash**  
   Confirmed in `SszProofCalldataLoop.lean`. Success iff `proof ≠ []` and `SszProofFold.Branch ffiPair (decodeIndex rawIndex).toNat leaf proof root`. Fold’s `Branch` is a separate inductive (root/left/right) with no CALL/loop state. `ffiPair` is `some (UInt256.ofNat (fromByteArrayBigEndian (shaOutput (fixedBE 32 left ++ fixedBE 32 right))))` — same opaque FFI as `shaOutput := ffi.sha256`. Empty proof is `invalidProof` before index/depth (`verify_empty` / mutants).

2. **Resources: cold/warm `Ccall`; INITIAL budget `2684*n+1`; CALL/precompile charges only**  
   - `Caccess` = `Gwarmaccess` if already accessed else `Gcoldaccountaccess` (`Gas.lean` 126–129).  
   - Zero-value: `Cextra = Caccess` (`extra_eq`); `Ccall = Cgascap + Cextra`.  
   - Kernel mutants: `Caccess` cold 2600 / warm 100; `Ccall` fee cold@2685 = 2684, warm@185 = 184; EIP-150 cap 83 vs 84 at 2684/2685 (cold) and 184/185 (warm).  
   - `call_admitted`: `2685 ≤ gas` ⇒ SHA cap ≥ 84 and `Ccall ≤ gas`.  
   - `call_resource` / `step_resources`: successful SHA costs `Caccess+84` hence **≤ 2684**; env preserved; **not** whole-opcode gas.  
   - `budget (rounds) := 2684 * rounds + 1`; mutants: `budget 0=1`, `1=2685`, `2=5369`, `247=662949`, `248>662949`.  
   - `decoded_branch_budget`: `Branch` ⇒ `proof.length ≤ 247` ∧ `budget ≤ 662949` (via `branch_interval` + decode width).  
   INITIAL `2684*n+1` is a **conservative always-cold** bound; per-iteration admission threshold is 2685 (`step_complete` / `step_resources`). Honest and numerically consistent.

3. **Loop follows actual `sourceStep` continuation/offset**  
   `sourceStep` sets `continues := decide (next < endOffset)` after CALL-success-only (no returndata-size guard — matches `source-check.json` `ssz_has_no_return_size_guard: true` and Fold header). Interpreter fuel is distinct from CALL/Theta `fuel+2` (mutant: `loop 0 … = engineFailure`).

4. **Axioms:** all 10 queried 280 theorems depend on `[propext, Classical.choice, Quot.sound]`. Standard Lean, not a hidden SHA axiom.

5. **Solidity:** 5 tests / 1024 fuzz / 256 positions / max 247 recorded in `solidity/receipt.json` exit 0. **Reused by identity this session, not re-run.** Independent complete-heap reference in the test; “not universal EVM/FFI, opcode gas, cryptography or consensus provenance.”

### 280 findings (do not close)

| Sev | ID | Location | Note |
|---|---|---|---|
| HIGH (campaign) | F1 | `audit/guarantees.yaml` P-SSZ-1 `next_gate` | Lot does not implement `SSZ.verifyProof` on production gindices, SHA correctness, or imported-to-deployed Yul. YAML already lists those **missing**. |
| MED | F2 | Resources / Loop comments; budget | CALL-only bound is **not** Solidity transaction gas. Surrounding memory/arithmetic/control opcodes uncharged. Easy to over-read. |
| MED | F3 | `ffiPair` / `shaOutput` | Opaque FFI. No SHA-256 standard proof (`A-SHA256-FFI`). |
| MED | F4 | Loop `verify` hypotheses | Raw ABI layout, decoded count, `size<2^256`, depth&lt;1024, `activeWords<2^251`, FFI length 32 remain **supplied**, not derived from a decoder/X. |
| LOW | F5 | `call_observations` | Caller `executionEnv` preserved; **not** a World/account/rollback theorem. |
| LOW | F6 | error tags vs selectors | Lean tags model order; revert ABI/selector encoding is a Solidity-test observation (`0x09bde339` etc.), not a Lean ABI theorem. |
| INFO | F7 | Classical.choice on all 280 theorems | Recorded in `axioms.log` / validation.log. |
| INFO | F8 | 280 receipt head `28a11871` vs git `a9f097c8` | a9 only retained logs; source hashes in `fresh-validation.json` unchanged. |

---

# VERDICT 282 — exact `c3cd5450af78a73daed221082b6d368fa9d18e90`

**Bounded-lot status:** typed digest ↔ actual word codec and bidirectional Branch transport are **source-supported**. Primitive helper success iff typed `sourceVerify` with `foldHash (standardSha ffiSha)`.  
**Campaign status:** still does **not** close P-SSZ-1. No new Forge. Remaining boundaries stay OPEN.  
**This lot is not CLEAN.**

282 sits on **byte-identical** 280 sources (tree delta = 11 new files). Receipt `checkout_head_at_validation` is `a9f097c8` (parent 280).

### Claims vs code

1. **`typedDigest` encoder → actual UInt256 codec**  
   `digest_bytes`: `bytes (digestBytes d) = fixedBE 32 d.toNat`.  
   `digest_actual_word`: `bytes (digestBytes (toDigest w)) = w.toByteArray` via 279 `actual_word_bytes`.  
   `toWord`/`toDigest` inverses (`digest_word` / `word_digest` `rfl`).  
   Mutants: byte 31 vs byte 0 of `1` and `2^248`; `2^255` ≠ reversed-significance `128`; full `2^256-1` word preserved.

2. **Same opaque FFI pair and bidirectional Branch**  
   `ffiSha` instantiates typed `Sha` with `shaOutput (bytes xs)` then `fromByteArrayBigEndian`. **Not** an independent SHA.  
   `pair_transport`: `ffiPair (toWord left) (toWord right) = some (toWord (pair ffiSha left right))`.  
   `branch_transport` / `branch_map` / `pair_transport_back`: `Branch ffiPair` ↔ `Branch (fun a b => some (pair ffiSha a b))`.

3. **Independently serialized typed proof → primitive success iff typed `sourceVerify`**  
   `proof_bytes`: `wordStream (proof.map toWord) = bytes (proof.flatMap digestBytes)`.  
   `primitive_typed_success`: ∃ afterState, Loop `verify … (toWord leaf) (toWord root) … = .ok afterState` iff  
   `SszProofFold.sourceVerify (SszVerifierEntry.foldHash (standardSha ffiSha)) (typedIndex rawIndex) leaf proof root = .ok ()`  
   under the **same explicit** layout/size/depth/budget/FFI32/width hypotheses as 280. Uses `verify_success_iff`, `branch_transport`, Fold `verify_success_iff`, `fold_hash_standard`.  
   Mutant: `typedIndex` strips GIndex metadata (`1430*2^40*256+255` → `1430*2^40`).

4. **No new Forge.** 282 `solidity.fresh_runs: 0`. Prior 5 tests/1024 fuzz retained by identity; they do **not** validate the Lean type conversion.

5. **Axioms:** `digest_actual_word` and `primitive_typed_success` add `Classical.choice`; others `propext, Quot.sound`.

### 282 findings (do not close)

| Sev | ID | Location | Note |
|---|---|---|---|
| HIGH (campaign) | F1 | P-SSZ-1 | Transport of the **final verifier only**. Raw pubkey/leaf-pair calls, slot check, EIP-4788 lookup, full entry adapter remain open (282 remaining_boundaries[4]). |
| MED | F3 | `ffiSha` | Still opaque FFI. No independent SHA cryptography. |
| MED | F4 | `primitive_typed_success` hyps | ABI/count/gas/depth/memory/FFI32 remain explicit. Compiled X / opcode gas open. |
| LOW | F5 | World/revert/provenance | Explicitly out of scope (remaining_boundaries[5]). |
| INFO | F9 | 282 receipt head `a9f097c8` vs git `c3cd5450` | Expected: receipt taken on parent; c3 **is** the 282 commit. Source hashes in 282 `fresh-validation.json` match packet/c3 Lean. |

---

## The 8 OPEN items (keep OPEN; do not force CLEAN)

These are **not** discharged by 280 or 282. Lot `remaining_boundaries` (verbatim):

**280 (6):**
1. Raw ABI layout, size<2^256 and decoded count supplied; actual ABI extraction/reachability open
2. Initial CALL-only budget 2684*n+1, depth<1024 and activeWords<2^251 explicit; no surrounding opcode memory/control gas or X/compiled-bytecode proof
3. Opaque actual FFI length32 for every pair explicit; no SSZ program size guard, SHA correctness or standardSha/typed entry adapter refinement
4. Final success state exists and caller environment is preserved; no full World/account frame or transaction rollback theorem
5. Error tags model guard order but omit selector-memory/revert ABI; per-loop rounds and CALL/Theta fuel are distinct
6. Canonical entry/membership, EIP4788 root anchoring, credentials/fork/deployed provenance and registered parent remain open

**282 (5):**
1. Raw ABI layout/count and initial calldata/memory/depth domains remain supplied
2. CALL-only initial budget; surrounding opcodegas and compiledX execution open
3. Actual opaque FFI32 output condition remains; no independent SHA implementation/cryptography proof
4. Final verifier only: raw pubkey/leaf pair calls, slot check, EIP4788 root lookup and fullentry adapter open
5. No fullWorld frame, revert ABI, rollback, consensus provenance or deployed configuration closure

Campaign set (still OPEN; do not force CLEAN):

1. **P-SSZ-1 parent** — `SSZ.verifyProof` on production gindices; YAML `next_gate` still OPEN. Encoding-row CHECKED (`deposit_root_iff`) is a different theorem.
2. **SHA-256 cryptography** — `A-SHA256-FFI`; opaque `ffi.sha256` / `shaOutput`.
3. **Imported-to-deployed Yul binding** — `A-YUL-INTERFACE`; `special_bindings.deployed_yul.status: OPEN`.
4. **Raw ABI extraction / decoder / compiled X opcode execution.**
5. **Surrounding opcode / memory / control gas** — CALL-only budget ≠ tx gas. `GasConstants.lean` body now read (47 lines, SHA `906cda79…` already in 280/282 1113/1115 closures). Source-visible `Gwarmaccess=100` / `Gcoldaccountaccess=2600` match mutants. File presence does **not** prove opcode/memory/control/X gas.
6. **Full World / account frame / transaction rollback / revert ABI.**
7. **Raw complete leaf / pubkey helper / slot check / EIP-4788 oracle entry.**
8. **Consensus membership, credentials/fork, deployed provenance, SSZ returndata-size guard** (source has none; model does not invent one).

P-SSZ remains **OPEN**.

---

## Exactly reused vs independent vs unavailable

**Independent this review**

- `which grok` / `grok --version` → 0.1.211.
- Isolated HEAD vs exact c3; `merge-base --is-ancestor` a9⊂c3; full-tree name-status a9..c3 (11 files) and 28a..a9 (17 files).
- Receipt SHA256 vs claimed 280/282; reconstructed 1195/1207 from **counts**; evidence file SHA vs `evidence_hashes`.
- One-shot read of primary Lean, relevant Fold/Step/ShaCall/Gas defs, both test modules, both harnesses, both READMEs, remaining_boundaries, YAML P-SSZ-1 missing/next_gate.
- Packet vs clone SHA of primary Lean; packet Solidity vs solidity receipt hashes.
- Semantic check of `verify_success_iff`, budget, `Ccall`/`Caccess` against mutants and Gas.lean (not a rebuild).
- Complete `GasConstants.lean` (47 lines) SHA `906cda79…` vs claimed engine source and vs 280/282 `package_source_closure` (counts-only lookup of that one path).

**Reused by identity (not re-executed)**

- `validation.log` lake graphs (3+1130 / 2+1132).
- Forge 5 tests / 1024 fuzz / 256 / 247 (280 solidity receipt; 282 `fresh_runs: 0`).
- 279 `SszWordBytes` theorems (`edf97867…` identical).
- 280 lot theorems inside 282 (`e56cb8cd…` receipt nested in 282 `validated_inputs`).
- `package_source_closure` 1113/1115 **counts** from JSON length; files not individually rehashed here.
- `check_receipt.py` not re-run (would need `lake env lean --print-prefix` and lido-core gitlink).

**Unavailable / outside claim**

- Fresh Lean kernel rebuild; full dependency binary cert.
- Independent SHA-256 proof; World/X/ABI/entry/provenance proofs.
- Surrounding opcode/memory/control/X gas (GasConstants body now read; schedule constants do not close that gap).
- Packet is an access aid, **not** independent acceptance (packet README).

---

## Process

- No 1113/1115 manifest dumps.
- No “Cached unchanged is not a body” resume cycle.
- If a needed source body had been missing → INCOMPLETE. Bodies were present in packet + clone.

---

## Separate lot verdicts (summary)

| Lot | Exact commit | Bounded claims | P-SSZ / 8 OPEN | Integration |
|---|---|---|---|---|
| **280** | `a9f097c8` | Supported in CALL-only FFI interpreter domain | Remain OPEN | Receipt itself: independent review required before integration |
| **282** | `c3cd5450` | Supported as representation/verifier transport on unchanged 280 | Remain OPEN | Depends on 280; no new Forge; independent review required |

Overall mission verdict cannot be CLEAN: P-SSZ OPEN, all 8 OPEN, lots do not authorize campaign closure or SHA/World/X/entry claims.

VERDICT: BLOCKED
