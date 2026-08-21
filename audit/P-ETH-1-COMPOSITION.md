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

`Guarantees.PEth1.verity_tx_universal_success_shape` (registered parent since
Wave 5) states the parent over `TxView` outcome observables — control, hop
count, and the seven-account balance sheet — not over full contract states.
It is a `∀ (msgValue batchSize feePerRequest : Nat)` theorem: under the
positivity, word-size, no-wrap, funding, and fuel premises below, the honest
wiring commits with the whole product fee at the consolidation-request
predeploy, the remainder at the refund recipient, and zero retained by every
protocol contract on the route. The proof chains per-hop frame lemmas through
the recursive dispatcher and closes the symbolic `batchSize`-driven request
loop by induction over `requestPhaseWorld`
(`Verity.PEth1CompositionTxUniversal.run_success_shape`).

`Guarantees.PEth1.verity_tx_composes_value_flow_and_rollback` is retained as
auxiliary regression evidence: the fee/refund split for one- and two-request
batches and the exact-fee batch (now instances of the universal parent),
restoration of the entry world when the request predeploy rejects, the
in-Gateway revert of an underfunded batch, ETH conservation on success and on
revert, and equality between the recursively dispatched run and a PR #2365
`denoteTransaction` replay of the discovered `List CompiledCall`.

The universal parent closes on `[propext, Classical.choice, Quot.sound]`; the
auxiliary numeral bundle closes on `[propext, Quot.sound]` with `decide
+kernel`, which is kernel reduction and introduces no axiom.

## Scope: universal over the success arm, under explicit premises

Since Wave 5 the Verity plane matches the abstract-plane `eth_flow_parent`
(`∀ (msgValue n fee : Nat)`) in quantifier strength on the success arm.
`verity_tx_universal_success_shape` quantifies over all
`(msgValue, batchSize, feePerRequest)` satisfying:

- `0 < msgValue` — the Gateway's compiled `ZeroArgument` guard (added to
  `gatewayFn` in Wave 5, matching the pinned source's
  `ZeroArgument("msg.value")` revert and the abstract plane's Wave 1 guard;
  it only affects `msgValue = 0` runs, which are outside the parent's
  premises, and it is what the positivity premise-necessity kill-line
  exercises);
- `msgValue`, `batchSize`, `feePerRequest`, and the product
  `batchSize * feePerRequest` below `2^256` — word-sized inputs and no wrap;
- `batchSize * feePerRequest ≤ msgValue` — the `InsufficientValue` guard;
- `batchSize + 4 ≤ fuelBudget` — the dispatch fuel bound.

The premises are exactly the abstract parent's non-revert conditions plus the
fuel bound. Two model properties make an unconditional `∀` statement *false*,
not merely hard to prove, which is why they appear as premises:

- **`fuelBudget = 32`** caps the number of dispatched frames (report issue
  9). A batch needs `3 + batchSize + (1 if refund > 0 else 0)` frames, so the
  fuel premise is the honest form of that cap.
- **`Expr.mul` wraps mod `2^256`** in the compiled Gateway/Vault bodies
  (report issue 12), so "funded" as the dispatcher computes it and "funded"
  under Solidity 0.8 checked arithmetic diverge for large inputs unless the
  no-wrap premise rules the divergence out.

Every premise is load-bearing: Wave 5 premise-necessity kill-lines in
`Tests.PEth1CompositionTxMutants` refute each premise-dropped projection of
the registered predicate on the honest wiring, and the two Wave 2 scope
kill-lines remain as the executable funding/fuel witnesses:

| Theorem | Tuple | Shows |
| --- | --- | --- |
| `zero_value_kill_line_refutes_dropped_positivity` | `(0, 2, 0)` | With `0 < msgValue` dropped, the `ZeroArgument` guard reverts a run the projection requires to succeed. |
| `underfunded_kill_line_refutes_dropped_funding` | `(10, 4, 3)` | With `n * fee ≤ msgValue` dropped, the `InsufficientValue` guard reverts a run the projection requires to succeed. Exact-shape form of `underfunded_batch_is_not_a_repartition`. |
| `fuel_exhaustion_kill_line_refutes_dropped_fuel_premise` | `(30, 29, 1)` | With `batchSize + 4 ≤ fuelBudget` dropped, a funded guard-passing batch needs `33 > 32` frames and hits `TxControl.exhausted`. Exact-shape form of `large_funded_batch_exhausts_fuel_budget`. |

The residual gap is the revert arms: the registered parent quantifies over
the success branch only, and no `∀` revert-shape theorem is registered on the
Verity plane (the premise-necessity kill-lines are negative witnesses, not a
positive revert characterization). This is recorded in
`audit/guarantees.yaml` `fidelity.missing`.

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
the *honest* wiring on inputs outside the registered parent's premises, so
they cannot be satisfied by weakening a mutant; since Wave 5 they double as
the executable funding and fuel premise witnesses.

The Wave 5 wiring kill-lines refute the registered universal predicate itself
(`universalSuccessShapePredicate`, proved equal to the registered parent at
the honest wiring by `universal_parent_is_predicate_at_honest`) at the
premise-satisfying witness `(10, 2, 3)`:

| Theorem | Wiring change | Refutes |
| --- | --- | --- |
| `dropped_refund_leg_kill_line_refutes_universal_parent` | `emitRefund := false` | the universal success shape (no refund leg) |
| `misrouted_vault_kill_line_refutes_universal_parent` | `vaultTarget := lidoAddr` | the universal success shape (fee lands at Lido) |
| `corrupted_refund_kill_line_refutes_universal_parent` | `refundWholeValue := true` | the universal success shape (refund is the whole `msg.value`) |
| `single_request_kill_line_refutes_universal_parent` | `perRequestCalls := false` | the universal success shape (one request for a two-request batch) |

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
