# P-TOPUP-1 — Beacon-Chain Top-Up Conservation & Rollback

## Registered Theorems

| Theorem | Claim |
|---------|-------|
| `source_topup_conserves_and_rolls_back` | pulled = pushed on every branch; reverting outcomes restore pre-state |
| `source_wrap_implies_assert_revert` | If unchecked sum wraps mod 2^256, `accumulated ≠ pushed` — the line 755 assert reverts |
| `source_module_guard_required` | `moduleExists = false` ⇒ `revertStakingModuleUnregistered` |
| `source_wc_type2_guard_required` | `wcTypeIsType2 = false` ⇒ `revertWrongWithdrawalCredentialsType` |
| `verity_tx_simulates_source` | Executable Verity transaction reproduces source observables |

## Wave 1 Additions

### Wrap ⇒ Assert Revert (discharges A-TOPUP-NOWRAP on the wrap branch)

The `unchecked` block at source line 722 means the `amount += _amounts[i]`
accumulator at line 732 wraps mod 2^256 on overflow. Under such a wrap the
accumulated value is strictly less than the true Nat sum, which the push loop
sends in full. The balance assert at line 755 therefore fires, reverting the
transaction.

`SolidityTopupParent.wrap_implies_accumulated_ne_pushed` proves this from
`allocSumUnchecked_eq_mod` and `loopPushed_eq_allocSum`.

### Promoted Guards

`source_module_guard_required` and `source_wc_type2_guard_required` prove that
the `_requireModuleIdExists` (line 689) and `_requireWCType2` (line 694) guards
are live: removing either one allows an invalid input to reach later branches.

### Kill-Line Mutants

- `kill_wrap_skip_assert`: concrete witness that `accumulated ≠ pushed` under wrap.
- `kill_remove_module_exists`: concrete witness that `run` returns `revertStakingModuleUnregistered`.
- `kill_remove_wc_type2`: concrete witness that `run` returns `revertWrongWithdrawalCredentialsType`.

## Scope Exclusions

- Per-validator amount computation and limit accounting → P-TOPUP-2.
- Allocation algorithm producing `_amounts` → P-ALLOC-1/2.
- SSZ deposit-data-root → P-SSZ-1.
- Beacon-address provenance: named assumption, not a parent conjunct.
- `LinksSource` derivation from ALLOC deferred until live loops are in place.
