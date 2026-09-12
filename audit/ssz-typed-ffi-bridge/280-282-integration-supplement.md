# Supplement: bounded-lot integration vs campaign (280 a9 / 282 c3)

**This file does not replace** [`/workspaces/mission-a5b20c8c/output/280-282-independent-review.md`](/workspaces/mission-a5b20c8c/output/280-282-independent-review.md). Preserve that original, including GasConstants fold, remaining_boundaries quotes, separate 280/282 lot verdicts, and campaign `VERDICT: BLOCKED`.

**Tooling:** Grok CLI **0.1.211** (`2f2cd6d5c`). Workspace UUID `a582` is not a git hash. Isolated clone HEAD still `c3cd5450af78a73daed221082b6d368fa9d18e90`. Predecessor `ee65607d` 85-minute loop not continued. No 1113/1115 dumps. No git/gh mutations. No DEPOSIT/CONSOL/site. PR283 is queued after this review; this supplement is documentary, not a merge.

Receipts unchanged: 280 `e56cb8cd…` / 282 `7e3c377f…`. GasConstants SHA `906cda79…` already in both closures. Candidate and receipts are the same objects as the original report.

---

## 1. Factual correction: 28a is not the 280 Lean commit

Original report line 35 said: “280 **source modules** are therefore the 28a bodies; a9 only retained logs.”

That sentence is **wrong**. Confirmed on the isolated clone (git cat-file / sha256):

| Path | 28a `28a1187169182494be04601a660a66d628694249` | b27 `b27f19da9c3f85d6df08bc1060c8271d1e9d814a` | a9 `a9f097c81db661dbd413dae298c7162ede248572` | c3 |
|---|---|---|---|---|
| `SszProofLoopResources.lean` | **ABSENT** | `064e7bca…` 217 lines | **identical** `064e7bca…` | identical |
| `SszProofCalldataLoop.lean` | **ABSENT** | `ebc58764…` 291 lines | **identical** `ebc58764…` | identical |
| `SszProofCalldataLoopMutants.lean` | **ABSENT** | `67d9e112…` 76 lines | **identical** `67d9e112…` | identical |
| `SszWordBytes.lean` (279) | `edf97867…` present | identical | identical | identical |
| `SszProofCalldataStep.lean` | `8c8404c7…` present | identical | identical | identical |
| 280 `receipt.json` | ABSENT | `e56cb8cd…` | identical | identical |
| 280 `fresh-validation.json` | ABSENT | `818d4649…` | identical | identical |
| 280 `validation.log` / `axioms.log` | ABSENT | ABSENT | added at a9 | identical |

Lineage:

- `28a11871` = Merge PR279 (validation **parent**). Receipt `checkout_head_at_validation` and `fresh-validation.json` `head` record this WIP parent. The three new 280 Lean files **do not exist** in that tree.
- `b27f19da` = “Prove SSZ primitive calldata loop with initial CALL resource bound”. `28a..b27` adds the three Lean files + 280 audit (14 paths). This is the 280 **source** commit.
- `a9f097c8` = “Retain SSZ loop validation and axiom logs”. `b27..a9` adds **only** `validation.log`, `axioms.log`, `solidity/validation.log`. Log-only successor.
- `fresh-validation.json` `unchanged: true`; before/after SHA of the three Lean files equal `064e7bca…` / `ebc58764…` / `67d9e112…` — the same blobs as b27 and a9.

INFO F8 in the original report (receipt head 28a vs git a9) remains a **labeling** note, not a source-mismatch. Do not treat “28a bodies” as the 280 Lean identity. 280 Lean identity is **b27 = a9 = c3** for those three files.

---

## 2. “Eight OPEN” = eight campaign guarantees, not eight SSZ findings

The campaign set that must stay OPEN (do not force CLEAN, do not hunt eight hidden SSZ bugs):

1. **DEPOSIT1**
2. **TOPUP1**
3. **TOPUP2**
4. **ACCOUNT1**
5. **ADDRESS1**
6. **CONSOL1**
7. **CONSOLETH1**
8. **SSZ1** (P-SSZ / P-SSZ-1)

280/282 are SSZ-lot work under **SSZ1**. They do not close DEPOSIT/TOPUP/ACCOUNT/ADDRESS/CONSOL. They also do not close SSZ1.

Keep the **actual SSZ residual work** regardless of how the eight are counted. That residual is the lot `remaining_boundaries` plus the SSZ-facing campaign holes already in the original report:

- SHA-256 cryptography (`A-SHA256-FFI`; opaque `ffi.sha256` / `shaOutput`)
- Imported-to-deployed Yul (`A-YUL-INTERFACE`)
- Raw ABI extraction / decoder / compiled X
- Surrounding opcode / memory / control gas (GasConstants body does **not** close this)
- Full World / account frame / rollback / revert ABI
- Raw leaf / pubkey helper / slot check / EIP-4788 oracle entry
- Consensus membership, credentials/fork, deployed provenance
- FFI32 as an **explicit model-trust / domain condition** (not a missing patch)

