# How assumptions are shown

The website groups model behaviour, correspondence between the reviewed source
and deployment, and configured addresses and deposit amounts. Their text and individual parts live
in `assumption-presentation.json`. The website copies this file from its pinned
proof checkout and checks that both copies match.

These are presentation groups, not new assumptions or proofs. The IDs, scope,
acceptance and risk records in `assumptions.yaml`, and each guarantee's IDs in
`guarantees.yaml`, remain authoritative. Wording corrections do not change theorem hypotheses or
proof status.

For each guarantee, include only the parts whose IDs occur in its assumption
list. Join those parts in catalog order. Omit empty groups. Keep other assumptions
separate, including hashing, arithmetic bounds and proof-artifact transport. Do not
use the text of a complete group for a partial match.

Show the explanation once, with the applicable assumption IDs spaced underneath.
Do not repeat the individual explanations in an expandable block. The catalog
retains the separate parts for traceability. In particular, ALLOC-2 keeps its handwritten
min-first limitation, and SSZ keeps its Yul/interface limitation without acquiring
a Verity-runtime or Solidity-transcription premise it does not declare.

Neither grouping nor a successful deployment check closes a model correspondence
gap. The checks described by the deployment group do not certify the compiler.

## Review of the eight unpublished cards

No theorem, proof status or canonical fidelity entry changes in this review.
The website keeps these cards disabled. Two assumption records need more precise
scope: A-TOPUP-NOWRAP is not a general hypothesis of the current wrapping-aware
parent; A-CONSOLIDATION-GATEWAY-NONZERO concerns value forwarded to the vault,
not the gateway’s outer payment. The gateway forwards count * fee and refunds
the remainder (ConsolidationGateway.sol:212-222 at 17005714). A positive outer
payment therefore does not establish a positive vault payment.

Keep concrete differences visible in the website’s disclosure dispositions:
deposit aggregate calls and two-batch rollback; accounting’s supplied registration
list and omitted empty-report branch; consolidation key checks before the fee
rather than within the request loop after the fee; single-call top-up caps;
address renaming over modeled fields; and structural hashing distinct from
SHA-256. Supplementary evidence does not replace the registered parents.
