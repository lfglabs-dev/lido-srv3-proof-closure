# Independent ACCOUNT treasury source/Solidity review — CLEAN

Exact head: `a7ea281e72298cc09239ed8a5e94f92eae2d03ce`.
Worktree: `/tmp/lido-account-treasury-call`.
Base: `eee5d6700e5d99cc35eab7bf3e1e2b51a2465857` (accepted ACCOUNT322).
Pinned core: `17005714f151e5502c559932319a3f2f74ac2436`.
Independent reviewer: `/root/topup_memory_exact_review`, who authored none of the candidate; author stopped before review.

**CLEAN for the stated additive typed ACCOUNT treasury-call increment. No blocking correctness, composition or source-correspondence finding.** One explicitly accepted formatting exception preserves raw assembly stdout: Git diff-check reports its final blank line. This is not an unconditional diff-check PASS or a new proof claim.

## Complete new source and composed public meaning

Read all four new Lean sources completely: `TreasuryCall.lean` (75 lines), `ReportFeeTreasuryCall.lean` (160), public `PAccount1TreasuryCall.lean` (31), and `ReportFeeTreasuryCallTest.lean` (96). Read the complete new fixtures, dossier, command/build/validator/receipt scripts before selecting non-mutating checks. The Git delta contains only additions: these four Lean files and the new treasury dossier, with no modification of ACCOUNT322 executors, definitions, domains or global wiring.

`ReportFeeTreasuryCall.execute` consumes the actual `ReportFeeMint.handleOracleReportFromCommittedFeeProducts` result. It does not accept a supplied mint, fee product, intermediate World or stage-success certificate. Positive mint enters actual sequential module transfers. Only after those transfers succeed, and only when treasury shares are positive, `TreasuryCall.call` is evaluated on `{minted with steth := middle}`: the same real ACCOUNT router/core plus the module transfers' actual returned StETH state. The readonly interpreter type is `Live.Request → ReportFeeMint.World → StaticCall.Reply`, not a fictional projection into a fresh `Live.World`. There is no returned mutable World to discard from a supposedly successful static operation.

The successful call's decoded Nat recipient directly enters `FeeDistribution.transferShares` on that same middle state. Events and payments append in actual module-then-treasury order. Failure records the real call fault/bytes and attempts; the enclosing executor restores the complete incoming ACCOUNT World, including prior report writes, mint and module transfers. Zero mint skips distribution/read entirely. Zero treasury allocation skips the read after module transfers. A successful read followed by ABI rejection retains the accepted read attempt; zero-address ABI success reaches the transfer's own zero-address failure.

`TreasuryCall.read` fixes the former arbitrary resolver to this actual call and only participates in the mathematical projection to accepted ACCOUNT322. `distribute_success` proves the existing distribution execution has precisely the same post-StETH/events/payments, while preserving the router. `execute_success` derives the existing full `ReportFeeDistribution.Success` and `Ledger` for this same mint and post-World. No second external call occurs in the new executable definition; projection equalities are proofs, not runtime effects.

I expanded `Success`, `Ledger`, `ReportFeeCheckedSplit.Success`, `FeeDistribution.Success`, `TransferEffect`, payment chains and the relevant mint execution. The public conclusion retains checked report/getter/mint/casts/split, derived funding, paired mint/transfer events, actual ordered payments, and `paid payments = actual minted fee shares`. The pointwise final ledger includes duplicate/self recipients. `ReadEffects` identifies the exact post-module call World, raw bytes, canonical decoded recipient and successful transfer of that recipient, with exact payment/event/attempt order.

The request uses a uint160 address projection of a Nat caller. Crucially the positive successful transfer derives `caller < 2^160`, and the proof derives request.caller.val = caller; this is not an added caller-width premise. The new theorem has only whole-execution success as its execution hypothesis. No new ABI, code-presence, frame, alignment, sum or stage-success assumption hides a correspondence gap.

## Pinned source, constants and assembly

Reviewed the complete relevant pinned Accounting mint/distribution suffix, exact `_distributeFee` body, inherited StETH transfer/mint/events and Lido share-rate functions. Accounting distributes module recipients sequentially, skips zero module allocations, then conditionally evaluates `LIDO_LOCATOR.treasury()` before passing that address to `LIDO.transferShares`. The fixture's entire `_distributeFee` source body is byte-identical to pinned Accounting, and both inherited harness bodies are byte-identical to accepted ACCOUNT322 fixtures.

Reviewed complete pertinent retained assembly sequences: module loop/transfer, positive treasury branch, locator preparation/code guard/STATICCALL, failed-return bubbling, successful decoder dispatch, full signed head decoder tag57 and canonical address validator tag66, then the actual treasury transfer calldata/CALL. The locator immutable is address-masked. The exact four-byte selector is **0x61d027b3**, independently recomputed using `cast sig treasury()`. Independently recomputed `transferShares(address,uint256)` as **0x8fcb4e5b** and checked it against assembly. The static request's logical value is zero; actual STATICCALL carries no value operand.

