# Independent review: funded source-byte TOPUP suffix

Verdict: **CLEAN** for exact candidate `163e3dc3038bf72e21b47b7a35f79244c353b7f1`, parent `f71fbcab599118c5e66484824bcee0e2c5a42f90`. No blocking or nonblocking finding identified within the stated bounded caller-side scope. This is not acceptance of full TOPUP-1, beacon execution or deployed EVM correspondence.

Reviewer: independent agent `/root/topup_units`, not author of either new TOPUP module or its tests. Project review was read-only, using the exact Git objects rather than assuming a stable checkout HEAD. Only this authorized report was written under `/tmp`. No new build, Forge run, project edit, commit, push or merge was performed.

## Scope and integrity

Read both new source modules, the entire new test file and all six audit artifacts. Examined the relevant modern `TopupTx` definitions, source deposit construction, caller primitive and frame entry, `TopupLiveWithdrawal`, `Pipeline`/`Live` execution and accounting frames, `TopupWeiBounds` bridge and opaque deposit-root boundary. Compared against the pinned Solidity withdrawal, receiver, allocation/value suffix, withdrawal-credentials helper and BeaconChainDepositor loop. The previously accepted withdrawal/pipeline review is reused only after verifying unchanged dependencies.

The candidate adds exactly nine files: two proof modules, one test module and six audit files. It modifies no registered `TopupTx`, common metadata, DEPOSIT file, accepted ALLOC/RESERVE foundation or pin. Its parent differs from accepted baseline `42210924cd58ff751d2472f5ea998383fed4be7f` only by the nine independent SSZ proof-fold additions.

Independently recomputed and checked:

- All 14 receipt input hashes and the matching 14 entries of `validated-inputs.sha256`.
- All three receipt log hashes: validation, axioms and source identity.
- All nine listed dependency files unchanged against accepted baseline Git objects.
- All three Solidity source hashes and complete file identities against `17005714f151e5502c559932319a3f2f74ac2436` and the local source files.
- `Contracts/Common.lean` against Verity Git pin `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`, the recorded SHA256 and local bytes; the candidate manifest records that same pin.
- Candidate `git diff --check`, source theorem count 14, new regression count 14 and eight principal axiom queries.

Principal source hashes:

- `TopupFundedSource.lean`: `821059b47c41a0cc3cedc2713a6fde256fff455a1f6c4871e3f3aa71ea7cc3c6`.
- `TopupFundedSourceTx.lean`: `019f6255dd60caa74af208f664a6dae2255292f6b3b7c020b2501084274bafcb`.
- Tests: `377554c2a3e14ecc96d8de6d655d1b1d2c5be1458ed0c139d84926d194efb8b2`.

## Proof assessment

`loop_run` inducts over the actual `TopupTx.sourcePushLoop`; it does not substitute legacy `pushLoop`, `scheduledDeposit` or `creditPull`. Its journal specification is a separate zip/filter selection of nonzero source-input/allocation pairs. Each emitted entry retains the actual source byte argument constructor. The induction proves successful helper guards, funded primitive execution, exact uint256 debit, ordered frame append and preservation of the other local fields. Bounds for the per-element cast and each subtraction follow from total available funds, rather than a supplied post-loop balance.

`source_deposits_run` uses `sourceDeposits call hw` and precisely `call.moduleReturndata`, with the delivered common-length theorem. `journal_value` reads the recorded values back and proves their mathematical sum. The source-derived public key, typed withdrawal credentials, dummy signature and deposit-root expression remain attached to the same paired input. This preserves the existing calldata-word representation; it does not independently prove raw ABI byte execution or the opaque SHA implementation.

The representation link is concrete: `project` reads the router's actual Nat ledger into the local caller word; `sourcePushLoop` performs the debit; `commit` reads its returned local balance back to that ledger account. Neither implementation operation inserts an expected aggregate credit/debit. `project_balance`, `ledger_roundtrip` and `push_run` justify those operations on the explicit word-representable domain. An unrelated stale incoming `core.selfBalance` is correctly overwritten from the ledger, and existing storage/call records remain available to the local loop.

`positive_conservation` uses one allocation list for the wrapped withdrawal total, the source input construction and the subsequent push values. The concrete accepted Lido pipeline derives funding, receiver authorization, ETH credit and event. The new loop result then derives router restoration, Lido debit and the exact appended value journal. The theorem does not assume the final Solidity assertion or any conservation output. Existing router funds need not be zero.

`hwidth` remains an explicit representation-domain premise, `oldRouterBalance + mathematicalSum < 2^256`; the report accurately does not call it a proven reachable protocol invariant. Its alternative discharge is useful and noncircular: #260 source-sized gateway limits and allocation guards derive exact sum, actual withdrawal funding bounds that sum by Lido's entry funds, and an independent initial two-account asset bound covers the old router funds. Reachability and physical extraction of these inputs remain open. The implementation retains wrapped-zero behavior, and a nonzero mathematical sum wrapping to zero is tested. Positive conservation does not silently claim the nonzero-wrap domain.

Generic configuration theorems are explicitly local-model statements. Pinned-source correspondence requires `pinnedConfig`, since source deposit construction uses literal `10^9`; `Guards` alone omits earlier router alignment/per-index checks. The README distinguishes this from the #260 bridge, which includes alignment. Thus the generic composer is not presented as proof of beacon success for arbitrary configured units or nonaligned allocations.

The outer `Live.run` supplies a common rollback snapshot across the withdrawal and later local push failure. The late-failure regression exercises this composed suffix; it is not evidence that its fixture passes every omitted outer module/router guard. Withdrawal attempts and beacon caller frames are deliberately separate channels. The retained callback is last only in the withdrawal attempt channel and its event list, not last in the global call order after beacon pushes.

## Validation and remaining scope

The retained targeted command builds both new modules and their tests. Its exact log records successful completion of 1266 jobs; only existing dependencies replay warnings. Eight queries report only `propext`, `Classical.choice` and `Quot.sound`. Three bridge/ledger queries omit `Classical.choice`; the remaining queries include it. No new sorry or native-checker axiom occurs.

The fourteen kernel regressions cover positive execution with old router funds, exact outgoing values and nonzero public-key ABI words after a zero skip, selector/length preservation, replacement of a stale caller balance, seed/withdrawal observations, a late guard failure with restored account balances and committed journal, wrapped-zero behavior and the `2^256` projection boundary. No new Forge suite or full repository build is claimed.

The remaining boundaries are material and correctly retained: the actual beacon callee, target balance/storage effects, ABI decoding, opaque SHA/precompile execution, gas/reentrancy, deployment and address provenance, root module/role/pause/target admission, physical gateway configuration extraction, unified call ordering and simulation of the unchanged registered parent. `externalCallBindTo` is the pinned caller debit/journal primitive with its name-based success stub; it does not execute or credit the beacon target. The new value equation therefore reduces the funded caller-side composition gap while leaving whole-protocol conservation unproved.
