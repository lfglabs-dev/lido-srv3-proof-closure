# SRv3 audit foundation

This first slice adds a separate `LidoSRv3.Audit` vocabulary. It does not
reinterpret the legacy `Nat`/`Option` model and does not claim that pure Lean
predicates are faithful to bytecode without a correspondence proof.

## Immutable source anchors

All anchors refer to Lido commit
`af095e48bbc1c3841c2c9936219c8461af01056b`.

- [`SRLib._getDepositAllocations`, lines 391-431](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/0.8.25/sr/SRLib.sol#L391-L431):
  requested Wei is converted to validator equivalents, strategy deltas are
  converted back to Wei, and returned rows retain router order.
- [`SRLib._getModulesAllocationAndCapacity`, lines 493-559](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/0.8.25/sr/SRLib.sol#L493-L559):
  projected total is requested demand plus every pre-allocation current
  equivalent; inactive capacity stays current; active capacity is target-capped.
- [WC01 top-up shadow rationale, lines 445-491](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/0.8.25/sr/SRLib.sol#L445-L491):
  WC01 rows remain competitors but their returned top-up allocations are not
  consumed as payments.
- [`MinFirstAllocationStrategy`, lines 30-107](https://github.com/lidofinance/core/blob/af095e48bbc1c3841c2c9936219c8461af01056b/contracts/common/lib/MinFirstAllocationStrategy.sol#L30-L107):
  deterministic scanning chooses the first least-filled open bucket, making
  input order observable on ties.

## Declarations and trust

| Declaration | Invariants | Status | Trust level |
| --- | --- | --- | --- |
| `Quantity.checkedAdd/Sub/Mul/Div/Sum` | A1, A5-A8, B1-B5 | implemented | pinned Verity `Uint256`/`safe*`; `checkedDiv` rejects zero |
| `Quantity.saturatingSub` | A5, A6 | implemented | source-only helper, not general arithmetic |
| `TxObservation`, `TxResult`, `CommitTrace` | A7, A8, B4, B5 | implemented | audit observation, not an EVM |
| `revert_restores_state_value_and_logs` | A7, A8 | proved | Lean theorem; attempted calls remain ghost evidence |
| allocation row/snapshot/result structures | A1-A6 | implemented | source-shaped data vocabulary |
| `AllocationSnapshot.sourceDenominator` | A6 | implemented | exact checked requested-plus-current predicate |
| `valid_result_preserves_router_order` | A3, A4 | proved | Lean theorem from row correspondence |
| `positive_committed_payment_is_eligible` | A2, A8 | proved | top-up payment eligibility is WC02-only |
| `positive_increment_respects_capacity` | A5 | proved | only positive increments are required to finish under capacity |
| `conservesAllocation` | A1 | implemented | checked delta sum and requested-demand bound |
| `firstOpenModule_deterministic` | A3 | proved | functional uniqueness of the ordered first-open selector; full strategy equivalence pending |
| initial-deposit identity/rollback | A7 | assumed/unsupported | trace vocabulary only; transition correspondence pending |
| top-up return length/no-wrap | A8 | unsupported here | handled separately by draft PR #4 in the legacy layer |
| report/growth/consolidation properties | B1-B5 | unsupported | future bounded slices |
| address equivariance | B6-B7 | unsupported | future bounded slice |
| cryptographic validity | stretch | unsupported | never a must-set assumption |

The exact theorem axiom report entrypoint is:

```text
lake build LidoSRv3.Audit.Trust
```

No theorem in this slice uses `sorry`, `admit`, a project `axiom`, or `unsafe`.

## Falsifier regressions

`LidoSRv3/Audit/Allocation.lean` contains executable examples showing:

1. a result may conserve the requested amount while paying an inactive WC01 row;
2. reversing two equally open rows preserves the module set but changes the
   first selected module.

These prevent conservation from being used as a substitute for eligibility and
prevent unordered module-set equality from being used as tie determinism.
