# P-ACCOUNT-1

Theorems: `PAccount1.source_report_before_reward`, `PAccount1.verity_tx_simulates_oracle_report`.
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Once per frame, `AccountingOracle.submitReportData` pushes a per-module validator-balance vector through `StakingRouter.reportValidatorBalancesByStakingModule`, then `Accounting.handleOracleReport` mints fee shares and only afterwards calls `reportRewardsMinted`. Rewards must be computed from the *just-written* balance snapshot, not from a stale or post-mint view. Getting that order wrong would mint fees against the wrong module weights.

The guarantee is meant to say: on an accepted report that mints a positive fee, the observable trace is exactly `balancesWritten → accountingCalled → rewardsRead(same balances) → rewardsMinted`.

## Modeling

- `A-SOURCE-SHAPED`: `ReportInput` is three lists (registered ids, reported ids, balances). No oracle committee, no hash consensus, no extra-data, no CL state, no vault transfers.
- `A-VERITY-SCAFFOLD`.
- `fullReportSucceeds : ReportInput → Nat → Prop` is a *free* hypothesis. The module comments that `accept` only covers the early router guards (length, order, `MAX_VALUE_GWEI`, uint64 accumulation) and cannot prove the rest of the report does not revert. The later Accounting / mint / `reportRewardsMinted` path is assumed, not executed.
- `handleOracleReport` does not call Accounting. It writes a map of balances, a total slot, and three *boolean flag slots* (`accountingCalledSlot`, `rewardsReadSlot`, `rewardsMintedSlot`) that stand in for those calls.
- Step list `successfulSteps` is a literal four-constructor list, not a recorded call journal.
- Storage slots 10–14 are model-local.

## Proof

**Abstract `source_report_before_reward`.** `sourceTrace` is `accept i >>= pure (successfulSteps accepted shares)`. `successfulSteps` is, by definition,

```
[balancesWritten bs, accountingCalled, rewardsRead bs]
  ++ (if 0 < shares then [rewardsMinted] else [])
```

The theorem assumes `0 < sharesToMintAsFees` and `sourceTrace _ = some trace`, unfolds the `Option.bind`, and closes by `rfl`. `fullReportSucceeds` is never inspected. No induction.

**SOURCE→word refinement `checkedTotal256_refines_source`.** Induction on the balance list: if the Nat `checkedTotal64` succeeds under `≤ 2^64-1`, each `safeAdd` succeeds and the word value equals the Nat total. This is the only non-definitional arithmetic in the abstract plane.

**VERITY `verity_tx_simulates_oracle_report`.** `handleOracleReport` re-checks `idsAndBalancesValid`, runs `txCheckedTotal` (a third copy of the same accumulator), writes the map and the flags, and returns `successfulSteps`. `observe` on success builds a `View` from **the input list** `i.balancesGwei`, the stored total, and `storedSteps` (which reads the flags the same function just wrote). `sourceView` is `accept` + `successfulSteps`. Equality is the third accumulator agreeing with `checkedTotal64` plus the shared step constructor. Rollback: `Contract.run` discards the dirty state on `OVERFLOW` and on the `failAfterWrites` hook.

## Issues

## Resolution

**Restated Lean/English.** `fullReportSucceeds` is named as an independent premise; the abstract is constructor order of `sourceTrace`, not `submitReportData`.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1, 5, 8, 10, 12 | A | Constructor `sourceTrace` / boolean flags named honestly. |
| 2 | A | `fullReportSucceeds` remains an unused parameter of the constructor theorem. |
| 3 | A | `observe` still uses the input balance list; not claimed as a map readback. |
| 4, 6, 7, 11, 16, 17, 19 | scope | Membership, caller, role, fee computation, packing, `submitReportData` in `missing`. |
| 9 | A | Abstract theorem is the positive-fee case. |
| 13, 15, 18 | A | `ofNat` / empty / non-unique ids documented. |
| 14 | A | `Contract.run` rollback is the spec. |


1. **The ordering theorem is true by construction.**
   The “trace” is not extracted from Accounting.sol. It is the list `successfulSteps` literally written in `AccountingCorrespondence.lean:86–89`. The theorem says that list equals itself under `0 < fees`. It cannot fail if the real `handleOracleReport` minted before reading balances; that call is not in the model.

   *Scenario that the guarantee is supposed to rule out, and does not.* Accounting is patched to call `reportRewardsMinted` *before* reading the freshly written module balances. `source_report_before_reward` still holds, because `successfulSteps` is unchanged. The CHECKED status does not track the deployed order.

