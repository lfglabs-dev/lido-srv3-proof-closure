# P-ALLOC-1

Theorems: `PAlloc1.checked_execute` (registered parent), `PAlloc1.active_capacity_bounded` (unregistered MathView-definitional child), `PAlloc1.verity_tx_simulates_allocation`.
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Lido SRv3’s `StakingRouter` decides how many new deposits (or top-ups) each staking module may receive. The live function is `SRLib._getModulesAllocationAndCapacity` (`lidofinance/core@af095e48`, lines 493–559), exposed as `StakingRouter.getDepositAllocations`. For every module it (1) reads `moduleId → moduleAddress` and calls the module’s `getStakingModuleSummary`, (2) computes a current allocation (active-validator count, or `ceil(stake / maxEBType1)` for type-2 / compounding modules), (3) sums those into a new network-wide validator total, then (4) sets each *active* module’s capacity to `min(share-limit target, available headroom)`.

The registered guarantee (`checked_execute`) is an execute↔MathView capacity-column correspondence: under the named checked-arithmetic bounds (`CheckedBounds`), the source-shaped executor succeeds and its capacity column equals the independent `MathView` model’s, row for row. The earlier headline — an active module cannot be given more capacity than its stake-share target *or* its available depositable/top-up headroom, the router’s anti-concentration / anti-over-allocation bound — is now the unregistered child `active_capacity_bounded`, a `Nat.min` tautology on the `MathView.capacity` definition (issue 1), not the registered claim.

## Modeling

- `A-SOURCE-SHAPED`: the Lean `Module` record is not extracted from the pinned Solidity AST; depositable / exited / stake words are trusted fields already sitting in model-local maps.
- `A-VERITY-SCAFFOLD`: `Contract.run` is a non-certified Verity 4.31 interpreter, not compiled bytecode.
- No live `getStakingModuleSummary()` / `getTotalModuleStake()` CALL. `AllocationTx.sourceBindOne` reads summary words from storage keyed by the already-bound `moduleAddress`. A module that lies, or a stale cache, is outside the model.
- Slot numbers (`moduleIdSlot = 30`, …) are a local projection, not `ROUTER_STORAGE_POSITION` / keccak map slots.
- `AllocCapacityPhase3.mappedSummaryTransaction` stubs the summary CALL: a successful adversary returning enough bytes leaves the *pre-placed* depositable slot unchanged; return data is not decoded.
- `MathView` uses unbounded `Nat`. Solidity 0.8 checked `+`/`*` revert; `CheckedBounds` is an extra hypothesis only on the SOURCE refinement, not on the headline bound.
- Inactive modules keep their current allocation as capacity (matching source line 541 / the `else` of line 542). The bound theorem requires `isActive = true`.

## Proof

**Abstract `checked_execute` (registered parent, Wave 2).** Restates `source_capacities_match_canonical` below under the parent's public name: under `CheckedBounds`, the source-shaped executor succeeds and its capacity column equals `MathView.capacities`. No `min`-tautology conjunct. The named kill-line `LidoSRv3.Tests.AllocationTxMutants.capacity_target_kill_line_refutes_parent` (`capacity := target`, skipping `wordMin`) is the explicit negation of the parent's predicate shape with the mutant executor substituted: `CheckedBounds` is discharged at the witness, the mutant commits a capacity column `[24, 24]` that disagrees with `MathView.capacities`' `[11, 11]`, so the kill-line is checked against the parent's entire statement, not half of it.

**Unregistered child `active_capacity_bounded`.** Unfold `MathView.capacity`. For an active module that definition *is* `min(targetValidators, availableCapacity)`. The two conjuncts are `Nat.min_le_left` and `Nat.min_le_right`. No induction, no source loop, no share-limit algebra — this is a fact about the `min` operator applied to whatever two `Nat`s `MathView` computed, true regardless of whether those `Nat`s are the router's actual target/headroom. Wave 1 folded this into the registered parent as `checked_execute_and_active_capacity_bounded`; Wave 2 demoted it back out (issue 1) because a definitional tautology in a registered parent cannot be targeted by any kill-line mutant.

