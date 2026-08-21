# P-TOPUP-2

> Round 2 (2026-08-21). Product note plus proof audit, arbitrated from GPT 5.6 Pro and Opus 5. Fable 5 was unavailable (data-retention gate). Kimi K3 was not an allowed Task model. No em dashes. Lean is authority.

P-TOPUP-2 is the per-block ceiling on Electra compounding top-ups. The product question is whether one call can top up more gwei than governance allows in a block. The answer the row gives is narrower.

`aggregate_bounded_by_block_cap` says that for every batch and config, with no well-formedness hypothesis,

$(\mathrm{transition}\, b\, \mathrm{cfg}).\mathrm{sum} \le \mathrm{cfg.maxTopUpPerBlockGwei}$

where `transition` is `consumeBudget` of `transitionBudget = \min(\mathrm{valueGwei},\ \min(\mathrm{moduleLimit},\ \mathrm{maxTopUpPerBlock}))` over per-key candidates. The proof is induction over that leftover walk. This replaces the historical tautology `router_require_post_condition`, which assumed the bound and returned it. `block_cap_kill_line_refutes_parent` drops the cap term and allocates above it.

`verity_tx_simulates_topup2_spec` is lockstep of the same leftover-budget walk on decoded arrays of length $\le 32$. `observe` rereads persisted allocations. A 33-validator mutant without the guard commits. We do not implement the live `topUp` plus beacon path: independent per-key limits, `allocateDeposits`, Lido pull, and beacon deposit stay in `fidelity.missing`. That is P-TOPUP-1's conservation surface, and the two rows do not compose.

## Proof limitations and recommendations

The forall is genuine and the tautology history is closed. Residual content is still definitional in one sense: any `consumeBudget (min _ (min _ cap))` satisfies the bound. Headroom-blind mutants still pass. Live routing accepts any split under per-key and aggregate `require`s; Lean's greedy walk is one policy among many.

`A-TOPUP-NOWRAP` has been removed from this row because its recorded StakingRouter line-732 risk belongs to P-TOPUP-1. Abstract `evaluated_topup_limit` is still unbounded Nat; the word plane uses `safeAdd` and reverts on overflow. The keccak oracle is inert for these reads; the real gap is harness-supplied arrays. The max-validators witness does not refute the registered Verity parent, which assumes `count ≤ 32`; YAML now labels it guard necessity. The guard is the literal 32, not the packed governance word.

CHECKED does not mean the deployed gateway respects `maxTopUpPerBlock`.

Ranked next work: `per_key_bounded_by_candidate` and the 32-guard honesty edit landed in `improve/report-recommendations-batch`; do not compose with P-TOPUP-1; keep the live path out unless the claim is widened on purpose.

Theorems: `PTopup2.aggregate_bounded_by_block_cap` (parent), `PTopup2.verity_tx_simulates_topup2_spec`.
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Electra compounding validators can be topped up through `TopUpGateway.topUp` (`TopUpGateway.sol` 160–237) after SSZ-witnessed CL state, type-0x02 credentials, activation, sort-order, root-age, and `TOP_UP_ROLE` checks. Each validator’s allowed top-up is `_evaluateTopUpLimit` (396–415): 0 if slashed/exiting or already at target, else the gap if it is at least `minTopUp`. The batch is then cut by `msg.value / 1 gwei`, the module’s remaining share, and `maxTopUpPerBlock`. The intended guarantee: the gwei actually allocated in one call cannot exceed the per-block cap (and, separately, the module limit).

## Modeling

- `A-SOURCE-SHAPED`. `PTopup2.Validator` is a record of Nats/Bools. No SSZ witness, no EIP-4788 beacon root, no pubkey bytes, no `CLValidatorVerifier`.
- `A-VERITY-SCAFFOLD`: `Contract.run` is a non-certified Verity 4.31 interpreter.
- `evaluated_topup_limit` is unbounded `Nat` addition. Solidity `effective + pending` is checked `uint256` and reverts on overflow. The file says so (`PTopup2.lean:31–34`). `audit/P-TOPUP-2-CORRESPONDENCE.md` still records “Parent SOURCE and TX stay OPEN” for that reason — the YAML now says CHECKED anyway.
- `well_formed_batch` *includes* `b.allocations = transition b cfg` as a conjunct, plus: wc = 0x02, activated, not slashed/exiting, strictly increasing indices, unique pubkeys, length caps, root age, gwei-aligned value. Those extra conjuncts are **not used** by `aggregate_bounded_by_block_cap` except the transition equality.
- Verity `Topup2DistributionTx` reads three memory arrays (effective, pending, requested) and a numeric budget. It does not model `onlyRole`, pause, root age, or witnesses.
- `txRun` calls `sourceCandidates` and `sourceConsume` (`Topup2DistributionTx.lean:74–78`). `txRun_eq_sourceRun` is `rfl`.

