# Pack N2 brief — ETH confinement beyond separate journals

One composition parent, no new guarantee ID. This is not a claim about all
SRv3 ETH, and it does not discharge deployment-provenance assumptions.

## Frozen interfaces

The conclusion uses `Spec.EthJournal` and the four constructors of
`Spec.ApprovedDestination`: `lidoPull`, `beaconDeposit`,
`consolidationRequest`, and `refundRecipient`. The composition follows the
existing Spec projections to their Source/Verity journals.

## Parent

`PEthJournal1.every_modeled_success_journal_approved` quantifies over:

1. a conserving, premise-satisfying two-batch deposit;
2. a value-moving top-up whose wrapped total is nonzero;
3. a successful consolidation fee/refund execution.

Each source-preserving candidate must be the lossless image of a
`Spec.EthJournal`. Candidate projection records an unknown destination as
`none` instead of dropping its leg, so every source leg must have an
`ApprovedDestination`.

`ProtocolReturnPathsExcluded` is a named parent conjunct over the actual
consolidation source moves. It excludes the retired Vault-to-Lido and
WithdrawalQueue protocol-return paths; it is not a vacuous theorem.

## Kill-line

The mutant keeps the honest deposit, top-up, and consolidation success
premises, then appends a source leg tagged `.other 999`. That leg projects to
`none`, making the mutant candidate impossible to represent as a
`Spec.EthJournal`. The theorem negates the same all-three-journals conclusion
used by the parent.

## Out of scope

VaultHub owner withdrawals, WithdrawalQueue return journals, widening
`ApprovedDestination`, treating P-CONSOLIDATION-ETH-1 as all SRv3 ETH,
discharging address or amount provenance, and changing the assurance registry.
