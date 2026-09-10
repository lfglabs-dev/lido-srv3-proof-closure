# ACCOUNT report/getter/fee/mint continuation

Candidate source starts at `f75775708b62b078adbd69018ad268815755c9d9`; that base had no authoritative integrated build receipt. This dossier validates this bounded continuation and does not retroactively validate the base or replace its historical receipts. Independent review and root integration remain separate gates.

## Public consuming result

`LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint` consumes one successful `AccountAddress.ReportFeeMint.handleOracleReportFromCommittedFeeProducts` execution. It proves `Success`, whose existential witnesses expose the actual report result, the getter on that exact report-written router, the checked fee result, and the final router identity. It has no supplied successful stage, fee amount, auth equality, separation, balance frame, or log frame premise.

For zero minted shares it proves the StETH component unchanged and no mint events. For positive shares it exposes the actual `mintShares accountingAddress accountingAddress amount before.steth` execution and `MintEffect`:

- caller equals the independently resolved locator Accounting address, derived from the executed authorization guard;
- recipient is neither zero nor the token contract;
- low128 total shares increase by exactly the computed amount, remaining below 2^128;
- high128 external shares are unchanged;
- the complete physical storage component is exactly its pre-mint value with the pinned total-share word replaced by `setLowUint128`;
- every abstract account-map entry equals its old value plus the amount exactly at the recipient key;
- conversion executes on the actual post-mint state and emits the paired Transfer/TransferShares payloads.

`actual_report_fee_mint_failure_restores` proves equality of the whole composed rollback World with the initial World, including both router and StETH storage, account map and context. A late mapping-add or event-conversion failure therefore restores earlier report writes and prospective mint updates. This is transactional function semantics, not a newly proved EVM root frame.

## Exact Solidity correspondence and retained boundaries

All source references use `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`. The receipt records full bytes of the relevant pinned files.

| Model stage | Pinned source extent | Boundary |
| --- | --- | --- |
| Existing `ReportWriteFee.reportValidatorBalances` and getter | SRLib report accounting writes and StakingRouter getStakingRewardsDistribution | Reuses accepted physical-word / supplied-layout model. Registry admission, deployed addresses, keccak derivation and arbitrary Nat layout correspondence are not newly proved. |
| `checkedFeeProductsFromCommittedGetter` | Accounting.sol 265–301, 306–333 | Consumes the actual getter result. ReportWei fields are the supplied report/calculation snapshot; omitted report-prefix operations do not derive them from this StETH state. All nine Nat word inputs receive uint256 admission checks, followed by checked additions, subtraction, multiplication and division. |
| `checkedFeeResultOf` / checked module loop | Accounting.sol 335–358 | Checks each module product, division, running addition and final treasury subtraction before minting. The actual getter constructs the parallel arrays; no caller supplies an arbitrary Distribution to the public composed executor. |
| Positive mint call | Accounting.sol 403–406; Lido.sol 894–900 | Calls the modeled Lido mint with independently supplied Accounting caller/recipient. It does not execute `_distributeFee`, `reportRewardsMinted`, rebase observer or subsequent calls. The intervening source operations before line403, including collectRewardsAndProcessWithdrawals, are not claimed executed by this composed function. |
| Mint writes and events | StETH.sol 518–527, 559–571; conversion329–334; Lido share-rate overrides | Packed total/external storage is physical. Shares is explicitly an abstract `Nat → Nat` account map, not a proved physical keccak mapping. Locator resolution, self address and active flag are supplied call context, not actual external locator CALL or proved deployment storage. Source auth and pause guards execute. The initial address-width guard is admission of Nat-encoded addresses, not an extra Solidity branch. |

Router and StETH are separate modeled state components; this is not proof of deployed address separation, cross-contract aliasing or dynamic CALL dispatch. The theorem establishes the explicitly defined report/getter/fee/mint composition, not an uninterrupted execution of the full Solidity handleOracleReport body. Prior broader ACCOUNT statements remain unmodified except the unaccepted event consumer's caller wiring and wording.

