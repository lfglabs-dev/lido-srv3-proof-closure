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

## Producer advance reported 2026-09-07

The user reports published producer checkpoint
`4aa9557e288b5ca0d6c4e4c41caffbcd213bdffd` in PR245. Local Git object inspection
confirms the commit exists and its `LidoSRv3/Audit/Source/TrioAlloc1/Interface.lean`
has blob `d6eb95cceeb42421011acd1a5d7f9de7fea4a43d`, identical to the same path at
accepted checkpoint `2a4e9d2a91d257353470677c6101fd91293cf4e4`. The v0 matching
agreement therefore remains applicable to this checkpoint.

The producer reports physical invariant preservation through the share writer,
admission guard/fresh-address/count proofs, checked uint24 last ID, and
EnumerableSet insertion/consistency preservation under explicit finite slot
separation. It reports 20 Init modules passing and 15 actual public Solidity
admission cases passing, including six late failures with five attempted slots
each fully restored and no events. Remote owned closure/trust was reported as
starting. These validation results are attributed reports; this recording did
not independently reconcile their receipts or certify their proofs.

Composition constraint: migration copies legacy count/shares without rechecking
admission bounds. Migration success or version alone must not be used to derive
those bounds. Any bridge requiring them needs explicit legacy-state premises
or a proved reachability argument establishing them. Admission preservation
does not by itself close migration reachability. Complete admission/migration
reachability and compiler-memory integration remain open as reported.

Read-only command `git ls-remote
https://github.com/lfglabs-dev/lido-srv3-proof-closure.git refs/pull/245/head`
returned `f785c7186b40d0cc249f1afe7c27d12d0c816493` (exit 0). Thus the live PR
head had already advanced beyond the supplied checkpoint at observation time.
Evidence for `4aa9557e` is checkpoint evidence, not a live-head gate. No content
or validation claims about the newer head are made here.

Both `git rev-parse` interface lookups and `git show --stat --oneline` for the
reported checkpoint succeeded (exit 0). This update changes only this owned
note; it does not repin composition, change canonical files, submit builds,
mutate PRs, or complete the broader ALLOC-2 scope.