## Proof

**Abstract `aggregate_bounded_by_block_cap` (parent).** Unconditional in `b`/`cfg`: `(transition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei`. From `consumeBudget_sum_le`: induction over the left-to-right leftover-budget walk shows the sum is ≤ the budget it was given, then `transitionBudget`'s `min _ (min _ blockCap) ≤ blockCap` closes it. The same skeleton gives `aggregate_bounded_by_module_limit` and `aggregate_bounded_by_individual`. The theorem's content is in the induction, not in a restated hypothesis, so it is non-vacuous: it constrains the actual output of `consumeBudget`/`candidates`, not an arbitrary `alloc` handed in by the caller.

*Kill-line (`block_cap_kill_line_refutes_parent`, `Topup2DistributionTxMutants.lean`).* `mutantTransition` runs the identical `consumeBudget` walk against a mutant budget that drops the `maxTopUpPerBlockGwei` term from `transitionBudget`'s `min` — the Lean analogue of a router that dropped its block-cap `require`. Two validators each independently eligible for 20 gwei (`evaluated_topup_limit = target(32) - effective(12) = 20`), each requesting 10 gwei, both clear the uncapped 100-gwei mutant budget in full: the walk commits `[10, 10]`, summing to 20 against `maxTopUpPerBlockGwei = 10`. `¬ ∀ b cfg, (mutantTransition b cfg).sum ≤ cfg.maxTopUpPerBlockGwei` is proved from this witness, and the file also shows the *real* `aggregate_bounded_by_block_cap` still holds on that same `b`/`cfg` pair — the cap term in `transitionBudget` is exactly what the mutant is missing.

**Retracted `router_require_post_condition` (Wave 1 review).** A prior revision registered a different parent: unconstrained `alloc`/`limits`, hypotheses `hEachBound : ∀ i, alloc[i] ≤ limits[i]` and `hSumBound : alloc.sum ≤ min share cfg.maxTopUpPerBlockGwei`, conclusion `⟨hEachBound, hSumBound⟩`. The conclusion is syntactically identical to the hypotheses — a pure tautology, true for any `alloc`/`limits`/`share` including ones no execution of `transition` could produce — and does not mention `transition`, `consumeBudget`, or `evaluated_topup_limit` at all. Its "kill-line mutant" fed concrete numbers into that same restated conclusion directly, never through the theorem, so it refuted a general `Nat` fact rather than the registered parent. It has been removed rather than restated (see `PTopup2.lean` for the retraction note), and `aggregate_bounded_by_block_cap` is registered again, now with the mutant-budget kill-line above closing the gap that made it vulnerable to being swapped out in the first place.

**VERITY `verity_tx_simulates_topup2_spec`.** Decode three arrays of equal length, run `txRun` (= `sourceRun` by `rfl`), write allocations and remaining/used slots, compare `observe` to `sourceView`. Rollback via `Contract.run` and `failAfterWrites`. Unaffected by the parent swap above: it was never `router_require_post_condition`'s Verity plane.

## Issues

## Resolution

**2026-08-20 Wave2 — Verity allocation persistence and block-cap binding:** Enforced `count ≤ maxValidatorsPerTopUp (32)` in `Topup2DistributionTx.allocate` as checked revert `MaxValidatorsPerTopUpExceeded` before decoding; updated `verity_tx_simulates_pinned_source` and `verity_tx_simulates_topup2_spec` to require `requested.length ≤ maxValidatorsPerTopUp` and proved equivalence via `Nat.not_lt.mpr`; added mutant `allocateNoMaxCheck` without guard and kill-line `max_validators_guard_kill_line_refutes_no_check` showing honest reverts a 33-validator batch (effective 32, pending 0, requested 1, target 64, remainingCap 100) while mutant commits `[1;33]` with remaining 67 / used 33; `observe` still rereads `state.readArray allocSlot`/`readSlot` persistence, now load-bearing for the new guard. YAML `fidelity.covered` now names the new observable; `fidelity.missing` stays honest.

