# P-ACCOUNT-1

> Round 2 (2026-08-21). Product note plus proof audit, arbitrated from GPT 5.6 Pro and Opus 5. Fable 5 was unavailable (data-retention gate). Kimi K3 was not an allowed Task model. No em dashes. Lean is authority.

Once per frame `AccountingOracle.submitReportData` pushes a per-module validator balance vector through `StakingRouter.reportValidatorBalancesByStakingModule`, then `Accounting.handleOracleReport` derives the fee distribution from that fresh router state, mints the fee shares, and records them last through `reportRewardsMinted`. Recording the mint before the fresh read would pay fees against stale module weights.

P-ACCOUNT-1 verifies that ordering as an execution-order discipline:

- registered parent `mint_after_read_discipline`: on every committed run, $0 < \mathrm{mintTick} \Rightarrow \mathrm{readTick} < \mathrm{mintTick}$
- $\mathrm{tick} = \mathrm{sequenceSlot} + 1$, from a transaction-local clock reset at the top of the commit branch
- zero fee shares write $\mathrm{rewardsMinted} = 0$, matching the pinned skip, and the implication then holds with nothing to order
- reverting runs carry no ordering obligation

Because the tick is read from state rather than written as a call-site constant, moving a step write changes the tick it records. That is what makes `mint_order_kill_line` a control-flow fault: the mint stamp moves above the read stamp with no literal edit, mint records $3$ and read $4$ after the stamped balance write, and the same predicate rejects it.

`verity_tx_simulates_oracle_report` equates observe with an independently stated source view. We do not prove the fee amount: `sharesToMintAsFees` is an argument. Constructor order on the source plane is the demoted child `source_report_before_reward`.

## Proof limitations and recommendations

The parent is an unbounded $\forall$ over every report, fee, and state. Invalid, overflowing, and zero-fee commits discharge vacuously. The demoted source child now uses premise-free `sourceTraceRetired`; the legacy `fullReportSucceeds` API remains only as a compatibility adapter. `storedSteps` compares exact ticks, so the reordering is also visible at the View boundary.

The kill-line now uses the valid nonempty report `⟨[1], [1], [1]⟩`. The balance write has its own clock stamp, so `storedSteps` no longer invents `.balancesWritten` unconditionally. `.rewardsRead` still has no counterpart in the pinned call sequence (the deployed order is write, compute fees, mint, `reportRewardsMinted`). Fee computation and `submitReportData` stay in `fidelity.missing`.

CHECKED does not mean the pinned path mints after reading fresh balances, that the caller is authorized, or that the minted amount is the protocol fee.

Ranked next work: keep the retired source child premise-free and the mint-after-read parent/kill-line intact; model later full-report failures only if widening to that surface is explicitly authorized.

Theorems: `PAccount1.mint_after_read_discipline` (registered parent), `PAccount1.mint_order_kill_line` (kill-line, refutes the parent), `PAccount1.verity_tx_simulates_oracle_report` (Verity child), `PAccount1.source_report_before_reward` (child, source-plane correspondence).
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Once per frame, `AccountingOracle.submitReportData` pushes a per-module validator-balance vector through `StakingRouter.reportValidatorBalancesByStakingModule`, then `Accounting.handleOracleReport` mints fee shares and only afterwards calls `reportRewardsMinted`. Rewards must be computed from the *just-written* balance snapshot, not from a stale or post-mint view. Getting that order wrong would mint fees against the wrong module weights.

The registered guarantee (`mint_after_read_discipline`) is the tick-order discipline: on every committed run of the real `handleOracleReport`, `0 < mintTick → readTick < mintTick` — the `rewardsReadSlot` tick is written strictly before any nonzero `rewardsMintedSlot` tick, read directly off the two raw tx-storage ticks rather than through `storedSteps`'s presence-only check. The earlier headline — on an accepted report that mints a positive fee, the observable trace is exactly `balancesWritten → accountingCalled → rewardsRead(same balances) → rewardsMinted` — is the demoted child `source_report_before_reward` (issue 1: constructor order of a literal four-step list, no kill-line of its own), not the registered claim.

## Modeling

