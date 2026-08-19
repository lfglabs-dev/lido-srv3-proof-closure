# P-ADDRESS-1

Theorems: `PAddress1.universal_address_writer_equivariance` (parent), `PAddress1.abstract_source_verity_tx_address_equivariance` (Verity), `AddressSourceMutants.fixed_owner_gate_not_admission_equivariant` (kill-line).
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Permissionless Lido entrypoints should treat two ordinary nonzero callers symmetrically: swapping callers and their address-indexed inputs should preserve admission and rename successful post-states. `WithdrawalQueue.claimWithdrawalsTo` is out of scope for the parent (`addressEquivarianceEntryScope`). The kill line: admission on `requestWithdrawals` / `unwrap` must depend only on pause plus the caller's own balance/allowance flags, not on `msg.sender == owner` or any other fixed, unrenamed caller.

## Modeling

- **SOURCE** `SolidityAddress.run` over four pinned single-item writers; the parent scopes `transferFrom`, `requestWithdrawals`, and `unwrap` (`addressEquivarianceEntryScope`); `claimWithdrawalsTo` is deferred and excluded by a case-split on `hScope` in the parent's own proof, not by an unused hypothesis.
- **Permissionless admission** on pause/balance paths: `pause_balance_admitted_is_permissionless` for `requestWithdrawals` and `unwrap`.
- **VERITY** four `Contract.run` programs with `observeAddress = sourceAddressView` under the same amount/bounds side conditions and snapshot rollback.
- **Kill-line** `AddressSourceMutants.admittedFixedOwnerGated`/`runFixedOwnerGated` add a fixed, unrenamed `caller == fixedOwner` gate directly to this file's own `admitted`/`run`/`renameInput`; `fixed_owner_gate_not_admission_equivariant` refutes equivariance for that mutant. (The prior `AddressAdmission.ownerGated` toy mutant is retained only as evidence for the separate `P-ADDRESS-1.denote-admission` row — it never touches `SolidityAddress`, so it does not refute this parent.) Source fact `owner_gated_admission_mutant_counterexample` independently shows the same gate shape on pinned `requestWithdrawals` admission.

## Proof

**Abstract `universal_address_writer_equivariance`.** Takes `hScope : addressEquivarianceEntryScope inp.entryPoint` and case-splits on `inp.entryPoint`: the `claimWithdrawalsTo` branch derives `False` from `hScope` (that predicate is `False` there) and closes by `hScope.elim`; the three in-scope branches apply `source_admission_nondiscriminatory` and `source_success_post_state_equivariant` directly. `wellFormedAddressInput` and `singletonActorEntryPoint` are no longer parameters: neither restricted the conclusion (the proof only ever needed `hScope` and `a₁, a₂ ≠ 0`), and `singletonActorEntryPoint` is provably `False` for every `EntryPoint` in this model (`not_singleton_actor_entry_point`), so requiring its negation added no content while reading as a real exclusion.

**Kill-line.** `fixed_owner_gate_not_admission_equivariant` mutates the registered parent's own `admitted` on `requestWithdrawals`/`unwrap` to additionally require `caller = fixedOwner`, a hard-coded address that `renameInput` never touches (unlike the per-request `requestOwner` field, which is renamed and so stays equivariant). Witness: caller `1` (the fixed owner) is admitted; after the `1 ↔ 2` swap, caller `2` is rejected. This directly falsifies the admission conclusion `universal_address_writer_equivariance` proves, unlike the disconnected `AddressAdmission` toy denotation used previously.

**VERITY `abstract_source_verity_tx_address_equivariance`.** Composes universal source swap, pinned four-entrypoint correspondence, amount/bounds observe = `sourceAddressView`, revert rollback, and renamed-post observe = `postAddressView`. Unaffected by this remediation.

## Issues

**P-ADDRESS-1 (Wave 4 review finding).** After the kill-line was retargeted (below), the parent's `_hScope`/`_hWellFormed`/`_hNotSingleton` hypotheses were still all unused (underscore-prefixed) in the proof body, and `_hNotSingleton` was additionally content-free (`singletonActorEntryPoint` is `False` for every `EntryPoint` in this model, so its negation is a tautology for any input) — carrying them as unused binders read as real restrictions on the claim without being any. The wave-3 branch had already fixed this (`b07e40b`), but that commit never landed on main: PR #131 was closed after only the kill-line half merged.

## Resolution

**Restated Lean/English.** Wave 1 folds well-formedness and singleton-actor exclusion into the registered parent, documents pause/balance/allowance admission on scoped paths, and registers the owner-gate kill line. `claimWithdrawalsTo` remains in `fidelity.missing`.

**Wave 3 fix (2026-08-19).** The Wave 1/2 kill-line (`AddressAdmission.ownerGateKillLine_holds`) refuted only a disconnected, audit-authored toy `FunctionSpec` (`AddressAdmission.claim`/`ownerGated`), never `SolidityAddress.run`, so it did not actually refute the registered parent. Replaced the parent-facing kill-line with `AddressSourceMutants.fixed_owner_gate_not_admission_equivariant`, a one-conjunct mutation of this file's own `admitted`/`run`/`renameInput`. The toy fact is retained only as evidence for the separate `P-ADDRESS-1.denote-admission` subordinate row.

**Wave 4 fix (2026-08-19).** Ports the un-landed wave-3 branch commit `b07e40b`. `_hWellFormed` and `_hNotSingleton` are dropped from the parent (neither was load-bearing; the latter's negation is vacuous since `singletonActorEntryPoint` is `False` on every entrypoint here); `hScope` is kept and genuinely threaded through a case split that excludes `claimWithdrawalsTo` via `hScope.elim`, so the parent still makes no claim about that entrypoint and the proof fails to compile if `hScope` is removed. YAML summary/fidelity now describe the scope premise as genuinely used and record in `fidelity.missing` that singleton-actor exclusion is not modeled.

| # | Close | Note |
| --- | --- | --- |
| 1 | B | Kill-line now refutes a mutant of the real `SolidityAddress.admitted`/`run`/`renameInput`, not a disconnected toy `FunctionSpec`. |
| 2 | B | `hScope` genuinely excludes `claimWithdrawalsTo` via case split; `_hWellFormed`/`_hNotSingleton` dropped as unused/content-free rather than carried as decorative binders. |
| 3 | scope | `claimWithdrawalsTo` deferred; classification `IMPLEMENTATION_PENDING`. |
