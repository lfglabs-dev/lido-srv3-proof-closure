# Campaign node 4 — claim-batch recipient rename (P-ADDRESS-BATCH-1)

One node, one PR. Same guarantee ID. Do not weaken
`PAddress1.universal_address_writer_equivariance`. keccak stays OPEN.

## What the parent says

`PAddressBatch1.p_address_batch_1_fuel_bounded_recipient_rename`,
universal over fuel, state, request/hint/payout lists, recipient, and
rename `ρ`, with the existing `BatchReady` / fuel / nodup / nonzero
premises plus `ρ recipient ≠ 0`.

Conclusion: `observe (execute (ρ recipient))` journals
`payoutEntry (ρ recipient)` at the pre-state payouts, and
`observe (execute recipient)` journals `payoutEntry recipient`. That is
`ρ · executeClaimWithdrawalsTo = execute · ρ` on the live loop dests.

The earlier payout-correspondence theorem stays as a lemma.

## Kill-line

`fixed_dest_rename_kill_line_refutes_parent`: mutant
`executeClaimWithdrawalsToFixedDest` always pays address 99. On the
three-item batch, `ρ` sends dest 2 to 7; the mutant still journals 99.

## Non-goals

- keccak / machine-storage slot maps stay OPEN.
- Unbounded (fuel-free) live-loop correspondence stays out.
- PAddress1 write-side equivariance is not edited.

## Build

    lake build LidoSRv3.Audit.Guarantees.PAddressBatch1
    lake build LidoSRv3.Tests.PackN4AddressBatchMutants
