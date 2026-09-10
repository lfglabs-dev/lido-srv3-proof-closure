# Independent ACCOUNT casts integration review

**CLEAN — exact frozen `430bd455d474ba3323dc1d403c9db7f66291b323`.** No unresolved source, provider, claim-scope or receipt finding. Checkout `/tmp/lido-account-casts-integrated` is clean; root integration writer stopped before review. Reviewer `/root/topup_root_call_batch` authored neither ACCOUNT source nor integration. Review date 2026-09-10.

## Complete union preservation

Verified reviewed source `408e6a4378711dece329d6c0ae0d045b8d54b81f` and accepted main `a8988b0140abe62450827b20300332e8f1961cdf` are both ancestors; their merge union is `450356fc3ee3eaef20c13716791f5842514044a1`.

Compared the entire accepted-main Git tree: every existing object is preserved except exactly four intended integration paths: lakefile.lean, AllGuarantees.lean, Trust.lean and the ACCOUNT README. All accepted #302 actual mint and #316 ordinary no-code TOPUP code, guarantees, tests, manifests, pins and historical evidence remain unchanged. The three new casts Lean source bodies are byte-identical to independently reviewed 408e.

Read all integration modifications and dossier contents. Source review is retained verbatim and matches the original independent report. Its full-source, pinned-Solidity, normal-kernel and proof-scope conclusions are reused through exact identities; this review does not claim a second source implementation or extra Solidity execution.

## Provider and actual public consumer

Lake adds `ReportFeeCastInvariant` and `Tests.Verity.ReportFeeCastInvariantTest` to the existing AccountAddressChecks roots, using its existing srcDir. There is no second accountAddress package/provider, and the external manifest is unchanged. AllGuarantees imports PAccount1ActualFeeCasts; Trust imports the new regression and adds five active axiom queries for the public consumer, derived report allocation bound, two alias regressions and positive actual mint regression.

Inspected the actual new module setup artifacts. Each resolves to the root package; its non-toolchain source providers match the reviewed scoped source identity packet. Local ACCOUNT imports resolve inside this integration build. AllGuarantees and Trust both resolve the casts guarantee, invariant and existing ReportFeeMint to the same local integration providers. Setup options are empty, and all five fresh module/facade/Trust build traces use normal compilation without a kernel bypass. This removes the old candidate's inherited setup-path ambiguity through the actual integration build.

The public statement remains exactly the reviewed one: success of the existing report/getter/checked-fee/mint execution yields complete existing Success plus ExactCasts for registered IDs on that same actual final router. No separation, distinct-ID, no-wrap, allocation-bound or successful-prefix premise is added. The executable helpers, previous guarantees and failure semantics are untouched.

## Claims and retained scope

The historical README now replaces only the specific post-report uint96-exactness HOLD with the derived result and public consumer. It continues to say P-ACCOUNT remains OPEN, preserves arbitrary report-inconsistent storage as a cast-sensitive domain, and retains the uncomputed keccak, supplied registry order, source-level model and deployment/compiler boundaries. Earlier exact per-row report/read results remain unchanged with their original separation and distinctness conditions. The new cast inequality does not certify those stronger correspondence claims without their premises.

The integration dossier correctly states that aliases/duplicates are admitted by the layout model and that both fee fields are bounded through actual post-report allocation≤total and decoded uint16 bounds. Zero-total and zero-allocation getter skips remain distinct from total Nat helper facts: no executed Solidity division-by-zero claim is introduced. Later fee distribution/reward callbacks and interposed full-report operations remain outside the existing actual mint suffix.

## Receipts and validation reuse

Independently ran the read-only source receipt checker on this union: PASS, 13 artifact hashes, 24 scoped source identities, 11 exact pins, 13 foundation-only scoped axiom sets and four full Solidity bodies at core `17005714f151e5502c559932319a3f2f74ac2436`. Checked all four integration hashes and the verbatim archived source review. Verified complete source preservation and `git diff --check`.

Reused the retained root AllGuarantees/Trust build: PASS, 1,689 jobs. Its log shows fresh normal builds of the new invariant, public theorem, regression, AllGuarantees and Trust. The regression build checks all six kernel examples and public instance. The integration receipt records a fresh `scripts/check_trust_axioms.py` PASS with environment dependencies recomputed and disclosed native claims re-evaluated.

Independently reconciled the complete retained Trust reports with the unchanged checker/allowlist and active source queries: exactly 29 global disclosed axioms, all active printed theorem names present, and all five new queries foundation-only. Global 29 means the existing 23 test/mutant native-decision dependencies, three existing production exceptions and three foundations; it is not a globally foundations-only claim. The source packet's 24 identities and 13 closures remain explicitly scoped, distinct from the combined facade/Trust build.

No redundant build, full trust re-evaluation, source kernel check or Solidity run was performed for this review. The already independent 408e source checks remain valid by exact source/dependency identity; root's new combined build and fresh trust receipts supply the integration evidence. Final HEAD is exact 430bd455 and working tree is clean.

No changes requested. Root owns archival, final merge/publication and any later changed bytes. Reviewer made no candidate edits and is stopped after this report.
