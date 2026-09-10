# Independent ACCOUNT post-report cast source review

**CLEAN — exact frozen candidate `408e6a4378711dece329d6c0ae0d045b8d54b81f`.** No blocking theorem, source-correspondence, claim-scope, test or receipt issue found. Checkout `/tmp/lido-account-fee-cast-invariant` is clean; author stopped before review. Reviewer `/root/topup_root_call_batch` authored no ACCOUNT code. Review date 2026-09-10.

## Exact scope and preservation

Compared the complete candidate change against `86ee843a2c755bc044b6eed47fe332a4138d4d6e`: exactly 14 added files, consisting of three new Lean files and the audit dossier. Every existing base object is preserved. Inherited ReportWriteFee, ReportFeeMint, StETHMintShares and public PAccount1 bodies also match accepted main `808db8a02694c1b0268f0480513466b03761491f` exactly. No executable, old theorem statement, Lake provider, AllGuarantees, Trust, package pin or historical check was changed.

Read complete new source `ReportFeeCastInvariant.lean`, `PAccount1ActualFeeCasts.lean` and `ReportFeeCastInvariantTest.lean`; complete inherited ReportWriteFee/PAccount1 definitions and proofs; the actual ReportFeeMint control flow, Success relation and committed-success derivation; all new dossier and validation scripts. Reused the earlier independent accepted ACCOUNT source review for unchanged mint internals and preserved suffix boundaries.

## Actual consumer and proof

`actual_report_fee_mint_casts` has a single execution-success proposition premise for the existing `handleOracleReportFromCommittedFeeProducts`. It retains the full existing `ReportFeeMint.Success` and adds `ExactCasts` for every registered ID on `post.router`. The proof obtains that same Success from actual execution, extracts the actual committed report router and its equality to the final router, then derives cast facts on precisely that state. It does not accept an independent successful stage, distribution, allocation bound, separated layout or distinct-ID premise.

`rows_allocation_bound` inducts over actual successful `writeReportRows`. For a queried head slot with a later alias, the induction result for that later registered row bounds the final slot value; without a later alias the existing frame result preserves the head write. Checked running-total monotonicity bounds either value by the final total. Duplicate registered IDs and distinct IDs sharing an accounting slot are admitted. The argument proves an inequality, not per-occurrence report/read equality.

`report_allocation_le_total` then accounts for the actual final router-total write. If the module accounting slot aliases the router slot, both final reads equal the written total. Otherwise the prior module bound is preserved. Registered/reported sequence equality and the checked uint64 final total are derived from committed report execution. Multiplication by the common gwei scale gives the same allocation/total relation read by the getter. No unchanged-configuration premise is needed: cast bounds use the actual final decoded configuration, including layouts where other slots alias configuration.

From allocation≤total, the share is at most `10^20`; each decoded fee field is below `2^16`. The deliberately loose bound `10^20 * 2^16 < 2^96` proves both independently floored pre-cast fee values strictly below uint96 without an assumed 10,000-basis-point configuration cap. Unfolding the existing computeModuleFee casts then yields equality with each exact pre-cast expression. Both fee floors and the earlier share floor remain distinct. No arithmetic or executable alternative is substituted for the consumed helper.

## Pinned Solidity mapping and zero behavior

Checked the receipt's four full Solidity bodies against Git pin `17005714f151e5502c559932319a3f2f74ac2436` and their recorded SHA256 values. Read SRLib's validation/report path around 853–892, SRUtils helpers, SRTypes packed field layout and StakingRouter getter/fee-computation path 819–893.

SRLib validates report ordering and each maximum amount, casts each admitted amount to uint64, writes that module's low64 balance, performs checked uint64 accumulation, then writes the router's low64 total. SRUtils reads those same low64 balances and multiplies each by 1 gwei. ModuleStateConfig carries independent uint16 moduleFee and treasuryFee fields at the offsets used by decodeConfig. `_computeModuleFee` performs allocation*precision/total and the two independent fee divisions followed by uint96 casts. The theorem concerns these exact existing helper expressions on the actual post-report domain.

At a zero router total, the actual getter sets its considered module count to zero and returns the empty distribution. At a positive total it skips any individual zero-allocation module before loading configuration or computing its fee. The theorem's Nat division-by-zero convention therefore describes a total mathematical helper on unexecuted rows; it does not assert that Solidity executes division by zero. All genuinely computed module fee arguments are the same final-state allocation, router total and configuration used by ExactCasts. This distinction is explicit in public documentation, dossier and zero regression.

Aliases and duplicate registry entries are legitimate witnesses in the admitted abstract layout/registry domain. They are not proof of deployed keccak collisions or deployed duplicate registration. Prior exact per-row correspondence results still retain their original separation/distinctness assumptions. This new bound does not erase those assumptions from unrelated results.

## Independent checks

- Ran all three new sources directly with normal `lake env lean`, without output writes or kernel-check bypass: PASS. This rechecks the six `decide +kernel` regressions and seventh public instance.
- Regressions cover module/module alias, module/router alias, repeated IDs, two maximum source-admitted `10^18`-gwei rows with full uint16 fee fields, zero report with actual empty getter, and actual positive report/getter/checked-fee/mint execution. Positive mint yields two shares, total shares 12 and the expected two events; public instance retains Success and final-router casts.
- Replayed `validate.py` with its two deterministic JSON writes intercepted as exact comparisons: PASS, 24 scoped source identities, 11 exact package pins, 13 independently recomputed foundation-only axiom sets. Retained source-inputs and axioms JSON are byte-identical to the independently recomputed results. All sets are subsets of propext, Classical.choice and Quot.sound; no sorry/custom/native-decision dependency introduced.
- Ran `check_receipt.py --core /tmp/lido-ssz-proof-committed/lido-core`: PASS, 13 artifact hashes, 24 source hashes, 11 pins, 13 axiom sets and four full pinned Solidity files.
- Checked complete diff preservation and `git diff --check`: PASS. Final HEAD remains exact 408e6a43 and status is clean.

The 24 identities are accurately labeled a scoped closure: the three new modules, inherited public PAccount1 and its non-toolchain setup imports. They are not a new whole-repository All/Trust closure. The retained inherited setup names the baseline `/tmp/lido-account302-integrated` artifact paths; current `lake env lean --deps` resolves all new direct imports through the isolated 408e local build. The inherited ReportFeeMint, ReportWriteFee, StETHMintShares and PAccount1 olean bytes match the accepted baseline cache exactly. Current source-body checks and inherited source identity support that cache reuse. Toolchain Std/Lean remains covered by the pinned lean-toolchain.

No new Solidity runtime test, compiler simulation or full AllGuarantees/Trust build is credited here. The baseline 1,685-job / 29-axiom result is historical; root must perform the future combined build and independent integration review after wiring the new modules. No additional package provider is needed.

## Limits and disposition

The casts are exact on the consumed post-report model state; this does not certify full deployed storage hashing, ABI/role/locator admission, interposed report operations, all uint256 execution/compiler behavior, later fee distribution or reward callbacks. The existing actual report→getter→checked fee products→bounded mint relation and its rollback/authorization scope are preserved; the new conclusion adds cast exactness without changing executions or narrowing prior claims.

No candidate changes requested. Root owns global single-provider wiring, combined checks, integration review and publication. Source review is complete and reviewer is stopped; CLEAN applies only to exact 408e6a43 with these boundaries.
