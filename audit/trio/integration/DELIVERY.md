# Trio composition delivery record

Status: the full composition at `0345a6146cd5cd10b55d318c48c2a4c578ae3bc8`
passed all six official RunValidation gates. The final additive ABI-copy source
at `36cc6af51c33461c2b8c5143d346a55a8638f0c6` passed its two focused root gates.
Both source reviews are CLEAN and their validation prerequisites are satisfied.
PR249 and PR245 are merged; PR251 (including PR244 and PR246) awaits the final
archive review and merge at this historical snapshot. This is not a deployment certificate.
The old primary guarantee declarations are preserved. The new source composition
is registered separately in each trio target's `execution_review` in
`audit/source-map.yaml` and printed by `LidoSRv3/Audit/Trust.lean`.

## Immutable dependencies and review surfaces

- Solidity: `lidofinance/core@17005714f151e5502c559932319a3f2f74ac2436`.
- Verity: `e977aaad6e1a9e92e0132d41b3d33a14135a4d46`.
- Lean: `leanprover/lean4:v4.31.0`.
- Writer PRs: [ALLOC-1 #245](https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/245),
  [ALLOC-2 #246](https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/246),
  [RESERVE-1 #244](https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/244).
- Integration: [#249](https://github.com/lfglabs-dev/lido-srv3-proof-closure/pull/249).
- Source reviews: `final-independent-review-round4.md` and
  `final-independent-review-published-addendum.md`. Each records exact source
  identities and a scope-limited verdict. The combined parent requires its own
  final review is recorded in `final-independent-review-stored-parent.md`.
  Later additive reviews are recorded in `final-independent-review-additions.md`.
  Requested Astra configuration is recorded; actual runtime model
  identity is not independently attested by the session.

## Source properties

`FinalMemoryStoredParent.public_iff` relates every return/revert and module
transcript to the independently defined `ParentSpec.Public`. The parent executes
one guarded producer, writes each output row, reads the library arguments from
those arrays, records the configured library call and raw response, copies the
response into separate caller memory, and performs checked in-place conversion.
`success` derives the public result from final memory reads. `trace_shape` and
`positive_calls` retain the old trace once, append only newly attempted module
calls, and record the one actual library event when reached, including failures
in caller allocation or conversion afterwards. Reverted private-memory writes
are not observable MSTORE traces.

The raw-state theorem takes count <=32 and
`pointer + 1184*count + 704 <= 2^32`. `LifecycleHistory.stored_parent_iff` derives
the count from modeled proxy initialization, ACL grants and the covered public
share/parameter/admission/status writers. It still takes entry pointer <=2^31
and the explicit finite storage-separation conditions. Migration and remaining
writer families are excluded. The separate +1 selection model is not identified
with the proportional library algorithm.

`VerityParent.stored_correspondence` relates that result/module projection to
the actual module-STATICCALL VM interpreter, preserving its external world. The
closed-library event is recorded by the source parent; this is not a claim that
the VM executed linked library bytecode.

`ReserveLeafSpend.withdrawal_corresponds` and the writer's independent
`AllocationFlow.withdrawal_corresponds` cover status, permission/lookup, queue
and frame calls, saved accounting, ABI failures, spending, receiver effects and
root rollback. The primitive adversarial CALL relation exposes request, response
and returned world. It does not assume a successful callee.
`PhysicalReserve.success_preserves` separately protects the actual final reserve
and next live queue demand for the concrete bound pipeline, under its listed
physical/configuration, admission, queue/frame, seed, funding and address
separation premises. It is not reserve protection against arbitrary successful
callbacks that replace accounting state. `PhysicalSequence` concerns its modeled
internal/committed transitions. `Transfers.credit_bound_from_aggregate` retains
the aggregate-world balance bound explicitly.

## Local compiler and environment premises

The word-memory map observes aligned, non-overlapping words; it is not physical
MLOAD at every arbitrary byte address. Primitive load/store/copy interpretation,
entry-pointer provenance, private callee memory and the configured linked-code
identity remain explicit. Omitted cache/configuration/scratch writes must obey
local frame conditions outside observed output regions; cache fields must agree
with their five word offsets and survive until the second pass. The proved
`CacheRepresentation` write/load/frame lemmas and producer geometry supply local
components, not an assumed final allocation result. Storage/hash primitives and
consensus inputs retain their stated bindings. Compiler trust, cryptography,
general deployed bytecode and gas are outside the claimed Lean result.

## Reproduction and evidence

Use a fresh checkout at the recorded candidate SHA, the pinned submodule and the
official remote build runner. Execute:

```
remote-lean-build lake env lean --run audit/trio/integration/RunValidation.lean
```

The driver records bootstrap, full production/test/trust/integration compilation,
`make prove` (its actual declared targets), `make test`, producer VM and parent VM
gates separately. A bounded Init-only receipt never replaces those gates.
`RunVerityParent.lean` executes the actual parent VM, twelve differential vectors,
return-memory/guard cases and the complete stored-parent runtime regressions.
`compare-parent-executions.py` independently compares the twelve actual VM records
with pinned Solidity observations and rejects stale transitive source hashes.
Reserve and sequential-library archives retain their own source/runner hashes
and mutation outcomes; recorded execution comparison is not a fresh VM run.

The complete passing receipt for the stored-parent composition is archived in
`remote-51037be4/progress.json`; its twelve parent observations independently
match the pinned Solidity records (`remote-51037be4/parent-comparison.json`).

Earlier failed full/targeted jobs remain under `remote-*` with their actual
failure classification. The final receipts and source comparisons are archived in `remote-0345a614/`
and `remote-36cc6af5/`. The source-comparison record documents why unchanged
production uses the full0345 receipt while additive leaves use focused36cc.
The archive commit only refreshes evidence, the UX source fingerprint and its
canonical tree receipt. It is not represented as another fully built source.
Final merge outcomes and the locally prepared site are recorded separately after
this archive snapshot. The site source pin is36cc and distinguishes both gates.
Publication or sending the dossier to Lido still requires Thomas's approval.
