# P-RESERVE-1

> Round 2 (2026-08-21). Product note plus proof audit, arbitrated from GPT 5.6 Pro and Opus 5. Fable 5 was unavailable (data-retention gate). Kimi K3 was not an allowed Task model. No em dashes. Lean is authority.

Lido's execution-layer buffer is not one pot. `_getBufferedEtherAllocation` (`Lido.sol` 605-616) splits stored buffered ether before any deposit can be funded:

- $\mathrm{depositsReserve} = \min(\mathrm{buffered},\ \mathrm{storedDepositsReserve})$
- $\mathrm{withdrawalsReserve} = \min(\mathrm{buffered} - \mathrm{depositsReserve},\ \mathrm{unfinalizedStETH})$
- $\mathrm{unreserved} = \mathrm{buffered} - \mathrm{depositsReserve} - \mathrm{withdrawalsReserve}$
- $\mathrm{depositable} = \mathrm{depositsReserve} + \mathrm{unreserved}$

`withdrawDepositableEther` may fund deposits out of depositable and nothing else. The withdrawals slice must not be raided.

`source_spend_preserves_withdrawal_reserve` proves, on any committed call:

- wrapper guards held: $\mathrm{canDeposit} \wedge \mathrm{authorizedRouter}$ (`scopedWithdrawGuards`), derived rather than assumed
- the spend is the pinned one (`withdrawalPartitionSpendInvariant`)
- the queue-facing reserve is unchanged under `freshQueueCache before live` (the cached word equals a live `unfinalizedStETH()` value)

`verity_tx_simulates_reserve_spec` equates `Contract.run` observables with the spec and restores the snapshot on revert. The relational fact that finalization does not depend on the deposits reserve is `P-RESERVE-RELATIONAL`, not this row.

## Proof limitations and recommendations

Both registered theorems are genuine unbounded universals, conditional on a committed wrapper and (for the parent) freshness. `freshQueueCache` is `before.unfinalizedStETH = live`: one inhabited `live` per state. Stale-cache theorems are premise necessity, not parent kill-lines. Conjunct (3) follows from conjunct (2) plus freshness; a mutant cannot satisfy (2) and violate (3) under a fresh cache.

Guards are free booleans, not bunker / pause / `msg.sender`. The zero-amount guard is not in `scopedWithdrawGuards`. `guard_drop` and `partition_spend` are parent-shaped. The Verity parent has no kill-line of its own. Buffer is a declared word, not `address(this).balance`.

CHECKED does not mean the reserve cannot be driven to zero by other writers (`setDepositsReserveTarget` plus a report), or that the queue stays payable.

Ranked next work: keep freshness explicit until a live WQ CALL exists; close or keep explicit the zero-amount guard and setDepositsReserveTarget surface; do not treat P-RESERVE-RELATIONAL as this parent.

Theorems: `PReserve1.source_spend_preserves_withdrawal_reserve`, `PReserve1.verity_tx_simulates_reserve_spec`. Parent kill-lines: `LidoSRv3.Tests.ReserveMutants.guard_drop_kill_line_refutes_parent` (kills the `scopedWithdrawGuards` conjunct on a `canDeposit`-dropped mutant) and `LidoSRv3.Tests.ReserveMutants.partition_spend_mutant_kill_line_refutes_parent` (kills the partition-invariant and live-reserve conjuncts on a mutated spend transition). Premise-necessity evidence: `staleQueueCacheKillLine_holds`, `LidoSRv3.Tests.ReserveMutants.stale_queue_cache_mutant_counterexample`.
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Lido’s execution-layer buffer (`Lido.sol` 0.4.24) is split by `_getBufferedEtherAllocation` (lines 605–616):

- `depositsReserve = min(buffered, storedDepositsReserve)` — ETH earmarked for CL deposits;
- `withdrawalsReserve = min(buffered − depositsReserve, unfinalizedStETH)` — ETH that must stay to pay the WithdrawalQueue;
- `unreserved` — the rest.

`withdrawDepositableEther` (router-only, lines 869–886) may spend only `depositsReserve + unreserved` via `_spendDepositableEther` (839–859). The withdrawals slice must not be raided to fund deposits. That separation is what keeps unfinalized stETH redeemable while the router is depositing.

## Modeling

