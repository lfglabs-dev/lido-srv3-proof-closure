# P-TOPUP-1 — Beacon-Chain Top-Up Conservation & Rollback

## Registered Theorem

`source_topup_conserves_and_rolls_back` is the single theorem registered as
P-TOPUP-1's CHECKED abstract claim in `audit/guarantees.yaml`. Its type is a
four-conjunct claim, not just conservation/rollback:

| Conjunct | Claim |
|---|---|
| 1 (conservation/rollback) | `pulled = pushed` on every branch — an unconditional exact-`Nat` fact with **no** `A-TOPUP-NOWRAP` hypothesis; a reverting outcome restores pre-state (`A-ABSTRACT-TX`) |
| 2 (module guard) | `moduleExists = false` ⇒ `run` returns `revertStakingModuleUnregistered` |
| 3 (wrap discharge) | If the unchecked sum wraps mod 2^256, `SolidityTopupParent.accumulated ≠ pushedValue` — the line 755 assert would fire on that finer-grained reading of the pinned source. `A-TOPUP-NOWRAP` lives here, in the wrap antecedent, and in the Verity-side `NoUncheckedWrap` premise of `verity_tx_simulates_source` — not in conjunct 1 |
| 4 (WC-type guard) | `wcTypeIsType2 = false` ⇒ `run` returns `revertWrongWithdrawalCredentialsType` |

Each conjunct is proved by, and stated identically to, a standalone lemma
(`source_module_guard_required`, `source_wrap_implies_assert_revert`,
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
| `dropped_conservation_assert_kill_line_refutes_parent` | `mutantRunNoAssert`: `run` with the line-755 `assert` deleted and the pull read through the wrapping `unchecked` accumulator | conjunct 1: mutant COMMITS with `pulled = 1 ≠ 2^256 + 1 = pushed` | `allocations = [2^256 - 1, 2]` with all limits/balances above the exact sum |
| `dropped_module_guard_kill_line_refutes_parent` | `mutantRunNoModuleGuard`: `run` without the `_requireModuleIdExists` require | conjunct 2: at an unregistered-module witness with all antecedents true, the mutant COMMITS instead of returning `revertStakingModuleUnregistered` | `moduleExists = false`, single key, allocation `[5]` |
| `dropped_wc_guard_kill_line_refutes_parent` | `mutantRunNoWcGuard`: `run` without the `_requireWCType2` require | conjunct 4: at a non-type-2 witness with all antecedents true, the mutant COMMITS instead of returning `revertWrongWithdrawalCredentialsType` | `wcTypeIsType2 = false`, single key, allocation `[5]` |
| `unwrapped_accumulator_kill_line_refutes_parent` | `mutantAccumulatedUnwrapped`: accumulator read as the exact `Nat` sum, ignoring the `unchecked` wrap | conjunct 3: at a wrapping, length-matched witness, `mutantAccumulatedUnwrapped = pushedValue` while honest `SolidityTopupParent.accumulated ≠ pushedValue` | `allocations = [2^256 - 1, 2]` |

The Verity-plane mutants earlier in that file
(`skipped_allocation_write_rejected`, `dropped_push_rejected`, etc.) refute
`observe … ≠ sourceObservables` for mutated Verity executes — the sibling
faithful plane, not the registered abstract parent's conjuncts — and are
unchanged.

## Scope Exclusions

- Per-validator amount computation and limit accounting → P-TOPUP-2.
- Allocation algorithm producing `_amounts` → P-ALLOC-1/2.
- SSZ deposit-data-root → P-SSZ-1.
- Beacon-address provenance: named assumption, not a parent conjunct.
- `LinksSource` derivation from ALLOC deferred until live loops are in place.
- The wrap-discharge conjunct (3) is a claim about `SolidityTopupParent.accumulated`/`pushedValue`,
  a separate finer-grained reading of the pinned source that models the
  `unchecked` truncation; `run`'s own `Outcome` interpreter reads the
  accumulator as an exact `Nat` sum and so cannot itself exhibit a wrap. The
  conjunct is bundled into the same registered theorem for audit tracking,
  not because `run cfg inp` reduces to `revertAssertBalanceUnchanged` under a
  wrap.