2. **`fullReportSucceeds` makes the abstract statement conditional on an unproved oracle.**
   The parameter is bound as `_` in `sourceTrace` (`AccountingCorrespondence.lean:111`) and never inspected. Tests instantiate it as `True` (`AccountingVectors.lean`).

   *Scenario.* A report that passes `accept` (ids match, balances `≤ MAX_VALUE_GWEI`, uint64 sum OK) and then reverts in `collectRewardsAndProcessWithdrawals`. `hSuccess` can still be `True`; `source_report_before_reward` produces the four-step “success” trace. The later revert — and any prefix effects — are outside the theorem.

3. **`observe` does not read the written balance map.**
   `HandleOracleReportTx.observe` (`:112–116`) puts `i.balancesGwei` into the `View`, not `state.readMapUint moduleBalancesSlot _`.

   *Counterexample mutant that the headline theorem cannot kill.* Replace `writeAll` with a no-op (or write `0` for every id). Keep the flag slots and `txCheckedTotal`. `observe` still reports `[10, 20]` from the input. `verity_tx_simulates_oracle_report` still holds. The YAML “persists module balances through writeMapUint” is not an observed fact.

   The mutants file does *not* contain a wrong-map-write mutant. It has a bypass-order-guard mutant and an injected-after-writes hook — both about control, not about map contents.

4. **Rewards are not read from the snapshot.**
   `rewardsRead balances` carries the same input list that `balancesWritten` carried. There is no second read of storage after a hypothetical intervening write.

   *Scenario.* After `writeAll`, a re-entrant module callback overwrites `moduleBalancesSlot[1]`. `storedSteps` still emits `.rewardsRead [10, 20]` from the input. The “same snapshot” claim is the same `List Nat` appearing twice in a literal.

5. **`storedSteps` reconstructs order from booleans, so a mint-first write is invisible.**
   `HandleOracleReportTx.lean:103–110` always concatenates `[balancesWritten] ++ acc? ++ rd? ++ mint?` in that *fixed* order. It does not record write chronology.

   *Counterexample mutant.* Swap the three `writeSlot`s so `rewardsMintedSlot` is written first. `observe` still reports `[balancesWritten, accountingCalled, rewardsRead, rewardsMinted]`. `verity_tx_simulates_oracle_report` still holds. That is exactly the ordering bug the guarantee is named for.

6. **“Registered” module ids are an input list, not `SRStorage.getModuleIdAt`.**
   `idsAndBalancesValid` checks `reportedModuleIds == registeredModuleIds` (and lengths / `MAX_VALUE_GWEI`). Live `_validateReportValidatorBalancesByStakingModule` (SRLib 854–869) loads `n = getModulesCount()` and `getModuleIdAt(i)` from storage.

   *Scenario.* Feed `registeredModuleIds = reportedModuleIds = [99]` with one balance. `accept` succeeds. The router has no module 99. The CHECKED report is “the two lists you handed me agree,” not “the oracle reported every live module in router order.”

7. **`audit/source-map.yaml` maps `_handleConsensusReportData` 477–559; Lean does not execute it.**
   That span includes extra-data format checks, sanity checker, exited-validator updates, WQ `onOracleReport`, and the comment at 513–515 (“update balances before rewards”). The Lean `handleOracleReport` never calls `AccountingOracle` or `Accounting.handleOracleReport`.

   *Scenario.* Extra-data hash is nonzero while format is EMPTY. Live oracle reverts `UnexpectedExtraDataHash`. A non-member calls `submitReportData` without a matching consensus hash (`AccountingOracle.sol:360–365`: `_checkMsgSenderIsAllowedToSubmitData`, `_checkConsensusData`). Lean `accept` on the three lists still succeeds and `source_report_before_reward` produces the four-step success trace. The mapped span is not the theorem’s input.

