# P-ETH-1 parent composition

Parent `P-ETH-1` is `CHECKED` on both planes. Child rows keep
`parent_id: P-ETH-1` as bounded per-leg evidence.

Pins: Lido `af095e48bbc1c3841c2c9936219c8461af01056b`, Verity
`a063bfc869735045354ebc3862ca08859da0f56e` (merged `main`, contains PR #2362
external-call frames and PR #2365 atomic compiled multicall).

## Abstract plane

`Guarantees.PEth1.eth_flow_parent` quantifies over `EthPath`, whose three
constructors are the complete ETH-bearing call-site inventory below. For every
path it proves that no wei reaches a lateral `EthDestination.other` and that
the committed trace totals exactly the value entering the path.

## Verity plane

`Verity.PEth1CompositionTx.run` dispatches the compiled ensemble recursively
over one shared `MultiContract.MultiWorld`. Each hop is a real PR #2362 frame:
`callFunction` enters the callee's `FunctionSpec`, the body executes under
`denoteFunctionWithCalls`, and the resulting control decides commit or restore.
The dispatcher then harvests the journal entries the executed body appended and
pushes them as the next frames, so the call graph is emitted by the caller
bodies rather than assembled by hand. This is what the previous head lacked.

ETH moves exactly once per hop under a declared-amount convention: every
`LinkedExternal` carries `value := 0`, the body-computed amount travels as
calldata word `0`, the dispatcher lifts it into `CallSite.value`, and every
receiver opens with `require(msg.value == amount)`. Without this the body debit
and the frame debit would both fire.

`Guarantees.PEth1.verity_tx_composes_value_flow_and_rollback` states the parent
over `TxView` outcome observables — control, hop count, and the seven-account
balance sheet — not over full contract states. It covers the fee/refund split
for one- and two-request batches and the exact-fee batch, restoration of the
entry world when the request predeploy rejects, the in-Gateway revert of an
underfunded batch, ETH conservation on success and on revert, and equality
between the recursively dispatched run and a PR #2365 `denoteTransaction`
replay of the discovered `List CompiledCall`.

Both theorems close on `[propext, Quot.sound]`; the decision procedure is
`decide +kernel`, which is kernel reduction and introduces no axiom.

## Mutants

`Tests.PEth1CompositionTxMutants` runs the same ensemble and the same
dispatcher under a mutated `Wiring`, so no mutant can be killed by weakening
the parent statement.

| Mutant | Wiring change | Killed by |
| --- | --- | --- |
| drop | `emitRefund := false` | refund leg missing from the balance sheet |
| misroute | `vaultTarget := lidoAddr` | fee lands on the wrong account |
| corrupt | `refundWholeValue := true` | refund declares the whole `msg.value` |
| rollback | `observeWithoutRollback` | committed prefix survives a failed hop |
| two-batch | `perRequestCalls := false` | one request issued for a two-request batch |

The rollback mutant is falsifiable rather than tautological because `TxOutcome`
retains both `entryWorld` and `lastWorld`; `observe` applies the atomicity rule
and `observeWithoutRollback` does not.

## ETH-bearing call-site inventory

1. `ConsolidationBus.executeConsolidation` forwards `msg.value` to `ConsolidationGateway`
2. `ConsolidationGateway.addConsolidationRequests` sends `requestsCount * fee` to `WithdrawalVault`
3. `ConsolidationGateway._refundFee` refunds `msg.value - fee` to `refundRecipient` or `msg.sender`
4. `WithdrawalVault.withdrawWithdrawals` sends `_amount` to Lido
5. `WithdrawalVaultEIP7685._callAddWithdrawalRequest` sends the EIP-7002 fee to `WITHDRAWAL_REQUEST`
6. `WithdrawalVaultEIP7685._callAddConsolidationRequest` sends the EIP-7251 fee to `CONSOLIDATION_REQUEST`

`P-ETH-1a` runs (2), (3), (4) with official `Contract.run`.
`P-ETH-1b` runs (1), (5), (6) the same way.
`P-ETH-1` composes (1), (2), (3), (6) as one dispatched transaction and covers
(4) and (5) on the abstract plane.

## Standing scope

The parent is a model-plane composition. It does not claim that the Bus,
Gateway, or Vault are the pinned Solidity contracts compiled to bytecode
(`A-SOURCE-SHAPED`), nor that the Verity 4.31 scaffold is certified
(`A-VERITY-SCAFFOLD`), nor that these are executable EVM trace semantics
(`A-ABSTRACT-TX`). Identifying the immutable `CONSOLIDATION_REQUEST` value with
the canonical EIP-7251 address remains the separate `P-ETH-1b` provenance
obligation.