- `A-SOURCE-SHAPED`: `unfinalizedStETH` is a **stored field** on `ReserveState`, not a CALL to `WithdrawalQueue.unfinalizedStETH()` as in source line 612. A queue that grows between the view and the spend is invisible.
- Authorization, pause, `canDeposit`, the ETH transfer to the router, seed-deposit counter, and events are outside the core spend. `WithdrawInputs.canDeposit` / `authorizedRouter` are two booleans wrapped around the same arithmetic.
- Solidity 0.4.24 raw `remaining -= depositsReserve` is modeled as `safeSub`. Underflow is treated as revert (`ALLOCATION_ARITHMETIC`); the real 0.4.24 subtraction wraps. The file claims the `min` bounds make the failure unreachable — that is an extra argument, not 0.4.24 semantics.
- SafeMath `.add` / `.sub` on the spend path *are* checked, matching the model.
- Slots 0–4 are model-local, not the real unstructured-storage positions (`DEPOSITS_RESERVE_POSITION`, …).
- `A-VERITY-SCAFFOLD`.

## Proof

**Abstract `source_spend_preserves_withdrawal_reserve`.** Case-split (not induction) on every `Option` arm of `spendDepositableEther`. On the unique `.committed` path, `withdrawalPartitionSpendInvariant` is assembled by *replaying those same arms*: there exist `allocation` and `depositable` equal to the functions just computed, `amount ≤ depositable`, `after.buffered` is `safeSub allocation.total amount`, `storedDepositsReserve` follows the `> amount ? − : 0` update, and `unfinalizedStETH` is unchanged. That last conjunct is `rfl` — the record update never writes the field.

**VERITY `verity_tx_simulates_reserve_spec`.** `ReserveContract.withdraw` is a `verity_contract` transcription of the same arithmetic. A second interpreter `sourceSpendDepositableEther` is copy-shaped; `verity_execution_simulates_spec` identifies `Contract.run` observables with `specTx`. The rollback conjunct is `Contract.run`’s snapshot restore on every `require` / `requireSomeUint` failure.

**`verity_tx_preserves_withdrawal_reserve`.** Simulate, then apply the abstract invariant to the decoded states.

## Issues

## Resolution

**Restated Lean/English.** Unused `buffered ≥ storedDepositsReserve` / `amount ≠ 0` hyps dropped; the invariant follows from any committed spend.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1 | A | Spend reproduces the WR formula; not “other writers leave WR unchanged.” |
| 2, 5, 6, 8, 9, 10, 14 | scope | WQ call, auth, packing, nonce, rebalance, seed in `missing`. |
| 3, 13 | B | Facade now requires well-formed `buffered ≥ storedDepositsReserve`. |
| 4, 11, 12 | A | Lockstep copies; invariant quotes the source `if`. |
| 7 | B | Facade now requires `amount ≠ 0` (wrapper already did). |
| 15 | D | Child `P-RESERVE-1.relational` registered. |
| 16, 17 | A | Lido design: declared report add, not a spend-path raid. |


1. **The named invariant is a restatement of the transition, not “WR is unchanged.”**
   `withdrawalPartitionSpendInvariant` (`ReserveCorrespondence.lean:429–440`) does **not** mention `effectiveWithdrawalsReserve`. It says: the spend succeeded, the buffer fell by `amount`, the stored deposits reserve was decremented, and the `unfinalizedStETH` *field* is the same pointer-equal word.

   The field being unchanged is true of any function that does not write slot 2, including one that drained the buffer below the queue’s claimable amount. The interesting property — `effectiveWithdrawalsReserve after = effectiveWithdrawalsReserve before` — is defined at line 100 and never used in the guarantee theorems.

   *Scenario.* `buffered = 100`, `storedDepositsReserve = 40`, `unfinalizedStETH = 30` ⇒ WR = 30, depositable = 70. Spend 70. After: `buffered = 30`, `storedDR = 0`, field `unfinalizedStETH = 30`, effective WR = `min(30, 30) = 30`. The *effective* quantity happens to hold here, but the theorem would also accept a mutant that set `buffered = 0` and left the field at 30: invariant’s last conjunct holds, effective WR becomes 0, and unfinalized stETH can no longer be paid from the buffer. The CHECKED guarantee does not distinguish those.

2. **`unfinalizedStETH` is not the WithdrawalQueue.**
   Deployed allocation calls `_withdrawalQueue().unfinalizedStETH()` every time. Model: a cached word. Scenario: queue reports 30 at t0 (stored in the Lean state); 20 more requests show up; router spends the old depositable. Live `_getBufferedEtherAllocation` would have reserved 50 and reduced depositable; the model still allows the larger spend. The guarantee as a claim about `Lido.sol` is then false.

