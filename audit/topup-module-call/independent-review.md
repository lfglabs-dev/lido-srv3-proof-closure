Starting the independent PR283 review: recording grok identity, then checking out the exact DRAFT head in an isolated clone.Recorded grok 0.1.211 (2f2cd6d5c) at `/usr/local/bin/grok`. Next: isolated clone at exact PR283 head; no source edits.HEAD matches claimed SHA; parent is `28a1187169182494`. Next: inventory PR files, receipt SHA, and machine-parse audit JSON.Checkout matches claimed head/base and receipt SHA. Reading primary sources and locating Live.CallData / encoder defs.Primary files match claimed line counts and receipt SHA. Next: machine-parse the 1256-entry JSON and identity-check Live/ABI/continuation defs.lido-core is an uninitialized submodule; lake packages aren't present. Fetching the pin and locating a matching lake cache.Closure JSON is 1256 entries and hashes match a lake cache — still need Git-HEAD identity, lido-core pin, and actual encoder defs.lido-core pin and lake pins match. Next: identity-check encoder/invoke defs, Git-HEAD closure, and 64 vectors.Encoder/invoke defs match the claimed Live path. Next: Git-HEAD identity of the 1256-entry closure, 64 vectors vs generated Sol, parent-file identity, and targeted reuse checks.Resuming PR283 READ-ONLY review at the leftover Git-HEAD, vector, and theorem-body checks. No edits.HEAD and grok identity match. Continuing Git-HEAD closure, vector reconstruction, and theorem-body assessment.Primary files are cached; running machine-verify scripts and extracting theorem bodies independently.Bodies exist (9 theorems, no `sorry`). Next: local-file Git identity, independent 64-vector reconstruction, and parent/olean reuse.Local Git-HEAD identity is 63/63; claimed `local_lido_count` is 64. Reconstructing vectors and checking that discrepancy, parent identity, and OPEN list.Reconstructing the encoder independently and checking the remaining identity/OPEN items.Reconstructing the encoder independently and finishing parent, OPEN-count, packet, and reuse checks.Confirming kernel reuse path, selector keccak, `getModuleState`, and receipt replay.Selector keccak was not independently recomputed (local keccak failed the empty-hash sanity check). `check_receipt.py` replayed 1378 identity checks with 0 errors. Completing the scoped verdict.**Reviewer:** grok 0.1.211 (`2f2cd6d5c`) at `/usr/local/bin/grok`  
**Mode:** READ-ONLY independent review of PR283 DRAFT. Not a5b20c8c. Workspace UUID `a582` is not a git hash. No merge/edit/push/comments. No DEPOSIT/CONSOL/SSZ source edits.

## Identity

