# P-CONSOLIDATION-ETH-1 parent composition

Parent `P-CONSOLIDATION-ETH-1` is `CHECKED` on both planes. There are no sibling guarantee
rows under this parent.

- **Former P-CONSOLIDATION-ETH-1b** (fee → configured consolidation-request target) is
  absorbed as **parent evidence** under `A-CANONICAL-REQUEST-ADDRESS`. It is
  not a separate guarantee. When the canonical `0x00…7251` obligation is
  discharged, that evidence should become a registered parent conjunct, not a
  sister claim.
- **Former P-CONSOLIDATION-ETH-1a** (vault → Lido / WithdrawalQueue returns) is **retired**
  from this parent. It matches neither the consolidation fee/refund happy path
  nor P-RESERVE-1 spend/buffer accounting. Lean modules remain as unregistered
  auxiliary builds only. A future standalone claim (“protocol ETH exits only
  to Lido/WQ”) would be a new guarantee, not an ETH-1 child.

Pins: Lido `af095e48bbc1c3841c2c9936219c8461af01056b`, Verity
`a063bfc869735045354ebc3862ca08859da0f56e` (merged `main`, contains PR #2362
external-call frames and PR #2365 atomic compiled multicall).

## Abstract plane

`Guarantees.PConsolidationEth1.eth_flow_parent` is a `∀ (msgValue n fee : Nat)` theorem
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

Fee-leg tag evidence `consolidation_fee_path_confined` lives in the same
module as parent evidence (configured target only). Canonical address
equality remains `A-CANONICAL-REQUEST-ADDRESS`.

The parent's success conjunct is load-bearing, not decorative: Wave 4 adds
two mutants of `gatewayExecute` in `Tests.PConsolidationEth1CompositionTxMutants` on whose
success outputs the conjunct is provably false —
`misrouted_journal_kill_line_refutes_parent` (fee legs journaled to an
off-`ApprovedSet` address, classified `.other`) and
`zero_value_success_kill_line_refutes_parent` (a guard-free gateway succeeds
at `msg.value = 0` paying `2 * 3 = 6` wei of fees, breaking
`totalAmount = msgValue`).

## Verity plane

Registered parent: `verity_tx_success_and_revert_partition`, conjoining
`verity_tx_universal_success_shape` (universal success arm under funded / word
/ fuel premises) with `UniversalRevertPartition` (a universal transaction-entry
rollback arm for each of the four modeled non-success shapes: zero `msg.value`,
wrapped product fee, underfunded batch, dispatch-fuel exhaustion), plus the
four numeral witnesses those arms subsume.
`verity_tx_universal_zero_remainder_boundary` closes the
`batchSize + 3 = fuelBudget` zero-remainder corner. Fee-target witness
`PConsolidationEth1RequestTx.consolidation_fee_target_success` is parent evidence, not a
child registry theorem. Refund/vault-to-Lido numerals in `PConsolidationEth1RefundTx`
remain unregistered auxiliary builds from the retired 1a row.

## Standing scope

Do not compose into P-CONSOLIDATION-1 until `FunctionSpec` is the live
`addConsolidationRequests` path (groups, fee fetch, failing refund). Do not
reintroduce a P-CONSOLIDATION-ETH-1a child for vault→Lido/WQ returns without opening a
separate guarantee.