3. **0.4.24 wrap vs `safeSub`.**
   If a future change broke the `min` precondition so `storedDepositsReserve > buffered`, 0.4.24 `remaining -= depositsReserve` wraps; the model reverts.

   *Scenario.* `buffered = 10`, `storedDepositsReserve = 12` (inconsistent storage). 0.4.24 `remaining -= 12` wraps to a huge `uint256`; withdrawalsReserve becomes `min(huge, unfinalized)`. Lean `safeSub` returns `none` and the spend reverts `ALLOCATION_ARITHMETIC`. The refinement is not 0.4.24-accurate on that branch.

4. **Two near-identical spend functions (`spendDepositableEther` and `sourceSpendDepositableEther`).**
   Independence is asserted in a comment (`ReserveCorrespondence.lean:155–158`) but the bodies are the same case tree. `source_spend_matches_model` is `simp`.

   *Counterexample to independence.* Mistranscribe SafeMath `.add` on `depositedPostReport` as wrapping `+` in *both* copies. Correspondence still holds. The CHECKED simulation cannot see a shared transcription error.

5. **`canDeposit` / `authorizedRouter` are free booleans, not live Lido/router checks.**
   `modelWithdrawDepositableEther` / `withdrawWithGuards` do reject `amount = 0` (matching line 873). The other two wrapper guards are `WithdrawInputs` bits. Live `canDeposit()` is a protocol-wide pause / deposit-enabled view; `_auth(address(stakingRouter))` is `msg.sender == stakingRouter`.

   *Scenario.* Bunker mode is on (`WithdrawalQueue.isBunkerModeActive()`). Live `canDeposit()` is false (`Lido.sol:815–816`: `!bunker && !isStopped()`), so `withdrawDepositableEther` reverts `CAN_NOT_DEPOSIT`. Lean `verity_tx_simulates_reserve_spec` with `inputs.canDeposit = true` commits. Anyone can satisfy the hypothesis by passing `true`. The CHECKED tx does not read the queue or the stop flag.

6. **Router ETH transfer is absent; packing is uint256 not uint128.**
   `withdrawDepositableEther` then sends `_amount` to `stakingRouter.receiveDepositableEther`. Lean never moves value. Live `buffered` / `depositedPostReport` are packed `uint128`s (`Lido.sol` ~1487–1508).

   *Scenario.* `buffered = 2^128 − 1`, `amount = 1`, depositable large enough. Lean `safeSub` on uint256 succeeds. Solidity `setLowUint128` wraps or reverts. The CHECKED spend is not the packed write.

7. **Abstract `spendDepositableEther` accepts `amount = 0`; the wrapper does not.**
   The named abstract theorem is about `spendDepositableEther`, which has no `ZERO_AMOUNT` guard. `withdrawalPartitionSpendInvariant` holds for a no-op spend. The Verity wrapper (`withdrawWithGuards`) does require `amount ≠ 0`.

   *Scenario.* Call the core spend with `amount = 0`. Lean commits; `unfinalizedStETH` unchanged; invariant holds. Live `withdrawDepositableEther` never reaches `_spendDepositableEther`. The CHECKED abstract guarantee includes a transition the external function cannot take.

8. **`depositedNextReportAdjusted` ignores the frame-nonce reset.**
   Live `_getDepositedNextReportAdjusted` (`Lido.sol:796–803`) returns `0` when `_getCurrentFrame()` ≠ `lastNonce`, then the spend adds `_depositAmount`. Lean stores a single word and always `safeAdd`s. No oracle frame is in the state.

   *Scenario.* New refSlot since the last deposit (`curNonce != lastNonce`). Live next-report counter becomes `0 + amount`. Lean `depositedNextReportAdjusted` becomes `old + amount`. The next accounting report’s “deposits this period” is wrong in the model. The CHECKED spend is not frame-aware.

9. **Report-time rebalance is another writer of the same pot.**
   `collectRewardsAndProcessWithdrawals` sets buffered to `buffered + EL + withdrawalsVault − etherToLockOnWQ` and `_updateBufferedEtherAllocation` can *raise* stored deposits reserve to target (`Lido.sol` 1104–1131). That shrinks the complement available to withdrawals without going through `spendDepositableEther`.

   *Scenario.* Frame locks 40 ETH onto the WQ and simultaneously raises deposits reserve. Effective WR changes. P-RESERVE-1 is silent because that function is not `spendDepositableEther`. The guarantee ID reads as “the reserve cannot be raided”; only one raid path is modeled.

