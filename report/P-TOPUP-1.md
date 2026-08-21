# P-TOPUP-1 — Beacon-Chain Top-Up Conservation & Rollback

> Operator round (2026-08-21). ChatGPT UI pool was unreachable from this session (`SANDBOXED_API_URL` unset), so these two sections are written from the live Lean parents, `audit/guarantees.yaml`, and the 2026-08-20 wrap memo. They are not GPT-5.6 Pro quotes.

## Auditor note

P-TOPUP-1 is the beacon-chain top-up path on `StakingRouter.topUp` (`lidofinance/core@af095e48`, lines 679-759). A type-2 module asks the router to pull depositable ether from Lido and push per-validator top-ups to the beacon depositor. P-TOPUP-2 owns per-key limits. P-ALLOC-1/2 own how the amounts array is filled.

The registered abstract parent `source_topup_conserves_and_rolls_back` is four conjuncts on the source-shaped `run`:
1. `pulled = pushed` on every branch, with abstract-tx rollback of a reverting observation.
2. An unregistered module reverts `revertStakingModuleUnregistered`.
3. If the unchecked line-732 accumulator wraps (`¬ NoUncheckedWrap`), `run` itself moves no wei (`pulled = pushed = 0`). Wrap-to-zero is `committedNoTopUp`, not a revert.
4. Non-type-2 withdrawal credentials revert `revertWrongWithdrawalCredentialsType`.

Over-target (line 737), zero-sum (line 741), Lido-side amount guards (Lido.sol 842/873), the line-744 pull, the funded router balance, and the line-755 assert all read `wrappedTotal = exactTotal % 2^256`. The wrap witness `wrapInput` (allocations `[2^256-1, 2]`) still reverts `revertAssertBalanceUnchanged` because wrapped pull `1` is not exact push `2^256+1`. Kill-line `dropped_conservation_assert_kill_line_refutes_parent` drops only that assert and commits with `pulled ≠ pushed`. Dual `unwrapped_accumulator_kill_line_refutes_parent` shows the wrap-ignoring mutant committing. `wrap_to_zero_commits_no_topup` is the honest wrap-to-zero empty-commit control.

The Verity parent `verity_tx_simulates_source` is a forall under `allocations.length ≤ 2^256`, each allocation a uint256 word, and `(run cfg inp).reverts = false`. It does not assume `NoUncheckedWrap`. On those premises, `observe` of `execute.run` equals `sourceObservables` (wrapped totals, including wrap-to-zero empty success), pulled/pushed agree, and every injected revert restores the entry snapshot.

## Proof issues and recommendations

The residual exact-reading gap is closed. Both planes now read `wrappedTotal = exactTotal % 2^256` at line 737, line 741, and Lido.sol 842/873. Abstract conjunct 3 is wrap precludes a value-moving commit. Verity no longer assumes `NoUncheckedWrap`; wrap-to-zero is an executed empty success.

Quantifier strength still differs: Verity keeps `hCommit` (`(run cfg inp).reverts = false`), so a nonzero wrap is excluded because the source run reverts rather than because it is an executed Verity observation. `sourceObservables` describes the wrapped success schedule, which `execute` does not produce on a nonzero wrap (the push frame fail-closes). YAML `fidelity.missing` records that gap plus beacon-address provenance. Do not derive a top-up `LinksSource` from ALLOC.

## Registered Theorem

`source_topup_conserves_and_rolls_back` is the single theorem registered as
P-TOPUP-1's CHECKED abstract claim in `audit/guarantees.yaml`. Its type is a
four-conjunct claim, not just conservation/rollback:

| Conjunct | Claim |
|---|---|
| 1 (conservation/rollback) | `pulled = pushed` on every branch — genuinely assert-backed since wave 5: `run`'s value-moving tail reads the on-chain `unchecked` accumulator (the line-732 sum reduced mod 2^256) for the line-744 pull, the funded router balance, and the line-755 assert, so reaching the commit means the assert passed with the wrapped pull equal to the exact push; a reverting outcome restores pre-state (`A-ABSTRACT-TX`) |
| 2 (module guard) | `moduleExists = false` ⇒ `run` returns `revertStakingModuleUnregistered` |
| 3 (wrap discharge) | If the unchecked sum wraps mod 2^256, `run` itself moves no wei (`pulled = pushed = 0`). A nonzero wrap still aborts on the value-moving tail; wrap-to-zero is `committedNoTopUp`. `A-TOPUP-NOWRAP` lives here, in the wrap antecedent, and in the discharged-balance-guard theorems — not in conjunct 1, and not as a Verity parent hypothesis |
| 4 (WC-type guard) | `wcTypeIsType2 = false` ⇒ `run` returns `revertWrongWithdrawalCredentialsType` |