8. **`.rewardsRead` is not a source step.**
   Deployed order after the router write is `handleOracleReport` → compute fees → `LIDO.mintShares` → `_distributeFee` → `stakingRouter.reportRewardsMinted` (`Accounting.sol:403–412`). There is no “read the same list again” call. Lean inserts `.rewardsRead balances` as a flag.

   *Scenario.* Accounting is patched to mint without ever reading the router map (it already has `feeDistribution` from `_simulateOracleReport`). Lean still emits `.rewardsRead [10, 20]`. The CHECKED four-step sequence is not the Solidity call order; “read then mint” is a story told with flags.

9. **Zero-fee path is excluded from the abstract theorem** (`hFees : 0 < sharesToMintAsFees`) but is the common “no fee shares this frame” production case (`Accounting.sol:403–413` skips mint).

   *Scenario.* `sharesToMintAsFees = 0`. Abstract theorem does not apply. Verity commits a three-step list without `.rewardsMinted`. A production frame with zero fees is the one the named guarantee is silent on.

10. **`storedSteps` always prefixes `.balancesWritten` with no flag.**
    `HandleOracleReportTx.lean:103–110` concatenates `[.balancesWritten balances] ++ acc? ++ rd? ++ mint?`. There is no `balancesWrittenSlot`. The other three steps are reconstructed from booleans; the first is hard-coded whenever `observe` is asked to build a success view.

    *Counterexample mutant.* Skip `writeAll` and still write the three flag slots plus the total. `storedSteps` still emits `.balancesWritten [10, 20]` from the input list. Combined with issue 3 (`observe` already takes balances from `i.balancesGwei`), a no-op map write is invisible *and* the “balances were written” step cannot be turned off. The CHECKED ordering starts with a constructor the storage never recorded.

11. **`sharesToMintAsFees` is an argument, not a fee computation.**
    Live `Accounting.handleOracleReport` obtains `sharesToMintAsFees` from `_simulateOracleReport` / `_calculateProtocolFees` on the just-written balances (`Accounting.sol:135–144`, `403–412`). Lean `handleOracleReport i sharesToMintAsFees` takes the number from the caller.

    *Scenario.* Balances `[10, 20]` should mint 0 (no reward delta). Caller passes `sharesToMintAsFees = 7`. Lean writes `rewardsMintedSlot = 1` and the four-step trace. The abstract theorem’s `hFees : 0 < shares` is satisfied by the same argument. The CHECKED “mint only after reading this snapshot” never computes a mint from the snapshot; it mints whatever the harness asked for.

12. **Three copy-paste accumulators plus a copy-paste step list.**
    `checkedTotal64` (Nat), `checkedTotal256` (word `safeAdd`), `txCheckedTotal` (another word `safeAdd`) are the same recursion. `verityTxSuccessfulSteps` (`AccountingCorrespondence.lean:93–97`) is character-identical to `successfulSteps` (`:86–89`).

    *Counterexample to independence.* Change the uint64 bound in all three accumulators to `2^63 − 1`, or drop `.rewardsRead` from both step lists. Source/Verity correspondence still holds. The CHECKED refinement cannot see a shared transcription of `_ensureAmountGwei` / the uint64 `+=` at SRLib 888. Same pattern as P-ALLOC-1’s `txBind = sourceBind`.

13. **`writeAll` / `txCheckedTotal` coerce ids and balances with `Uint256.ofNat`.**
    `HandleOracleReportTx.lean:58–59`: `writeMapUint moduleBalancesSlot (Uint256.ofNat id) (Uint256.ofNat bal)`. `idsAndBalancesValid` does not require `id < 2^24` (live module ids) or `id < 2^256`.

    *Counterexample.* `registeredModuleIds = reportedModuleIds = [0, 2^256]`, `balancesGwei = [10, 20]`. `accept` succeeds. `ofNat (2^256) = 0`, so both writes hit key `0`; last write `20`. `observe` still reports `[10, 20]` from the input (issue 3). Live `_addModule` never issues id `0` and cannot pass `2^256` (`uint24`). The wrap is invisible to the CHECKED View.

