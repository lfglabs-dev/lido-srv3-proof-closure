# Independent ACCOUNT checked fee split integration review

Verdict: **CLEAN** for exact frozen commit `5907aec50567317e1d88c76ef9bbdb21c1e1e95e` in `/tmp/lido-account-split-integrated`. The author was stopped and the checkout was clean at review completion. I authored none of the ACCOUNT source or integration changes. This review made no candidate changes and performed no repeated build or Solidity execution.

## Union and preservation

The union `ac3893e784f7af7a60a973638aef57821070c288` contains reviewed source candidate `a3fe6041ecddbc3b7a4af56495da17ae15e9f001` and accepted main `f8ea5f9d3cffc165f5d84dd96444836c806827eb`. Both are ancestors. I compared the complete accepted-main tree: outside the previously reviewed ReportFeeMint theorem insertion and the three explicit wiring files, all existing objects are preserved. All four changed/new Lean source bodies are byte-identical to a3fe. Removing the exact 5,126-byte, 112-line theorem insertion from ReportFeeMint recovers its accepted-main bytes. Existing executors, theorem statements and public premises are unchanged. `git diff --check` passes.

The complete independent source review is reused by verified identity, and its integration archive is a verbatim copy. I read the integration changes and dossier completely. Added audit records do not alter executable or proof semantics.

## Actual consumers and providers

The existing single AccountAddressChecks provider now registers `ReportFeeCheckedSplit` and `Tests.Verity.ReportFeeCheckedSplitTest`; its source directory remains `audit/trio/account-address`. No duplicate provider or manifest change is introduced. AllGuarantees imports `LidoSRv3.Audit.Guarantees.PAccount1CheckedFeeSplit`. Trust imports the actual regression module and adds four active queries: the public `actual_report_fee_mint_checked_split`, `checkedFeeResultOf_split`, `checkedFeeProducts_split_origin`, and `committed_checked_split`.

Actual generated setup files resolve the source and public imports to this checkout's local build artifacts. The registered split and test modules have their intended short identities, and setup options are empty. No old long audit.trio account-address module identity supplies these imports. The resolved scoped sources match the 27-source packet. Normal build traces for ReportFeeMint, split, test, public, AllGuarantees and Trust contain no kernel-skipping option.

The public theorem retains its sole actual committed-execution premise. It consumes the same existing report/getter/checked-fee/mint success and derives exact casts, the three aligned lengths, and the checked module-floor/treasury partition from the same post-router distribution and fee result. There is no separately supplied stage success, distribution equality, arithmetic bound or new separation/nonduplication premise. Alias and duplicate rows remain positional. Zero module fees avoid division in the source; zero mint skips distribution. Later `_distributeFee`, recipient transfers and `reportRewardsMinted` remain outside the claim. Existing snapshot/layout, physical packed total shares versus abstract account mapping, compiler and Verity boundaries are preserved.

## Artifact identity and validation

The candidate's manual compile assigned long module names to two new source modules. Normal Lake registration correctly uses the short provider names, changing those two artifacts and their dependent public artifact. This is accurately disclosed. ReportFeeMint's artifact remains identical; no claim of byte-identical reuse is made for the other three.

I checked the four current SHA-256 artifact identities against their actual bytes:

- ReportFeeMint: `470fd24a198f4016aa7b2e5e0d527e883caacd722e57e7cc9cf0da5358ee53db`.
- ReportFeeCheckedSplit: `42b944c7019bfa061a926535ceec22525c962f10bb5941b262986129b2f9484f`.
- PAccount1CheckedFeeSplit: `471ac75962a6b2220d6b231eacc3471b3b9e7cbec89624d51a1c2a7a1cc95e47`.
- Tests.Verity.ReportFeeCheckedSplitTest: `017bb6dc0b61427a39b22d7e81ba389affd4950b53117c8c32a205a579baf9fb`.

All 14 source-packet hashes and six integration receipt hashes match. The 27 scoped source identities, 11 actual package revisions and five pinned Solidity body identities match the reviewed packet. The core checkout remains pinned to `17005714f151e5502c559932319a3f2f74ac2436`. No new Solidity execution is required or credited.

The retained normal combined build passes 1,697 jobs and rebuilds the registered source, regression, public consumer and affected dependants. The actual Trust import compiles all ten checked-split kernel regressions, including the composed public success instance. Complete build axiom outputs agree with the 17 scoped sets. Every active Trust query is represented in the build output; its four new queries are foundations-only.

The fresh full Trust gate passes with exactly the existing 29 globally disclosed axioms: 23 native test/mutant axioms, three production exceptions and three foundations. This is not a globally foundations-only result. The separate scoped JSON correctly names `Tests.Verity.ReportFeeCheckedSplitTest` and records the current artifacts. All 17 sets equal the source packet and contain foundations only. In addition to checking the retained logs, I independently invoked the trust checker's environment-dependency query for all 17 names against that actual registered test environment. It passed and reproduced every recorded set. No Lean build was repeated for this check.

## Disposition

No actionable integration or scope finding remains. The exact 5907 candidate preserves accepted main and joins the reviewed checked-split proof to the real aggregate and Trust consumers with normal registration and kernel validation. Root retains ownership of any archive-only final commit, PR and merge. Review stopped after writing this external report; the candidate remains unchanged.
