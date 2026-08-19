# P-DEPOSIT-1

Theorems: `PDeposit1.source_deposit_conserves_and_rolls_back`, `PDeposit1.verity_tx_composes_deposit_conservation_and_rollback`.
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

`LidoSRv3.Audit.Verity.DepositLedgerTx.dropped_assert_commits_nonconserving_deployment` removes the model of `assert(etherBalanceBeforeDeposits == etherBalanceAfterDeposits)` at `StakingRouter.sol` line 996 on a deployment where `MAX_EFFECTIVE_BALANCE_WC_TYPE_01 ≠ DEPOSIT_SIZE` (so pulled ≠ pushed by construction). Without the assert this mutant commits and strands wei in the router instead of reverting, which the observable equality rejects. The two-batch `DepositParentTxMutants` transaction ties its pulled and pushed totals together by construction (`total := first.amount + second.amount` feeds both legs), so it cannot exhibit a non-conserving deployment; the kill-line is only reachable, and only claimed, at the `DepositLedgerTx` ledger-model granularity above.

## Blocked follow-ups

- `LinksSource` from ALLOC output only after P-ALLOC-1 and P-ALLOC-2 parents are the live loops. Composing onto +1 MinFirst or planted capacities launders the wrong fill into conservation.
- Beacon-address provenance: named assumption.

## Reproduction

```
lake build LidoSRv3.Audit.Guarantees.PDeposit1 LidoSRv3.Tests.DepositParentTxMutants
```
