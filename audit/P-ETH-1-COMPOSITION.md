# P-ETH-1 parent composition

Parent `P-ETH-1` is `CHECKED` on both planes. Child rows keep
`parent_id: P-ETH-1` as bounded per-leg evidence.

Pins: Lido `af095e48bbc1c3841c2c9936219c8461af01056b`, Verity
`a063bfc869735045354ebc3862ca08859da0f56e` (merged `main`, contains PR #2362
external-call frames and PR #2365 atomic compiled multicall).

## Abstract plane

`Guarantees.PEth1.eth_flow_parent` is a `∀ (msgValue n fee : Nat)` theorem
over the call-journal gateway model `gatewayExecute`. An execution reverts
`ZeroArgument` at `msg.value = 0`, `Panic(0x11)` when `n * fee ≥ 2^256`, and
`InsufficientValue` when `n * fee > msg.value`. On success the model emits
`n` fee legs of `fee` wei plus at most one refund leg of
`msg.value − n * fee` wei, each journaled address classified against a
two-address `ApprovedSet` by `classifyJournal`; the parent proves every
classified move is `parentApproved` (no lateral `EthDestination.other`) and
that the moves total exactly `msg.value` (`totalAmount moves = msgValue`).
VaultHub and `StakingVault.withdraw` are named out of scope on the theorem
itself.

The parent's success conjunct is load-bearing, not decorative: Wave 4 adds
two mutants of `gatewayExecute` in `Tests.PEth1CompositionTxMutants` on whose
success outputs the conjunct is provably false —
`misrouted_journal_kill_line_refutes_parent` (fee legs journaled to an
off-`ApprovedSet` address, classified `.other`) and
`zero_value_success_kill_line_refutes_parent` (a guard-free gateway succeeds
at `msg.value = 0` paying `2 * 3 = 6` wei of fees, breaking
`totalAmount = msgValue`). The factored `parentOutcomePredicate` is proved to
be exactly the parent's conclusion by
`parentOutcomePredicate_is_eth_flow_parent_conclusion`, so both kill-lines
refute the predicate the registered parent proves, applied to a mutant of its
own model. The Wave 1 theorems formerly presented as kill-lines are retained
under honest names (`confirms_lateral_journal_entry_is_not_parent_approved`,
`confirms_zero_msg_value_reverts`): one tested a hand-built list the parent
never quantifies over, the other confirmed the honest model's own guard.

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

## Scope: finite witness bundle, not `∀` funded batches

Unlike the abstract-plane `eth_flow_parent` (`∀ (msgValue n fee : Nat)`),
`verity_tx_composes_value_flow_and_rollback` is a finite conjunction over
exactly five concrete `(msgValue, batchSize, feePerRequest)` tuples:
`(10,2,3)`, `(10,1,3)`, `(6,2,3)`, `(10,2,3)` with `requestAccepts := false`,
and `(10,4,3)`. It does not quantify over `msgValue`, `batchSize`, or
`feePerRequest`.

A `∀`-generalization was evaluated for this wave and rejected as infeasible
without `sorry`: the recursive `MultiContract.callFunction` dispatch
(`PEth1CompositionTx.step`) has no existing induction lemmas over an
arbitrary `batchSize`-driven `forEach` in this codebase (P-ETH-1 is the only
guarantee using this cross-contract dispatch pattern; other composed
guarantees — e.g. `P-CONSOLIDATION-1`, `P-DEPOSIT-1` — simulate a single
contract's own `.run`, which is a materially simpler target for induction).
Beyond the proof-engineering gap, two model properties make an unconditional
`∀` statement *false*, not merely hard to prove:

- **`fuelBudget = 32`** caps the number of dispatched frames (report issue
  9). A batch needs `3 + batchSize + (1 if refund > 0 else 0)` frames, so
  any candidate universal statement needs a `batchSize` side condition the
  current statement has none of.
- **`Expr.mul` wraps mod `2^256`** in the compiled Gateway/Vault bodies
  (report issue 12), so "funded" as the dispatcher computes it and "funded"
  under Solidity 0.8 checked arithmetic diverge for large inputs.

Two named kill-line theorems in `Tests.PEth1CompositionTxMutants` make this
scope executable rather than only asserted in prose:

| Theorem | Tuple | Shows |
| --- | --- | --- |
| `underfunded_batch_is_not_a_repartition` | `(10, 4, 3)` | Reverts instead of repartitioning the total; not a counterexample to a `∀`-success reading confined to guard-passing batches, but to a naive "the total is always split" reading. |
| `large_funded_batch_exhausts_fuel_budget` | `(30, 29, 1)` | Funded and guard-passing (`29 * 1 ≤ 30`, no overflow), yet needs `3 + 29 + 1 = 33 > 32` frames and hits `TxControl.exhausted` — a control value none of the five registered witnesses produce, and a failure mode `eth_flow_parent`'s `GatewayRevert` cases do not mention either. |

`P-CONSOLIDATION-1` composition remains blocked on the `FunctionSpec` /
`ConsolidationGateway.addConsolidationRequests` gap noted below regardless of
this scope; the two facts are independent.

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

The two scope kill-lines above (`underfunded_batch_is_not_a_repartition`,
`large_funded_batch_exhausts_fuel_budget`) are not `Wiring` mutants — they run
the *honest* wiring on inputs the registered parent does not witness, so they
cannot be satisfied by weakening a mutant; they bound how far the registered
parent's finite conjunction may honestly be read.

The Wave 4 kill-lines are different again: they target the *abstract* parent
`eth_flow_parent` and mutate its own model `gatewayExecute` rather than the
Verity `Wiring`.

| Theorem | Mutant of `gatewayExecute` | Refutes |
| --- | --- | --- |
| `misrouted_journal_kill_line_refutes_parent` | `gatewayExecuteMisrouted` — fee legs journaled to `rogueFeeSink = 999` (off `ApprovedSet`) | `(10, 2, 3)` succeeds with fee moves classified `.other 999`, so `∀ m, m ∈ moves → parentApproved m.destination` fails |
| `zero_value_success_kill_line_refutes_parent` | `gatewayExecuteUnguarded` — `ZeroArgument`/`InsufficientValue` guards dropped | `(0, 2, 3)` succeeds paying `2 * 3 = 6` wei of fees, so `totalAmount moves = 0` fails |

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