**SOURCE `source_capacities_match_canonical`.** Under `CheckedBounds` (nonzero `maxEBType1`, no underflow on exited-count, no `uint256` overflow on the sums/products), a pair of inductions on `firstLoop` / `secondLoop` show each `safe*` word equals the corresponding `Nat` operation, so the checked interpreter’s capacity column equals `MathView.capacities`. Router order is a structural list-map identity (`secondLoop_router_order`).

**VERITY `verity_tx_simulates_allocation`.** Assume `sourceBindAll state n = modules`. `txBindOne` is a character-for-character copy of `sourceBindOne`; `txBindOne_eq_sourceBindOne` is `rfl`. The transaction re-runs the same two loops, writes capacity/allocation maps, and `observe` reads those maps back. Equality with `sourceView` is therefore the bind identity plus the already-checked SOURCE interpreter. Revert-rollback is `Contract.run` restoring the snapshot, including an injected `failAfterWrites` hook.

## Issues

## Resolution

**Restated Lean/English.** `active_capacity_bounded` is `MathView.capacity = min`, not a live router clamp. Verity names `hBind` and reads persisted arrays.

Closed in the 2026-08-18 honesty + encoding repair. Lean theorems stay CHECKED
on their (now honest) statements. No pinned-core counterexample was found.
`A` = YAML/`fidelity.missing`/assumption. `B`/`C` = Lean premise or encoding
repair that keeps the existing proof. `D` = register an already-proved sibling.
`scope` = accepted as an explicit fidelity gap; not expanded to full Lido.

**Wave 2 (2026-08-19): registered-parent repair for issue 1.** The 2026-08-18
`A+D` close kept `active_capacity_bounded`'s `Nat.min` tautology conjoined
into the registered parent (`checked_execute_and_active_capacity_bounded`)
and pointed at the unrelated `P-ALLOC-1.eugene-bound` sibling instead of
touching the parent statement itself, so the tautological conjunct was still
part of every CHECKED claim about P-ALLOC-1 and still could not be killed by
any mutant. This wave splits the Wave 1 parent: the registered parent is now
`checked_execute` (`source_capacities_match_canonical`'s statement, renamed
to the public parent name), and `active_capacity_bounded` is kept only as an
explicit, unregistered, separately labeled MathView-definitional fact. The
existing kill-line mutant in `AllocationTxMutants.lean` (`capacity := target`)
is unchanged in substance and is now checked against the parent's entire
(purely executable) statement instead of half of a conjunction. Issue 1 is
reclassified `B` below.

**Wave 5 (2026-08-19): kill-line naming.** The parent kill-line was an
anonymous `example`; it is now the named theorem
`LidoSRv3.Tests.AllocationTxMutants.capacity_target_kill_line_refutes_parent`,
strengthened to the explicit negation of the registered parent's predicate
shape with `executeMutant` substituted: `CheckedBounds` discharged at the
witness, the mutant commits, and `Option.map` of its capacity column differs
from `MathView.capacities`. No other theorem statement changed.

| # | Close | Note |
| --- | --- | --- |
| 1 | B (Wave 2) | Registered parent is now `checked_execute` (no `min` conjunct); `active_capacity_bounded` is an explicit unregistered child. `P-ALLOC-1.eugene-bound` remains an unrelated sibling. |
| 2, 12, 16 | A | SOURCE/TX are lockstep copies. |
| 3, 4 | scope | Live summary CALL/returndata listed in `missing`. |
| 5, 14, 17 | A | Unbounded-Nat min; `CheckedBounds` is a separate sibling. |
| 6 | C | Fixed in PR #105: `observe` reads the persisted `writeArray` columns (`AllocationTx.lean:132–136`); the write-noop mutant `allocateNoWrite` is rejected. |
| 7 | scope | Packed `ModuleStateConfig` in `missing`. |
| 8, 9 | C | Active is status `== 0`; type-2 is WC `== 2`; seed writes 0/1 and 2/1. |
| 10 | A | Named `_getModulesAllocationAndCapacity` only. |
| 11 | scope | Unique `moduleAddress` in `missing`. |
| 13, 15, 19 | A | `count` is a harness argument; `hBind` already required. |


