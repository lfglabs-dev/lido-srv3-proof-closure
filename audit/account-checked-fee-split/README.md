# ACCOUNT: checked fee split consumed by the actual mint

Base: `70301660264f2f710e7160e190aaa3af330e84fa`.
Lido source pin: `17005714f151e5502c559932319a3f2f74ac2436`.
Public theorem: `LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_checked_split`.

## Exact increment

Success of the existing `handleOracleReportFromCommittedFeeProducts` now implies, jointly:

- the previous report → same post-report getter → actual checked fee calculation → actual physical mint `Success`;
- the previously derived exact post-report uint96 fee casts for all registered IDs;
- equal recipient/ID/module-share list lengths;
- a distribution read from that same returned router, whose actual checked products return the very same `fee` consumed by the mint;
- `sum(fee.moduleSharesToMint) + fee.treasurySharesToMint = fee.sharesToMintAsFees`;
- for a positive mint, every positional module amount is precisely `floor(fee.sharesToMintAsFees * moduleFee / distribution.totalFee)`, with positive total fee derived from execution and the exact original recipients/IDs; for a zero mint, all three distribution lists are empty.

The positive map includes zero-fee entries as zero. It does not claim Solidity executed division for a skipped zero-fee row. The zero-mint branch bypasses the whole distribution routine, including its positive-total-fee assertion, as the source does.

No new executable, domain restriction, distribution equality, total-fee positivity, running-sum bound, arithmetic-success or mint-success premise is supplied. The only public hypothesis is the existing complete covered executor's success. This increment retains previous useful claims and strengthens their conjunction; it does not assert subsequent fee transfer calls.

## Proof and source correspondence

`Accounting.sol:335-358` calculates the distribution before the `Accounting.sol:403-406` mint. The former multiplies each nonzero module fee by the minted quantity, divides by the total fee, adds each module amount to the running total, and subtracts the total from minted shares for treasury. All these are checked Solidity 0.8 arithmetic in the pinned source.

The new private induction in `ReportFeeMint.lean` consumes the existing `checkedModuleShares` success. It recovers each exact checked product/division, proves the returned list equals the positional floor map, and relates the returned running accumulator to the mathematical sum. `checkedFeeResultOf_split` then consumes the existing checked subtraction guard to derive exact conservation, rather than assuming the module sum fits the minted amount. Zero mint is handled separately with exact empty lists. The existing representation performs a checked addition of zero for a zero-fee row; that operation cannot reject on the reachable bounded accumulator and introduces no new public condition.

`checkedFeeProducts_split_origin` follows all eleven preceding word/add bindings, the source branch, and the seven checked reward/fee/share operations to the exact `checkedFeeResultOf` invocation. The higher consumer extracts the same distribution/fee from existing `committed_success`, and the list lengths from the same getter's `getter_ok_spec`. It preserves the prior cast invariant by using `composition_exact_casts` on the same input, world and committed result.

Only new theorem blocks are inserted into `ReportFeeMint.lean`. `preservation.json` verifies that removing this precise block recovers every byte of the base file: all executable definitions and all previous theorem statements/proofs remain unchanged. New files define propositions and proofs, not another executor. `AllGuarantees`, `Trust`, root registration files, package pins and site files are untouched.

## Checks

`build.py` builds the registered public cast consumer and existing mint tests (26 Lake jobs), then compiles the three new modules in dependency order using the same Lean environment and explicit `.olean`/`.ilean` outputs. This avoids unauthorized registration-file edits. Root integration must register these new modules and rerun its normal All/Trust gate after independent review.

Ten new named kernel regressions verify:

- two nontrivial floors (`11 * [2,3] / 7 → [3,4]`) and treasury remainder 4;
- a retained zero-fee row (`[3,0,4]`);
- zero-mint skip even when total fee is zero;
- checked multiplication overflow, running-sum overflow, and treasury subtraction rejection separately;
- an actual three-row report/getter/checked-product/mint with two rounding losses and a zero-fee row: exactly 10 shares minted, partitioned `[2,0,2] + 6`, packed total shares 20, recipient shares 15 and actual mint events;
- the public joint consumer instantiated on that actual successful execution;
- actual zero-mint state preservation despite unauthorized accounting caller (mint is skipped);
- actual arithmetic rejection restoring the initial router and StETH storage.

The first six have no axioms. The composed tests and theorem use only the existing Lean foundations. `validate.py` independently queries exact kernel dependency closures, verifies all actual prerequisite import-source identities and 11 pinned packages, checks the proof-only base-file preservation, and compares five complete Solidity source bodies to the pinned Git objects. No new Solidity fixture/compiler execution is claimed: executable Lean and Solidity inputs are unchanged, and this increment proves the missing connection between them at the already scoped source-model level.

Reproduce:

```sh
python3 audit/account-checked-fee-split/build.py
python3 audit/account-checked-fee-split/validate.py
```

## Boundaries and acceptance

This is the existing bounded report/getter/checked-fee/mint source-corresponding model, not the full oracle report or general compiled EVM equivalence. Supplied report snapshots/layout/components and the existing physical total-share/abstract account-share boundary retain their scope. The later `_distributeFee` transfers, reward callback, observers and rebase are outside this result; this theorem proves a calculated partition of the quantity actually minted, not its subsequent payout. Existing compiler, Verity, crypto, gas and consensus boundaries are unchanged; no stronger assumption is introduced under those labels.

Independent exact source/Solidity review and root facade/Trust integration remain pending. This is a candidate dossier, not a delivery verdict.
