# SRv3 audit foundation

`LidoSRv3.Audit.MinFirst` is an executable allocation model. It does not
reinterpret the older `Nat`/`Option` model. A Lean predicate is not bytecode
unless a correspondence theorem says so.

All anchors use Lido `af095e48bbc1c3841c2c9936219c8461af01056b`.

- [`SRLib._getDepositAllocations` 391–431](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/0.8.25/sr/SRLib.sol#L391-L431):
  requested wei becomes validator units; strategy deltas convert back to wei;
  row order stays router order.
- [`SRLib._getModulesAllocationAndCapacity` 493–559](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/0.8.25/sr/SRLib.sol#L493-L559):
  projected total is demand plus current equivalents; inactive capacity stays
  current; active capacity is target-capped.
- [WC01 top-up shadow 445–491](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/0.8.25/sr/SRLib.sol#L445-L491):
  WC01 rows still compete; their top-up amounts are not paid.
- [`MinFirstAllocationStrategy` 30–107](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/common/lib/MinFirstAllocationStrategy.sol#L30-L107):
  first least-filled open bucket wins; input order decides ties.

| Declaration | Invariants | Status | Trust |
| --- | --- | --- | --- |
| `Quantity.checkedAdd/Sub/Mul/Div/Sum` | A1, A5–A8, B1–B5 | implemented | pinned Verity `Uint256`/`safe*`; `checkedDiv` rejects zero |
| `Quantity.saturatingSub` | A5, A6 | implemented | source helper only |
| `TxObservation`, `TxResult`, `CommitTrace` | A7, A8, B4, B5 | implemented | audit observation, not EVM |
| `revert_restores_state_value_and_logs` | A7, A8 | proved | attempted calls stay ghost |
| allocation row/snapshot/result | A1–A6 | implemented | source-shaped data |
| `AllocationSnapshot.sourceDenominator` | A6 | implemented | requested-plus-current predicate |
| `valid_result_preserves_router_order` | A3, A4 | proved | from row correspondence |
| `conservesAllocation` | A1 | implemented | checked delta sum and demand bound |
| `MinFirst.candidate_mem/open/minimal/router_tie` | A3 | proved | first least-filled open; left tie |
| `MinFirst.incrementSelected_monotone/eq_of_ne` | A3, A5 | proved | one-step monotone; others unchanged |
| `MinFirst.allocate_preserves_length/module_order` | A3, A4 | proved | fuelled allocate keeps shape |
| `MinFirst.totalAllocated_le_requested` | A1 | proved | requested fuel bounds units |
| executable-to-`validAllocationResult` bridge | A1, A5, A6 | incomplete | not relabeled as a strategy fact |
| committed-payment / eligibility bridge | A2, A8 | incomplete | WC01 competes; WC02 pay filter separate |
| initial-deposit identity/rollback | A7 | assumed | trace vocabulary only |
| top-up return length/no-wrap | A8 | unsupported here | other slice |
| report/growth/consolidation | B1–B5 | unsupported | later slices |
| address equivariance | B6–B7 | unsupported | later slice |
| cryptographic validity | stretch | unsupported | never assumed true |

Axiom report:

```text
lake build LidoSRv3.Audit.Trust
```

This slice has no `sorry`, `admit`, project `axiom`, or `unsafe`.

Executable counterexamples live in `LidoSRv3/Audit/Vectors.lean` and
`Allocation.lean`: first-open is false; equal minima take the first router
index; saturated and inactive rows are skipped; WC01 still competes;
over-cap rows stay put; low headroom leaves demand; conservation is not
eligibility.

Removed names `positive_increment_respects_capacity`,
`positive_committed_payment_is_eligible`, and `firstOpenModule_deterministic`
were uniqueness overclaims. `allocate` is a function on a fixed ordered input.
Selection is `candidate_minimal` and `candidate_router_tie`.
