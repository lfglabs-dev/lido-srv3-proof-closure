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
  bounds on the checked executor's returned capacity word.
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
| Physical storage | Slot formulas and width proofs implemented. Bind router-slot/hash to actual deployment; execute compiler layout checks and prove writer transitions. |
| Reachable bounds, address uniqueness | Width bounds derived. Count<=32, share<=10000, unique addresses, admission and migration reachability remain open; never imposed as read guards. |
| Exact call and error behavior | Ordered executor and regressions implemented. Compiler enum/call decoder behavior and panic bytes still need executed confirmation and all-outcome source relation. |
| Independent specification | Second-pass Nat spec and proof implemented. First-pass/call-level independent relational specification still open. |
| Memory / ABI | v0 word-memory relation only. Construct actual memory, prove byte relation, allocation failures and consumer ABI bridge. |
| Rollback / sequential behavior | View executor has no state effects. This alone does not establish parent/writer rollback or callback realization; those proofs/tests remain open. |
| ALLOC-2 interface | Messages sent to mission 44053c4f-2578-4df5-84f2-4f66bc73586a. v0 unchanged; agreement and composition consumer evidence pending. |
| Differential execution | Pinned helper harness added; Solidity-vs-Verity execution remains open. Lean reductions alone are not differential evidence. |
| Full verification | Production/test/trust, make prove/test, annotations/metadata/inventory/provenance/proof-escape and parent-shaped executed mutations remain required. |
| Delivery | Scoped PR and immutable validated SHA still required; no merge, publication or self-certification authorized. |

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