The post-mint conversion retains Solidity0.4 raw uint256 multiplication and subtraction behavior. The internal ether is read from the existing two physical packed words. It does not silently use pre-mint share rate, total pooled ether or the external-share half as total shares. The accessed recipient map addition and total addition execute uint256 checks; successful total shares also satisfy the source128-bit cap. The map as a whole remains abstract on arbitrary Nat keys.

## Arithmetic order evidence

Pinned hardhat.config.ts selects solc0.8.9 legacy code generation, optimizer200 and evmVersion istanbul (the separate0.8.25 configuration uses viaIR). `FeeOrder.sol` is a small expression fixture, not a compiled full Accounting contract. Its retained legacy assembly evaluates `postEther - feeEther` before `feeEther * shares`; the diagnostic IR evaluates the product first. The legacy assembly therefore supports denominator-first for this expression/compiler path; no language-wide left-to-right guarantee is asserted. Both the active Nat consumer and the older standalone Source.ReportFeeProductsCorrespondence helper now use denominator first. Both erase panic subcodes into Option/feeArithmetic rejection; underflow versus overflow ordering does not become an observable error distinction in these models. No fresh Solidity runtime or complete-source bytecode test is claimed.

## Validation

- Isolated account-address package: seven jobs PASS, including ReportFeeMint, StETHMintShares and the existing report/mint tests.
- New `Tests/Verity/ReportFeeMintTest.lean`: eight `decide +kernel` regressions PASS: report/getter/mint/rate; distinct Accounting rejection; zero-fee skip; packed cap failure; word overflow; module distribution product overflow; post-mint event denominator failure; map-add overflow. Seven use only the standard foundational axioms; the standalone distribution-product regression has none. These are kernel checks, not FFI/native-reduction receipt axioms.
- Direct scoped root Lean checks: Source.ReportFeeProductsCorrespondence, HandleOracleReportTx and public PAccount1 PASS. Axioms.lean records ten exact theorem closures, each limited to propext, Classical.choice and Quot.sound (or a subset).
- Strict source annotation checker, using this checkout's root Audit and isolated account-address files against the pinned local core:863 citations, zero false and zero quote mismatches. This is a citation check, not a Solidity equivalence theorem.
- Three physical slot constants independently recomputed with `cast keccak`: all match their pinned Solidity constants. This is a runtime identity check, not a Lean keccak theorem.
- Existing root proof-escape checker:539 project files PASS, preserved native_decide inventory. Package theorem axiom queries separately cover the new transitive consumers.
- `check_receipt.py` checks the exact recorded hashes and validation log contents, including pinned source bytes.

Normal kernel checking of the original concrete nested-case proof was expensive. The final code shares private runRoot/runStages match helpers between execution and generic control-flow lemmas, preserving the same branches while avoiding repeated kernel normalization across independently generated matchers. A temporary skipKernelTC diagnostic identified the bottleneck; it was removed and supplies no retained theorem or validation evidence.

## Integration handoff

The exact duplicate-provider failure is retained in `mint-build.log` as a diagnostic, not a passing build. Base f757 adds a path dependency `accountAddress` although the root already provides AccountAddressChecks. Root owns removing the redundant dependency/manifest entry and adding StETHMintShares, ReportFeeMint and Tests.Verity.ReportFeeMintTest to the existing root provider. This candidate changes no global AllGuarantees, Trust, Lake file or manifest. Consequently this dossier claims scoped direct checks, not a new full All/Trust run. A root integration build and independent full unaccepted-branch/source review must precede credit.

The old StETH examples used undecidable Outcome equalities (State contains a function); their executable regression observations now use Boolean projections and kernel reduction, preserving auth/pause/overflow priority and packed/mapping/event checks. The new full rollback theorem supplies the universal state equality.
