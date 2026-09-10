# Independent ACCOUNT review — 96583566

Verdict: **CLEAN for the explicitly bounded report/getter/checked-fee/mint source composition.** No blocking executable or theorem finding on frozen commit `965835661f8db5caba9263b0d62e94106b1f07cf`. This is not an integration, full-root build, compiled Solidity equivalence or deployment verdict.

Reviewer: `/root/topup_root_call_batch`, reassigned after finishing the disjoint TOPUP lot; authored no ACCOUNT code. Candidate writer was stopped and root explicitly confirmed the frozen commit before final checks. Checkout `/tmp/lido-account297-integrated` was clean before and after checking. No candidate source, build artifact or receipt was edited; this external local review report is the reviewer's sole file write.

## Extent reviewed

Reviewed the complete unaccepted ACCOUNT ancestry through 96583566, not only its final diff against f7577570. The comparison baseline was current integrated root `64f73f101187992db5b9b446852c3063a5a6d5b7`, with common ancestor `bc2416618a2d10d8dada15e4106422d8107761a8`. Read full ReportFeeMint and StETHMintShares sources, physical ReportWriteFee and PAccount1 substrate, changed root HandleOracleReportTx wiring, public PAccount1 statements, standalone checked fee helper, retained callback projection sources/theorems/mutants, new and inherited mint regressions, and the dossier/receipt/compiler artifacts. The earlier callback projection remains separate and unregistered; it is not composed into or credited by `actual_report_fee_mint`.

Pinned Solidity was read from `/tmp/lido-ssz-proof-committed/lido-core`, exact commit `17005714f151e5502c559932319a3f2f74ac2436`: Accounting, Lido, StETH, SRLib, StakingRouter, UnstructuredStorageExt, pause/auth helpers, hardhat configuration and compiler notes. Receipt validation byte-compared the eight recorded pinned sources with their Git blobs.

## Semantic review

1. `handleOracleReportFromCommittedFeeProducts` executes the actual modeled report writer. `continueFromCommittedReport` supplies its exact returned router to `getStakingRewardsDistribution`. The checked arithmetic consumes that returned Distribution; `Success` exposes these same executions and `post.router = router`. There is no supplied successful stage, independent amount, arbitrary fee distribution, auth equality or frame hypothesis in the public necessary-success theorem.
2. `Input.accountingAddress` is independent of `before.steth.locatorAccounting` and is passed to `mintShares` as both caller and recipient, matching Accounting's `LIDO.mintShares(address(this), quantity)`. Positive success derives the caller/locator equality from the executed Lido address authorization guard, not from selecting the locator as caller. Auth precedes pause, which precedes zero/self recipient checks. Zero fee skips mint and its authorization exactly as the source conditional does.
3. Checked word admission is explicit for the nine Nat-encoded uint256 inputs. The unified CL additions, rewards subtraction/addition, fee multiplication/division, final denominator subtraction, share multiplication/division, every positive module distribution product/division, running addition and treasury subtraction are checked. The actual getter ensures parallel array shape; no separate user-provided array-shape success premise replaces execution. The old unrestricted Nat fee helper remains separately identified; the new public executor does not route through it.
4. StETH total shares come from the low 128 bits of the pinned total/external slot. Mint checks the uint256 total addition before the uint128 cap and the recipient mapping addition; successful storage is exactly the old storage updated at that one slot. The setLowUint128 lemmas preserve the complete high 128 bits external-share payload. The per-account map is explicitly abstract `Nat → Nat`, and the theorem states its pointwise increase without claiming physical keccak refinement.
5. Event conversion consumes the actual post-mint state. It uses Lido's internal-ether numerator from the two packed words and raw Solidity 0.4 uint256 multiplication/subtraction for the share rate. It does not substitute pre-mint totals, total pooled ether, or the high external-share half as total shares. Events are the paired zero-address Transfer and TransferShares with the same minted quantity.
6. `runStages` and `runRoot` share executable control flow with their generic inversion proofs. Getter, arithmetic and mint failures restore the complete initial modeled World, including report writes, both storage components, abstract account map and supplied context. The public failure theorem has only the observed complete executor failure premise. A late map-add or post-mint conversion failure therefore cannot leak earlier modeled writes.
7. The covered positive sequence stops after Accounting 403–406's mint. It does not execute `_distributeFee`, `reportRewardsMinted`, collectRewardsAndProcessWithdrawals, earlier full-report operations or later observer/rebase calls. ReportWei remains a supplied calculation snapshot; router/StETH component separation, locator result, self address and active flag remain explicit model boundaries. No broader EVM/CALL/ABI/crypto/compiler correspondence is asserted by this result.