| Item | Actual |
|---|---|
| Isolated HEAD | `af331323faf4d8a1e74314506343bc91ae6499fe` |
| Parent / claimed base | `28a1187169182494be04601a660a66d628694249` |
| PR | [lfglabs-dev/lido-srv3-proof-closure#283](https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/283) DRAFT OPEN, 25 files, +9439/−0 |
| Receipt SHA | `abbf056d150b0b70e41e1388e5f2bc3b69c8fa7a2c5b2469ee9c7b1fe80cdf47` (Git HEAD blob) |
| Core pin | `17005714f151e5502c559932319a3f2f74ac2436` |
| Host packet | **absent** at claimed path; Git used for all artifacts |

`check_receipt.py` replay: **1378 checks, 0 errors**. Tracked tree clean at exact HEAD.

## What was machine-checked (no mass rebuild)

- **1256-entry** `dependency-inputs.json`: 1193 lake package files = Git HEAD of each pinned package; **63** local Lean files = Git HEAD of this clone. `json≠wt=0`, `git_head_diff=0`.
- **64/64** `vectors.json` independently reconstructed from `allocateCalldata` + `TopupBeaconEffects.serialize` + `Export.lean` `vector(seed)`; byte-identical to Git HEAD JSON **and** `ModuleVectors.sol`.
- **93/93** `validated_inputs` and **6/6** `evidence_hashes` = disk = Git HEAD (lido-core vs pin).
- **62/62** parent Lean files identical to base `28a11871`.
- **7/7** selected Lean core sources match toolchain `leanprover/lean4:v4.31.0`.
- Lake pins, lakefile, manifest, toolchain identical to reuse cache.
- Primary sizes: [TopupModuleCall.lean](/tmp/lido-pr283-isolated/LidoSRv3/Audit/Source/TopupModuleCall.lean) **224** lines, **9** theorems; [TopupModuleCallMutants.lean](/tmp/lido-pr283-isolated/LidoSRv3/Tests/TopupModuleCallMutants.lean) **111** lines, **29** `example` + **1** `positive_execution` + **7** `#print axioms`. **No `sorry`. No `axiom` decls.** Bodies present → not INCOMPLETE.

Receipt field `local_lido_count: 64` vs **63** local JSON paths (1256 = 1193 + 63). Off-by-one in the receipt, not in the closure bytes. `checkout_head_at_validation` is the **parent**, not PR HEAD; file hashes at HEAD still match.

## Claim (assessed, not widened)

Physical packed module address → five-arg `allocateCalldata` bytes → `Live.CallData.invoke` with **value 0** → raw return decoder → decoded words **and interpreter `after` World** into accepted continuation.

That path is what the defs do:

- `moduleAddress` = `Address.ofNat` of the ERC-7201 config word (`ofNat` is `% 2^160`). `address_packed` proves the packed split when `address < 2^160`.
- `payload` = `TopupBeaconEffects.serialize (allocateCalldata (typedCall i))`. Selector word `0x783b8a65`, value 0. `typedCall` leaves WC/type/returndata empty; those fields are unused by the encoder.
- `CallData.invoke` is the actual 5-arg Live CALL (early `codeSize`, funds, provisional transfer, arbitrary `External`).
- `decodeReturn` is a **logical** ABI word-array reader (offset/`count` uint64 guards + extent).
- `program` feeds `.ok allocations` and the **callee-returned** World into `TopupRouterContinuation.program`.
- Origin theorems derive request/reply/decode from success; `External` stays a parameter.

This is **not** compiler equivalence and **not** pre-module conservation.

## Theorems (9, all have bodies)

| Theorem | What it actually proves |
|---|---|
| `address_packed` | Packed config → low 160 bits under the stated split |
| `call_success_origin` | Success ⇒ `codeSize ≠ 0` and actual `.success` / `.successWithTrace` on transferred World |
| `encodeWords_length` / `readWords_encoded` | Word-list codec |
| `decodeReturn_encoded` | Canonical `offset=32` encoding + arbitrary tail, `length < 2^64` |
| `program_of_call` | Bind of call into decode/continuation |
| `program_encoded` | Canonical bytes ⇒ continuation on **that** `after` World |
| `program_success_origin` | Any program success ⇒ raw reply + decode + same allocations/World/attempts into continuation |
| `failure_restores` | `execute = Live.run`; error restores `before` |

Recorded kernel axioms (not re-kernelled here): `propext` / `Classical.choice` / `Quot.sound` only.

## Tests

29 kernel examples cover packed address, selector prefix `783b8a65`, empty/short/`2^64` offset, `count≥2^64` → `Panic(0x41)`, **`count=2^59` → `.empty` (not Panic 41)**, short payload, canonical + trailing byte, **non-canonical offset 0 and 33**, zero-target module effects surviving, malformed rollback, exact bubble `dead`, budget fail rollback, no-code **no attempt**.

`positive_execution` reuses `TopupRouterContinuationMutants.positiveFacts` on the **interpreter-returned** 275 world, not on the pre-module world. Arbitrary callee remains explicit.

Forge (recorded, not re-run): 8 tests, 1024-fuzz, 64 Lean vectors vs compiler calldata/return. Harness is callsite + raw callee, **not** full `StakingRouter.topUp`. IR has `panic_error_0x41` and **no `extcodesize`**. Solidity `2^59` fixture is Panic 41; Lean is `.empty`. Both retained.

## Boundaries — all OPEN (assessed, not hidden)

1. **Parent ABI/auth/registration/rounded-target** — starts at `StakingRouter.sol:717` after preamble. Inputs are typed, not a proved topUp ABI decode. **OPEN.**
2. **Arbitrary callee** — no module impl, no callback restriction, no pre-module conservation, no aggregate history. Zero-target fixture **changes** router balance on purpose. **OPEN.**
3. **Payload** — reused accepted word encoder + **64 finite** byte checks. Not a universal compiler encoder theorem. Selector agreed by recorded compiler differential, not a keccak proof in this review. **OPEN.**
4. **Logical decoder vs compiler alloc/gas** — `2^59` short return: compiler Panic 41 vs Lean `.empty`. **Both retained.** `count≥2^64` Panic 41 matches the separate guard. **OPEN.**
5. **No-code traces** — Live early `codeSize` ⇒ no attempt; modern typed CALL attempts then decoder-fails. Outcome-only failure agrees; origin derives positive-code on success. **OPEN.**
6. **`Live.run` rollback** — existing model rule, not an EVM/X/revert-ABI theorem. **OPEN.**
7. **Beacon address, hash correctness, runtime provenance, aggregate history** — **OPEN.**
8. **Complete TOPUP / P-TOPUP** — **OPEN.** Do not treat this increment as closing them.

Receipt lists 7 `remaining_boundaries` (last is a bundle); README says “all eight unfinished guarantees remain OPEN.” Substance: **all eight OPEN.** Site PR426 not in scope.

## Severities

| Sev | Item |
|---|---|
| Critical | None found in this increment’s stated transport claim |
| High | None in-scope. **P-TOPUP remains OPEN** (program-level, not this PR’s theorem hole) |
| Medium | All 8 unfinished guarantees OPEN; no compiler equivalence; no pre-module conservation; no callback/history; finite 64 ≠ universal encoder; decoder/gas split retained; Live vs compiler no-code traces; `Live.run` ≠ EVM rollback; beacon/runtime provenance OPEN |
| Low | `local_lido_count` 64 vs 63 local JSON entries; receipt `checkout_head_at_validation` is parent not HEAD; remaining_boundaries 7 vs README “eight”; host packet missing |

**Not claimed:** compiler equivalence, pre-module conservation, universal ABI encoder, EVM rollback, keccak/SHA, beacon identity, runtime provenance, full TOPUP.

This increment’s bodies exist and match a **scoped** transport claim. Remaining program obligations stay OPEN. DRAFT; integration still requires those OPENs, not this review, to close.

VERDICT: CLEAN
