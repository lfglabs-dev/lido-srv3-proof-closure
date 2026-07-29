# SRv3 audit foundation

This remediation adds a separate executable `LidoSRv3.Audit.MinFirst` model. It does not
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
| `conservesAllocation` | A1 | implemented | checked delta sum and requested-demand bound |
| `MinFirst.candidate_mem/open/minimal/router_tie` | A3 | proved | executable first least-filled open selector; strict left tie break |
| `MinFirst.incrementSelected_monotone/eq_of_ne` | A3, A5 | proved | one-step monotonicity and non-selected-row stability |
| `MinFirst.allocate_preserves_length/module_order` | A3, A4 | proved | fuelled executable allocation preserves the ordered shape |
| `MinFirst.totalAllocated_le_requested` | A1 | proved | exact requested fuel bounds unit allocation iterations |
| executable-to-`validAllocationResult` bridge | A1, A5, A6 | incomplete | no assumption is relabeled as a strategy conclusion |
| committed-payment construction/eligibility bridge | A2, A8 | incomplete | WC01 remains a strategy competitor; WC02 payment filtering remains separate |
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

`LidoSRv3/Audit/Vectors.lean` and `Allocation.lean` contain executable examples showing:

1. `[5/10],[0/10]` selects row 1, falsifying first-open;
2. equal minima use the first router index and reversing tied order changes the recipient;
3. saturated and inactive rows are skipped, while active WC01 rows still compete;
4. pre-existing over-cap rows stay unchanged;
5. insufficient headroom leaves demand unallocated;
6. conservation alone does not imply payment eligibility.

The removed theorem names `positive_increment_respects_capacity`,
`positive_committed_payment_is_eligible`, and `firstOpenModule_deterministic`
were projection/functional-uniqueness overclaims, not executable MinFirst proofs.
No replacement “determinism” theorem is claimed: `allocate` is an executable
function on a fixed ordered input, while the substantive selection behavior is
proved by `candidate_minimal` and `candidate_router_tie`.
