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

## Parameter-writer advance reported 2026-09-07

The user reports published producer checkpoint
`8691c7881a863715ab5ec9b39631ab41243e7c91`. Local `git cat-file -t`
confirms the commit exists. `git rev-parse` at this checkpoint and accepted
`2a4e9d2a91d257353470677c6101fd91293cf4e4` confirms identical Interface.lean
blob `d6eb95cceeb42421011acd1a5d7f9de7fea4a43d`. The accepted v0 meanings
remain unchanged; this recording does not repin the consumer bridge.

The producer reports ParameterWriter coverage of the full public
updateStakingModule/helper guards, fee/enum precedence, packed writes and
events, and count/share/address invariant preservation through both share and
parameter writers. Reported validation: 21 Init modules PASS; eight actual
Solidity parameter cases PASS; remote job
`78ecbf4e-d80a-4142-ae21-e6d7ab976c37` PASS with 50 jobs and 18 axiom
inspections; twelve Solidity/Verity comparisons PASS. These are attributed
reports, not independently reconciled remote receipts or certification.

Read-only inspection confirms this commit adds ParameterWriter.lean,
WriterInvariant.lean changes and parameter-case evidence. The committed
implementation-status.md still describes the earlier 49-job closure at
`4aa9557e288b5ca0d6c4e4c41caffbcd213bdffd`, explicitly excluding
ParameterWriter. Its solidity-verity-4aa9557.json records twelve comparisons
of decoded returns/raw errors and ordered top-level calls; compiler memory,
world preservation and nested callbacks have separate evidence. Those older
artifacts do not establish the newly reported remote job or a current-head gate.
The parameter receipt identifies Solidity pin
`17005714f151e5502c559932319a3f2f74ac2436` and compiler
`0.8.25+commit.b61c2a91.Emscripten.clang`.

At this observation, `git ls-remote origin refs/pull/245/head` returned
`f785c7186b40d0cc249f1afe7c27d12d0c816493` (exit 0), different from the
reported checkpoint. Publication at the live PR head and the reported refreshed
PR body are therefore not independently confirmed here. Local commit presence
and interface identity are confirmed; receipt scope remains tied to its exact
source revision, not inferred from a publication report.

Full admission composition, including compiler string-storage failure/cleanup
and the final deposit-state event, remains open as reported. The migration
constraint above remains in force: successful migration/version does not derive
legacy admission bounds. Writer preservation alone does not close complete
reachability or producer-to-consumer premises.

All Git inspection commands above exited 0. This update changes only the owned
coordination note and preserves existing working changes. No canonical edits,
PR mutations, build submissions, dependency changes or certification occur.

## Admission storage and corrected push boundary reported 2026-09-07

The user reports published producer head
`b171b363c5948705894d36d5cdeb414a2bd77c0a`, a receipt/documentation-only
commit after `43ae5e8face86528e199491fa9954f74a0bddd5b`. Local Git inspection
confirms these objects and the receipt-only diff. Interface.lean at the new head
has blob `d6eb95cceeb42421011acd1a5d7f9de7fea4a43d`, byte-identical to
accepted checkpoint `2a4e9d2a91d257353470677c6101fd91293cf4e4`.
The v0 agreement remains applicable; this update does not repin composition.

Reported admission coverage now includes name panic/cleanup, parameters,
last-ID/deposit state, six events and public rollback. The producer reports all
expanded actual writer tests passing. Inspected committed light-v18.json records
23 Init module checks with exit 0. scoped-checks-43ae5e8.json records six checks
with exit 0 at the exact corrected source SHA: proof escapes, annotations,
inventory, provenance, pinned source and metadata. These are inspected producer
artifacts, not checks rerun here or independent certification.

The unrestricted storage-array push correction is material: length >= 2^64
panics with code 0x41, an existing ID is a no-op, and insertion at length
2^64 - 1 succeeds. Inspected enumeration-boundary.json records panic bytes,
existingIdNoop=true, lastPermittedLength=18446744073709551615,
resultingLength=18446744073709551616 and matching element/position, under
Solidity pin `17005714f151e5502c559932319a3f2f74ac2436`, solc 0.8.25.
These executed vectors do not replace universal correspondence.

