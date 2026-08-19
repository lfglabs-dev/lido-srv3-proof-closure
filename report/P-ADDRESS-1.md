# P-ADDRESS-1

Theorems: `PAddress1.universal_address_writer_equivariance` (parent), `PAddress1.abstract_source_verity_tx_address_equivariance` (Verity), `AddressSourceMutants.fixed_owner_gate_not_admission_equivariant` (kill-line).
Assumptions: `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Permissionless Lido entrypoints should treat two ordinary nonzero callers symmetrically: swapping callers and their address-indexed inputs should preserve admission and rename successful post-states. Singleton-actor protocol callers (`withdrawWithdrawals`, `addWithdrawalRequests`, `addConsolidationRequests`) and request-owner gates are out of scope for the Wave 1 parent. The kill line: admission on `requestWithdrawals` / `unwrap` must depend only on pause plus the caller's own balance/allowance flags, not on `msg.sender == owner`.

## Modeling

- **SOURCE** `SolidityAddress.run` over four pinned single-item writers; Wave 1 parent scopes `transferFrom`, `requestWithdrawals`, and `unwrap` (`addressEquivarianceEntryScope`); `claimWithdrawalsTo` is deferred.
- **Well-formedness** `wellFormedAddressInput`: `amount < 2^256` and coherent balance/allowance flags when those bits are true.
- **Singleton-actor exclusion** is an explicit parent hypothesis (`¬ singletonActorEntryPoint`); none of the four mapped tags are singleton-actor gated.
- **Permissionless admission** on pause/balance paths: `pause_balance_admitted_is_permissionless` for `requestWithdrawals` and `unwrap`.
- **VERITY** four `Contract.run` programs with `observeAddress = sourceAddressView` under the same amount/bounds side conditions and snapshot rollback.
- **Kill-line** `AddressSourceMutants.admittedFixedOwnerGated`/`runFixedOwnerGated` add a fixed, unrenamed `caller == fixedOwner` gate directly to this file's own `admitted`/`run`/`renameInput`; `fixed_owner_gate_not_admission_equivariant` refutes equivariance for that mutant. (The prior `AddressAdmission.ownerGated` toy mutant is retained only as evidence for the separate `P-ADDRESS-1.denote-admission` row — it never touches `SolidityAddress`, so it does not refute this parent.) Source fact `owner_gated_admission_mutant_counterexample` independently shows the same gate shape on pinned `requestWithdrawals` admission.

## Proof

**Abstract `universal_address_writer_equivariance`.** Under scope, well-formedness, and singleton-actor exclusion, `source_admission_nondiscriminatory` gives admission bit equality and `source_success_post_state_equivariant` gives post-state renaming. The extra hypotheses are carried on the registered statement for honest fidelity even when the existing source proof is unchanged.

**Kill-line.** `fixed_owner_gate_not_admission_equivariant` mutates the registered parent's own `admitted` on `requestWithdrawals`/`unwrap` to additionally require `caller = fixedOwner`, a hard-coded address that `renameInput` never touches (unlike the per-request `requestOwner` field, which is renamed and so stays equivariant). Witness: caller `1` (the fixed owner) is admitted; after the `1 ↔ 2` swap, caller `2` is rejected. This directly falsifies the admission conclusion `universal_address_writer_equivariance` proves, unlike the disconnected `AddressAdmission` toy denotation used previously.

**VERITY `abstract_source_verity_tx_address_equivariance`.** Composes universal source swap, pinned four-entrypoint correspondence, amount/bounds observe = `sourceAddressView`, revert rollback, and renamed-post observe = `postAddressView`.

## Issues

## Resolution

**Restated Lean/English.** Wave 1 folds well-formedness and singleton-actor exclusion into the registered parent, documents pause/balance/allowance admission on scoped paths, and registers the owner-gate kill line. `claimWithdrawalsTo` remains in `fidelity.missing`.

**Wave 3 fix (2026-08-19).** The Wave 1/2 kill-line (`AddressAdmission.ownerGateKillLine_holds`) refuted only a disconnected, audit-authored toy `FunctionSpec` (`AddressAdmission.claim`/`ownerGated`), never `SolidityAddress.run`, so it did not actually refute the registered parent. Replaced the parent-facing kill-line with `AddressSourceMutants.fixed_owner_gate_not_admission_equivariant`, a one-conjunct mutation of this file's own `admitted`/`run`/`renameInput`. The toy fact is retained only as evidence for the separate `P-ADDRESS-1.denote-admission` subordinate row.

| # | Close | Note |
| --- | --- | --- |
| 1 | B | Parent now carries `wellFormedAddressInput`, scope, and singleton exclusion hypotheses. |
| 2 | B | Kill-line mutant (`fixed_owner_gate_not_admission_equivariant`) ties an owner gate on the parent's own model to broken equivariance. |
| 3 | scope | `claimWithdrawalsTo` deferred; classification `IMPLEMENTATION_PENDING`. |
