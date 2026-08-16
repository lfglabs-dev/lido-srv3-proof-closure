# Campaign-to-main recovery

This integration makes `main` the sole active delivery branch without discarding
the historical `campaign/lido-minimal-11` proof lineage.

## What is recovered

The integration merge has `campaign/lido-minimal-11@3f0d1c291a6b3e43e4255663d6a01f8b1016e65f`
as a parent. All campaign commits and merged PR history are therefore reachable
from the integration lineage, including PRs #9–#75 that landed on the campaign
branch.

The following campaign-only active artifacts are present in the resulting tree:

- `LidoSRv3/Audit/Source/AddressCorrespondence.lean`
- `LidoSRv3/Audit/Source/TopupParentCorrespondence.lean`
- `LidoSRv3/Audit/Verity/AddressTx.lean`
- `LidoSRv3/Audit/Verity/DepositLedgerTx.lean`
- `LidoSRv3/Audit/Verity/TopupPackedStorage.lean`
- `LidoSRv3/Audit/Verity/TopupParent.lean`
- their address/top-up mutant suites;
- the theorem-scoped evidence index and tests;
- the P-TOPUP-2 pinned-layout/runtime receipts and differential Foundry harness.

The Verity dependency is advanced to the campaign pin
`1fe0218863a4c8d6113e6cdd4de3766a54df81c7`, which contains the external-call
DSL consumed by the recovered artifacts.

## Conflict policy

A history merge is not evidence that every older campaign claim remains sound.
Where the two branches changed the same claim-bearing file, the current `main`
version is retained by default because it contains later exact-head corrections,
including retractions of vacuous transaction claims. Campaign-only artifacts are
recovered as subordinate evidence and remain compiled, but they do not promote a
canonical guarantee merely because their commits are now reachable.

The active assurance contract remains:

1. a checked abstract Lean model; and
2. a behaviorally faithful checked Verity model.

Any remaining gap is classified as a Verity feature, false property with
counterexample, explicit assumption, or pending implementation. General
Yul/EVM/deployment refinement is out of scope; SSZ retains only its targeted
imported-to-deployed Yul-fragment binding.

## Branch policy

After this integration reaches `main`, `campaign/lido-minimal-11` is archival.
New work and pull requests target `main`. The archival branch is synchronized to
the integrated `main` head and locked against further updates, preserving its
name and history without allowing a second active integration line.