10. **`buffered` is a free `uint256` field, not the packed `uint128` cache `_getBufferedEther` reads.**
    Live `_getBufferedEtherAllocation` (`Lido.sol:605–608`) starts from `_getBufferedEther()` (`:1487–1488`), the **low uint128** of `BUFFERED_ETHER_AND_DEPOSITED_POST_REPORT_POSITION` — not `address(this).balance`. Lean `getBufferedEtherAllocation` reads `ReserveState.buffered : Word` (full `uint256`). Spend writes the `safeSub` result back into that field. No packed slot, no high-half `depositedPostReport` companion (issue 6).

    *Scenario.* `buffered = 2^128`. Lean `min` / `safeSub` treat it as a legal total. Live `getLowUint128` cannot store that value; `setLowUint128` wraps or reverts. Conversely, Lean can keep `buffered` and `depositedPostReport` independently inconsistent (high/low halves of the same packed word on chain). The CHECKED allocation is not the packed 0.4.24 cache. Neither plane reads the contract’s ETH balance: a later `send` of depositable ether (issue 6) can still fail on-chain while Lean commits.

11. **`depositedPostReport` / `depositedNextReportAdjusted` overflow is a third copy of the same `safeAdd`.**
    `spendDepositableEther`, `sourceSpendDepositableEther`, and `ReserveContract.withdraw` each `safeAdd` those two counters. Issue 4 already notes the two Lean functions are clones; the Verity contract is the third transcription.

    *Counterexample to independence.* Mistranscribe both counters as wrapping `+` in all three copies. `verity_tx_simulates_reserve_spec` still holds. Live 0.8 `Accounting` / 0.4.24 Lido packing would wrap or revert on `uint128` (issue 6). The CHECKED simulation cannot see a shared overflow transcription.

12. **`storedDepositsReserve` update uses wrapping `sub`, not `safeSub`.**
    `ReserveContract.withdraw` (`ReserveCorrespondence.lean:137–139`): `ite (current > amount) (sub current amount) 0`. `sub` is wrapping `Uint256` subtraction. The `>` guard makes underflow unreachable *if* `>` is a value comparison, which it is. `spendDepositableEther` (`:89–92`) uses the same `>` / `-` / `0` pattern on `Word`.

    *Scenario.* A mutant that flipped `>` to `<` would take wrapping `sub` and write a huge `storedDepositsReserve`. The CHECKED invariant *quotes* that same `if > then - else 0` (`:437–439`), so it would hold of the mutant. Live `_spendDepositableEther` (`Lido.sol:855–858`) uses the same 0.4.24 `-` after `>` (buffer itself uses SafeMath `.sub` at 847). The CHECKED “pinned update” is a restatement of the wrapping-`sub` ite, not an independent check that the withdrawals slice was left alone (issue 1).

13. **Depositable `+` is 0.4.24 wrap; Lean `safeAdd`s.**
    Live `_getDepositableEther` is raw `depositsReserve + unreserved` (0.4.24, wraps). Lean `getDepositableEther` (`:64–65`) is `safeAdd` → `DEPOSITABLE_OVERFLOW`. Issue 3 already covers `remaining -=`; this is the *other* operator on the same path.

    *Counterexample.* Inconsistent storage `buffered = 10`, `storedDepositsReserve = 12`. After a wrapping `remaining -=` (issue 3), `depositsReserve + unreserved` can exceed `2^256 − 1`. 0.4.24 wraps and may still `require(amount ≤ depositable)`. Lean `safeAdd` reverts and never spends. `verity_tx_simulates_reserve_spec` is not 0.4.24 on the depositable sum.

14. **`_seedDepositsCount` is a live argument with no Lean field.**
    `withdrawDepositableEther(uint256 _amount, uint256 _seedDepositsCount)` (`Lido.sol:869–881`) SafeMath-adds the seed counter and emits `DepositedValidatorsChanged` when `_seedDepositsCount > 0`. Lean `withdraw` / `spendDepositableEther` take only `amount`.

    *Scenario.* Router withdraws 32 ETH with `_seedDepositsCount = 1`. Live seed counter increments; later accounting uses it. Lean spend updates buffer/reserves only. A bug that incrementing the seed counter overflowed (SafeMath would revert the whole withdraw) cannot appear. The CHECKED spend is not the external function’s second parameter.

