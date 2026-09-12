# ACCOUNT: checked fee mint followed by actual typed share distribution

Base: `241c2ce1e78860b8451a843949b71f60b8c2df25` (reviewed/integrated checked split #319).
Lido core pin: `17005714f151e5502c559932319a3f2f74ac2436`.
Public consumer: `LidoSRv3.Audit.Guarantees.PAccount1.actual_report_fee_mint_distribution`.
Public rollback: `actual_report_fee_distribution_failure_restores`.

## Public claim and exact composition

The new executor consumes the existing report/getter/checked-fee/mint result, and passes that *same* `FeeResult` to the Accounting fee distribution. Positive module allocations are transferred in recipient-array order; zero entries are skipped. A positive treasury allocation resolves the treasury from the actual post-module state and then transfers that allocation. Zero mint skips the distribution entirely; zero treasury skips the resolver.

Success simultaneously establishes:

- the full previous checked report/mint/split/cast certificate at the actual intermediate minted world;
- available Accounting shares at that world cover the minted fee quantity, derived from the actual mint;
- unchanged post-mint physical packed storage throughout distribution, and the unchanged post-report router;
- every executed transfer with its exact caller/recipient/amount, intermediate before/after states, source guards, checked debit/addition, returned token amount and paired events;
- the actual sequential module-transfer chain, actual conditional treasury read on its returned state, and actual subsequent treasury transfer;
- exactly the original mint events followed by those distribution events;
- the sum of actual payment amounts equals the same minted fee quantity;
- for **every** account, final abstract shares equal its initial shares plus the actual payments received. Duplicate recipients and Accounting self-recipients are admitted without special assumptions.

Failure restores the complete incoming report world: report writes, mint, and every prior successful transfer. Diagnostic typed transfer arguments remain in the returned attempt list; that list is not an EVM trace or committed event log.

Only success/failure of this complete covered executor is a public premise. Array alignment and exact fee partition come from #319; funding comes from mint; per-call guards and arithmetic facts come from execution. No supplied successful stage, fee equality, global balance bound, distinct recipient assumption, callee frame or external funding premise is added.

## New explicit external boundary

`FeeDistribution.TreasuryRead : StETHMintShares.State → Except Nat Nat` is a **typed read-only external treasury resolver on the actual post-module state**. Its returned address is consumed by the transfer; an error aborts the root. This is separate from the pre-existing supplied `locatorAccounting` context. Its correctness as the deployed locator's return, ABI decoding, revert bytes and actual STATICCALL implementation are **not proved by this Lean model**. This new scope condition must remain visible in any published distribution claim. It is not silently folded into a general compiler or Verity boundary.

The Solidity fixture checks the source interface compiles to STATICCALL for this getter and executes after the module effects, then ordinary CALL for the final StETH transfer. That runtime check supports the declared read-only degree, not a universal implementation theorem for the supplied resolver.

## Source correspondence

`Accounting.sol:403-407` mints before `_distributeFee`, and skips both for zero mint. Lines 470-488 iterate recipients, read the corresponding allocated amount, skip zero, call `LIDO.transferShares`, then conditionally resolve `LIDO_LOCATOR.treasury()` and transfer treasury shares. The checked split consumed here derives the equal recipient/amount lengths from the actual getter and the mathematical partition from checked fee calculations.

`StETH.sol:494-507` checks sender nonzero, recipient nonzero/not StETH, active status and sender funding in that order. It writes the sender debit, then **reads the recipient after that write** before checked addition. `FeeDistribution.debit/moved/transferShares` preserve this ordering; sender=recipient therefore restores the original balance rather than creating shares. The initial address/amount checks admit Nat representations into the Solidity word/address domain; they are explicitly model admission, not additional source revert branches.

`StETH.sol:365-369,329-334,562-565` then converts using the returned state and emits Transfer followed by TransferShares. The existing `pooledEthByShares` helper keeps Lido's post-share-rate packed storage reads, uint128 amount guard, raw uint256 multiplication/subtraction and denominator checks. Transfers do not change those packed words. There is no recipient callback in this source path, and none is invented.

`PaymentChain` does not merely carry a claimed payload: every constructor contains the equality for the exact executed `transferShares` and its derived `TransferEffect`, with one returned state feeding the next call. Its aggregate ledger is proved by induction over those actual transitions. Combining its sum with the consumed checked fee split cancels Accounting's mint/debit and yields the final pointwise credited-share result, including aliases.

The account-share map remains the previously accepted abstract Nat-keyed map, not a new formal keccak storage-layout proof. Physical total/external share words and the other packed state are preserved exactly. The broader report prefix, locator ABI/CALL implementation, `reportRewardsMinted`, observer/rebase calls and full deployed Accounting/Lido entry remain outside this increment. Accepted compiler/Verity/gas/crypto/consensus boundaries retain their scope.

## Lean verification

`build.py` first builds the existing public split consumer and tests (29 Lake jobs), then sequentially compiles the four new modules with the same Lean environment. No lakefile, manifest, AllGuarantees, Trust or existing source is changed. Root integration must register the new package modules and run its global gate after independent review.

Nine named kernel regressions cover:

1. actual report/checked split/mint/distribution: 10 minted shares, module payments 2/0/2, treasury 6, actual recipient balances, packed halves and eight ordered events;
2. the complete public success/pointwise-ledger consumer instantiated on that actual execution;
3. repeated Accounting self-recipients, including treasury;
4. a later recipient addition overflow restoring the report, mint and earlier module transfer;
5. zero mint skipping a rejecting resolver;
6. zero treasury skipping a rejecting resolver;
7. sender-zero rejection preceding paused/recipient checks;
8. post-debit conversion rejection rolling back the mapping writes;
9. raw share-rate multiplication wrap in a successful actual transfer.

`validate.py` independently recomputes kernel axiom closures, pins and actual prerequisite import-source identities. Cached setup paths from the accepted integration checkout are compared byte-for-byte with current source and local imported oleans before reuse. Every inherited local source matches the base Git body; no whole-build repetition is used as a substitute for this identity check.

## Fresh Solidity checks and their exact scope

Eight fresh Foundry tests execute **unmodified inherited full StETH0.4.24**, including its private mapping operations, using a setup/virtual-rate harness. The full Accounting `_distributeFee` function is copied byte-for-byte from pinned Accounting0.8.9 into a small caller harness. Its external StETH CALLs and treasury STATICCALL are real runtime calls. Tests verify transfer/event order and amounts, the resolver observing actual post-module balances, duplicate/self recipients, late-overflow rollback, both zero skips, guard order, conversion rollback and raw multiplication wrap.

This is a distribution-function fragment/full-StETH test, not a full deployed Accounting/Lido/report test. The harness exposes setup writes and `_mintShares`; it does not reproduce Lido mint authorization or calculate protocol fees. The Lean composed regression separately consumes the actual accepted report/fee/mint model. The StETH harness's numerator/rate overrides and mapping-slot setup are explicit fixture choices; runtime `sharesOf` checks validate setup, but do not establish a universal formal physical mapping theorem.

`prepare_solidity.py` copied 29 complete original StETH dependencies. Core files match the pinned Git bodies; Aragon OS4.4.0 and OpenZeppelin Solidity2.0.0 match the core package versions and verified registry tarball integrities. `solidity/check.py` verifies all 32 actual compiler input keccak identities from metadata and retains three compiled artifacts. Legacy assembly from the compiled Accounting fragment explicitly shows treasury STATICCALL and module/treasury CALLs.

Compiler versions: 0.4.24 and 0.8.9, optimizer200, common **Byzantium fixture target** so both compilers run together. This is not a production-bytecode/profile equivalence claim. The original Aragon compiler warnings and Foundry's gas reporting are retained; no gas result is claimed. No fresh paid compute/resource was used.

Reproduce:

```sh
python3 audit/account-fee-distribution/build.py
python3 audit/account-fee-distribution/validate.py
forge test --root audit/account-fee-distribution/solidity -vv
forge inspect --root audit/account-fee-distribution/solidity DistributionHarness assembly
python3 audit/account-fee-distribution/solidity/check.py
```

Independent exact source/Solidity review and root global integration remain pending. This dossier is a candidate record, not delivery or publication acceptance.
