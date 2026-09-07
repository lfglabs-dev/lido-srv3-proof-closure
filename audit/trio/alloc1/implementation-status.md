# ALLOC-1 implementation status

This is implementation work for independent review, not certification. The original
full scope remains open. The recovered base is `2a4e9d2a91d257353470677c6101fd91293cf4e4`.
The previous receipt reconciliation changed the authoritative PR evidence and is
classified as progress; it did not establish implementation completion.

## Current declarations

The v0 `Interface.lean` types are unchanged. New additive modules:

- `Storage`: raw storage words, actual module/array slot formulas with explicit
  keccak and router-slot parameters; packed config and accounting widths.
- `Execution`: history-sensitive adversarial static calls; exact summary,
  subtraction, optional stake, total interleave; ordered capacity pass; failure
  transcript retained. `produce` constructs `CapacityOutput` from stored count.
- `Properties`: first-row storage identity, complete first-loop order, second-pass
  preservation and per-bucket equations, `producer_router_order`.
- `CapacitySpec`: independent Nat capacity formulas, success correspondence, and
  bounds on the checked executor's returned capacity word. `producer_math_view`
  derives the network total from demand plus returned allocations;
  `producer_total_bound` derives its uint256 bound from execution success.
- `Bytes` and `Memory`: generic word encode/decode inverse, exact summary field
  order with trailing bytes, array element byte decoding, constructive byte-backed
  `MemoryArraysRelated`, and output lengths equal to the stored count.
- `Tests/TrioAlloc1/Execution`: actual executor reductions for ordered mixed WC rows,
  top-up, below-allocation capacities, empty helper, underflow before stake, late
  rejection, raw revert preservation, malformed/trailing returndata, zero divisor,
  word limits, and overflow precedence.

Light Init-only elaboration used `/root/.elan/toolchains/leanprover--lean4---v4.31.0/bin/lean`,
with private oleans in this mission's `temp/lean`. Each of the above modules and the
regression module elaborated with exit 0. These checks do not replace remote
production/test/trust or full-suite receipts.

## Remaining original gates

| Requirement | Evidence / remaining work |
| --- | --- |
| Physical storage | Slot formulas, width proofs and executed solc layout checks implemented. Deployment/hash primitive relation and physical writer-transition proofs remain open. |
| Reachable bounds, address uniqueness | Width bounds derived. Count<=32, share<=10000, unique addresses, admission and migration reachability remain open; never imposed as read guards. |
| Exact call and error behavior | Ordered executor and regressions implemented. Pinned Solidity executions confirm enum panic, malformed returndata and raw error bytes on the vectors. The universal all-outcome source relation remains open. |
| Independent specification | Second-pass Nat spec and checked-total accumulation proofs implemented. First-pass/call-level independent relational specification still open. |
| Memory / ABI | Constructive byte-backed array relation and decoder inverses proved. Actual solc allocation sequencing/failures (including panic 0x41), complete compiler memory correspondence and consumer ABI bridge remain open. |
| Rollback / sequential behavior | View executor has no state effects. This alone does not establish parent/writer rollback or callback realization; those proofs/tests remain open. |
| ALLOC-2 interface | Messages sent to mission 44053c4f-2578-4df5-84f2-4f66bc73586a. v0 unchanged; agreement and composition consumer evidence pending. |
| Differential execution | 12 paired Solidity/SOURCE-executor executions pass, including state/balances/calls/events observations. Two compiled Solidity mutants are killed by outcome mismatches. Solidity-vs-Verity execution remains open. |
| Full verification | Production/test/trust, make prove/test, annotations/metadata/inventory/provenance/proof-escape and parent-shaped executed mutations remain required. |
| Delivery | Draft scoped PR #245 is open; complete validation at its immutable final SHA is still required. No merge, publication or self-certification authorized. |

## Remote transport preparation

`prepare-remote.py` exports the complete root plus pinned Solidity and every pinned
Lake dependency from Git objects, with no compiled caches or credential reads.
Only the disposable transport snapshot uses path dependencies. It materializes
internal symlinks and relocates non-build filenames rejected by the transport,
recording every relocation without dropping the original bytes. Build inputs with
unsupported filenames fail closed. The candidate checkout is not modified.

Diagnostics so far: invoking the wrapper with `--help` was interpreted as a build
request and rejected HTTP 422 (`argv[0] must be one of lake/lean`). First complete
snapshot preparation stopped on `remote-deps/batteries/docs/README.md` symlink.
The next request stopped before submission on transport-invalid path
`remote-deps/verity/docs-site/app/[[...mdxPath]]/page.tsx`. Both have explicit
transport-only handling in the preparation script. No failed preflight is a build
receipt. Snapshot SHA/manifest and final job logs must be reconciled with the actual
candidate source before they can support validation.

## Latest evidence

The receipt packet under `receipts/` is partial validation evidence, with its scope
and reproduction commands in `reproduce.md`. All nine owned Lean modules pass the
bounded Init-only checker. The evaluated vector JSON is byte-identical after the
encoding proof refinement (SHA-256
`eaac1882ec16fe743d11fd4b2309910896fcffe7d285f72a33a697c373c4ecde`).
Proof-escape, source-annotation, report-inventory and pinned Verity provenance
checks pass. `make test` stops at shared UX2. Remote build requests are rejected by
source request-size limits or the ashur node disk admission floor; exact messages
are recorded in `reproduce.md` and the job diagnostics. No remote heavy validation
succeeded during this continuation.

ALLOC-2 remains authoritatively active/healthy, with its current run ID confirmed
on 2026-09-07. Messages provide the producer declarations and draft PR. No explicit
acceptance has been received in this mission, so mediated agreement remains pending.
The interface has not been changed incompatibly.
