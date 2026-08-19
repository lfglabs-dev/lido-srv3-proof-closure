# P-TOPUP-1 — Beacon-Chain Top-Up Conservation & Rollback

## Registered Theorem

`source_topup_conserves_and_rolls_back` is the single theorem registered as
P-TOPUP-1's CHECKED abstract claim in `audit/guarantees.yaml`. Its type is a
four-conjunct claim, not just conservation/rollback:

| Conjunct | Claim |
|---|---|
| 1 (conservation/rollback) | `pulled = pushed` on every branch; a reverting outcome restores pre-state (`A-ABSTRACT-TX`, `A-TOPUP-NOWRAP`) |
| 2 (module guard) | `moduleExists = false` ⇒ `run` returns `revertStakingModuleUnregistered` |
| 3 (wrap discharge) | If the unchecked sum wraps mod 2^256, `SolidityTopupParent.accumulated ≠ pushedValue` — the line 755 assert would fire on that finer-grained reading of the pinned source |
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

### Kill-Line Mapping

| Kill line | Registered conjunct | Concrete witness |
|---|---|---|
| `kill_wrap_skip_assert` | conjunct 3 (wrap discharge) | `allocations = [2^256 - 1, 2]`; wraps, so `accumulated ≠ pushedValue` |
| `kill_remove_module_exists` | conjunct 2 (module guard) | `moduleExists = false`, all earlier guards pass ⇒ `run` reverts `revertStakingModuleUnregistered` |
| `kill_remove_wc_type2` | conjunct 4 (WC-type guard) | `wcTypeIsType2 = false`, all earlier guards pass ⇒ `run` reverts `revertWrongWithdrawalCredentialsType` |

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
