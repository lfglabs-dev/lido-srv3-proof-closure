# Pack N3 — computed oracle mint and aggregate cap

## Result

This node supplies two supplemental parents for later integration:

1. `POracleMint1.fee_share_rate_computed_mint` constructs a
   `Spec.OracleFrame` from `feeWei` and `shareRate` and proves
   `sharesMinted = feeWei * shareRate / 10^27` together with
   `shareRateDelta = shareRate`.
2. `POracleBound1.computed_mint_le_aggregate_cap` proves that
   `shareRate <= maxShareRate` implies
   `mintedShares feeWei shareRate <=
   feeWei * maxShareRate / 10^27`.

`OracleMintCorrespondence.mintedShares` is the computed operation.
`shareRateScale` is `10^27`, with a theorem identifying it with the existing
`AddressClaimBatchTx.E27`.

## Separation from existing parents

P-ACCOUNT-1 remains order-only.  This node cites its existing
`mintAfterReadDiscipline` theorem and does not add mint arithmetic to that
parent.

Pack E's `OracleFrame.sharesMinted = sharesToMintAsFees` is an argument
projection.  The new frame is deliberately separate: its minted shares are
computed from fee wei and share rate, not supplied as a free mint argument.

The existing Eugene child is cited only through
`eugene_operator_bond_fact_cited`, which retains its checked per-operator bond
meaning.  It is not used as the aggregate supply parent.

## Fail-closed vectors

`sum_balances_mutant_refutes_computed_mint_parent` negates the complete
universal mint-parent shape for a mutant that uses the sum of balances.  On
balances `[10, 20]`, fee `10^27`, and share rate `1`, the honest computation
mints `1` while the mutant mints `30`.

`raw_fee_mutant_refutes_aggregate_cap_parent` retains the named-cap premise
and negates the complete universal bound-parent shape.  Its mutant treats raw
fee wei as shares, dropping the share-rate-scaled E27 quotient.  At fee,
share rate, and maximum share rate all equal to `1`, the mutant produces `1`
while the capped quotient is `0`.

## Verification

The new modules are:

- `LidoSRv3.Audit.Spec.OracleMintCorrespondence`
- `LidoSRv3.Audit.Guarantees.POracleMint1`
- `LidoSRv3.Audit.Guarantees.POracleBound1`
- `LidoSRv3.Tests.PackN3OracleMintMutants`

Only these modules and this brief belong to the node.  Registry, aggregate
guarantee lists, trust output, receipts, metadata, and existing parent files
remain unchanged for the integrator.