**Wave 2 (2026-08-18 fix): retracted a tautological parent.** The Wave 1 revision that registered `router_require_post_condition` conjoined the per-validator and aggregate-sum hypotheses and handed them straight back as the conclusion, so the "parent" held for any `alloc`/`limits` and its kill-line mutant never actually applied the theorem — it checked a `Nat` fact about hand-picked numbers instead. `router_require_post_condition` is removed. `aggregate_bounded_by_block_cap` — unconditional in `b`/`cfg`, proved by induction over `consumeBudget` — is the registered parent again, and its non-vacuity now has an explicit witness: `block_cap_kill_line_refutes_parent` shows a mutant that drops `maxTopUpPerBlockGwei` from `transitionBudget`'s `min` lets the identical leftover-budget walk exceed the cap, using the same two-validator numbers the retracted kill-line used, now driven through the real `consumeBudget`/`candidates` functions.

**Restated Lean/English.** `aggregate_bounded_by_block_cap` no longer takes unused `well_formed_pre`. An ill-formed batch still has `transition.sum ≤ cap`.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

| # | Close | Note |
| --- | --- | --- |
| 1 | B | `well_formed_pre` split; registered cap is about `transition`. |
| 2, 8 | A | Lockstep / leftover-walk plane named honestly. |
| 3, 9, 13, 14, 7, 15, 24 | scope | Executed SSZ/role/distance/slash/activation/`maxValidators` in `missing`. |
| 4, 20, 26 | A | `A-TOPUP-NOWRAP` now on the row. |
| 5, 6, 12 | A | Two planes; `observe` reads result allocations. |
| 10, 11, 16–19, 21–23, 25, 27–31 | scope | WC, budget name, leftover vs independent limits, units, beacon pull, packed model in `missing`. |


1. **The headline bound assumes the result it proves.**
   `well_formed_batch` requires `b.allocations = transition b cfg`, and `transition` is `consumeBudget` of a budget that is already `min(…, maxTopUpPerBlockGwei)`. Then `sum allocations ≤ blockCap` is `consumeBudget_sum_le`. Any list already defined to be the leftover-budget walk is bounded by that budget.

   *Counterexample to reading this as a property of TopUpGateway.* Construct `b` with `allocations = [10^18]`, `maxTopUpPerBlockGwei = 1`. `well_formed_batch` is false (transition would have allocated 1), so the theorem does not apply. The *deployed* gateway (`TopUpGateway.sol:226–232`) writes **independent** `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei` and sums them; it never walks a leftover budget. A bug that skipped the later router `sum ≤ cap` check would produce exactly that `b`. The CHECKED theorem cannot see the bug because such an output is excluded by the hypothesis, not refuted by the code.

2. **`txRun` is not independent of `sourceRun`.**
   The comment (`Topup2DistributionTx.lean:67–68`) says the correspondence theorem is the boundary. The definition calls `sourceCandidates` / `sourceConsume` and the equality is `rfl`.

   *Counterexample to independence.* Change `gap < minTopUp` to `gap ≤ minTopUp` inside `sourceEvaluateLimit` (or the helper `sourceCandidates` calls). Both `txRun` and `sourceRun` change; `txRun_eq_sourceRun` remains `rfl`. The CHECKED equality cannot see a shared off-by-one on the min-top-up test.

3. **SSZ / activation / 0x02 / role / root-age are hypotheses, not executed guards.**
   `well_formed_batch` *assumes* wc = 0x02, activated, not slashed/exiting, sorted unique indices, fresh beacon root. `TopUpGateway.topUp` *enforces* those or reverts. Scenario: a caller without `TOP_UP_ROLE` or with a failed Merkle proof. Live gateway reverts. The Nat model never sees the caller; a well-formed batch can still be written down and the cap theorem applies to it. The Verity tx likewise has no role check — it will allocate if the arrays decode.

