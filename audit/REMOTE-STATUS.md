# Remote status log — Spark integrator

One line per candidate that is frozen (pushed), reviewed (verdict recorded),
merged into main, or blocked. Kept in tree so future turns and reviewers can
pick up the coordination state without re-deriving it from `git log`.

Distinctions used:
- `frozen`   — commit exists on a `spark/*` or external branch, ready for review
- `reviewed` — independent read-only review produced `VERDICT: CLEAN|BLOCKED`
- `merged`   — landed on `lfglabs-dev/lido-srv3-proof-closure`, `main`
- `blocked`  — findings prevent merge until repaired

| Date (UTC) | Lane / branch | SHA | Event | Next obligation |
| --- | --- | --- | --- | --- |
| 2026-09-11 | audit/spark-integrator-bootstrap | e9d6288a | context | pre-existing landed history: #345–#349 in via merges 4207bb05, 6e59055f, 43f0e7ab, e9d6288a |
| 2026-09-11 | grok/lido-topup-aliasing-20260911 | b9182478 | frozen (external) | independent read-only review before any integration |
| 2026-09-11 | grok/lido-topup-aliasing-20260911 | b9182478 | reviewed CLEAN | HOLD merge — TOPUP is Mac-agent lane; wait for Thomas/Hermes clearance before cherry-pick. Findings: pure additive (3 new files, 475 lines); kill-line `independent_cursor_alias_refutes_global_nonalias` genuinely refutes universal non-aliasing (concrete witness at cursor=128, overlapping zones), no sorry/axiom, IR3149–3159 & IR512–538 cited exactly. Report kept out-of-tree at `/tmp/spark-review-grok-topup-aliasing-b9182478.md`. |
| 2026-09-11 | scoping/account-1 | e9d6288a | scoped | Candidate obligation: derive `callerAllowedByRole` from live REPORT_EXITED_VALIDATORS_ROLE state instead of the opaque `senderAllowed` Boolean at SubmitReportEntry. Needs pre-flight to confirm the role check is genuinely absent from the current Lean model (avoid renamed-premise trap). Report `/tmp/spark-scope-account1-20260911.md`. |
| 2026-09-11 | scoping/address-1 | e9d6288a | scoped | Candidate obligation: promote `bounded_live_claim_batch_storage_call_surface` (two-item) to arbitrary-length `unbounded_live_claim_batch_caller_swap_equivariance` on `WithdrawalQueue.claimWithdrawalsTo`. Bounded→unbounded is real strengthening (no renaming). Report `/tmp/spark-scope-address1-20260911.md`. |
| 2026-09-11 | scoping/consolidation-eth-1 | e9d6288a | scoped | Candidate obligation: fold canonical EIP-7251 request literal (0x0000BBdDc7CE488642fb579F8B00f3a590007251) into `verity_tx_success_and_revert_partition`, closing A-CANONICAL-REQUEST-ADDRESS. Risk: could become renamed premise if literal is added as axiom rather than derived from artifact provenance. Report `/tmp/spark-scope-consolidation-20260911.md`. |
