# PR278 TOPUP witness-batch increment — independent review

**Reviewer identity:** `/usr/local/bin/grok` → `grok 0.1.211 (2f2cd6d5c)`. Expected `0.1.211` on `a582`; **git hash is not `a582`**. Version matches; recorded as a caveat, not an abort. Isolated clone; no CONSOL/DEPOSIT/site426 touch; no merge/push/comment/edit.

**Tree identity**

| Pin | Observed |
|---|---|
| HEAD | `b0d10887313075ee3c19e0d6fe0b07eee10598c8` |
| Parent | `23728167b21c2b0768c9d59cabd4c1dfb55eb6c1` (treated CLEAN; not re-opened) |
| Subject | `Derive gateway witness limits and keys for router arithmetic` |
| Core | `17005714f151e5502c559932319a3f2f74ac2436` |
| Receipt SHA256 | `c28186b02c89d0f3831b08114e3d8824b0f95375bbbaf194e3c21918b3859eae` **MATCH** |

Increment vs parent is exactly the three Lean files + `audit/topup-gateway-witness-batch/**`. Receipt reused (no mass-rebuild). Claimed `16 thm / 40 kernel tests / 11 ordinary axioms / 1285 jobs / testBuilt 11s` matches `receipt.json` and `validation.log` (`Built LidoSRv3.Tests.TopupGatewayWitnessBatchMutants (11s)`). Source hashes match receipt/`source-check.json`. No `sorry`/`admit`/`native_decide`/`axiom` in the three new Lean files. Axiom queries are only `propext` / `Classical.choice` / `Quot.sound`.

P-TOPUP-1 remains **OPEN**.

---

## Claimed scope (accepted as the review boundary)

Canonical same registry / header / common WC → actual typed `sourceEntry` → same keys/limits → arithmetic-only 275 router bridge. Honest zero-divisor, pending overflow, admission. Prefix separate from temporal WC.

**Not claimed:** full module / funding / EVM / aggregate cap; supplied accepted Boolean / limits / root-match; noReentry / frame.

---

## Correspondence (real source, not digest)

### Length prefix — [`TopupGatewayWitnessBatch.lean:34-40`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean)

Maps `TopUpGateway.sol:163-175`: empty indices; four sibling lengths vs count; `count > maxValidatorsPerTopUp`. Success iff `n ≠ 0 ∧ four equalities ∧ n ≤ max` ([`checkLengths_iff:42-50`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean)). Solidity `>` vs Lean `>` then `≤` on success is exact.

`checkLengths` and `loop` are **not** composed as one entry. Role/pause precede the prefix; `_requireBlockDistancePassed` / `_verifyRootAge` / locator WC / type-0x02 sit between prefix and loop (`sol:178-191`). That separation is real, not a hidden collapse.

### Row guards — [`rowLimit:86-97`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) vs `sol:208-226`

| Source | Lean |
|---|---|
| `pubkey.length != 48` | `wrongPubkeyLength` |
| `i != 0 && index <= prev` | `ordered` (`none` ⇒ first index unrestricted, including 0) |
| `_verifyValidatorWasActivated` | `activated` |
| `_verifyValidator` | `sourceEntry` (typed parent consumer) |
| `_evaluateTopUpLimit * 1 gwei` | `evaluate` then `* gwei % 2^256` in `loop` |

Order matches. Failures: pubkey → sort → activation → proof → pending overflow. Mutants and Foundry `test_guardPriorityAndVerifiedFields` agree (proof error before Panic(0x11)).

### Activation / zero divisor — [`activated:73-76`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) vs `sol:390-393`

Constructor stores `SLOTS_PER_EPOCH` with **no** nonzero check (`sol:64-74`). Lean `slotsPerEpoch.val = 0 → divisionByZero`. Epoch is `uint64(_slot / SLOTS_PER_EPOCH)`; Lean `(slot / divisor) % 2^64`. [`epoch_cast_exact:78-81`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) shows the mod is identity because `slot < 2^64`. Comparison is `>` as in source. Honest, not assumed-nonzero.