The reported prior 52-job / 21-axiom-inspection / 12 Solidity-Verity comparison
PASS is scoped to `876649b`, before the correction: STALE_SUCCESS for the new
source. The committed remote-rejected-43ae5e8.json identifies source
`43ae5e8face86528e199491fa9954f74a0bddd5b`, durable attempt
`1b893089-10e0-4e57-b689-e4e4c5ccf96c`, exit 1, and HTTP 422 from ashur:
80 GiB available versus 2 GiB estimate plus 80 GiB emergency floor. This is
REMOTE_ADMISSION_REJECTED with no compilation, not a proof failure or passing
gate. No retry or floor change was performed here.

Read-only `git ls-remote origin refs/pull/245/head` again returned
`f785c7186b40d0cc249f1afe7c27d12d0c816493` (exit 0). The user reports
publication and refreshed PR245 text; this checkout's remote observation does
not independently confirm either at b171b363. Local object and artifact
verification remain distinct from live publication verification.

Inspected integration-patch.md specifies shared source inventory, source/test/
audit imports, axiom and execution drivers, coordinated canonical metadata/UX2
regeneration, and make prove/test on an immutable integrated head. Those
obligations remain unapplied here. Complete admission/migration reachability,
universal compiler-memory composition and integration remain open. In particular,
migration success/version does not establish legacy admission bounds. Typed
writer inputs do not establish malformed public calldata rejection. The producer
is not certification-ready, and this update does not certify the consumer bridge.

Coordination recording only: Git inspection and JSON parsing exited 0; existing
working changes were preserved. No PR mutation, dependency change, canonical
edit, build submission or broader implementation work was performed.


## Public admission invariant update reported 2026-09-07

The user reports published producer head
`56787713037c736aea4593f36b5907aa1e81551a`, a clean checkout and verified
draft PR245. Local Git inspection confirms this commit and its AdmissionFacts
source. Publication, draft status and producer checkout cleanliness are attributed
to the user's verification; no live PR query was performed for this update.
Interface.lean has blob `d6eb95cceeb42421011acd1a5d7f9de7fea4a43d`, identical
to accepted v0 at `2a4e9d2a91d257353470677c6101fd91293cf4e4`.
The existing agreement and composition dependency pin remain unchanged.

Inspected `AdmissionFacts.public_preserves` establishes
`WriterInvariant.Holds` on the public execute result for both success and
rejection, given the entry invariant, `FreshRecords`, and finite
`AppendSeparation` obligations for actual successful stages. Its supporting
proofs derive final stored share, checked uint24 new ID, count growth/bound,
new element/address and old-row preservation. `successful_record_freshness`
derives absent ID and zero fresh name from FreshRecords and successful checked
next-ID computation; `zero_fresh_records` establishes FreshRecords in zero
storage. These are conditional physical-storage invariant results, not a
completed reachable-state induction or a new consumer composition certificate.
Initialization, migration and other-writer preservation of FreshRecords remain
open. Migration success/version alone still cannot establish legacy bounds.

Inspected committed `light-v20.json`: LIGHT_INIT_ONLY_PASS, 24 checks, all
exit_code 0. Inspected `admission-axioms-v1.json`: exit_code 0 and five named
inspections (success_witness, success_stored_share, success_count_bound,
successful_record_freshness, public_preserves), each listing only propext,
Classical.choice and Quot.sound. Both source hashes recorded in the axiom
receipt match files at this exact producer commit. These are inspected producer
receipts, not locally rerun builds or independent certification. Source-escape
and annotation passes, and unchanged runtime, are reported by the user.

New proofs have no remote production/Verity/trust validation. The prior remote
PASS remains stale for this source. Known admission rejection remains HTTP 422:
ashur 80 GiB free versus 2 GiB estimate plus 80 GiB emergency floor, with no
compilation. No retry or floor change was performed. Full lifecycle, memory and
integration obligations remain open; neither producer nor consumer is certified.

