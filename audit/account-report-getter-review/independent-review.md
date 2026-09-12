# Independent read-only review: lfglabs-dev/lido-srv3-proof-closure PR #297

Reviewer role: writer=false. No source edits, no push, no PR comment, no merge.

## 1. SHA
- Required head: dbe17499619b4f96e3f488cd2beaeb0c8ac4bdfd
- `git rev-parse HEAD` after `git fetch origin pull/297/head`: dbe17499619b4f96e3f488cd2beaeb0c8ac4bdfd  (MATCH)
- Branch: g-account-address/physical-slots-fee-getter, state OPEN, MERGEABLE, base main
- merge-base with origin/main: a455cc1ab0f75f7ebd6e11dddee18c7e87a1dd0f (writer claim a455cc1 confirmed). origin/main has since advanced to 02b53a15 (PR #289 follow-ups); not a concern for this slice.
- Solidity pin: lidofinance/core 17005714f151e5502c559932319a3f2f74ac2436, cloned and checked out; all line refs below read from that checkout.

## 2. Files (diff a455cc1..dbe17499)
| File | Change |
|---|---|
| audit/trio/account-address/ReportWriteFee.lean | +814 (new) sha256 98ab33f1…2932 |
| audit/trio/account-address/Tests/Verity/ReportWriteFeeTest.lean | +133 (new) sha256 6a08b51a…b301 |
| audit/trio/account-address/README.md | +57/-8 sha256 97cdd6a3…a262 |
| audit/trio/account-address/lakefile.lean | roots += ReportWriteFee, Tests.Verity.ReportWriteFeeTest |
| lakefile.lean (root) | AccountAddressChecks roots += same two |

Hashes match the PR body. PAccount1.lean unchanged (71609c24…938d). No change to audit/source-map.yaml or any registry. No SSZ / TOPUP / site files touched. Working tree clean after build.

## 3. Build (independent, clean .lake)
- Toolchain: /root/.elan/toolchains/leanprover--lean4---v4.31.0 (Lean 4.31.0, Lake 5.0.0-src+68218e8). lean-toolchain file: leanprover/lean4:v4.31.0.
- Note: the sandbox `lake` on PATH is a policy shim; the first attempt exited 127 ("real Lake binary not found"). Rerun with SANDBOXED_REAL_LAKE pointing at the v4.31.0 binary, `rm -rf .lake` first.
- Command: `lake build` in audit/trio/account-address. Real exit captured with `; echo LAKE_EXIT=$?` (no tee): **LAKE_EXIT=0**, "Build completed successfully (8 jobs)", 0 warnings, 0 errors. Log: output/lake-build-pr297.log.
- Root target `AccountAddressChecks` NOT built (root manifest needs verity/EVMYulLean/mathlib; out of scope for the isolated-package check). Root lakefile edit is syntactically identical to the isolated one.

## 4. Axiom / escape audit
- grep over PAccount1.lean, ReportWriteFee.lean, test: no `axiom`, `sorry`, `native_decide`, `unsafe`, `implemented_by`, `extern`.
- Programmatic `collectAxioms` over every declaration of modules ReportWriteFee (333 decls) and PAccount1 (166 decls): only `propext`, `Quot.sound`, `Classical.choice`. No `sorryAx`, no `Lean.ofReduceBool`.
- Test file re-elaborated with its 20 `example`s renamed to theorems: all 20 check; axioms used ⊆ {propext}. Every vector is kernel `decide` on concrete `Fin (2^256)` words.

## 5. Solidity correspondence (pinned 17005714, full ranges read, not excerpts)
Layout (SRTypes 174-193, SRStorage 14-31):
- RouterState: moduleStates slot0, moduleIds (EnumerableSet.UintSet) slots1-2, accounting slot3, withdrawalCredentials slot4, lastModuleId+maxTopUpPerBlockGwei slot5 → 6 words. Lean `routerAccountingSlot = routerBase+3`, `Separated.router_gap` uses 6. CORRECT.
- ModuleState: config +0, deposits +1, accounting +2, name +3 (name ≤31 bytes, single slot). Lean `moduleConfigSlot = moduleBase id`, `moduleAccountingSlot = moduleBase id + 2`, module_gap width 4. CORRECT.
- ModuleStateConfig packing (SRTypes 118-136): address 0..159, moduleFee 160..175, treasuryFee 176..191, stakeShareLimit 192..207, priorityExitShareThreshold 208..223, status 224..231, wcType 232..239. Lean decodeConfig. CORRECT.
- ModuleStateAccounting (157-164): validatorsBalanceGwei low 64, exitedValidatorsCount 64..127. RouterStateAccounting (166-172): low 64. Lean low64 write / aboveLow64 preserved. CORRECT.
- `moduleBase id` = keccak256(abi.encode(id, routerBase)) is NOT computed; `Layout.Separated` is a caller premise. Disclosed in Lean header and README. Allowed, does not close P-ACCOUNT-1.

Writer SRLib 873-892 (registry span 872-892 incl. comment line):
- 877 validation = 853-870: length vs getModulesCount (860) → arraysLengthMismatch; per-i id mismatch (866) before _ensureAmountGwei (868, MAX_VALUE_GWEI = 1e18, SRUtils 23/78-83). Lean: length guard then `validateInterleaved` (PAccount1). Order CORRECT. maxValueGwei = 1e18 CORRECT.
- 882-888: iterate reported ids; uint64 cast (884); low-64 write on accounting word (886); checked uint64 += (888). Lean writeReportRows. CORRECT; overflow reachable in principle (32 modules × 1e18 > 2^64), modeled as Error.arithmeticOverflow; revert returns the pre-state snapshot.
- 890-891 router word low-64 write. CORRECT.

Getter StakingRouter 808-874 and 885-894:
- 819 total = fromGwei(router.accounting.validatorsBalanceGwei) (SRUtils 67-69). 820 count = total==0 ? 0 : modulesCount. 828-829 empty return with totalFee=0, precisionPoints=1e20 (56). Lean stakingModulesCount / getter_empty_success. CORRECT.
- 834-859: getModuleIdAt(i) order; allocation (836, SRUtils 62-64); skip 0 (839); config load (843) before fee; _computeModuleFee 890-893: share = alloc*1e20/total; moduleFee = uint96(share*moduleFee/10000); treasuryFee likewise (TOTAL_BASIS_POINTS SRUtils 17). Stopped (enum 2, SRTypes 40-44) → no module fee recorded (851-853); totalFee += treasuryFee+moduleFee checked uint96 (854); assert totalFee ≤ precisionPoints (862); shrink (865-870). Lean rewardedRows / computeModuleFee / getStakingRewardsDistribution. CORRECT, including error order (status panic per row, overflow per row, cap after loop) and division-by-zero unreachability (total ≠ 0 on that path).
- Status byte >2 modeled as Panic(0x21) at the 843 storage→memory copy. Consistent with solc enum validation on storage reads; not machine-verified here; disclosed.

Consumer Accounting 265-303, 306-333, 335-358:
- 277 getter; 279-280 asserts discharged by getter_ok_spec; 282-288 → totalProtocolFeeShares: 317 unified sum, 322 LIP-12 strict `>` guard, 323 totalRewards, 325 feeEther, 331 checked subtraction (Panic 0x11 if post < feeEther) then division (Panic 0x12 if equal). Lean models both in source order. CORRECT.
- 290-302: shares>0 → distribution else default empty struct. Lean feeResultOf. CORRECT.
- 340 assert(totalFee>0) discharged by totalFee_pos_of_shares_pos (shares>0 ⇒ totalFee>0). 347-354 floor shares for fee>0, 351 checked +=, 356 checked −. Lean moduleShares; moduleShares_sum_le proves 351/356 cannot panic. CORRECT.

## 6. Theorems vs README/PR claims
| Claim | Theorem | Status |
|---|---|---|
| committed report sets exactly low-64 of registered words / router word, preserves other bits & slots incl. config | report_committed_module, report_committed_router, report_committed_frame, report_committed_config | proved; module theorem needs `L.Separated reg` and `reg.Nodup` |
| every revert restores snapshot | report_reverted_restores | proved (rollback is by construction: `.reverted e core`) |
| getter total / allocations after report = reported gwei in wei | report_then_routerTotalWei, report_then_moduleAllocationWei | proved |
| equal-length arrays, Σfees ≤ totalFee ≤ 1e20, only registered nonzero ids | getter_ok_spec | proved |
| 340 assert holds on every reachable path | totalFee_pos_of_shares_pos | proved |
| module + treasury shares = minted; 351/356 safe | calculateProtocolFees_ok, moduleShares_sum_le | proved |
No theorem statement overclaims beyond what is proved. No end-to-end "report ⇒ getter succeeds" theorem is claimed or present.

## 7. Tests (Tests/Verity/ReportWriteFeeTest.lean, 20 vectors)
Numerically re-derived in Python: cfgActive / cfgStopped / cfgStatus3 / cfgMax word encodings, decoded fields (170, 500, 500, 0), post-report words (7·2^64+20, 9·2^64+30, 11·2^64+50), distribution ([170,187],[1,4],[2e18,0], totalFee 1e19), uint96 truncation value 44642003085559411534374961152 (unmasked value ≥ 2^96, so cast is load-bearing), fee shares 5025125628140703517 → 1005025125628140703 + 4020100502512562814, feeExceedsPostEther(1e19, 1). All match. Covers: committed write, config untouched, Stopped, skip-zero, empty success, status panic, cap panic, three rollbacks, non-profitable, checked subtraction.

## 8. Minor notes (not defects; no verdict impact)
1. `report_committed_module` / `report_then_moduleAllocationWei` require `reg.Nodup`; README says only that the id order stands for the EnumerableSet array (which implies distinctness) but does not name the premise.
2. Slot keys are `Nat`; `moduleBase id + 2` does not wrap mod 2^256 as the EVM would. Harmless under `Separated`, but it is part of the uncomputed-keccak gap.
3. README discloses uint256 overflow only for the 325 and 331 products; the 317/323 sums and the 350 product are likewise unbounded `Nat`. Same category of gap, slightly under-listed.
4. Enum storage-load panic ordering (item 5 above) is a modeling assumption, disclosed, not compiler-verified.
5. Root `AccountAddressChecks` target not built here (heavy deps).

## 9. Remaining holds — P-ACCOUNT-1 stays OPEN
Registered P-ACCOUNT-1 spans not covered by this slice: AccountingOracle 360-366 / 477-559 / 609-619; StakingRouter 285-290 (role-guarded entry) and 263-271 + SRLib 616-639 (reportRewardsMinted); Accounting 135-144 (handleOracleReport) and 359-428 (_applyOracleReportContext). Plus: keccak key derivation uncomputed (`Separated` premise); EnumerableSet slots unmodeled; getter over arbitrary storage; uint96 exactness on report-consistent storage unproved (HOLD); no compiler/EVM/bytecode/deployment correspondence. No YAML/registry change requested or made.

## 10. Verdict
**CLEAN** for the PR's stated obligation: exact HEAD; isolated package builds from a clean .lake on Lean/Lake 4.31.0 with real exit 0; no axioms/escapes; slot layout and packing match the pinned SRTypes/SRStorage; writer, getter and consumer match SRLib 873-892, StakingRouter 808-874/885-894 and Accounting 265-358 at pin 17005714 line-for-line in guard order and arithmetic; theorem statements match README/PR claims; premises (keccak opacity, Separated, registered order, Nodup) are disclosed or implied. P-ACCOUNT-1 remains OPEN. No merge action taken.
