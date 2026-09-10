# Independent ACCOUNT checked fee-split source review

**CLEAN — exact frozen `a3fe6041ecddbc3b7a4af56495da17ae15e9f001`.** No unresolved proof, source-correspondence, scope, provider or receipt finding. Checkout `/tmp/lido-account-checked-fee-split` is clean; writer stopped before review. Reviewer `/root/topup_root_call_batch` authored no ACCOUNT code. Date 2026-09-10.

## Complete change and preservation

Reviewed the entire delta from accepted `70301660264f2f710e7160e190aaa3af330e84fa`: three new Lean modules, the new audit dossier and a 112-line theorem-only insertion in existing ReportFeeMint. No global registration, AllGuarantees, Trust, package, manifest or site edits. Independently removing precisely the new 5,126-byte theorem block recovers every original ReportFeeMint byte, including all executables, prior theorem statements/proofs and namespace structure.

Read all added theorem proofs, complete ReportFeeCheckedSplit, public PAccount1CheckedFeeSplit, all ten regression propositions and the entire dossier/scripts. Reviewed the inherited checkedModuleShares, checked arithmetic, checkedFeeResultOf, checkedFeeProducts and actual report/getter/mint control flow against the earlier independently reviewed #302/#317 bodies. Their existing execution semantics and previous public claims are unchanged.

## Exact checked split and actual mint consumer

The new private induction consumes successful execution of the existing checkedModuleShares loop. For each positive fee it recovers the checked product and division, yielding exactly `shares * fee / totalFee`; for a zero fee it proves zero is the same mathematical floor while preserving its list position. It recovers each checked accumulator equality and derives final accumulator = initial accumulator + sum(returned parts). It assumes neither bounded module sum nor total-fee positivity.

`checkedFeeResultOf_split` consumes the actual positive/zero branch. Positive success derives positive totalFee from the existing guard, obtains the exact positional floor map and original recipients/IDs, and uses the successful checked treasury subtraction to derive sum(module shares)+treasury=shares. Zero mint returns all three empty lists and zero treasury, bypassing the total-fee assertion and entire distribution routine.

`checkedFeeProducts_split_origin` follows the existing word/add checks and reward branch to the exact checkedFeeResultOf invocation, deriving the share quantity from execution. It does not assume a helper result equal to the minted quantity. The higher theorem obtains the actual distribution and same fee from ReportFeeMint.Success, preserves the existing post-report ExactCasts property and derives list alignment from that actual getter's shape theorem. `post.router = actual report router` places the distribution on the same final router.

The public `actual_report_fee_mint_checked_split` assumes only success of the existing complete covered report/getter/checked-fee/mint executor. Its joint Success contains the full prior ReportFeeMint.Success, ExactCasts for every registered ID, equality of the recipient/ID/module-share lengths, and an actual getter result on post.router whose checked products return the same fee consumed by the mint. Split then proves exact mathematical conservation and the positive positional floor map or exact zero lists. There are no new stage-success, distribution equality, arithmetic success, bounded-sum, positive-total-fee, layout or mint-success premises.

This partition concerns the quantity actually minted in the existing model. It does not claim subsequent payout or mutate fee calculation to make conservation hold.

## Pinned Solidity and zero/overflow behavior

Independently compared five complete Solidity bodies against core `17005714f151e5502c559932319a3f2f74ac2436`: Accounting, StakingRouter, SRLib, Lido and StETH. Read Accounting 265–301, 306–358 and 403–413, including exact checked split order; inspected the unchanged mint entry and physical mint/event source. Reused prior full report/cast/mint correspondence reviews through unchanged identities.

Accounting allocates module-share entries in order, leaves a zero-fee row at zero, computes each positive fee product then division, checks the running sum and subtracts it from minted shares for treasury. The model adds zero through checkedAdd on skipped rows; its reachable accumulator starts at zero and every prior update is bounded, so this redundant zero update cannot introduce a reachable rejection. The proof does not claim Solidity evaluates division for a skipped fee row. The overall zero-mint branch skips distribution even if totalFee=0, as the source does.

Actual checked multiplication overflow, running-sum overflow and treasury underflow remain distinct executable rejection triggers at helper level; the bounded composition retains its existing feeArithmetic classification and entire modeled World rollback. The previously reviewed Accounting expression-evaluation profile is unchanged because no executable definition or compiler input changed.

The Lido mint receives the same sharesToMintAsFees, performs its existing authorization/stopped and recipient checks, updates the physical low128 total-share word and abstract recipient-share map and emits the existing post-mint conversion events. Existing supplied report snapshots/layout/components remain explicit; this increment does not prove those supplied snapshots equal arbitrary deployed prior state. `_distributeFee`, reportRewardsMinted, observers, rebase and later transfer calls remain outside the result and are explicitly excluded in source and README.

## Independent checks and non-vacuity

Ran normal `lake env lean` directly on modified ReportFeeMint and all three new modules, without output artifact writes or kernel bypass: PASS. This rechecks all ten named regressions and the public actual-consumer instance. Six arithmetic/helper examples have no axioms; composed examples use only existing foundations.

The regressions cover 11*[2,3]/7→[3,4] with treasury4; an internal zero row retaining [3,0,4]; zero mint with zero total fee; separate checked product, accumulator and treasury-subtraction failures; actual three-row report/getter/checked-calculation/mint returning fee10 with [2,0,2]+6; physical total shares20, recipient shares15 and the two actual mint events; the public conjunction on that same successful result; zero mint skipping an unauthorized caller; and actual fee-arithmetic failure restoring initial router and StETH storage. These demonstrate a non-vacuous successful composed execution and relevant error branches in the stated model.

Replayed the complete validator with all four deterministic JSON writes intercepted as exact comparisons: PASS, 27 actual scoped source identities, 11 exact package pins, five pinned Solidity bodies, 17 independently recomputed foundation-only kernel axiom sets and precise old-byte preservation. All resulting JSON bytes match the retained packet. No sorry/custom/native-decision dependency is introduced; the new private loop lemma is consumed transitively by the checked public split proofs.

Independently checked all 14 retained artifact/source hashes and all four recorded built olean hashes. The two prerequisite setup files resolve modified ReportFeeMint through this local build with normal options. `lake env lean --deps` for each new module resolves its direct imports through the isolated candidate cache, not another checkout. The 27 identities are correctly scoped to the actual prerequisite closure plus the sequentially compiled modules; they are not presented as a full repository/Trust closure.

The retained build receipt records 26 prerequisite Lake jobs followed by three normal sequential Lean module compilations; the log matches that scope. Reused these unchanged prerequisites and independently rechecked the proof sources. No redundant full build, full Trust gate or Solidity fixture/compiler execution was run or credited. Complete diff and `git diff --check` passed; final HEAD remains exact a3fe6041 and status is clean.

## Disposition

No corrections requested. This strengthens the already scoped report/getter/checked-fee/physical-mint model while preserving the prior Success and cast claims. Physical total-share storage versus abstract account-share mapping, supplied report snapshots/layout, full ABI/entry/deployment/compiler equivalence and subsequent payouts retain their established limits.

Root owns registration in the existing single ACCOUNT provider, facade/Trust wiring, combined checks, independent exact integration review and publication. Reviewer made no candidate edits and is stopped after this source report. CLEAN applies only to exact a3fe6041 with these boundaries.