### Evaluate / overflow — [`fields:52-56`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) + parent `TopupWeiBounds.evaluate` vs `sol:396-414`

Uses `effectiveBalance`, `pending`, `exitEpoch`, `slashed` only — source does not consult `withdrawableEpoch`. Function-call addition is **checked** (unchecked loop does not apply inside `_evaluateTopUpLimit`). Exit/slash returns 0 **before** add, so overflowing pending on excluded rows does not panic. [`PendingSafe:65-67`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) is the honest domain for non-excluded rows; not smuggled as a always-true bound.

`headroom` ([`:60-63`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean)) is an independent Nat spec. [`evaluate_headroom:127-138`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) relates it to `evaluate` **under** `PendingSafe`. That is correspondence, not opaque Nat-as-source.

### Loop accumulator — [`loop:107-116`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) vs `sol:203-228`

`wei := n * gwei % 2^256`; `acc := (acc + wei) % 2^256`; pubkeys/limits keep input order. Unchecked `* 1 gwei` and `totalLimits +=` modeled as word mods. [`canonical_batch:268-275`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) plus parent `gateway_wei_bounds` prove the sum is exact and `< 2^256` from uint64 widths × cardinality. Wrap is not assumed away.

### Canonical consumer — [`canonical_batch:251-302`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean)

- One `stateTree` / `headerTree` / `pinnedConfiguration pivot`
- Proofs from `treeBranch` of that header, not a supplied success bit
- Common `credentials` via `hwc` (all selected members)
- `sourceEntry (standardSha sha) … pinnedConfiguration … = .ok ()` **derived** from [`canonical_validator_entry`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/SszStatePlacement.lean) (`SszStatePlacement.lean:283-306`)
- Index is `memberOffset` = member value as `Fin 2^256` (`SszStatePlacement.lean:246-248`) — the actual wrapper offset, not a dummy
- Outputs: copied pubkeys, `weiLimits (map headroom)`, exact sum

`standardSha` and the EIP-4788 `hresponse` equality remain **explicit trust**. No supplied accepted Boolean, limits array, or root-match flag on the canonical theorem.

Generic [`loop_run:166-189`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) **does** take `sourceEntry = .ok` as a premise. The file says so (`:164-165`). The canonical theorem is the one that discharges it. That split is honest.

[`loop_spec:328-361`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) reconstructs `ns` from `evaluate (fields r)` of the **same** row that just passed `sourceEntry` ([`rowLimit_evaluated:306-324`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean)). Limits are observed, not trusted-in.

### 275 arithmetic bridge — [`router_checked_from_loop:396-420`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean)

Builds `routerInput` from executed `out` (keys via `UInt8.ofNat` with [`router_keys_exact:373-379`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) proving no 8-bit loss; limits via `word` with [`wei_word_values:385-389`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean)). Assumes only observed `loop = .ok` and router `guardSum = .ok` on **arbitrary** module allocations, plus `hmin` as a later helper condition. Derives exact allocation sum, `< 2^256`, and `AmountsAdmitted`. Does **not** run withdrawal/beacon/module. Arithmetic-only, as claimed.

### Config words — [`TopupGatewayConfigWords.lean:10-38`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayConfigWords.lean)

`gatewayRoot` = `GATEWAY_STORAGE_POSITION` (`sol:52-53`). Decode: low-64 count, bits 160–223 target, next-slot low-64 min. Matches packed `Storage` (`sol:41-48`) and `storage-layout.json` (uint64 @0, uint64 @20 of slot 0, uint64 @0 of slot 1). [`decode_packed:23-38`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayConfigWords.lean) separates those fields from the intervening 96 timestamp/block/distance/age bits. **Mathematical packing**, not solc/runtime refinement — stated in the module header. Foundry `testFuzz_actualConfigWordReads` checks the live getters.

---

## Real correspondence vs opaque Nat / constructor / Bool

