# P-ETH-1 parent composition blocker

Parent `P-ETH-1` stays `OPEN` with `theorem: null`. Child rows stay
`parent_id: P-ETH-1`.

Pins: Lido `af095e48bbc1c3841c2c9936219c8461af01056b`, Verity
`2d9d2d1e88a7a8eb78f8a13c8407b18e3a2b91bf` (provisional PR #2362 head).

## Execution-backed composition slice

`PEth1CompositionTx.run` now executes four `callFunction` frames in one
atomic outer run: Bus → Gateway, Gateway → Vault, Gateway → refund recipient,
and Vault → request. It splits `10` into a fee of `3` and refund of `7`, and
restores the transaction-entry world when the final request hop fails. The
four required mutants are rejected in `PEth1CompositionTxMutants`.

This is stronger than the old journal-only `routeEth`, but it remains bounded
evidence: the outer nested-call scheduler and fee split are handwritten Lean,
not denoted from the bodies of the pinned Lido caller functions. Parent
`P-ETH-1` therefore remains OPEN pending a Verity `denoteTransaction` (or
equivalent nested frame scheduler) that drives child frames from executed
caller `FunctionSpec` external-call statements.

## Children

ETH paths in source:

1. `ConsolidationBus.executeConsolidation` forwards `msg.value` to `ConsolidationGateway`
2. `ConsolidationGateway.addConsolidationRequests` sends `requestsCount * fee` to `WithdrawalVault`
3. `ConsolidationGateway._refundFee` refunds `msg.value - fee` to `refundRecipient` or `msg.sender`
4. `WithdrawalVault.withdrawWithdrawals` sends `_amount` to Lido
5. `WithdrawalVaultEIP7685._callAddWithdrawalRequest` sends the EIP-7002 fee to `WITHDRAWAL_REQUEST`
6. `WithdrawalVaultEIP7685._callAddConsolidationRequest` sends the EIP-7251 fee to `CONSOLIDATION_REQUEST`

`P-ETH-1a` runs (2), (3), (4) with official `Contract.run`.
`P-ETH-1b` runs (1), (5), (6) the same way.

Each program writes storage, then `require`s later calls. `Contract.run`
restores the snapshot on revert, so a failed refund or second request drops
the prefix. Mutants that double-refund, pay the wrong party, or keep a prefix
disagree.

## What PR #2360 added

The three old "composition does not exist" blockers are now official APIs.
They are not a parent closure.

1. `DenoteFunctionCalls` denotes `Expr.call` and `Stmt.externalCallBind` with
   target, value, ETH debit, returndata, and an `AdversaryModel`. Base
   `evalExpr` / `execStmt` stay `none` / `.revert`, so
   `ConsolidationCallFragment.success_hypotheses_are_vacuous` remains valid.
   The widened path is `denoteFunctionWithCalls`, not default `Contract.run`.
2. `externalCallBindTo` journals a real target and value and debits
   `selfBalance` on success. Callee state is not updated here. The older
   `externalCallBind` still journals without value or target.
3. `MultiContract.callValue` debits the caller, credits the callee, installs
   sender / this / msg.value, and journals the hop. `routeEth` sequences
   Bus → Gateway → Vault → (Lido | request).

## Why the parent still cannot close

`TX: LEAN_CHECKED` needs one executed program that is the source call graph:
Bus calls Gateway with `msg.value`; Gateway pays `requestsCount * fee` to the
Vault and refunds the rest; Vault pays Lido or a request contract.

This pin still cannot do that.

1. `routeEth` forwards one `value` on every hop. It does not split fee versus
   refund, name a refund recipient, or distinguish `WITHDRAWAL_REQUEST` from
   `CONSOLIDATION_REQUEST`.
2. Hops are model-plane `callValue` steps. They are not compiled Lido
   `FunctionSpec`s under `denoteFunctionWithCalls` or `denoteTransaction`.
3. `externalCallBindTo` updates only the caller journal and `selfBalance`.
   Callee effects live in `MultiContract`, not in the same `Contract.run`.
4. Base `FunctionSpec` denotation still reverts on `Expr.call` /
   `Stmt.externalCallBind`. Default `Contract.run` still sees empty success
   hypotheses.

A local `routeEth` that splits fee and refund is the next honest slice. It is
still a MultiContract model, not source-compiled TX closure.

Therefore parent `statuses.tx` stays `OPEN` and no parent theorem is declared.