15. **A relational “reserve does not change finalization” model exists and is not this row.**
    `PReserveRelational.abstract_reserve_does_not_change_finalization` says two states that differ only in the reserve field have the same outcome observables. That is closer to “WR is not raided” than `withdrawalPartitionSpendInvariant` (issue 1). It is a different module, not `PReserve1.source_spend_preserves_withdrawal_reserve`.

    *Scenario.* A reader of CHECKED P-RESERVE-1 expecting “finalization / WQ observables are independent of the deposits-reserve write” will not find that theorem on the registered row. You can change `PReserveRelational` and `verity_tx_simulates_reserve_spec` still holds. The CHECKED parent restates the spend transition; the relational lemma was left unused.

16. **`receiveWithdrawals` is a vault-only ETH receive that does not touch stored `buffered`.**
    Live `Lido.receiveWithdrawals` (`:530–534`) only `_auth`s the vault and emits. The stored uint128 buffer is raised later in `collectRewardsAndProcessWithdrawals` (`:1104–1109`) by adding a *declared* `_withdrawalsToWithdraw`, not `address(this).balance`. P-RESERVE-1’s spend reads `ReserveState.buffered` and never models this hop (issue 9 already notes report-time rebalance).

    *Scenario.* Vault sends 10 ETH via `receiveWithdrawals`. Live stored buffer is still the old word. Accounting then reports `_withdrawalsToWithdraw = 7`. Buffer becomes old+7 while the contract holds +10. Lean spend never sees either write. A mutant that spent the extra 3 ETH as depositable would raid ETH that the stored WR accounting did not reserve. The CHECKED spend is silent on the receive/report pair that actually funds the pot.

17. **Report-time buffer update is a declared add, not `address(this).balance`.**
    Extends issue 16 and issue 9. `collectRewardsAndProcessWithdrawals` (`:1104–1109`) does `_getBufferedEther().add(_elRewards).add(_withdrawalsToWithdraw).sub(_etherToLockOnWQ)`. Those three numbers are oracle-report fields, not the ETH that actually arrived. Lean `buffered` is a free word the spend subtracts from.

    *Counterexample.* Oracle reports `_withdrawalsToWithdraw = 100` after the vault sent 10. Live stored buffer jumps by 100 (SafeMath add) while the contract only received 10. Depositable becomes 90 too large. Lean spend can be fed `buffered = 100` and will “preserve WR” while spending ETH that is not there (issue 6: no send). The CHECKED allocation is not tied to either the declared report or the real balance.

## Wave 1 changes (2026-08-19)

Directly answers issues #1, #2, and #5 above, without widening the claim past a source-shaped `WithdrawInputs`/`ReserveState` model.