Each conjunct is proved by, and stated identically to, a standalone lemma
(`source_module_guard_required`, `source_wrap_precludes_value_moving_commit`,
`source_wc_type2_guard_required`) kept in the same file for readability; the
registered theorem's proof term is a direct `⟨_, _, _, _⟩` bundling of those
four facts. `verity_tx_simulates_source` is the separate CHECKED Verity claim.

Folding conjuncts 2–4 into the registered theorem (rather than leaving them as
unregistered siblings) means a regression in any one of them — dropping a
`require`, or losing the wrap-branch assert — breaks `source_topup_conserves_and_rolls_back`
itself, which is the theorem `audit/guarantees.yaml`, `scripts/audit_metadata.py`,
and `scripts/check_public_claim_surfaces.py` all track, not only a sibling
lemma the assurance registry never cites.

## Wave 2: Folding Guards Into the Registered Parent

Wave 1 (`aea23ba`) added `source_wrap_implies_assert_revert`,
`source_module_guard_required`, and `source_wc_type2_guard_required` as
theorems in this module, plus three "kill-line" mutants in
`TopupTxMutants.lean` pinning their concrete behavior. None of the three was a
conjunct of the registered `source_topup_conserves_and_rolls_back`, so a
regression that silently dropped one of those guards from `run` (or lost the
wrap discharge) would have broken only a sibling lemma the registry never
cites — the registered theorem, and the `make test` gate built around it,
would have kept passing.

Wave 2 closes that gap by making `source_topup_conserves_and_rolls_back`'s own
type the four-conjunct claim above, and by rewriting the three kill-line
mutants (below) to derive their conclusion from a direct projection of that
same registered theorem at a concrete witness, instead of an independent
`by decide`. A regression in any guard or the wrap discharge now fails the
registered theorem's build, and every kill-line that projects from it fails
right along with it.

## Wave 4: Real Kill-Lines on Mutants of the Parent's Own Model

Wave-4 review found that the wave-2 "kill-lines" were still not kill-lines:
each merely *projected* the registered parent's own conjuncts at concrete
inputs, proving the HONEST model satisfies the parent. No mutant artifact was
defined and nothing was refuted; conjunct 1 (conservation) had no kill-line at
all; and `A-TOPUP-NOWRAP` was misattributed to conjunct 1, whose exact-`Nat`
conservation is in fact unconditional.

Wave 4 remediates this in `LidoSRv3/Tests/TopupTxMutants.lean`:

- The three projections are renamed honestly to
  `guard_discharge_at_wrapping_input`,
  `guard_discharge_at_unregistered_module_input`, and
  `guard_discharge_at_non_type2_wc_input`. They remain as positive controls
  (honest-side witnesses projected from the registered parent); nothing in the
  audit metadata or this report calls them kill-lines anymore.
- Four real kill-lines are added, each defined over a MUTANT of the parent's
  own model (a copy of `SolidityTopup.run` / `SolidityTopupParent.accumulated`
  with exactly one guard deleted or one reading changed) and proving the
  negation of the same predicate the corresponding parent conjunct proves for
  the honest model.

### Kill-Line Mapping

