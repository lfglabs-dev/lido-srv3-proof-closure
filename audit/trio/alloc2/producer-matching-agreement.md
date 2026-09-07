# Producer matching agreement for v0

Recorded 2026-09-07 from the producer's written message delivered by the user.
This records receipt of the matching agreement for orchestrator recording; it
does not assert that the orchestrator has separately recorded both agreements.

The producer explicitly agrees to every v0 meaning in the consumer acceptance:
complete order/filtering, exact capacities including capacities below allocations,
WC01-equivalent units, Fin/list types, derived bounds, disjoint word-memory
relation, and failure distinctions. No incompatible edits are proposed.

Accepted consumer document:
`b279d572b694a9e106fdf61337323fbe5f6d3d33:audit/trio/alloc2/interface-acceptance.md`,
blob `b8c5422b535bc218fbd10d8730cdd41c49c6cb27`.
Both the historical blob and the current local acceptance file were verified to
have this blob identity. The historical acceptance is preserved unchanged.

The producer states that its interface remains byte-identical to checkpoint
`2a4e9d2a91d257353470677c6101fd91293cf4e4`. This message supplies the producer's
matching written agreement; byte identity at the new producer head has not been
independently rechecked in this recording step. Incompatible interface changes
remain prohibited pending the required coordination.

## Producer status supplied with the agreement

The producer reports reading PR246's composition description at `8269ac` and ABI
closure. It reports that producer `9923f9d` adds universal SOURCE/spec iff,
full CallTree/Verity call-VM equivalence, physical VM word-storage adaptation,
writer bounds/rollback, compiler-memory snapshot vectors, and nested static
callback execution, with remote 33-job and 37-job builds passed.

These are attributed producer reports, not independently reconciled receipts or
consumer certification. The short producer revision is retained as supplied;
this note does not update the pinned composition dependency.

The corrected VM differential rerun is reported disk-admission rejected:
84 GiB free versus 5 GiB estimated plus an 80 GiB floor (85 GiB required).
An explicit `nippur` request reportedly resolves to `ashur`. The original full
job `3ca9d1e4` is reported still running. Neither the rejected rerun nor the
running original job establishes a passing differential gate.

This recording performs no build submission, remote polling, PR mutation,
or certification. Independent review and exact-head receipt reconciliation
remain separate obligations.