4. **Nat vs checked addition (documented, still CHECKED).**
   *Scenario.* Validator with `effectiveBalanceGwei = 2^256 − 1`, `pendingBalanceGwei = 1`. Solidity reverts in `_evaluateTopUpLimit`. `evaluated_topup_limit` computes `currentTotal = 2^256`, then `≥ target` or a wrap-free Nat gap. The abstract cap theorem still holds of the Nat numbers. `audit/P-TOPUP-2-CORRESPONDENCE.md` called this a reason to keep SOURCE/TX OPEN. Promoting the row to CHECKED does not remove the mismatch.

5. **No theorem that the Verity allocations satisfy `well_formed_batch`.**
   Different types (`Word` lists vs `TopupBatch`). `verity_tx_simulates_topup2_spec` never mentions `maxTopUpPerBlockGwei`.

   *Scenario.* Call `allocate` with `remainingCap = moduleLimit = valueGwei = 10^18`. It commits `used` up to that budget. A configured on-chain `maxTopUpPerBlock` of 1 gwei is not an input unless the harness happens to pass it. CHECKED Verity does not imply the abstract cap.

6. **`observe` on revert reports caller-supplied `beforeAllocs`, not storage.**
   *Scenario.* `failAfterWrites = true` after `writeAllocs`. `Contract.run` restores the snapshot (monad). `observe` on revert returns the `beforeAllocs` argument (`List.replicate n 0` in the facade), not a storage read. A mutant that skipped `Contract.run` and left dirty maps would still present a clean View if someone only looked at `observe`.

7. **Slash / exit is dropped on the executed plane.**
   Abstract `evaluated_topup_limit` returns 0 if `v.exiting || v.slashed`. Source/Verity `sourceEvaluateLimit` (`Topup2Correspondence.lean:67–72`) is only `effective + pending` vs target / minTopUp — no slash flag. The comment says this is “after activation/exit/slash filters,” i.e. those filters are assumed, not executed.

   *Counterexample.* One slashed validator, `effective = pending = 0`, `target = 32e9`, `minTopUp = 1`, `requested = remainingCap = moduleLimit = valueGwei = 32e9`. Solidity `_evaluateTopUpLimit` (`TopUpGateway.sol:403–404`) returns 0. `sourceRun` / `allocate` commit allocation `32e9`. `well_formed_batch` hides this by *requiring* `slashed = false`, so the abstract theorem never sees the case; Verity never sees the flag.

8. **The registered Verity theorem is not `Topup2Tx`’s call-program plane.**
   `Verity/Topup2Tx.lean` is an adversary-quantified `CallProgram` / `CallsIn` model that actually talks about wei on call sites (`tx_aggregate_bounded_by_block_cap`). YAML points at `PTopup2.verity_tx_simulates_topup2_spec` → `Topup2DistributionTx`, the array/`consumeBudget` script. The module header of `Topup2Tx` even records a *retracted* `tx_revert_has_failed_call` that was discharged by fabricating an unconstrained `CallObservation`.

   *Scenario.* A reader follows the CHECKED Verity name expecting “every adversary’s paid CALL sum ≤ block cap.” That lemma is not the registered theorem. The registered one never mentions an adversary or a CALL value.

9. **Mapped `_verifyValidator` (CLValidatorVerifier 44–57) is not executed.**
   `audit/source-map.yaml` lists that span for P-TOPUP-2. Neither `evaluated_topup_limit` nor `sourceEvaluateLimit` nor `allocate` calls it. Witnesses are trusted fields / absent.

   *Scenario.* A top-up with a forged Merkle proof. Live `TopUpGateway.topUp` reverts in `_verifyValidator`. Lean `verity_tx_simulates_topup2_spec` still allocates if the three numeric arrays decode. The mapped verifier span is not a premise of the CHECKED theorem.