**Returndata-size guard:** `source-check.json` `ssz_has_no_return_size_guard: true` matches the Solidity helper and the Lean model. **Absence is not a request to add a guard.** Do not invent an implementation finding that the source should grow a returndata-size check. FFI32 remains a supplied hypothesis on both sides of `verify_success_iff` / `primitive_typed_success`.

Original-report campaign item 8 mixed “SSZ returndata-size guard” into the guarantee list. Correct reading: no guard in source; that is a domain fact, not a to-do.

---

## 3. Within-domain integration verdict (README / receipt only)

User authorizes **reviewed incremental proof merges** with all eight campaign guarantees still OPEN. No campaign closure. Root will seek an independent documentary integration gate. PR283 is queued; this review does not merge.

Exact claimed domains (lot README + receipt `remaining_boundaries`):

**280** (`audit/ssz-proof-calldata-loop/README.md`): `verify_success_iff` = nonempty proof ∧ independent `Branch` over the **same** opaque FFI-backed word hash; `loop` follows actual `sourceStep` continuation/offset; CALL/precompile charges only; conservative initial budget `2684*n+1`; cold admission 2685; not compiled X; ABI count supplied; FFI32 explicit; no SHA crypto; no World/rollback; error tags ≠ revert ABI. Independent review required; SSZ-1 remains open.

**282** (`audit/ssz-typed-ffi-bridge/README.md`): typed `digestBytes` ↔ actual UInt256 codec; same opaque FFI pair; bidirectional Branch; independently serialized typed proof → primitive helper success iff typed `sourceVerify (foldHash (standardSha ffiSha))` under the same explicit layout/gas/FFI32 hyps; final verifier only; no new Forge; depends on 280; SSZ-1 not closed.

### Defects inside those domains requiring correction before bounded-lot integration?

**None found.**

Inside the claimed interpreter / codec / transport domains, this review did not find an implementation bug, a theorem that contradicts its README statement, a receipt-hash mismatch, a 280-under-282 source mutation, or an evidence counter that fails reconstruction:

- 280 Lean at b27/a9/c3 is byte-identical; a9..c3 is 11 added 282 files only.
- Receipt SHA256 match claimed; reconstructed 1195 / 1207 check counts match.
- `verify_success_iff`, budget arithmetic, cold/warm `Caccess`/`Ccall`, empty-proof `invalidProof` priority, and CALL-only comments match mutants and Gas/GasConstants numbers.
- 282 `digest_bytes` / `digest_actual_word` / `branch_transport` / `primitive_typed_success` match the typed-bridge README; 279 encoder `edf97867…` identical.
- Axioms are exactly the disclosed `{propext, Classical.choice, Quot.sound}` set (280: choice on all 10 queried thms; 282: choice on `digest_actual_word` and `primitive_typed_success` only).
- `check_receipt.py` is pin comparison only — as the README says.
- Receipt head `28a` vs source commit `b27` is a validation-parent label, not a body mismatch: before/after hashes bind b27/a9 source.

The original report’s F1–F7 / 282 F1–F5 are **campaign or explicit remaining_boundaries**, not within-domain defects to fix before an incremental merge of these lots.

INFO F8 is a reviewer/receipt-head labeling note; corrected above. It does not require a source or proof change.

### What this does *not* say

- It does **not** relabel the campaign CLEAN.
- It does **not** close SSZ1 / P-SSZ-1 or DEPOSIT1…CONSOLETH1.
- It does **not** authorize SHA crypto, World, X/ABI gas, full entry, or provenance claims.
- It does **not** merge. Root’s documentary gate and queued PR283 are outside this session.

---

## 4. Separate lot status (unchanged substance)

| Lot | Exact commit | Within README/receipt domain | Campaign (8 guarantees) |
|---|---|---|---|
| **280** | `a9f097c8` (source at `b27f19da`; a9 log-only) | Bounded CALL-only FFI-loop claims **source-supported**; **no within-domain defect** requiring correction | OPEN |
| **282** | `c3cd5450` on unchanged 280 | Typed↔word transport **source-supported**; **no within-domain defect** requiring correction | OPEN |

---

## 5. Verdict lines

**Within-domain (280/282 README/receipt):** no implementation/proof/evidence defect requiring correction before bounded-lot integration.

**Campaign:** all eight guarantees remain OPEN (DEPOSIT1, TOPUP1, TOPUP2, ACCOUNT1, ADDRESS1, CONSOL1, CONSOLETH1, SSZ1). P-SSZ remains OPEN. Do not force CLEAN.

VERDICT: BLOCKED