1. **`scopedWithdrawGuards` premise, proved not assumed (issue #5).** The registered parent's premise is now `modelWithdrawDepositableEther inputs before amount = .committed after` — the guard-checking wrapper, not the bare `spendDepositableEther` the old theorem quoted directly. The conclusion now includes `scopedWithdrawGuards inputs` (`canDeposit ∧ authorizedRouter`) as a *derived* fact: any committed call necessarily took the guarded branch, since a guard failure reverts. `canDeposit`/`authorizedRouter` remain free `WithdrawInputs` booleans, not live `Lido.canDeposit()`/`_auth(stakingRouter)` reads — that half of issue #5 is unchanged and stays in `fidelity.missing`.

2. **`freshQueueCache` names the WQ/CALL gap, and `liveEffectiveWithdrawalsReserve` is the property issue #1/#2 asked for.** `liveEffectiveWithdrawalsReserve state live` recomputes the min-capped queue-facing reserve against an explicit `live` value standing in for a `WithdrawalQueue.unfinalizedStETH()` CALL, instead of the state's cached field. `committed_preserves_live_effective_withdrawals_reserve` proves it is invariant under a legal spend *given* `freshQueueCache before live` (`before.unfinalizedStETH = live`). This is the non-restatement invariant issue #1 said the old theorem never used, made conditional on the cache freshness issue #2 said was implicit.

3. **`staleQueueCacheKillLine` — premise-necessity evidence for #2, made concrete.** `staleQueueCacheKillLine_holds` (in `ReserveCorrespondence.lean`) and `ReserveMutants.stale_queue_cache_mutant_counterexample` exhibit `before`/`after` states where `spendDepositableEther` commits, the *original* `withdrawalPartitionSpendInvariant` holds with no trouble, but `liveEffectiveWithdrawalsReserve` drops from 80 to 50 once the cached `unfinalizedStETH = 50` is stale against a live value of 80 — the exact raid issue #2 describes. `freshQueueCache` is exactly the hypothesis that rules this vector out; drop it and the strengthened conclusion is false on this witness. (Relabeled in Wave 4: this refutes the freshness-*dropped* sibling claim — hypothesis necessity — not the registered parent, which cannot be instantiated on the stale-cache vector. The parent kill-line is the Wave 4 transition mutant below.)

4. **What is still not claimed.** No live `WithdrawalQueue.unfinalizedStETH()` CALL exists in the model — `freshQueueCache` is an accepted per-call hypothesis, not something derived from `ReserveState` or a Verity `CALL` observation. `canDeposit`/`authorizedRouter` are still not tied to bunker mode, pause state, or `msg.sender`. Issues #3, #4, #6–#17 are unaffected and remain as originally reported.

## Wave 4 changes (2026-08-19): P-RESERVE-1 parent kill-line remediation

**Defect.** The registered parent
`PReserve1.source_spend_preserves_withdrawal_reserve` had no kill-line that
refutes *its own* predicate. The named `staleQueueCacheKillLine` /
`staleQueueCacheKillLine_holds` (plus the `ReserveMutants` witness
`stale_queue_cache_mutant_counterexample`) refutes only the *unconditional,
freshness-dropped* sibling claim
`∀ before after amount live, spendDepositableEther before amount = .committed after → liveEffectiveWithdrawalsReserve after live = liveEffectiveWithdrawalsReserve before live`.
On the stale-cache witness the parent cannot even be instantiated:
`freshQueueCache staleCacheBefore live` forces `live = 50`, where the
conclusion holds — so the witness demonstrates hypothesis *necessity*, not
parent *falsifiability*.

**Fix: registered a transition-mutant parent kill-line.** The mutation hits
the spend transition, not the freshness premise:
`withdrawalPartitionMutant` (pre-existing in `Tests/ReserveMutants.lean`)
commits exactly like `spendDepositableEther`, then overwrites `buffered` with
the post-spend `storedDepositsReserve`. The new `mutantWithdraw` wraps it in
the same `canDeposit` / `authorizedRouter` / nonzero guards as
`modelWithdrawDepositableEther`, so the kill-line targets the parent's own
predicate shape:

- `LidoSRv3.Tests.ReserveMutants.partition_spend_mutant_witness` — concrete
  witness: `freshQueueCache vector (word 50)` holds (the cache is FRESH), the
  mutated call commits, and
  `liveEffectiveWithdrawalsReserve` drops 50 → 0 across it.
- `LidoSRv3.Tests.ReserveMutants.partition_spend_mutant_kill_line_refutes_parent` —
  proves the negation of the parent's statement shape with
  `mutantWithdraw` in place of `modelWithdrawDepositableEther`, the
  `freshQueueCache` hypothesis retained, instantiated by the witness above.

**Relabeling.** `staleQueueCacheKillLine_holds` and
`stale_queue_cache_mutant_counterexample` are kept unchanged as Lean
theorems, but every reference (the parent's docstring, the
`staleQueueCacheKillLine` docstring, the `ReserveMutants` section header, the
YAML row, and this report) now describes them as premise-necessity evidence —
they show the `freshQueueCache` hypothesis cannot be dropped — not as the
parent kill-line.

**What did not change.** No registered theorem statement is touched:
`source_spend_preserves_withdrawal_reserve`,
`verity_tx_simulates_reserve_spec`, `verity_tx_preserves_withdrawal_reserve`,
`staleQueueCacheKillLine`, and `staleQueueCacheKillLine_holds` are all
identical; the only source-file edits are docstrings. `abstract.theorem`,
`verity.theorem`, classification, and assumptions in `audit/guarantees.yaml`
are unchanged; `summary`, `fidelity.covered`, and `reproduction.expected` now
cite the transition-mutant kill-line as the parent kill-line and the
stale-cache theorems as hypothesis-necessity evidence. No `sorry`/`admit`;
every new vector closes by `rfl` or `decide` (no `native_decide`).

**Build.** `lake build LidoSRv3` and `lake build
LidoSRv3.Tests.ReserveMutants LidoSRv3.Tests.ReserveRelationalMutants
LidoSRv3.Tests.ReserveRelationalTxMutants`: exit 0. `python3
scripts/audit_metadata.py generate && check`: exit 0 (11 canonical guarantees
+ 14 subordinate rows; detail sha for P-RESERVE-1 recomputed).

## Wave 5 changes (2026-08-19): guard-liveness kill-line for conjunct (1)

**Defect (found in wave-5 review).** The registered parent's first conjunct,
`scopedWithdrawGuards inputs`, is proved by branch inversion on the model's
own guard chain (a committed call necessarily passed `canDeposit ∧
authorizedRouter`), and the Wave 4 kill-line cannot exercise it:
`mutantWithdraw` preserves the guard chain, so on the Wave 4 witness the
guards hold (`allowed = ⟨true, true⟩`) and conjunct (1) is true trivially. A
conjunct that no connected mutant falsifies is dilution (criterion 1
residual): the parent's three-conjunct conjunction was only falsified at
conjuncts (2)-(3).

**Fix: P-TOPUP-1-style guard-drop kill-line, not demotion.** The conjunct is
real falsifiable content about the model's gating, so it is kept and backed
by its own kill-line in `LidoSRv3/Tests/ReserveMutants.lean`:

- `mutantWithdrawNoCanDeposit` — a guard-for-guard copy of
  `modelWithdrawDepositableEther` with ONLY the `canDeposit` check deleted;
  `authorizedRouter`, the nonzero-amount check, and the honest
  `spendDepositableEther` transition are unchanged. Pinned by examples: the
  honest model reverts `CAN_NOT_DEPOSIT` on the witness inputs while the
  mutant commits the honest spend, and with `canDeposit = true` the mutant is
  indistinguishable from the honest model.
- `guard_drop_mutant_witness` — concrete witness: `noCanDeposit = ⟨false,
  true⟩`, nonzero amount, the standard `vector`, `live = 50` so
  `freshQueueCache` holds by `rfl`; the mutant COMMITS, and
  `scopedWithdrawGuards noCanDeposit` is FALSE (`canDeposit = false`).
- `guard_drop_kill_line_refutes_parent` — proves the negation of the
  registered parent's FULL predicate shape (all five binders,
  `freshQueueCache before live` retained, the same three-conjunct conclusion)
  with `mutantWithdrawNoCanDeposit` substituted for
  `modelWithdrawDepositableEther`. Instantiated by the witness above, the
  parent's conjunction fails at its first conjunct on a premise-satisfying
  witness.