10. **Type-0x02 is a per-validator field in Lean and a per-module field on chain.**
   `well_formed_batch` requires `v.wc = 0x02` for each `Validator`. Live `TopUpGateway.topUp` reads **one** `stakingRouter.getStakingModuleWithdrawalCredentials(moduleId)` and `_requireWithdrawalCredentials02`. `sourceEvaluateLimit` / `allocate` have no WC field at all.

   *Scenario.* Module WC is 0x01. Live top-up reverts `WrongWithdrawalCredentials`. Lean `allocate` on effective/pending/requested still commits. The abstract `wc = 0x02` conjunct is unused by `aggregate_bounded_by_block_cap` anyway.

11. **`valueWei` is the wrong resource; the gateway is not payable.**
   `TopUpGateway.topUp` is `onlyRole` / `whenResumed` and pulls from `LIDO.getDepositableEther()` after the **module** runs `allocateDeposits`. Lean treats `valueWei / GWEI` as a left-to-right `consumeBudget`.

   *Scenario.* Attacker sends `msg.value` to the gateway (it is non-payable → revert) or a module `allocateDeposits` returns a permutation that is *not* left-to-right greedy. Live `StakingRouter.topUp` (lines 696–718) takes `min(moduleShare, maxTopUpPerBlockWei)`, rounds to gwei, then calls `IStakingModuleV2(moduleAddress).allocateDeposits(...)`. The module, not the gateway, picks per-key amounts. The router only checks `allocations[i] ≤ limits[i]` and `sum ≤ smDepositableEthAmountRounded`. The CHECKED `consumeBudget` walk is not that algorithm; CSM queue-cursor advancement on a zero budget is unmodeled.

12. **`observe` on success reports `result.allocations`, not the allocation map.**
   `Topup2DistributionTx.observe` (`:140–145`) copies `result.allocations` from the value `allocate` built after `txRun`. Only remaining/used are `readSlot`.

   *Counterexample mutant.* Make `writeAllocs` a no-op. `verity_tx_simulates_topup2_spec` still holds. YAML “persists allocations through writeMapUint” is not an observed fact for the allocation column.

13. **`_requireBlockDistancePassed` is unmodeled.**
   Live `topUp` (`:179`) reverts `MinBlockDistanceNotMet` if not enough blocks since `_setLastTopUpData`. `well_formed_batch` has no block-distance field. `allocate` has no last-top-up timestamp.

   *Scenario.* Two `topUp` calls in the same block with `minBlockDistance ≥ 1`. Live second call reverts. Lean `allocate` twice (or two-batch mutant) commits both. The CHECKED tx does not implement the frequency guard.

14. **`RootPrecedesLastTopUp` is not in `well_formed_batch`.**
   Live `_verifyRootAge` (`:385–386`) reverts if `childBlockTimestamp <= lastTopUpTimestamp`. Abstract `well_formed_batch` only has `beaconRootTimestamp ≤ currentTimestamp` and `current − beacon ≤ maxRootAge`. No last-top-up timestamp.

   *Scenario.* Beacon root is fresh vs `maxRootAge` but older than the last top-up. Live `topUp` reverts `RootPrecedesLastTopUp`. A `well_formed_batch` can still be written and `aggregate_bounded_by_block_cap` applies. The CHECKED cap theorem does not know about last-top-up ordering.

15. **Activation is not on the executed plane.**
   Live `_verifyValidatorWasActivated` (`TopUpGateway.sol:390–393`) reverts if `activationEpoch > current epoch`. `evaluated_topup_limit` does not look at `activated`. `sourceEvaluateLimit` has no epoch. `well_formed_batch` requires `activated = true` and then ignores it in the cap proof.

   *Scenario.* Validator with `activationEpoch = FAR_FUTURE`, `effective = pending = 0`, `target = 32e9`, request 32e9. Live `topUp` reverts `ValidatorIsNotActivated`. Lean `allocate` commits 32e9. Same shape as the slash hole: the abstract hypothesis excludes the case; Verity never sees the flag.

16. **Same dummy memory oracle as P-ALLOC-2.**
   `Topup2DistributionTx.oracle` is `mappingSlot := fun _ _ => 0`. Arrays are planted at `0x1000` / `0x2000` / `0x3000`.

   *Scenario.* Premises `hEff` / `hPend` / `hReq` assume `readArray` already returned the three lists. A different memory layout (real ABI) would not satisfy those premises, so the CHECKED equality does not apply to a compiled `topUp` call.