- `A-SOURCE-SHAPED`: `ReportInput` is three lists (registered ids, reported ids, balances). No oracle committee, no hash consensus, no extra-data, no CL state, no vault transfers.
- `A-VERITY-SCAFFOLD`.
- `fullReportSucceeds : ReportInput → Nat → Prop` is a *free* hypothesis. The module comments that `accept` only covers the early router guards (length, order, `MAX_VALUE_GWEI`, uint64 accumulation) and cannot prove the rest of the report does not revert. The later Accounting / mint / `reportRewardsMinted` path is assumed, not executed.
- `handleOracleReport` does not call Accounting. It writes a map of balances, a total slot, and three flag slots (`accountingCalledSlot`, `rewardsReadSlot`, `rewardsMintedSlot`) that stand in for those calls.
- Step list `successfulSteps` is a literal four-constructor list, not a recorded call journal.
- Storage slots 10–14 are model-local.
- `accountingCalledSlot`, `rewardsReadSlot`, `rewardsMintedSlot` hold *ticks* (`1`, `2`, `3`; `0` for "never written"), one per write call site, in the exact program order accounting is pinned to. These are values threaded through execution, not per-call-site constants: `sequenceSlot` (slot 15) is a transaction-local step clock, reset to `0` at the top of the commit branch, and every step flag is written by `stampStep`, which reads the clock and stores `clock + 1` into both the clock and its own slot. A tick therefore records the position at which that write actually ran, so moving a step write — without touching its slot or editing any numeral — changes the tick it records.

## Proof

**Abstract `mint_after_read_discipline` (parent).** A presence check on the tick flags (as in `storedSteps`) cannot see write order at all: `ContractState` is a key-value store, so writes to `rewardsReadSlot` and `rewardsMintedSlot` commute regardless of which `writeSlot` call runs first in the program text. `mintAfterRead readTick mintTick := 0 < mintTick → readTick < mintTick` is a second, independent check over the two raw ticks (`2` for read, `3` for mint) rather than their mere presence. Because both ticks come from `stampStep`'s read of the reset `sequenceSlot` clock, `2 < 3` here *is* the execution-order fact and not a fact about which numeral a line of program text contains. `mintAfterReadDiscipline_holds` proves it for the real `handleOracleReport` for every input, fee, and starting state.

**Kill-line `mint_order_kill_line` (refutes the parent).** `handleOracleReportMintBeforeRead` is a second executable transaction, defined beside the discipline it violates, obtained from the real one by a *pure call-site reordering*: the `stampStep rewardsMintedSlot` call moves above the `stampStep rewardsReadSlot` call and nothing else changes — every slot binding is identical and no literal is edited. `mintOrderKillLine_holds` proves that mutant does *not* satisfy `mintAfterReadDisciplineOf` — the identical predicate `mint_after_read_discipline` proves for the real transaction — witness: an empty report with a positive fee yields ticks `mint = 2`, `read = 3`, so `mintAfterRead 3 2` is `0 < 2 → 3 < 2`, i.e. false. This is what makes the registered parent falsifiable rather than true by construction: the kill-line mutates the same shape of transaction the parent quantifies over, changes only control flow, and the parent's own statement rejects it.

**Child `source_report_before_reward`.** `sourceTrace` is `accept i >>= pure (successfulSteps accepted shares)`. `successfulSteps` is, by definition,

```
[balancesWritten bs, accountingCalled, rewardsRead bs]
  ++ (if 0 < shares then [rewardsMinted] else [])
```

The theorem assumes `0 < sharesToMintAsFees` and `sourceTrace _ = some trace`, unfolds the `Option.bind`, and closes by `rfl`. `fullReportSucceeds` is never inspected. No induction. This is a source-plane correspondence fact, useful for pinning `successfulSteps`'s shape, but it is tautological on its own statement (see issue 1) and carries no kill-line, which is why it is demoted rather than registered as the headline.

**SOURCE→word refinement `checkedTotal256_refines_source`.** Induction on the balance list: if the Nat `checkedTotal64` succeeds under `≤ 2^64-1`, each `safeAdd` succeeds and the word value equals the Nat total. This is the only non-definitional arithmetic in the abstract plane.

**VERITY child `verity_tx_simulates_oracle_report`.** `handleOracleReport` re-checks `idsAndBalancesValid`, runs `checkedTotal256` (a second copy of the same accumulator over words), writes the map and the tick flags, and returns `storedSteps dirty i.balancesGwei` — read back from its own storage, not from `AccountingCorrespondence.successfulSteps`. `observe` on success builds a `View` from **the input list** `i.balancesGwei`, the stored total, and `storedSteps` (which reads the flags the same function just wrote). `sourceView` is `accept` + `successfulSteps`. Equality is the second accumulator agreeing with `checkedTotal64` plus each side's own step-list constructor happening to be the same four-step list on this input. Rollback: `Contract.run` discards the dirty state on `OVERFLOW` and on the `failAfterWrites` hook.

## Issues

## Resolution

**Restated Lean/English.** `fullReportSucceeds` is named as an independent premise; the abstract is constructor order of `sourceTrace`, not `submitReportData`.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