1. **The headline abstract bound is a tautology of `min`.**
   `MathView.capacity` for `isActive = true` is defined as `min(target, available)`. `active_capacity_bounded` restates `min a b ≤ a ∧ min a b ≤ b`. It would hold for any two Nats, including a model that computed the wrong target or the wrong headroom. It does not prove that the *router* clamps capacity; it proves that the *definition* that already is a clamp is a clamp.

   *Counterexample to the intended guarantee, not to the Lean statement.* Take `targetValidators = 10^9` (share limit 10000, huge `totalValidators`) and `availableCapacity = 10^9` (a module that advertised `depositableCount = 10^9`). The theorem holds (`min` of those is still `≤` both). On the deployed router the same inputs produce a capacity of `10^9` validators. The “bound” did not constrain anything the share-limit or depositable-count already failed to constrain.

2. **Verity bind is definitional, not a correspondence.**
   `txBindOne` and `sourceBindOne` are the same function (`AllocationTx.lean:73–86` vs `104–116`; `txBindOne_eq_sourceBindOne` is `rfl`).

   *Counterexample to “two independent artifacts.”* Edit only a comment in `txBindOne`. The equality still holds by `rfl`. The only way to break `verity_tx_simulates_allocation` via binding is to hand-edit one copy and leave the other. A solc that emitted the wrong key would not be one of those copies.

3. **No module callback, so a lying / stale summary is in-model.**
   Deployed `SRLib` lines 516–517 call `getIStakingModule()` then `getStakingModuleSummary`; line 529 is a **second** CALL `getIStakingModuleV2().getTotalModuleStake()` for type-2 modules. The Verity tx never performs those CALLs. Scenario: module address `0xM` is stored; the summary map at `0xM` still holds yesterday’s `depositableCount = 100` while the live module now reports `0`. `verity_tx_simulates_allocation` commits capacity 100. The deployed view function would read `0`. The guarantee as a claim about `getDepositAllocations` is false under any desynchronised summary.

4. **Phase-3 “mapped summary” does not parse return data.**
   `mappedSummaryTransaction` (PAlloc1.lean:14–54) is not used by `verity_tx_simulates_allocation`. Its `CallsIn` adversary always returns `success (replicate summaryReturnBytes 0)` and a no-op `stateTransition`. On a long-enough success, `executeObservedSummary` leaves `lastCapacitySlot` equal to the *pre-written* `depositable`. The 4-byte selector `0x9abddf09` is the real `getStakingModuleSummary()` selector; that is the honest fragment.

   *Scenario.* Module returns 96 bytes of `0xff` (a huge depositable). Lean still commits with the old slot. The Phase-3 conjunct is “the stub CALL happened,” not “capacity came from returndata.”

5. **`CheckedBounds` is not proved of any reachable router state.**
   If `maxEBType1 = 0`, Lean `Nat` division in `MathView.availableCapacity` is `0`; Solidity `activeCount * maxEBType2 / maxEBType1` reverts. The abstract bound still “holds” (capacity 0 ≤ 0). The SOURCE refinement simply does not apply. No theorem says a configured SRv3 router satisfies `CheckedBounds`.

   *Scenario.* Misconfigured `maxEBType1 = 0` on a type-2 top-up. Live `getDepositAllocations` reverts. `active_capacity_bounded` reports capacity 0 and succeeds. CHECKED does not mean “the router cannot be in the reverting configuration.”