17. **`consumeBudget` is saturating `Nat` subtraction, not a checked leftover walk.**
    `consumeBudget` (`PTopup2.lean:60–64`) does `min amount budget` then `budget - allocated`. `Nat.sub` saturates. Combined with issue 4 (Nat vs checked add on the gap), a `requestedGwei` entry larger than `2^256` is a legal `Nat` and is silently clamped.

    *Scenario.* `requestedGwei = [2^256]`, `budget = 32e9`. `consumeBudget` allocates `32e9` and continues. Solidity `_evaluateTopUpLimit` / `+=` on `uint256` would revert on the overflowed effective+pending that produced such a request, or the ABI would have wrapped the word already. The CHECKED leftover walk is not a `uint256[]` consumption.

18. **Per-key limits are independent on chain and a leftover walk in Lean.**
    Extends issue 1 to the executed plane. Live `TopUpGateway.sol:226–232` sets `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei` independently, then the router checks each `allocations[i] ≤ limits[i]` and `sum ≤ cap`. `transition` / `txRun` walk leftover budget left-to-right, so key `i+1` is cut because key `i` took the cap.

    *Counterexample.* Two validators, each independently eligible for 20 gwei, `maxTopUpPerBlockGwei = 20`. Live limits `[20, 20]`; module `allocateDeposits` may return `[20, 0]` or `[10, 10]` (module policy); router accepts either if `sum ≤ 20`. Lean `consumeBudget` forces `[20, 0]`. A module that returned `[0, 20]` is in-spec on chain and is not `transition`. `well_formed_batch` then *rejects* that in-spec output (issue 1). The CHECKED cap theorem is a property of a different allocator.

19. **`pendingBalanceGwei` is unauthenticated calldata; Lean treats it as a trusted word.**
    Live `_evaluateTopUpLimit(vw, _topUps.pendingBalanceGwei[i])` (`TopUpGateway.sol:226, 396–415`) takes pending from the `TopUpData` array. The SSZ witness supplies `effectiveBalance`; pending is **not** a CL field and is not `_verifyValidator`’d. `sourceEvaluateLimit` / `allocate` take a `pending` word with the same status as `effective`.

    *Scenario.* Operator submits `pendingBalanceGwei[i] = 0` for a validator that already has 16 ETH in-flight deposits. Live limit is `target − effective` (too large). `allocateDeposits` may send another 16 ETH and overshoot the target once pending lands. Lean `sourceRun` with the same lie commits the same inflated gap. The CHECKED limit is “gap vs the numbers you handed me,” not “gap vs CL + known pending.” Inflating pending shrinks the limit (self-DoS); deflating it is the over-allocation.

20. **Live `totalLimits +=` sits in `unchecked`; Lean uses `safeAdd` / `Nat`.**
    `TopUpGateway.sol:203–228` wraps the evaluation loop in `unchecked`, including `totalLimits += topUpLimits[i]`. `sourceConsume` / `sourceRun` use `safeSub` / `safeAdd` (`Topup2Correspondence.lean:75–108`). Abstract `consumeBudget` is unbounded `Nat`.

    *Counterexample.* Contrived limits whose wei sum exceeds `2^256 − 1`. Live `totalLimits` wraps (then `if (totalLimits > 0)` may be false and `_setLastTopUpData` is skipped, while `stakingRouter.topUp` still received the unwrapped per-key array). Lean `sourceRun` returns `none` on `safeAdd` overflow, or `Nat` addition stays exact. Practical batches cannot hit this (32 × 2048 ETH ≪ `2^256`); the CHECKED correspondence is still not the `unchecked` loop. The later router `sum ≤ cap` is not in `sourceRun` at all (issue 11).

21. **Lean allocations are gwei; live `topUpLimits` are wei.**
    Live line 226: `topUpLimits[i] = _evaluateTopUpLimit(...) * 1 gwei`. `sourceRun` / `allocate` stay in gwei (`valueGwei`, `target`, `minTopUp`, result `used`). The router then consumes wei.

    *Scenario.* One validator, gap 32e9 gwei (32 ETH). Lean `allocate` commits `used = 32e9`. Live writes `32e9 * 1e9 = 32e18` wei into `stakingRouter.topUp`. Comparing the CHECKED `used` word to the on-chain `topUpLimits[i]` is a `10^9`× disagreement. Feeding Lean’s number into the router as wei would top up 32 gwei, not 32 ETH. The CHECKED Verity column is not the array the router sees.