2026-08-19: independent tx storage-flag ticks replace the shared
`successfulSteps` call in `handleOracleReport`'s own `Result`/`View`
construction (no bridge between the source if-tree and the tx plane), and a
new `mint_after_read_discipline` / `mint_order_kill_line` pair adds a
narrower order check plus its swapped-tick kill-line mutant. This was a
partial mitigation of issue 5; the residual it disclosed is closed by the
2026-08-20 entry below.

2026-08-20 (issue 5 residual closed): the registered parent
`mint_after_read_discipline` had degenerated into the numeral fact `2 < 3`.
Its two ticks were hardcoded at their write call sites, and `ContractState`
writes to distinct slots commute, so no reordering of the transaction body
could change either tick — the only mutant that could refute the parent was
one that moved the *literals* between slots, which is not a control-flow
fault. `handleOracleReport` now resets a transaction-local step clock
(`sequenceSlot`) and writes every step flag through `stampStep`, which reads
that clock and stores `clock + 1`; the tick values are unchanged (`1`, `2`,
`3`), so `storedSteps`, `observe`, `sourceView` and
`verity_tx_simulates_oracle_report` all keep their previous meanings, but a
tick now records when its write ran. The kill-line mutant is correspondingly
replaced: `handleOracleReportSwappedMintBeforeRead` (which moved literals) is
retired in favour of `handleOracleReportMintBeforeRead`, a pure call-site
reordering. Lean: `HandleOracleReportTx.lean`, `Guarantees/PAccount1.lean`
doc comments, `Tests/HandleOracleReportTxMutants.lean` (kill-line renamed to
`reordered_mint_read_kill_line_refutes_parent`), `Audit/Trust.lean`.

2026-08-19 (remediation): the metadata registration was tautological —
`audit/guarantees.yaml`'s `abstract.theorem` pointed at
`source_report_before_reward` (issue 1: true by construction, no kill-line of
its own) while the only kill-line that actually exercises a real fault class
(`mint_order_kill_line`) refutes the *sibling* `mint_after_read_discipline`,
never the registered parent. `mint_after_read_discipline` is now the
registered P-ACCOUNT-1 parent (`audit/guarantees.yaml` `abstract.theorem`
and `EXPECTED_CANONICAL_CLAIMS`/`EXPECTED_CANONICAL_DETAIL_SHA256` in
`scripts/audit_metadata.py`); `source_report_before_reward` is demoted to a
child (source-plane correspondence only). `verity_tx_simulates_oracle_report`
stays the Verity child. No Lean theorem statement or proof changed; this is
a registration/documentation fix over already-proved theorems (`Guarantees.PAccount1.lean`
doc comments, this report, `audit/guarantees.yaml`, `scripts/audit_metadata.py`).

| # | Close | Note |
| --- | --- | --- |
| 1, 8, 10, 12 | A | Constructor `sourceTrace` / tx storage flags named honestly; issue 1's child is no longer the registered headline. |
| 5 | B | Closed 2026-08-20. Step flags are stamped from a transaction-local clock (`sequenceSlot`) instead of per-call-site constants, so `mint_after_read_discipline` (the registered parent) is an execution-order claim; `mint_order_kill_line` / `handleOracleReportMintBeforeRead` refute it with a pure call-site reordering that edits no literal and rebinds no slot. The previously disclosed residual is gone. |
| 2 | A | `fullReportSucceeds` remains an unused parameter of the (now child) constructor theorem. |
| 3 | C | Fixed in PR #105: `observe` reads the persisted `writeArray` balances (`HandleOracleReportTx.lean:113–117`); a dedicated wrong-map-write mutant is still absent. |
| 4, 6, 7, 11, 16, 17, 19 | scope | Membership, caller, role, fee computation, packing, `submitReportData` in `missing`. |
| 9 | A | Child abstract theorem is the positive-fee case. |
| 13, 15, 18 | A | `ofNat` / empty / non-unique ids documented. |
| 14 | A | `Contract.run` rollback is the spec. |


1. **The child `source_report_before_reward` is true by construction.**
   The “trace” is not extracted from Accounting.sol. It is the list `successfulSteps` literally written in `AccountingCorrespondence.lean:86–89`. The theorem says that list equals itself under `0 < fees`. It cannot fail if the real `handleOracleReport` minted before reading balances; that call is not in the model. This is why `source_report_before_reward` is a demoted child rather than the registered parent: the mint-before-read scenario below is exactly the fault class `mint_after_read_discipline` (the registered parent) and its `mint_order_kill_line` mutant are built to catch, over the tx storage-flag ticks instead of the source if-tree.

   *Scenario that this child alone is supposed to rule out, and does not.* Accounting is patched to call `reportRewardsMinted` *before* reading the freshly written module balances. `source_report_before_reward` still holds, because `successfulSteps` is unchanged. The CHECKED status of this child does not track the deployed order; that tracking is the registered parent's job, not this child's.