**Division of labor (now explicit in every docstring).**
`guard_drop_kill_line_refutes_parent` kills conjunct (1)
(`scopedWithdrawGuards` guard liveness);
`partition_spend_mutant_kill_line_refutes_parent` kills conjuncts (2)-(3)
(`withdrawalPartitionSpendInvariant` and live-reserve invariance, freshness
retained); `staleQueueCacheKillLine_holds` and
`stale_queue_cache_mutant_counterexample` remain premise-necessity evidence
for `freshQueueCache` (they refute the freshness-dropped sibling claim, not
the parent).

**What did not change.** No registered theorem statement is touched:
`source_spend_preserves_withdrawal_reserve`,
`verity_tx_simulates_reserve_spec`, `verity_tx_preserves_withdrawal_reserve`,
`staleQueueCacheKillLine`, and `staleQueueCacheKillLine_holds` are identical;
the Wave 4 kill-line theorem and witness are unchanged (docstring roles
clarified). `abstract.theorem`, `verity.theorem`, classification, and
assumptions in `audit/guarantees.yaml` are unchanged; `summary`,
`fidelity.covered`, and `reproduction.expected` now cite both kill-lines and
their division of labor. No `sorry`/`admit`/`native_decide`: the new vectors
close by `rfl`, `decide`, or an explicit term (`Bool.false_ne_true`).

**Build.** `lake build LidoSRv3` and `lake build
LidoSRv3.Tests.ReserveMutants`: exit 0. `python3 scripts/audit_metadata.py
generate && check`: exit 0 (11 canonical guarantees + 14 subordinate rows;
detail sha for P-RESERVE-1 recomputed).
