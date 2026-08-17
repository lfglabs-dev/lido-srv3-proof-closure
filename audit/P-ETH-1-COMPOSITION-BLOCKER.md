# P-ETH-1 parent composition blocker

Parent `P-ETH-1` stays `OPEN` with `theorem: null`. Child rows stay
`parent_id: P-ETH-1`.

Pins: proof head `7d7cdee29947037875d23d58b44e94c3b24ce938`, Lido
`af095e48bbc1c3841c2c9936219c8461af01056b`, Verity
`1fe0218863a4c8d6113e6cdd4de3766a54df81c7`.

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

## Why the parent cannot close

`TX: LEAN_CHECKED` needs one executed program that is the source call graph:
Bus calls Gateway with `msg.value`; Gateway pays the Vault and refunds; Vault
pays Lido or a request contract.

This Verity pin cannot do that.

1. Official `FunctionSpec` denotation has no external call. `Expr.call` and
   `Stmt.externalCallBind` become `none` or `.revert`.
   `ConsolidationCallFragment` checks this for every oracle, transaction, and
   world. `success_hypotheses_are_vacuous` shows `success = true → P` proves
   nothing.
2. `Contracts.Common.externalCallBind` is `pure ()`. No call, no value, no
   callee effect.
3. No official multi-contract world threads `msg.value` from Bus to Gateway to
   Vault to `(Lido | WITHDRAWAL_REQUEST | CONSOLIDATION_REQUEST)` under one
   `denoteTransaction` bound to the child ledgers.

One local store that sequences the six transfers is still one store, not the
source call graph. It is child evidence, not parent coverage.