6. **`observe` read the returned `Result`, not the written maps.** **Resolved** (observe-from-storage repair, PR #105): `AllocationTx.observe` on success now reads the persisted arrays — `state.readArray allocationSlot`, `state.readArray capacitySlot`, `state.readArray boundAddressSlot` — plus `state.readSlot totalSlot` (`AllocationTx.lean:132–136`), and the write-noop mutant `allocateNoWrite` in `AllocationTxMutants.lean` is rejected precisely because `observe` reads the storage arrays. Historical statement: `observe` took `result.allocations`, `result.capacities`, `result.moduleAddresses` from the value `allocate` constructed *before* looking at the writes; only `totalValidators` was `state.readSlot totalSlot`.

   *Counterexample mutant (now rejected).* Make the row persistence a no-op (or write `0` for every capacity) while keeping the `Result` triple built from `rows`. Before the fix, `verity_tx_simulates_allocation` still held; after the fix, the mutant disagrees with `observe`.

7. **Share-limit / status / WC-type live in one packed Solidity slot; Lean uses separate maps.**
   `ModuleStateConfig` (`SRTypes.sol:118–136`) packs `moduleAddress`, `uint16 stakeShareLimit`, `status`, `uint8 withdrawalCredentialsType` in a single slot. `AllocationTx` reads `shareLimitSlot = 32`, `statusSlot = 33`, `wcTypeSlot = 34` as independent words. `stakeShareLimit` is `uint16`; Lean allows any `Uint256`.

   *Scenario.* A wide `SSTORE` that updates status also clobbers the packed share limit on chain. Lean `statusSlot` write (if anyone modeled one) would not touch `shareLimitSlot`. Conversely, Lean can have `shareLimit = 10001` (not a `uint16` field); target becomes `10001 * total / 10000`. The CHECKED bind/loop never sees packing.

8. **`status != 0` was the opposite of `StakingModuleStatus.Active`.** **Resolved** (bind/seed repair, PR #105): `sourceBindOne` now sets `isActive := statusSlot == 0` (`AllocationTx.lean:75`) and `seedOne` writes `0` for active / `1` for inactive (`:187`), matching the Solidity enum (`SRTypes.sol:40–43`: `Active = 0`, `DepositsPaused = 1`, `Stopped = 2`) and the `cache[i].status == Active` clamp (`SRLib.sol:542`). Historical statement: the bind set `isActive := statusSlot != 0` and `seedOne` wrote `1` for active and `0` for inactive, so the Lean harness was self-consistent and inverted vs storage.

   *Counterexample (pre-fix).* Real slot: module A `status = 0` (Active), `depositable = 100`; module B `status = 1` (DepositsPaused), `depositable = 100`. Live `getDepositAllocations` gives A `min(target, alloc+100)` and B its current allocation (no new deposits). The pre-fix Lean bind read A as inactive and B as active: A kept current allocation, B got the share-limit clamp and new depositable, so `verity_tx_simulates_allocation` on a state copied from mainnet storage computed the wrong capacities.

9. **`wcType != 0` treated type-0x01 modules as type 2.** **Resolved** (bind/seed repair, PR #105): `sourceBindOne` now sets `isType2 := wcTypeSlot == 2` (`AllocationTx.lean:76`) and `seedOne` writes `2` for type 2 / `1` otherwise (`:188`), matching the stored `withdrawalCredentialsType` values `0x01` / `0x02` (`WithdrawalCredentials.sol:13–14, 47–48`). Historical statement: the bind set `isType2 := wcTypeSlot != 0`, so type `0x01` (curated / DVT) modules took the type-2 branch — `ceil(stake / maxEBType1)` instead of active-validator count, and the top-up `active * maxEBType2 / maxEBType1` capacity — and `seedOne` hid it by writing `1` only for type 2 and `0` for type 1.

   *Scenario (pre-fix).* Curated module, `wcType = 1`, `deposited = 100`, `stake = 0`. Live allocation is `100` (active count). The pre-fix Lean bind saw `isType2 = true`, `ceil(0 / 32) = 0`; capacities and share-limit totals were computed from the wrong column.

10. **`getDepositAllocations` (the user-facing function) is not this guarantee.**
   After capacities, `SRLib._getDepositAllocations` converts to ETH and runs `MinFirstAllocationStrategy.allocate` (lines 404–421). P-ALLOC-1 stops at the capacity column.

   *Scenario.* Two modules, allocations 0, capacities 10, `depositsToAllocate = 1`. Capacities are fine; MinFirst then mis-splits the single deposit. P-ALLOC-1 still CHECKED. That bug is supposed to be P-ALLOC-2, which is a different model (see that report).

11. **Summary words are keyed by `moduleAddress`, so colliding addresses share depositable.**
    `sourceBindOne` / `txBindOne` (`AllocationTx.lean:82–85, 113–116`) read `summaryDepositableSlot[moduleAddress]` (and deposited / exited / stake). Two module ids that resolve to the same address (legal under P-DEREF-1 `Reachable` — see that report issue 7) bind the same summary.

    *Scenario.* Modules 1 and 2 both have address `0xA`. Map at `0xA` holds `depositable = 10`. Lean gives *each* module available 10, total headroom 20. Live `_addModule` reverts `StakingModuleAddressExists` on the second add, so this state does not arise; if a migration produced it, each CALL to `0xA.getStakingModuleSummary` would still return one summary, but the router would count that summary twice in the first loop. The CHECKED bind cannot tell “two modules” from “one module registered twice.”

12. **`txFirstLoop` / `txAllocationEntry?` are a second handwritten copy of `AllocCapacity`.**
    Bind equality is already `rfl` (issue 2). The loops (`AllocationTx.lean:124–138`) re-implement `txActiveCount?`, `txCeilDiv?`, type-2 `ceil(stake / maxEBType1)` vs active count — the same arithmetic `AllocCapacity.firstLoop` already runs under `sourceExecute`.

    *Counterexample to independence.* Invert `isType2` in both `AllocCapacity.allocationEntry?` and `txAllocationEntry?`. `verity_tx_simulates_allocation` still holds (both sides take the stake-ceil branch for curated modules). Combined with issue 9 (`wcType != 0` already treats 0x01 as type 2), a shared type-dispatch bug is invisible to the CHECKED equality.

13. **`allocate` takes `count` as an argument, not `getModulesCount()`.**
    Live `_getModulesAllocationAndCapacity` (`SRLib.sol:496`) sets `modulesCount = SRStorage.getModulesCount()` and walks `getModuleIdAt(i)`. Lean `allocate count` (`AllocationTx.lean:275–278`) does `txBindAll snapshot count` = `List.range count`. There is no modules-count slot.

    *Scenario.* Router has 3 modules. Harness calls `allocate 2`. Lean binds indices 0 and 1, computes a `totalValidators` that omits module 2, and clamps the first two capacities against that smaller total. Live view includes all three and a larger share-limit total. `verity_tx_simulates_allocation` holds of the 2-row fiction. The CHECKED tx is “run the loops on the first `count` map rows,” not “the router’s live module list.”

14. **`MathView.activeCount` saturates; Solidity 0.8 reverts.**
    `AllocCapacity.lean:129–130`: `(deposited : Nat) - max(summaryExited, accountingExited)`. `Nat.sub` is 0 when exited > deposited. Live `SRLib.sol:521–522` is checked `depositedValidatorsCount - Math.max(...)`. `CheckedBounds.active_subtraction` excludes this case from the SOURCE refinement only.

    *Counterexample.* `depositedCount = 10`, `summaryExitedCount = 20`, module active, `isType2 = false`. Live `getDepositAllocations` reverts. `MathView.activeCount = 0`, `capacity = min(target, 0+depositable)`. `active_capacity_bounded` holds. The CHECKED abstract bound is true of a configuration the router cannot return. Same shape as issue 5 (`maxEBType1 = 0`).

15. **`count` can exceed `MAX_STAKING_MODULES_COUNT = 32`.**
    Extends issue 13. Live `_addModule` reverts when `getModulesCount() >= 32` (`SRUtils.sol:18`, SRLib 183–231). Lean `allocate 33` is a legal tx: `List.range 33` binds 33 map rows (many default-zero). Share-limit `totalValidators` includes those zeros.

    *Scenario.* Harness calls `allocate 33` on a two-module seed. Lean walks 33 indices; ids 2..32 read as 0, share-limit total is computed over 33 rows. Live view has 2 modules. `verity_tx_simulates_allocation` holds of the 33-row fiction. The CHECKED tx is not capped by the router’s module limit.

16. **SOURCE `execute` is an alias of `AllocCapacity.execute`, not a second interpreter.**
    `AllocCapacityCorrespondence.lean:31–33`: `def execute := AllocCapacity.execute`. The file header still talks about “independent” source semantics. `source_capacities_match_canonical` compares that alias to `MathView` under `CheckedBounds`. Combined with issue 2 / 12 (`txBind` / `txFirstLoop` copies), the three “planes” are one loop plus a `Nat` `List.map`.

    *Counterexample to independence.* Change `availableCapacity?`’s type-2 formula. SOURCE `execute` changes with it (`:=`). MathView is a separate `Nat` formula, so the refinement can fail — that pair has teeth. The SOURCE *name* is not a third artifact. A reader of CHECKED “MODEL→SOURCE→TX” is looking at `MathView` vs `execute` vs a handwritten copy of `execute`. YAML’s three-layer story oversells the SOURCE export.

17. **`MathView.targetValidators` is unbounded `Nat` `shareLimit * total / 10000`.**
    Live `SRLib.sol:552` is checked `(shareLimit * totalValidators) / TOTAL_BASIS_POINTS`. `CheckedBounds.target_multiplication` excludes overflow from the SOURCE refinement. `active_capacity_bounded` uses `MathView` with no such bound.

    *Counterexample.* `shareLimit = 10000`, `totalValidators` (including `depositsToAllocate`) = `2^256`. Live `*` reverts. MathView target is `2^256`; `capacity = min(2^256, available)` still satisfies `≤ target` and `≤ available`. The CHECKED abstract bound holds of a reverting share-limit multiplication. Same shape as issues 5 and 14.

18. **The Eugene “amount ≤ capacity headroom” lemma is not this row.**
    `PAlloc1EugeneBound.checked_amount_le_bond` says MinFirst `checkedAmount` is `≤ capacity − allocation`. That is a P-ALLOC-1 × P-ALLOC-2 composition the CHECKED parent does not state. `active_capacity_bounded` is `min` tautology (issue 1); `verity_tx_simulates_allocation` stops before MinFirst (issue 10).

    *Scenario.* Capacities are fine; MinFirst then over-fills a bucket (issue 11 of P-ALLOC-2). P-ALLOC-1 stays CHECKED. The Eugene lemma would have constrained that fill and is not the registered theorem. YAML “anti-concentration / anti-over-allocation bound” is the `min` of two Nats, not `checked_amount_le_bond`.

19. **`verity_tx_simulates_allocation` assumes the bind already produced `modules`.**
    The theorem takes `hBind : sourceBindAll state modules.length = modules`. Unset map rows read as `moduleId = 0`, `moduleAddress = 0`, `status = 0` (inactive under the inverted test, issue 8), `depositable = 0`. `allocate 33` on a two-module seed (issue 15) binds 31 phantom id-0 rows.

    *Scenario.* Two real modules at indices 0,1. `allocate 5` without seeding 2..4. Bind is `[m0, m1, zero, zero, zero]`. Share-limit `totalValidators` includes three extra current-allocation 0s. Live `getModulesCount() = 2`. `hBind` holds of that 5-row fiction. The CHECKED equality is “given a list that is already the bind of `state`, re-run the loops.” It does not prove the bind is the router’s module list.