## Compiler and failure-order review

Accounting declares exact `pragma solidity 0.8.9`. Pinned hardhat.config.ts selects solc0.8.9 legacy code generation, optimizer enabled with 200 runs and Istanbul; the sole source override is for VaultHub, and viaIR is configured for 0.8.25, not Accounting. Lido/StETH use exact 0.4.24, optimizer 200 and Constantinople.

Read the retained 0.8.9 compiler version and FeeOrder assembly. At tag7, the final quotient enters subtraction helper tag12 for `postEther - feeEther`, returns at tag11, then enters multiplication helper tag14 and finally division tag16. This supports the denominator-before-product transcription for the selected legacy expression/profile; diagnostic IR has a different order and is not used as the selected profile. Both active Nat and standalone Word helpers now use denominator subtraction, product, division. Overflow/underflow/division panics are deliberately collapsed to Option/feeArithmetic, so those subcodes are not falsely claimed observable. No language-wide evaluation order or full Accounting compiled identity is inferred from the small expression fixture.

The getter's raw arithmetic is over physically decoded widths: low 64-bit Gwei amounts, fixed 1e20 precision and uint16 fees, which keep those products inside uint256 even on arbitrary stored layouts. StETH internal-ether additions read four 128-bit halves, so their checked-overflow branches cannot conflict with the denominator-zero error on the typed packed-word domain. No additional success-domain premise was silently introduced to hide an arithmetic failure.

## Independent checks performed after freeze

All commands used normal kernel checking; no skipKernelTC/native decision/FFI proof receipt was accepted.

- `python3 audit/account-actual-mint/check_receipt.py --core /tmp/lido-ssz-proof-committed/lido-core`: PASS, 27 exact artifacts, 8 pinned source files, 10 recorded axiom sets, 8 new kernel regressions, 3 recorded slot identities. Retained slot checks were identity evidence, not independently rerun Solidity execution.
- In the isolated account-address package, independent `lake env lean` checks of `StETHMintShares.lean`, `ReportFeeMint.lean`, `Tests/Verity/StETHMintSharesTest.lean` and `Tests/Verity/ReportFeeMintTest.lean`: all exit 0. This replayed the eight new kernel regressions and four inherited mint examples, including genuine positive mint/poststate rate, mismatched Accounting caller, zero-fee auth skip, uint128 cap rejection, word admission, distribution-product overflow, event denominator failure and mapping-add rollback.
- At root, independent `lake env lean` checks of Source.ReportFeeProductsCorrespondence, HandleOracleReportTx, public PAccount1 and `audit/account-actual-mint/Axioms.lean`: all exit 0. Fresh theorem queries confirmed all ten exact closures use only `propext`, `Classical.choice`, `Quot.sound`, or a subset. The standalone distribution-product regression uses no axioms.
- `git diff --check HEAD`: PASS; exact HEAD remained 965835661f8db5caba9263b0d62e94106b1f07cf and the candidate worktree remained clean.

Receipt SHA256: `06d1c86928690a39d841adca016000de2b691b3a26daa261cc0cb11b21412695`.

Key independently observed source hashes:

| File | SHA256 |
| --- | --- |
| ReportFeeMint.lean | 0876f53edde2fbb6742fa4ac1e49b01071d14ccf54896165299264be9fca05c0 |
| StETHMintShares.lean | f4fc5b04455acb9c5993779e4171ccc5a288fe5adf701ee68b0a16d47b031f1b |
| public PAccount1.lean | 67c88010fdc868ee990f41e0775da5d829f01d34b72946886e60f22629195d0c |
| HandleOracleReportTx.lean | d41736060fc56b9d89f2c2fec1859dda053357c3895cb3fd109972033d5aae4d |
| ReportFeeProductsCorrespondence.lean | 471edd6b2b855844679dd5ef23409523caea2b221482991a51bc028a06135936 |

## Root-owned integration follow-up

The shared account-address README has inherited wording citing 403–413 for the new mint paragraph, calling the account map conventional without the new paragraph's explicit abstract qualification, and saying fee-product overflow is unmodeled without restricting that sentence to the older helper. This is a documentation clarification, not a defect in the frozen executor/public theorem/current dossier. Root acknowledged and is correcting it in the integration union.

The known duplicate accountAddress path dependency / root AccountAddressChecks provider is a root wiring issue. This review did not treat the retained diagnostic failed full build as passing and did not modify Lake/manifest/All/Trust. Root owns the single-provider wiring, aggregate public import and Trust inventory, full union build and independent final-union review. Those remain required before integration credit; this CLEAN verdict does not replace them.
