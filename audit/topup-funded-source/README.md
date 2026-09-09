# TOPUP: concrete withdrawal followed by the modern source-byte loop

This increment composes the accepted Lido withdrawal consumer with the existing
`TopupTx.sourcePushLoop`, using the same returned allocations and the actual
`sourceDeposits` list. It proves the caller-side value equation: Lido loses the
sum, the router returns to its arbitrary old balance, and the newly appended
calldata-bearing frames carry exactly that sum. It does **not** execute a
beacon callee or establish whole-protocol conservation.

Baseline: `42210924cd58ff751d2472f5ea998383fed4be7f` (#265).
Solidity pin: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
Only two new proof modules, one test module and this audit directory are added.
No `TopupTx`, DEPOSIT, RESERVE, shared metadata or pin is modified.

## Concrete contribution

`TopupFundedSource.loop_run` is an induction over the real modern paired loop.
It executes each minimum-amount/uint64 guard and caller-side beacon frame, then
derives its exact final balance and journal. The journal specification selects
nonzero pairs from `inputs.zip amounts` and retains `sourceBeaconCalldata` for
each input. It does not use the legacy `scheduledDeposit`, arbitrary validator
IDs, supplied roots, or a premise describing the desired journal.

`source_deposits_run` applies that result to `sourceDeposits call hw`, whose
length is already proved from the same call. `journal_value` proves the sum of
the values read back from these frames equals the mathematical allocation sum.
The root bytes remain those of the same source input and the existing opaque
SHA model; this increment does not prove that SHA model correct.

`TopupFundedSourceTx.project` reads the actual router ledger balance into the
local `ContractState.selfBalance`. `commit` reads the local loop's returned
balance back into that same ledger account. `project_balance`,
`ledger_roundtrip` and `push_run` derive the representation relation and debit.
Neither operation manually credits a pull, and neither receives the debit or
credit conclusion as input. `push_run` also preserves every other local field
apart from the caller balance and newly appended call records.

`program` runs the delivered concrete withdrawal with zero seeds and then the
modern loop. `positive_conservation` derives:

```
finalRouter = initialRouter
finalLido + sum(allocations) = initialLido
finalCoreCalls = initialCoreCalls ++ exactSourceByteJournal
sum(exactSourceByteJournal.values) = sum(allocations)
```

The actual source byte selection is preserved, including zero skips, key
order, router-derived credentials, dummy signature and computed source root.
The statement does not derive conservation merely by assuming the final
Solidity balance assertion succeeds; the new consumer does not use that
assertion as a guard. It proves the equality that assertion needs.

`failure_restores` proves the new wrapper restores its initial shared-world
snapshot on failure, including a later beacon caller guard after a successful
withdrawal and earlier push. This is rollback in this explicitly composed
model, not an EVM refinement theorem for the original registered executor.

## Source mapping

| Pinned source | Result |
|---|---|
| [StakingRouter.sol:741-750](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/StakingRouter.sol#L741-L750) | Uses the same wrapped allocation total for the zero branch and Lido amount, then the same allocation list and source-constructed inputs for pushes. |
| [BeaconChainDepositor.sol:79-107](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/lib/BeaconChainDepositor.sol#L79-L107) | Modern loop, zero skip, two guards, actual calldata-bearing caller primitive, inductively derived journal and debit. |
| [StakingRouter.sol:752-755](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/StakingRouter.sol#L752-L755) | Positive-domain theorem derives the before/after router balance equality. |
| [Lido.sol:869-885](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.4.24/Lido.sol#L869-L885) and [receiver](https://github.com/lidofinance/core/blob/17005714f151e5502c559932319a3f2f74ac2436/contracts/0.8.25/sr/StakingRouter.sol#L665-L669) | Reuses delivered Pipeline/TopupLiveWithdrawal execution, actual Lido funding/debit, receiver identity check and event. |

## Domain, representation and wrapping

The positive composer retains the physical admission premises of the delivered
pipeline: locator/consensus bindings, code presence and dispatcher separation,
non-bunker queue, active Lido, authorized router, computed demand/allocation,
valid frame/timestamp arithmetic, actual Lido funds, immutable identity and
distinct Lido/router addresses. No withdrawal-success or credit premise is
introduced.

It additionally requires the two executed nonzero-push guards and
`oldRouterBalance + mathematicalAllocationSum < 2^256`. This is an **explicit
representation-domain condition**, not a fully derived no-wrap invariant. It
implies exactness of the wrapped total on this domain and makes the local
balance projection lossless. The old router balance need not be zero.

There is a separate way to discharge that condition:

1. `gateway_sum_exact` consumes delivered #260 uint64 target/count bounds and
   the actual per-allocation guards for the **same allocation list**. It proves
   its mathematical sum fits and its source wrapped sum is exact.
2. `gateway_projection_bound` combines that result with funding of the actual
   computed withdrawal amount and the independent initial invariant
   `initialLidoBalance + initialRouterBalance < 2^256`.
3. The resulting bound can be supplied to `positive_conservation`. The initial
   asset invariant's reachability, physical gateway extraction and connection
   to the module-entry execution remain unproved. #260 alone does not bound
   an unrelated prior router balance.

The implementation still branches on the source **wrapped** total.
`wrapped_zero` preserves the entire zero-wrap domain without requiring the
mathematical sum to be zero, nor any positive-path guard/funding premise. A
regression uses `[2^256-1, 1]`. Positive nonzero-wrap executions remain in the
definition, but the positive conservation theorem does not cover them. No
claim of unrestricted old-domain conservation is made.

`loop_run` and the positive theorem quantify over a generic configuration.
Those are local caller-model statements. Pinned source unit/field
correspondence specializes to `pinnedConfig`: `sourceDepositsOf` computes
amountGwei using the literal `10^9`, not a supplied configuration unit. `Guards`
contains only the helper's minimum and uint64 checks, not the earlier router
gwei-alignment/per-limit checks. The #260 bridge does require alignment through
`allocationGuards`; the generic composer alone can admit caller-model cases a
real beacon callee would reject. It is not a theorem of beacon success.

## Remaining boundaries

- **Two journals.** Withdrawal calls are in `Live.attempts`; the later beacon
  caller frames are in `core.calls`. The preserved `Callback` property means
  the last withdrawal-channel attempt and its event, not the last global call
  after the beacon loop. No unified global ordering theorem is claimed.
- **Actual beacon behavior.** Verity's pinned `externalCallBindTo` checks local
  funds, records the frame and debits the caller. Its deposit success is the
  existing name-based stub. It does not execute the target, credit its account,
  update its deposit tree, validate actual ABI bytes or model reentrancy.
- **Physical state.** `Live.World.balances` is an explicit Nat ledger. The local
  `core.selfBalance` is a projected caller view, not independently linked to a
  deployed EVM account. No unrestricted Nat-to-word round-trip is claimed; the
  boundary regression at `2^256` demonstrates why a domain is needed.
- **Root entry.** The new consumer starts at the value suffix with a well-formed
  call. It does not execute the module allocator, role/pause/target checks,
  share allocation or outer router-to-Lido ABI entry. `TopupTx.creditPull` and
  the registered parent remain unchanged; their simulation by this consumer
  remains a later obligation.
- **Cryptography/runtime.** Deposit roots still use the existing opaque SHA
  function. Precompile failures, full memory/compiler/EVM correspondence,
  actual beacon-address provenance and runtime identity remain open.

## Validation

The exact targeted command and output are retained in `validation.log` and
`receipt.json`; it builds both new source modules and the new test module.
`axioms.log` contains the eight principal queries. Only `propext`,
`Classical.choice` and `Quot.sound` occur; no sorry or native checker axiom is
introduced. Existing dependencies may replay their recorded warnings.

Fourteen new regressions cover pinned-unit positive execution with a nonzero
old router balance, exact outgoing values, retained public-key ABI words,
selectors/lengths, stale local-balance replacement, seed and withdrawal trace,
late guard rollback, mathematical/nonzero wrapped-zero behavior and the
Nat-to-word boundary. They reuse the accepted withdrawal fixture, with the
buffer and Lido balance scaled to realistic wei units. They are Lean tests,
not a new Forge suite. Source identity checks, hashes and the exact receipt are
retained alongside this file. Independent exact-candidate review is pending.
