# P-ETH-1 parent composition blocker

Recorded against:

* proof head `7d7cdee29947037875d23d58b44e94c3b24ce938`
* Lido pin `lidofinance/core@af095e48bbc1c3841c2c9936219c8461af01056b`
* Verity pin `1fe0218863a4c8d6113e6cdd4de3766a54df81c7`

Parent `P-ETH-1` transaction status stays `OPEN` with `theorem: null`.
Child rows `P-ETH-1a` and `P-ETH-1b` remain `parent_id: P-ETH-1`.

## What the children cover

The inventoried ETH-bearing paths are:

1. `ConsolidationBus.executeConsolidation` forwards `msg.value` to `ConsolidationGateway`
2. `ConsolidationGateway.addConsolidationRequests` sends `requestsCount * fee` to `WithdrawalVault`
3. `ConsolidationGateway._refundFee` refunds `msg.value - fee` to `refundRecipient` or `msg.sender`
4. `WithdrawalVault.withdrawWithdrawals` sends `_amount` to Lido
5. `WithdrawalVaultEIP7685._callAddWithdrawalRequest` sends the EIP-7002 fee to immutable `WITHDRAWAL_REQUEST`
6. `WithdrawalVaultEIP7685._callAddConsolidationRequest` sends the EIP-7251 fee to immutable `CONSOLIDATION_REQUEST`

`P-ETH-1a` is a `verity_contract` ledger under official `Contract.run` for (2), (3), and (4).
`P-ETH-1b` is a `verity_contract` ledger under official `Contract.run` for (1), (5), and (6).

Those programs write real storage slots, then `require` later calls. `Contract.run`
restores the caller snapshot on revert, so a failed refund or a failed second
request discards the prefix credit. Mutants that double-refund, credit the wrong
party, or keep a prefix after failure disagree with those observations.

## Exact parent blocker

A parent `TX: LEAN_CHECKED` claim would require one executed program that is the
composition of those paths as they appear in source: Bus calls Gateway with
`msg.value`, Gateway calls Vault with `totalFee` and then refunds, Vault calls
Lido or the immutable request contracts with the per-request fee.

At this Verity pin that composition is unavailable:

1. Official `FunctionSpec` denotation implements no external call. `Expr.call`,
   `Expr.staticcall`, `Stmt.externalCallBind` fall through to `| _ => none` or
   `| _, _ => .revert`. Machine-checked in
   `LidoSRv3.Audit.Verity.ConsolidationCallFragment`: the call entrypoint
   reverts for every oracle, transaction, and world, and
   `success_hypotheses_are_vacuous` shows `success = true → P` is contentless.
2. `Contracts.Common.externalCallBind` is `pure ()`. A `Contract.run` suffix
   built on it observes no call, no value, and no callee effect.
3. There is no official multi-contract world that threads `msg.value` from Bus
   to Gateway to Vault to `(Lido | WITHDRAWAL_REQUEST | CONSOLIDATION_REQUEST)`
   under one `denoteTransaction` while also binding the typed child ledgers.

A single-contract ledger that sequences all five transfers would still be one
local store, not the source call graph. That is useful subordinate evidence; it
is not compositional coverage of every inventoried ETH-bearing source path.

Therefore parent `statuses.tx` stays `OPEN` and no parent theorem is declared.
