# P-DEPOSIT-1

Theorems: `PDeposit1.source_deposit_conserves_and_rolls_back`, `PDeposit1.verity_tx_composes_deposit_conservation_and_rollback`, `DepositParentTxMutants.skipped_lido_debit_breaks_pulled_eq_pushed` (kill-line).
Assumptions: `A-ABSTRACT-TX`, `A-SOURCE-SHAPED`, `A-VERITY-SCAFFOLD`.

## Intent

Lido SRv3's `StakingRouter.deposit` pulls ether from Lido and pushes it to the beacon deposit contract in a bounded two-batch loop. The guarantee says:

1. **Conservation**: the wei pulled from Lido equals the wei pushed to the beacon deposit contract on every branch of the source-shaped path.
2. **Rollback**: every reverting outcome (guards, the line-996 assert, arithmetic panics) maps onto the abstract-transaction model's `.reverted` result, restoring the pre-state and erasing all committed ETH moves and logs.
3. **Non-conserving deployment revert**: a deployment where `MAX_EFFECTIVE_BALANCE_WC_TYPE_01 ≠ DEPOSIT_SIZE` reverts on a nonempty key batch rather than committing a mismatched push.

## Modeling

- `A-SOURCE-SHAPED`: the Lean `SourceDepositConfig` / `SourceDepositInput` records are handwritten from the pinned Solidity spans, not extracted from an AST.
- `A-ABSTRACT-TX`: `revert_restores_state_value_and_logs` is the abstract-transaction axiom; the EVM plane stays open.
- `A-VERITY-SCAFFOLD`: `Contract.run` is a non-certified Verity 4.31 interpreter, not compiled bytecode.
- `LinksSource` bridges the pinned-source model to the executable transaction's inputs. It is data-only and says nothing about the post-state.
- `Preconditions` are the transaction's own executable guards.

## Composition

`verity_tx_composes_deposit_conservation_and_rollback` quantifies over every `(cfg, inp, inputs, entry)` satisfying `LinksSource` and `Preconditions`. It produces:

- (a) conservation and abstract rollback for the source model;
- (b) executable rollback: every reverting `Contract.run` restores the entry snapshot;
- (c) observable correspondence: the executable transaction reproduces the pinned source observables.

`canonical_composition_witness` discharges both hypothesis bundles on a conserving five-key deployment that actually commits, proving non-vacuity.

## Kill-line mutant

The registered parent `verity_tx_composes_deposit_conservation_and_rollback` names the conserved quantity at the `DepositParentTx` granularity: conjunct (a) is `(run cfg inp).pulled = (run cfg inp).pushed`, and conjunct (c) transports that same equality onto `Observables.pulled` / `Observables.pushed` for the honest `execute`. The kill-line lives at that identical granularity: `LidoSRv3.Tests.DepositParentTxMutants.skipped_lido_debit_breaks_pulled_eq_pushed` patches out the conservation-carrying step -- the `mutantPull .skipLidoDebit` case skips the `setStorage` that debits `lidoDepositableSlot` while still crediting the router and still sending both beacon pushes -- and shows the mutant's own `Observables.pulled` (`0`, since Lido's slot never moves) disagrees with its own `Observables.pushed` (`160`, the full two-batch total). That is the same `pulled = pushed` equality the registered parent asserts for the honest transaction, broken by patching the conserved quantity, at the same `DepositParentTx.Observables` granularity the parent composes over. The weaker, whole-record `skipped_lido_debit_rejected` (`≠ sourceObservables`) is proved alongside it for the same mutant.

`LidoSRv3.Audit.Verity.DepositLedgerTx.dropped_assert_commits_nonconserving_deployment` is a **different, disconnected model** and is not this guarantee's kill-line. `DepositLedgerTx` is a standalone single-batch ledger transaction that predates `DepositParentTx`: `PDeposit1.lean` never imports it, the `P-DEPOSIT-1` registry row and reproduction command never build it, and it has no `SourceDepositConfig`/`SourceDepositInput` link (`LinksSource`) into the registered parent at all. Its own deployment-mismatch scenario (`MAX_EFFECTIVE_BALANCE_WC_TYPE_01 ≠ DEPOSIT_SIZE`) also has no analogue in `DepositParentTx.Inputs`, which takes one shared `depositSize` per key rather than separate pull-scale/push-scale config knobs -- so that specific abstract-model deployment fact is out of scope for the executable layer by construction, not because the executable layer's conservation is unbreakable. It is not: `skipped_lido_debit_breaks_pulled_eq_pushed` breaks it by a different, still-realistic mechanism (crediting without debiting) that *is* expressible at this granularity. `DepositLedgerTx` remains a legitimate, independently-useful piece of evidence for its own narrower model; it is kept in the tree but must not be cited as the registered parent's kill-line.

## Blocked follow-ups

- `LinksSource` from ALLOC output only after P-ALLOC-1 and P-ALLOC-2 parents are the live loops. Composing onto +1 MinFirst or planted capacities launders the wrong fill into conservation.
- Beacon-address provenance: named assumption.

## Reproduction

```
lake build LidoSRv3.Audit.Guarantees.PDeposit1 LidoSRv3.Tests.DepositParentTxMutants
```
