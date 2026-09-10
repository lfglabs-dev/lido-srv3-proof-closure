# TOPUP-2 exact-candidate review — `131ae229f2c26d6703c3679714d8d0c81b8e1f36`

**Verdict: Lean/value-path CLEAN (unchanged `actual_module_batch_bound`). NOT CLEAN to merge as TOPUP-2 scope close until UX2 `summary` / `next_gate` / `classification.work` stop advertising wei conversion and module-selected `allocateDeposits` as OPEN while `main_result.missing` is `[]`.**

Not campaign delivery. P-TOPUP-1 Bound/conservation remain OPEN. Hermes does not merge/push/site.

Packet: `/var/lib/hermes-assistant/direct-pilot/lido-evidence/local-20260909/topup2-scoped-review-input`
Hashed files: **1838/1838 match**. Manifest SHA256 `cc3aa71385f3d5c975283b993c8466d0fd3a6842320d978c5b38566a245c953e`.
DATA: `d6167455a263e24536986cfbc5137d2f9d1a0ba95ebbb0c0111dd1a65f74c296`
Head: `131ae229f2c26d6703c3679714d8d0c81b8e1f36`
Base: `14f601e7b34d62663a38d06ccee1d1ba113ae953` (DEPOSIT308)
Site freeze in packet: `a2f172ae` (P-TOPUP-2 presentation still `630010d1…`, not this candidate)
Pin: `17005714f151e5502c559932319a3f2f74ac2436` (6 Solidity identities match packet files)
Writer: ROOT STOPPED. No Hermes TOPUP writer.
Prior scope review: `a9240be4abaa7c635add85e6b4dd8019b6ce9da8054258021f1931118bb8ea7e` copied as `initial-independent-review.md`.

## What this candidate changes

11 files only: `audit/topup2-scoped-assurance/*`, `audit/trio/main-guarantees.json`, `audit/ux2/P-TOPUP-2.json`, `scripts/main_guarantees.py`, `scripts/test_main_guarantees.py`.

**0 Lean/proof/dependency diffs vs site308/`14f601e7` proof tree** (1664 compared files identical). Receipt: `proof_changes: 0`, `new_axioms: 0`, 1274 source identities, 11 pins. `PTopup2ActualBatch.lean` still wraps `TopupBatchConsumer.run_success_bound`. All+Trust still import/query `actual_module_batch_bound`. Trust 29 reused, not re-run here.

Registry now allows empty `missing` (test asserts `missing == []`). Conditions + theorems remain mandatory.

## Value path (unchanged, still sufficient for the cap)

Public: `PTopup2.actual_module_batch_bound`.
Premises: `TopupBatchConsumer.run = .ok` and `outcome = .ok ()`.
Conclusion: decoded module allocations sum ≤ packed slot-5 cap · 1 gwei, with `loop` + `moduleInput` + raw CALL/decode on the **same** keys/limits.

Pinned gateway `TopUpGateway.sol:163–236` builds `pubkeys`/`topUpLimits` then `stakingRouter.topUp(...)`; `_evaluateTopUpLimit:399–420` is a **checked** body (zero/headroom/min) even when the caller loop is `unchecked`. Router `696–743`: packed cap, min with arbitrary `moduleAllocation`, gwei-round, module CALL, align/limit/sum, no-wrap before compare. `history` write is **after** `topUp` returns. View prefix cannot rewrite selected config.

No new packing/count/callback/stage-success premise. No new global. Roles/error/rollback/no-code trace/oversized-return allocation are **outside** this inequality; they cannot inhabit a successful decoded sum. TOPUP-1 `Pipeline.Bound` / conservation stay OPEN and are not premises of this bound.

`missing=[]` for **this** promise is therefore not a hide of a necessary ABI/value connection. The connection is the existing consumer.

## Blocking documentary defect on this exact head

`main-guarantees.json` / `ux2.main_result`: description, covered, missing=[], conditions, outside — match the theorem.

Same file `P-TOPUP-2.json` still has:
- `summary`: “Live wei conversion, module allocateDeposits policy, and SSZ remain open.”
- `next_gate`: “OPEN: model the live wei conversion and module-selected allocateDeposits return…”
- `classification.kind`: `IMPLEMENTATION_PENDING` with `work` repeating that next model step
- `roadmap_priority`: `DONE`

Merging `missing=[]` while `next_gate` still names the already-consumed module-selected path as OPEN is a **weakened/contradictory registration**, not a Lean gap. Smallest raccordement: rewrite those three UX2 fields (and any generator that copies `summary` onto the site) to the `main_result` text; do not add theorems.

Current site `a2f172ae` is untouched (hash `630010d1`). Do not treat this candidate as site delivery.

## CLEAN meaning if UX2 is aligned

Then `actual_module_batch_bound` is sufficient for the original useful per-batch cap. Full-entry/roles/errors/rollback are not this promise. All eight campaign IDs stay OPEN until root/site record the aligned candidate. No Hermes merge.

## Writers (not this review)

ACCOUNT `23e86519` and ADDRESS `a4865aa2` exclusive. `send_message` blocked by `writer_identity_stale` (`github_pr` null displayed as `-`). Ask sidecar (not a wake): ACCOUNT lake 761022 / lean 761032 ~80% on ReportFeeMint; `| some fee =>` still; hint file unread. ADDRESS lake 1977674 ~35m live; **zero reads** of `root-39c-enumset-findings.md`; `ownerRequestIndexSlot` still `nestedMappingSlotLocation … 1`. Copied file ≠ consumed. No duplicate writer. No kill.