| Kill line | Mutant of the parent's model | Registered conjunct refuted on the mutant | Concrete witness |
|---|---|---|---|
| `dropped_conservation_assert_kill_line_refutes_parent` | `mutantRunNoAssert`: the routed `run` with ONLY the line-755 `assert` deleted (surgical since wave 5; `mutantRunNoAssert_eq_run_of_assert_passing` / `mutantRunNoAssert_commits_where_assert_fires` pin the single edit down) | conjunct 1: mutant COMMITS with `pulled = 1 ≠ 2^256 + 1 = pushed` | `allocations = [2^256 - 1, 2]` with all limits/balances above the exact sum |
| `dropped_module_guard_kill_line_refutes_parent` | `mutantRunNoModuleGuard`: `run` without the `_requireModuleIdExists` require | conjunct 2: at an unregistered-module witness with all antecedents true, the mutant COMMITS instead of returning `revertStakingModuleUnregistered` | `moduleExists = false`, single key, allocation `[5]` |
| `dropped_wc_guard_kill_line_refutes_parent` | `mutantRunNoWcGuard`: `run` without the `_requireWCType2` require | conjunct 4: at a non-type-2 witness with all antecedents true, the mutant COMMITS instead of returning `revertWrongWithdrawalCredentialsType` | `wcTypeIsType2 = false`, single key, allocation `[5]` |
| `unwrapped_accumulator_kill_line_refutes_parent` | `mutantRunUnwrapped`: the assert-drop mutant's dual — the routed `run` with the `unchecked` wrap ignored, so the pull, funded-balance guard, and line-755 assert all read the exact `Nat` sum (equivalently, the pre-wave-5 honest `run`) | conjunct 3: at the wrapping witness, the honest routed `run` reverts via the assert while the wrap-ignoring mutant COMMITS with `pulled = pushed = 2^256 + 1` | `allocations = [2^256 - 1, 2]` |

The Verity-plane mutants earlier in that file
(`skipped_allocation_write_rejected`, `dropped_push_rejected`, etc.) refute
`observe … ≠ sourceObservables` for mutated Verity executes — the sibling
faithful plane, not the registered abstract parent's conjuncts — and are
unchanged.

## Wave 5 (2026-08-19): Routing the Wrap Through `run`; a Surgical Conservation Kill-Line

Wave-5 review found the wave-4 conservation kill-line
`dropped_conservation_assert_kill_line_refutes_parent` was built on a
MULTI-EDIT mutant: the wave-4 `mutantRunPushNoAssert` (1) deleted the
line-755 assert branch, (2) rewrote the pull field from the exact
`totalAllocated` to the wrapping `accumulated`, and (3) rewrote
balance-after to the wrapped reading. At the witness `wrapInput`
(`allocations = [2^256 - 1, 2]`) the honest exact-`Nat` assert was DEAD
(`totalAllocated = pushedValue = 2^256 + 1`, never fires), so the kill's
lethality came entirely from edit (2) — the pull-field wrap rewrite — not
from the advertised assert deletion. Counterfactual: assert-drop alone
leaves `pulled = pushed`; the pull rewrite alone kills even with the assert
kept. The kill-line therefore did not demonstrate what its name and the
YAML/report claimed (that dropping the line-755 assert breaks conservation).

Wave 5 remediates this by closing the first wave-4 fidelity gap — "wrap
accumulator is not routed through `run`" — and rebuilding the kill-line on
the routed model:

- **Routing** (`LidoSRv3/Audit/Source/TopupCorrespondence.lean`): the honest
  `run`'s value-moving tail `runPush` now reads the on-chain `unchecked`
  accumulator semantics — the line-732 sum reduced mod 2^256, exposed as
  `SolidityTopup.accumulated` — for the line-744 pull field, the funded
  router-balance guard, and the line-755 assert, matching
  `StakingRouter.sol` line 732's `unchecked` block and the line 744 pull.
  `routerBalanceAfter` and the `Outcome` accessors are updated consistently,
  and the exact-`Nat` reading (`totalAllocated`) remains available where the
  earlier guards use it. The new theorem `SolidityTopup.run_reverts_of_wrap`
  proves the honest `run` reverts on any wrapping batch: the wrapped pull is
  strictly below the exact pushed total, so the push is underfunded or the
  assert fires. Every other guard/branch is unchanged; the over-target
  comparison (line 737), the zero-sum test (line 741), and the Lido-side
  amount guards (`Lido.sol` 842/873) still read the exact `Nat` sum — a
  residual fidelity gap, now recorded in `audit/guarantees.yaml`, under which
  a wrap can change *which* revert fires first but not that a wrapping batch
  reverts.