14. **The overflow arm writes maps *inside* the `Contract` body; only `.run` rolls them back.**
    `handleOracleReport` on `txCheckedTotal = none` returns `.revert "OVERFLOW" (writeAll … snapshot)` (`:75–76`) — dirty state as the revert argument. `Contract.run` then replaces it with the snapshot. `HandleOracleReportTxMutants.lean:71–74` *demonstrates* that the raw body leaves `moduleBalancesSlot[1] = MAX_VALUE_GWEI` on the 19×MAX overflow input.

    *Scenario.* A future caller invokes `handleOracleReport overflowInput 1` without `.run` (or a mutant `Contract.run` that kept the supplied revert state). The CHECKED `verity_tx_simulates_oracle_report` uses `.run`, so it still reports a clean revert View. The “executable transaction” as a `Contract` value is not atomic; atomicity is the interpreter wrapper. YAML “rolls every intermediate write back through Contract.run” is true of the wrapper and false of the body the mutants file itself inspects.

15. **An empty report is a success when `registered = []`.**
    `idsAndBalancesValid ⟨[], [], []⟩` is true; `txCheckedTotal [] = some 0`; `handleOracleReport` commits and, if `sharesToMintAsFees > 0`, still emits `.rewardsMinted`. Live `_validateReport…` (`SRLib.sol:858–861`) sets `n = getModulesCount()` and reverts `ArraysLengthMismatch` when the arrays are empty and `n > 0` (production always has ≥1 module).

    *Scenario.* Curated module registered (`n = 1`). Oracle submits empty ids/balances. Live reverts. Lean `handleOracleReport ⟨[], [], []⟩ 7` commits `total = 0` and a four-step “mint” trace. Combined with issue 6 (registered is an input), the CHECKED success/order theorem holds of a report the router cannot accept.

16. **Live balances are packed `uint64`; Lean writes a full word into an isolated map.**
    `SRLib.sol:884–891`: `uint64 validatorsBalanceGwei = uint64(_validatorBalancesGwei[i])` into `ModuleStateAccounting`, then `uint64 total +=`. Lean `writeMapUint` of a full `Uint256` into slot 10, total in slot 11.

    *Scenario.* A wide `SSTORE` of the packed accounting slot on chain clobbers neighboring fields (`exitedValidatorsCount`, …). Lean’s map write cannot. Conversely Lean can store a total word that is not a `uint64` field (the ≤ `uint64Max` check is only on the accumulator, not a packed encode). The CHECKED “balance write” is not the packed router word, so packing/truncation bugs are out of model.

17. **`handleOracleReport` is `accountingOracle`-only; Lean has no caller.**
    Live `Accounting.handleOracleReport` (`Accounting.sol:137–139`) reverts `NotAuthorized` unless `msg.sender == accountingOracle`. The Lean `handleOracleReport` is an unauthenticated function of three lists and a fee `Nat`.

    *Scenario.* An EOA calls `Accounting.handleOracleReport` with a well-formed `ReportValues`. Live reverts. Lean `verity_tx_simulates_oracle_report` commits the four-step trace whenever the lists match. Combined with issue 7 (mapped `_handleConsensusReportData` not executed), the CHECKED tx is not the authorized Accounting entrypoint. The “report-before-reward” order is a flag list written by whoever invoked `Contract.run`.

18. **Registered ids need not be unique or `uint24`.**
    `idsAndBalancesValid` is list equality. `registeredModuleIds = reportedModuleIds = [1, 1]` with two balances is accepted. Live `getModuleIdAt` yields a permutation of distinct ids. `writeAll` then writes id 1 twice; last balance wins. `observe` reports both input balances (issue 3).

    *Counterexample.* `[1, 1]` / `[10, 20]`. Lean commits total 30 and steps with `[10, 20]`. Map key 1 holds 20. Live cannot report the same module twice in router order. Combined with issue 13 (`2^256` aliases 0), the CHECKED “registered order” is not `getModuleIdAt`.

19. **Router write is `onlyRole(REPORT_EXITED_VALIDATORS_ROLE)`; Lean has no role.**
    Live `StakingRouter.reportValidatorBalancesByStakingModule` (`:285–289`) is `onlyRole(REPORT_EXITED_VALIDATORS_ROLE)` then `SRLib._report…`. Issue 17 is Accounting’s `accountingOracle` check. This is the *router* gate on the write the guarantee is named for.

    *Scenario.* A caller without that role invokes the router with matching id/balance lists. Live reverts. Lean `handleOracleReport` commits the four-step trace. Combined with issue 6 (registered is an input), anyone who can satisfy list equality can “write balances before mint” in the CHECKED tx. The named ordering is not an authorized router transition.