The EXTCODESIZE check precedes STATICCALL: absent code gives empty failure without an attempted external. Failed STATICCALL bubbles returned bytes. Success checks signed uint256 `(dataEnd-headStart) < 32` before reading the address word, then requires equality to its low160-bit cleanup. `decodeAddress` implements the equivalent projected-size condition (size below32 or high signed bit set rejects), then rejects values >=2^160. Trailing bytes remain accepted; canonical zero is admitted by the decoder. There is no invented canonical padding-length requirement, no low160 truncation of a noncanonical returned word, and no code-presence premise supplied to the theorem. The allocator/copy/pointer relation omitted from this scalar byte-view decoder is expressly outside its claim.

I paid particular attention to inherited literals rather than assuming accepted ancestry made constants correct. These three actually consumed literals match exact pinned Git bodies numerically and textually:

- totalSharesPosition: `0x6038150aecaa250d524370a0fdcdec13f2690e0723eaf277f41d7cae26b359e6` (StETH).
- bufferedEtherAndDepositedPostReportPosition: `0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f` (Lido).
- clValidatorsAndPendingPosition: `0x096e465397f38e659238ccd5d5a2c434ced54a63fd8d694045bfb058ab9d8112` (Lido).

The inherited router accounting +3 and module accounting +2 offsets match pinned SRTypes layout; those auxiliary SRTypes/SRStorage bodies were separately matched against pinned Git. The router base/module mapping keys remain the inherited explicit Layout boundary. StETH transfer guard order, sequential debit-then-credit (including self transfer), paired events and post-state share conversion remain unchanged. The packed total/external uint128 split and Lido internal-ether/share-rate override agree with the source. No new invented share storage slot appears.

## Independent checks and execution evidence

All checks ran locally; no paid resources, other models, external publication or candidate mutations were used.

- All **28 candidate receipt hashes** recomputed and matched.
- All **37 actual source identities** matched disk and either base Git bodies or pinned package Git bodies. Reconstructed both prerequisite setup import closures plus the four sequential modules, verifying cached setup source paths and current local olean byte equality where prerequisite setup paths point outside the worktree. All **11 package HEADs** match the manifest and receipt pins.
- All **five recorded complete pinned Solidity bodies** matched pinned Git. Verified **29 retained StETH dependency identities**, including pinned core source bodies; fixture sources are unchanged from accepted ACCOUNT322. Verified every actual metadata source Keccak across **32 distinct compiler inputs**, not just a fixture filename or marker.
- All **four compiled artifact snapshots**, metadata versions/settings and assembly digest matched. The raw `DistributionHarness.asm` is 38,062 bytes; the artifact's assembly string is 38,061 bytes. They are identical except the raw stdout's additional terminal newline. `git diff --check` reports exactly `DistributionHarness.asm:1609: new blank line at EOF`; this sole known raw-output preservation exception is explicit and nonblocking. No source/semantic difference is hidden by the exception.
- Independently recomputed **18 actual-environment axiom scopes** using the existing isolated `Lean.collectAxioms` probe. Exact agreement with the retained sets; union is only `propext`, `Classical.choice`, `Quot.sound`.
- Freshly re-elaborated each of the four exact Lean sources using `lake env lean <source>` without output-artifact options. All returned exit0; this independently checks the new ordinary-kernel proofs and **12 kernel regressions/public consumer checks** against the identity-verified cached imports. No source/olean/receipt/log was written. The **35-job prerequisite build** is reused from its verified receipt, not represented as a new full build.
- Reviewed all **nine fresh author-run Foundry tests**, their complete fixtures and identity-verified successful log: actual sender/selector/four-byte calldata/post-module share observation and consumed trailing-byte address; short/noncanonical reply failures; exact `dead` bubbling; actual SSTORE failure under STATICCALL; zero-address transfer failure; missing-code rejection with prior mint/payment rollback; and both zero skip branches. The readonly violation uses an actual SSTORE, not an interpreter assertion. No-code tests credit rejection/rollback, not intercepted empty revert bytes. I did not rerun these unchanged fixtures or claim a fresh independent Forge execution.

Compiler metadata is solc **0.8.9+commit.e5eed63a** and inherited StETH **0.4.24+commit.e67f0147**, optimizer200, common fixture **Byzantium**. It is not production bytecode/profile equivalence. The RawTreasury fixture observes actual module effects on real inherited StETH; its harness setup/mint and rate overrides remain explicit. Its large static-write gas number establishes no gas theorem.

## Preserved limits and final state

The immutable locator and address-indexed code metadata are supplied context, not deployment-provenance proofs. The arbitrary external is readonly over the accepted ACCOUNT World; no correctness claim is made for a particular deployed locator implementation. Existing separate router/StETH components, abstract shares mapping, earlier locatorAccounting authorization input, and uncomputed physical mapping derivation retain their accepted scope. The scalar byte view does not establish full returndata memory/copy/alias/pointer execution. The report prefix, reportRewardsMinted callback, rebase/full-report suffix, compiler/Verity/crypto/gas/consensus boundaries remain outside this increment. No stronger general Ethereum theorem or full production Accounting/Lido simulation is implied.

Final reviewed head remains `a7ea281e72298cc09239ed8a5e94f92eae2d03ce`; worktree is clean. The only durable review write is this external campaign report. Source review complete; stopped without modifying the candidate or publishing externally.