22. **`well_formed_batch` does not require 48-byte pubkeys.**
    Live `topUp` (`:208–210`) reverts `WrongPubkeyLength` unless `vw.pubkey.length == PUBKEY_LENGTH` (48). Abstract `Validator.pubkey` is an unconstrained `ByteArray`. `well_formed_batch` asks wc/activated/slash/exit, sorted unique indices, and `pubkeys.Nodup` — not length 48. `sourceEvaluateLimit` / `allocate` have no pubkey field.

    *Scenario.* Validator with `pubkey = #[]` (or 96 bytes), otherwise well-formed, gap 32e9. Live reverts. Lean `allocate` on the numeric arrays commits 32e9. `aggregate_bounded_by_block_cap` still applies to a `well_formed_batch` with empty pubkeys. The CHECKED cap theorem is silent on the length guard the gateway actually runs first.

23. **A packed ERC-7201 gateway model exists and is not the CHECKED theorem.**
    `Verity/TopupPackedStorage.lean` binds `GATEWAY_STORAGE_POSITION = 0x22e5…2200` and packed `Uint64`/`Uint32`/`Uint16` fields (`maxValidatorsPerTopUp`, `lastTopUpTimestamp`, `minBlockDistance`, `targetBalanceGwei`, …). Its header says it starts *after* the source guards and does not close SOURCE/TX. YAML CHECKED points at `verity_tx_simulates_topup2_spec` → `Topup2DistributionTx` (toy memory arrays, no packed slot).

    *Scenario.* Change `minBlockDistance` in the packed contract; `verity_tx_simulates_topup2_spec` is unchanged (no such field). The frequency guard (issue 13) lives in the unused packed model as a *slot*, still not as a check. CHECKED “Verity of topUp” is the leftover-budget script, not the ERC-7201 layout the gateway actually stores.

24. **`maxValidatorsPerTopUp` is not a Verity guard.**
    Live `topUp` (`:174–176`) reverts `MaxValidatorsPerTopUpExceeded` when `validatorsCount > $.maxValidatorsPerTopUp`. Lean `allocate` reverts only on `count == 0`. `maxValidatorsPerCall` exists on `well_formed_batch` and is unused by `aggregate_bounded_by_block_cap`; `allocate` does not take the field.

    *Scenario.* `maxValidatorsPerTopUp = 2`, three eligible keys, each gap 1 gwei, budget 3. Live reverts. Lean `allocate 3 …` commits `[1, 1, 1]`. The executed CHECKED tx allocates a batch the gateway rejects before `_evaluateTopUpLimit`.

25. **Same 128-word memory alias as P-ALLOC-2.**
    `Topup2DistributionTx.memoryFor` plants effective at `0x1000`, pending at `0x2000`, requested at `0x3000`. Length `≥ 129` makes `0x1000 + 32·128 = 0x2000`: pending[0] reads as effective[128].

    *Counterexample.* 129 validators, `effective[128] = 99`, `pending[0] = 0`. `readArray "pending"` returns a list whose head is `99`. `hPend` fails, or a raw `allocate` evaluates the wrong gap. Live `uint256[]` pending is a separate calldata array. Combined with issue 16 (dummy oracle), the CHECKED decoder is a layout that is false above 128 keys (`maxValidatorsPerTopUp` is typically much smaller — issue 24 — but the decoder does not know that).

26. **`A-TOPUP-NOWRAP` is HIGH and not on this row.**
    `audit/assumptions.yaml` accepts `A-TOPUP-NOWRAP`: unbounded `Nat` matches Solidity only when the sum stays below `2^256`. It is listed on P-TOPUP-1, not on P-TOPUP-2 (`guarantees.yaml` assumptions are only `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`). Issue 4 is exactly that wrap: `evaluated_topup_limit` / `consumeBudget` are `Nat`; live `_evaluateTopUpLimit` / `* 1 gwei` / `totalLimits +=` (unchecked) are words.

    *Scenario.* `effective + pending` overflows `uint256`. Live reverts. Lean Nat gap is well-defined and `aggregate_bounded_by_block_cap` holds. The campaign already named this risk HIGH and asked every consuming theorem to keep an explicit NoUncheckedWrap premise. The CHECKED P-TOPUP-2 theorems do not. Promoting the row to CHECKED dropped the assumption rather than discharging it.

