# P-ADDRESS-1

Theorems: `PAddress1.universal_address_writer_equivariance` (parent), `PAddress1.abstract_source_verity_tx_address_equivariance` (Verity), `AddressAdmission.ownerGateKillLine_holds` (kill-line).
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Permissionless Lido entrypoints should treat two ordinary nonzero callers symmetrically: swapping callers and their address-indexed inputs should preserve admission and rename successful post-states. Singleton-actor protocol callers (`withdrawWithdrawals`, `addWithdrawalRequests`, `addConsolidationRequests`) and request-owner gates are out of scope for the Wave 1 parent. The kill line: admission on `requestWithdrawals` / `unwrap` must depend only on pause plus the caller's own balance/allowance flags, not on `msg.sender == owner`.

## Modeling

- **SOURCE** `SolidityAddress.run` over four pinned single-item writers; Wave 1 parent scopes `transferFrom`, `requestWithdrawals`, and `unwrap` (`addressEquivarianceEntryScope`); `claimWithdrawalsTo` is deferred.
- **Well-formedness** `wellFormedAddressInput`: `amount < 2^256` and coherent balance/allowance flags when those bits are true.
- **Singleton-actor exclusion** is an explicit parent hypothesis (`¬ singletonActorEntryPoint`); none of the four mapped tags are singleton-actor gated.
- **Permissionless admission** on pause/balance paths: `pause_balance_admitted_is_permissionless` for `requestWithdrawals` and `unwrap`.
- **VERITY** four `Contract.run` programs with `observeAddress = sourceAddressView` under the same amount/bounds side conditions and snapshot rollback.
- **Kill-line** `AddressAdmission.ownerGated` adds `caller == owner`; `ownerGateKillLine_holds` refutes equivariance. Source mutant `owner_gated_admission_mutant_counterexample` shows the same gate on pinned `requestWithdrawals` admission.

## Proof

**Abstract `universal_address_writer_equivariance`.** Under scope, well-formedness, and singleton-actor exclusion, `source_admission_nondiscriminatory` gives admission bit equality and `source_success_post_state_equivariant` gives post-state renaming. The extra hypotheses are carried on the registered statement for honest fidelity even when the existing source proof is unchanged.

**Kill-line.** `ownerGateKillLine_holds` is `ownerGated_not_admission_equivariant`: witness world with owner `1`, caller `1` admitted, caller `2` after balance swap rejected by the owner test. `AddressSourceMutants.owner_gate_kill_line_refutes_parent` registers this against the parent.

**VERITY `abstract_source_verity_tx_address_equivariance`.** Composes universal source swap, pinned four-entrypoint correspondence, amount/bounds observe = `sourceAddressView`, revert rollback, and renamed-post observe = `postAddressView`.

## Issues

## Resolution

**Restated Lean/English.** Wave 1 folds well-formedness and singleton-actor exclusion into the registered parent, documents pause/balance/allowance admission on scoped paths, and registers the owner-gate kill line. `claimWithdrawalsTo` remains in `fidelity.missing`.

| # | Close | Note |
| --- | --- | --- |
| 1 | B | Parent now carries `wellFormedAddressInput`, scope, and singleton exclusion hypotheses. |
| 2 | B | Kill-line mutant + `ownerGateKillLine` tie owner gate to broken equivariance. |
| 3 | scope | `claimWithdrawalsTo` deferred; classification `IMPLEMENTATION_PENDING`. |