| Item | Classification |
|---|---|
| `checkLengths`, `ordered`, `activated`, `evaluate` none, loop mods | **Real** source guards / word arithmetic |
| `fields` / `headroom` field selection | **Real** (`withdrawableEpoch` correctly unused) |
| `sourceEntry` in `canonical_batch` / `canonical_row_entry` | **Real** derived consumer (parent CLEAN) |
| `memberOffset` / `index.val = member.val` | Definitional offset = validator index; **not** a success-flag projection |
| `PendingSafe` | Honest domain; overflow is a runtime panic, not a theorem hypothesis that erases it |
| `loop_run`'s `sourceEntry = .ok` | Premise of a **generic** lemma; discharged on the canonical path |
| `hresponse` / `standardSha` | Explicit trust, not a Bool admit of “proof ok” |
| `hmin` on allocations | Later helper, not gateway |
| Kernel tests with `sha := fun _ => 0` ([`Mutants.lean:15-34`](/tmp/lido-review/repo/LidoSRv3/Tests/TopupGatewayWitnessBatchMutants.lean)) | Synthetic hash fixture; **not** crypto. Comments say so. Byte-sum oracle tests credential mismatch ([`:80-84`](/tmp/lido-review/repo/LidoSRv3/Tests/TopupGatewayWitnessBatchMutants.lean)) |
| `decide` on finite mutants | Kernel examples, not `native_decide` |

No Bool-admit of “accepted / limits / root-match” on the canonical theorem.

---

## Candidate findings

None that break the claimed increment.

**Non-blocking / in-scope honesty (not defects):**

1. [`TopupGatewayWitnessBatch.lean:264-266`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) — trusted oracle reply (success + digestBytes(header) ++ suffix). Explicit.
2. [`TopupGatewayWitnessBatch.lean:65-67`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) — `PendingSafe` required for non-excluded pending add. Honest vs `sol:408`.
3. [`TopupGatewayWitnessBatch.lean:32-33,247-250`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) — prefix ⊀ temporal WC ⊀ loop as one theorem.
4. [`TopupGatewayConfigWords.lean:4-6,17-19`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayConfigWords.lean) — slot decode, not compiler refinement.
5. [`TopupGatewayWitnessBatch.lean:402-404,395`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/TopupGatewayWitnessBatch.lean) — bridge is arithmetic; module allocations arbitrary; `hmin` later.
6. [`Mutants.lean:15-34`](/tmp/lido-review/repo/LidoSRv3/Tests/TopupGatewayWitnessBatchMutants.lean) — constant SHA is control-flow only.

**Still open (claimed):** ABI/calldata pointers; SHA/precompile gas/memory for this composition; root authentication; full entry/modifier/time/WC ordering; module/funding; timing write vs recorder; nested calls; per-block cap; noReentry/frame.

**P-TOPUP-1:** OPEN. This slice does not conserve pulled/pushed wei or prove router rollback.

---

## SSZ SHA-call (noted, not expanded)

[`SszShaCallBytes.lean`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/SszShaCallBytes.lean) (92 lines) and [`SszShaCallMemory.lean`](/tmp/lido-review/repo/LidoSRv3/Audit/Source/SszShaCallMemory.lean) (227 lines) exist on **parent** `23728167` (`Prove SHA precompile call output transport through EvmYul memory`). **Diff vs parent is empty.** Not part of this increment. No CALL/output/gas closure review.

---

## Evidence reuse

| Artifact | Result |
|---|---|
| receipt SHA256 | match author |
| Lean 16/40/11/1285/11s | match `validation.log` / `axioms.log` |
| Core `TopUpGateway.sol` `a7ffb654…` | match pin + `source-check.json` |
| Solidity 7 tests / 3×1024 fuzz / solc 0.8.25 | match `solidity/validation.log` (not re-run) |
| `lido-core/` gitlink in clone | unpopulated; hashes checked against independent `lidofinance/core@17005714` |

---

**CLEAN** for the claimed TOPUP witness increment on CLEAN parent `23728167`. No correspondence defect vs pinned `TopUpGateway.sol:163-228,390-414` and the arithmetic 275 bridge. Trust boundaries and non-claims are labeled. P-TOPUP-1 stays OPEN.

VERDICT: CLEAN