27. **Gwei alignment is only an abstract `well_formed` conjunct.**
    Abstract `well_formed_batch` requires `valueWei % GWEI = 0`. Live `topUp` is not payable and has no `valueWei`; it writes wei via `* 1 gwei` (issue 11, 21). `allocate` / `sourceRun` take `valueGwei` already divided; there is no `% 10^9` check.

    *Scenario.* Harness passes `valueGwei = 32e18` thinking it is wei. Lean treats it as 32e18 gwei (~32 million ETH) and allocates up to that budget. Combined with issue 21, the CHECKED Verity column has no alignment guard the abstract theorem pretends to have, and the live function never saw a `valueWei` field at all.

28. **One `count` is used for all three arrays; short memory reads as 0.**
    Live `topUp` (`:163–171`) reverts `WrongArrayLength` unless four arrays plus witnesses all have the same nonzero length. Lean `allocate count` (`Topup2DistributionTx.lean:112–117`) reads `count` words from each of three bases. `memoryFor` returns 0 outside the planted range. A short `requested` list is padded with zeros, not rejected.

    *Scenario.* `count = 3`, planted `requested = [10, 10]` (two words). `readArray "requested"` returns `[10, 10, 0]`. `txRun` treats the third validator as requesting 0 and may still allocate the first two. Live would have reverted before evaluation. Combined with issue 25 (128-word alias), the CHECKED decoder can invent trailing zeros instead of `WrongArrayLength`.

29. **Router `amount += allocations[i]` is `unchecked`; Lean `safeSub`s leftover.**
    Live `StakingRouter.topUp` (`:722–734`) sums module-returned wei in `unchecked`, then requires each `allocations[i] % 1 gwei == 0` and `allocations[i] ≤ _topUpLimits[i]`. `sourceConsume` uses `safeSub` on gwei words and has no wei-alignment test on the output.

    *Counterexample.* Module returns `[1]` wei (not gwei-aligned). Live reverts `AmountNotAlignedToGwei`. Lean `allocate` never sees the module return; it *is* the leftover walk (issue 18). A 1-wei allocation is unrepresentable as a Lean gwei word that came from `consumeBudget`. Combined with issue 20 (gateway `totalLimits +=` also unchecked), both live sums that the CHECKED row claims to simulate are wrapping loops, and the executed Lean tx is a different algorithm in a different unit.

30. **`withdrawDepositableEther` + `makeBeaconChainTopUp` are not in `allocate`.**
    After the module returns, live router (`:741–755`) pulls ETH from Lido (`withdrawDepositableEther(amount, 0)` — P-RESERVE-1’s spend) and `BeaconChainDepositor.makeBeaconChainTopUp`, then `assert`s the router’s ETH is unchanged. Lean `allocate` writes a gwei map and remaining/used slots.

    *Scenario.* Module returns 32e18 wei. Live pulls 32 ETH from the Lido buffer and deposits it to the beacon deposit contract with 0x02 WC. Lean `verity_tx_simulates_topup2_spec` commits `used = 32e9` (gwei) and never moves ETH. A bug that pulled and then failed to deposit (assert would fire) cannot appear. The CHECKED “top-up” is not a deposit.

31. **Live `_setLastTopUpData` runs only when `totalLimits > 0`.**
    `TopUpGateway.sol:234–236`: `if (totalLimits > 0) _setLastTopUpData()`. A all-zero-limit batch does not move the last-top-up timestamp, so a second call in the same block is allowed. Lean `allocate` has no last-top-up field (issue 13). `well_formed_batch` has no such conjunct.

    *Scenario.* Three validators all already at target (limits 0). Live `topUp` succeeds, does not write last-top-up, and a second `topUp` in the same block is allowed. A later non-zero batch in that block also succeeds. If Lean modeled block distance as “any previous allocate,” it would wrongly reject the second call. The CHECKED tx cannot represent either policy: it has no timestamp at all.