2. **`fullReportSucceeds` makes the abstract statement conditional on an unproved oracle.**
   The parameter is bound as `_` in `sourceTrace` (`AccountingCorrespondence.lean:111`) and never inspected. Tests instantiate it as `True` (`AccountingVectors.lean`).

   *Scenario.* A report that passes `accept` (ids match, balances `≤ MAX_VALUE_GWEI`, uint64 sum OK) and then reverts in `collectRewardsAndProcessWithdrawals`. `hSuccess` can still be `True`; `source_report_before_reward` produces the four-step “success” trace. The later revert — and any prefix effects — are outside the theorem.

3. **`observe` did not read the written balance map.** **Resolved** (observe-from-storage repair, PR #105): `HandleOracleReportTx.observe` (`:113–117`) now builds the `View` from `(state.readArray moduleBalancesSlot).map (·.val)` — the persisted `writeArray` balances — plus the stored total and `storedSteps`, not from `i.balancesGwei`. Historical statement: `observe` put `i.balancesGwei` into the `View`, so a mutant that replaced `writeAll` with a no-op (or wrote `0` for every id) while keeping the flag slots and the checked total still reported `[10, 20]` from the input and `verity_tx_simulates_oracle_report` still held. After the fix such a mutant is caught at the observed balance column.

   Residual: the mutants file still does *not* contain a dedicated wrong-map-write mutant. It has a bypass-order-guard mutant and an injected-after-writes hook — both about control, not about map contents — though the two-batch chaining vector does exercise the array readback.

4. **Rewards are not read from the snapshot.**
   `rewardsRead balances` carries the same input list that `balancesWritten` carried. There is no second read of storage after a hypothetical intervening write.

   *Scenario.* After `writeAll`, a re-entrant module callback overwrites `moduleBalancesSlot[1]`. `storedSteps` still emits `.rewardsRead [10, 20]` from the input. The “same snapshot” claim is the same `List Nat` appearing twice in a literal.

5. **`storedSteps` reconstructs presence from tick literals, so a mint-first write is still invisible to it.**
   `HandleOracleReportTx.lean`'s `storedSteps` always concatenates `[balancesWritten] ++ acc? ++ rd? ++ mint?` in that *fixed* list order, gated on each flag equaling its own expected literal (`1`/`2`/`3`). It does not record write chronology; `ContractState` writes to distinct slots commute, so no state-based check can see which `writeSlot` call physically ran first.

   *Counterexample mutant.* Reorder the step writes so `rewardsMintedSlot` is written before `rewardsReadSlot`, keeping each write bound to its own slot. `observe` still reports `[balancesWritten, accountingCalled, rewardsRead, rewardsMinted]`; `storedSteps` still sees three nonzero flags and cannot tell. That is exactly why `mint_after_read_discipline` (see Proof) is a second, independent check over the raw ticks rather than an upgrade to `storedSteps` itself.

   *Status: closed (2026-08-20).* This was previously recorded here as an open, disclosed gap, on the grounds that the ticks were hardcoded per-call-site constants, so "order" meant "which literal ended up in which slot" rather than "which write ran chronologically first." That is no longer the case. `sequenceSlot` (slot 15) is a transaction-local step clock reset at the top of the commit branch, and each step flag is written by `stampStep`, which reads that clock and stores `clock + 1`. `handleOracleReportMintBeforeRead` is the counterexample mutant above expressed against this model — a pure call-site reorder with no literal edited and no slot binding changed — and because `stampStep` sources its tick from the clock, the mint step now records `2` and the read step `3`, so `mintOrderKillLine_holds` refutes `mintAfterReadDisciplineOf` for it. `HandleOracleReportTxMutants.lean` pins both tick pairs (honest: read `2`, mint `3`; mutant: mint `2`, read `3`) and separately checks that all three of the mutant's `storedSteps` flags are still nonzero, i.e. that the reordering really is invisible to a presence-only check and is caught only by the tick comparison the registered parent performs.

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

    *Scenario.* Balances `[10, 20]` should mint 0 (no reward delta). Caller passes `sharesToMintAsFees = 7`. Lean writes `rewardsMintedSlot = 3` (its "written" tick) and the four-step trace. The abstract theorem’s `hFees : 0 < shares` is satisfied by the same argument. The CHECKED “mint only after reading this snapshot” never computes a mint from the snapshot; it mints whatever the harness asked for.

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