This coordination update only changes this owned note. Git source inspection,
receipt JSON parsing and axiom-source hash verification exited 0. Existing work
is preserved; no repin, PR mutation or remote build submission occurred.

## Interim Cancun validation update reported 2026-09-07

The producer reports using the RESERVE1 PR244 Hardhat 2.26.3 pattern with
`allowUnlimitedContractSize=false`, targeting production Cancun with solc
0.8.25, viaIR and optimizer runs 200. The initial twelve capacity vectors and
existing root-memory pointer schedule reportedly pass, and comparison against
preserved Verity outputs at `876649b` reportedly passes. These are attributed
execution results; no compiler, deployment or source receipt was supplied or
independently inspected for this update. PR244 was not inspected or modified.

The comparison uses historical Verity outputs and is not fresh full Lean
validation. Passing vectors and a pointer schedule do not establish universal
memory correspondence or close the producer-to-consumer memory relation.
Interface.lean is reported unchanged; the accepted v0 agreement and existing
composition dependency pin remain unchanged.

Final compiler/deployment/source receipts and mutants remain underway. The
producer will publish an immutable SHA to PR245 when finalized; no new SHA or
publication gate is inferred from this interim report. Full original proof,
composition, integration and independent certification obligations remain open.
This recording preserves existing work and makes no runtime, dependency,
canonical metadata or PR changes and submits no remote build.

## Finalized Cancun evidence update reported 2026-09-07

Fetched producer `db4a6fd1ccaf8310463527752514e190d9cb32a2` from origin
successfully. PR245 publication at that immutable head is reported by the user;
no live PR query was performed. Interface.lean has blob
`d6eb95cceeb42421011acd1a5d7f9de7fea4a43d`, byte-identical to accepted
`2a4e9d2a91d257353470677c6101fd91293cf4e4`. The matching v0 agreement and
consumer composition dependency pin remain unchanged.

Inspected committed Cancun documentation and receipts. The suite records seven
passing checks: capacity/error/memory, callback, writer, historical London-proxy
compatibility and preserved-Verity comparison exit 0; target-only and call-order
mutants exit 1 with behavioral rejection reported. Verified SHA256 for all 64
recorded archive artifacts directly from the committed tar archive. Suite source
hashes match this producer head except check-proxy-initialization.cjs, whose
production Istanbul correction is covered by the separate receipt. That corrected
receipt records exit 0; all its source hashes match this head, and all 10 archive
artifact hashes verify. This preserves the distinction between router solc 0.8.25
Cancun (viaIR, optimizer 200) and production proxy solc 0.8.9 Istanbul. Strict
EIP-170 enforcement, deployed code and complete compiler inputs/outputs are
producer execution evidence, not locally rerun tests or independent certification.
The preserved Verity comparison still uses historical 876649b outputs.

Inspected ProxyGenesis.initialization_invariants: it derives WriterInvariant.Holds
and FreshRecords from the implementation-slot prefix with explicit finite storage
separation premises, without assuming initializer or notification success.
The committed axiom receipt exits 0 and lists only propext, Classical.choice and
Quot.sound for this declaration; both recorded source hashes match this head.
Proxy code-existence/dispatch/admin correspondence, full lifecycle and migration
closure, universal memory refinement and consumer composition remain open.
Producer vector success does not resolve the consumer's recorded 1536-versus-1024
memory differential failure.

The user reports one reviewed full-source remote submission,
`durable:921a08e5-b5b6-4c34-b282-0432cdf32cfd`. Its terminal receipt was not
inspected here; submission establishes no passing current-head gate. The shared
UX2 make-test failure remains reported and unresolved. No remote retry, repin,
canonical change, PR mutation or certification occurred. Existing working changes
were preserved. Fetch, Git inspection, receipt parsing and archive/source hash
verification exited 0; this is an owned coordination-note update only.