- **Re-aimed parent** (`LidoSRv3/Audit/Guarantees/PTopup1.lean`): conjunct 1
  is now genuinely assert-backed — under a wrap the commit cannot happen (the
  assert fires), so conservation on the commit branch is real content, not a
  same-array `Nat` fact. Conjunct 3 is restated as the direct
  "wrap ⇒ `run` reverts" fact about `run` itself
  (`¬ NoUncheckedWrap inp → (run cfg inp).reverts = true`), proved by the
  renamed standalone lemma `source_wrap_implies_revert` (was
  `source_wrap_implies_assert_revert`, which concluded
  `SolidityTopupParent.accumulated ≠ pushedValue` on a separate
  finer-grained reading). Conjuncts 2 and 4 are intact.
  `SolidityTopupParent.accumulated`/`routerBalanceAfterWrapped` were retired;
  the parent module now uses the routed `SolidityTopup.accumulated` /
  `routerBalanceAfter`.
- **Surgical kill-line** (`LidoSRv3/Tests/TopupTxMutants.lean`):
  `mutantRunNoAssert` is now the routed `run` with ONLY the line-755 assert
  branch deleted — a single edit. Two characterization theorems in the
  P-DEPOSIT-1 style pin the edit down:
  `mutantRunNoAssert_eq_run_of_assert_passing` (wherever the assert passes,
  the mutant coincides with the honest `run`, branch for branch) and
  `mutantRunNoAssert_commits_where_assert_fires` (wherever the honest `run`
  hits `revertAssertBalanceUnchanged`, the mutant commits the push). The
  kill-line then honestly shows: dropping the assert lets the wrapping batch
  `wrapInput` commit with `pulled = 1 ≠ 2^256 + 1 = pushed` — the wrapped
  pull against the exact push.
- **Dual kept, honestly labeled**: `mutantAccumulatedUnwrapped` is retired;
  `unwrapped_accumulator_kill_line_refutes_parent` now runs on
  `mutantRunUnwrapped`, the assert-drop mutant's dual — the routed `run`
  with the wrap ignored (equivalently, the pre-wave-5 honest `run`). At
  `wrapInput` the honest routed `run` reverts via the assert while the
  wrap-ignoring mutant commits with `pulled = pushed = 2^256 + 1`, showing
  the routing itself is load-bearing for the wrap discharge. The module/WC
  guard mutants and their kill-lines are unchanged (wave-5 review verified
  them surgical).
- **Verity plane**: `verity_tx_simulates_source` still builds unchanged in
  statement; its `pulled`/`pushed` conjuncts now bridge `accumulated` and
  the exact `allocSum` via `allocSumUnchecked_eq_allocSum` under the
  `NoUncheckedWrap` premise. No commit values changed on the Verity
  witnesses — they do not wrap, so the wrapped and exact readings coincide
  there. The `guard_discharge_at_wrapping_input` positive control now shows
  the honest `run` itself reverting at `wrapInput`, and pins the revert to
  the line-755 assert (`run killCfg wrapInput = .revertAssertBalanceUnchanged`).

## Wave 6: wrappedTotal on both planes

The residual exact-reading guards now read the same wrapped word the chain
reads. Over-target (line 737), zero-sum (line 741), Lido-side amount guards
(`Lido.sol` 842/873), the line 744 pull, the funded router balance, and the
line 755 `assert` all use `accumulated` (`wrappedTotal = exactTotal % 2^256`).

Conjunct 3 is therefore `source_wrap_precludes_value_moving_commit`, not wrap
implies revert. `wrap_to_zero_commits_no_topup` shows
`allocations = [2^256-1, 1]` committing `committedNoTopUp` with
`pulled = pushed = 0`. A nonzero wrap at `wrapInput` still hits the line-755
assert. The four surgical kill-lines are unchanged in predicate: dropping the
assert still commits `pulled ≠ pushed`; the wrap-ignoring dual still commits
the wrapping batch.

Verity `verity_tx_simulates_source` dropped the `NoUncheckedWrap` hypothesis.
It keeps `hLen`, a per-allocation uint256 bound `hAmt` (strictly weaker than
sum no-wrap), and `hCommit`. Wrap-to-zero is included as
`execute_observes_source_wrapped_zero`. A nonzero wrap is excluded because
the source run reverts (`hCommit`); that remaining quantifier mismatch is
listed in YAML `fidelity.missing`.

## Scope Exclusions

- Per-validator amount computation and limit accounting → P-TOPUP-2.
- Allocation algorithm producing `_amounts` → P-ALLOC-1/2.
- SSZ deposit-data-root → P-SSZ-1.
- Beacon-address provenance: named assumption, not a parent conjunct.
- `LinksSource` derivation from ALLOC deferred until live loops are in place.
